// @ts-nocheck
import db from '../database';
import { PasswordUtils } from '../utils/password';
import { JWTUtils } from '../utils/jwt';
import logger from '../utils/logger';
import { User, UserRole, TransactionStatus, KYCStatus, PaginationParams } from '../types';
import * as speakeasy from 'speakeasy';

export class AdminService {
  /**
   * Admin login with 2FA/TOTP
   */
  static async login(
    email: string,
    password: string,
    totpCode?: string
  ): Promise<{
    requiresTOTP?: boolean;
    accessToken?: string;
    refreshToken?: string;
    expiresIn?: number;
    admin?: Partial<User>;
  }> {
    try {
      // Get admin user
      const users = await db.query<User>(
        `SELECT id, email, password_hash, is_active, role, first_name, last_name,
                two_factor_enabled, two_factor_secret, locked_until, failed_login_attempts
         FROM users
         WHERE email = $1 AND (role = $2 OR role = $3)`,
        [email, UserRole.ADMIN, UserRole.SUPER_ADMIN]
      );

      if (users.length === 0) {
        // Log attempt with non-existent email for security monitoring
        logger.warn('Admin login attempt with non-existent email', {
          email,
          timestamp: new Date().toISOString(),
        });

        // Return generic error to prevent email enumeration
        throw new Error('INVALID_CREDENTIALS');
      }

      const admin = users[0];

      // Check if account is locked
      if (admin.locked_until && new Date(admin.locked_until) > new Date()) {
        const remainingMinutes = Math.ceil((new Date(admin.locked_until).getTime() - Date.now()) / (1000 * 60));
        const error: any = new Error('ACCOUNT_LOCKED');
        error.remainingTime = remainingMinutes;
        throw error;
      }

      // Check if account is active
      if (!admin.is_active) {
        throw new Error('ACCOUNT_INACTIVE');
      }

      // Verify password
      const isValidPassword = await PasswordUtils.compare(password, admin.password_hash);

      if (!isValidPassword) {
        // Increment failed attempts
        const attempts = admin.failed_login_attempts + 1;
        const lockedUntil = attempts >= 5 ? new Date(Date.now() + 30 * 60 * 1000) : null;

        await db.query(
          'UPDATE users SET failed_login_attempts = $1, locked_until = $2 WHERE id = $3',
          [attempts, lockedUntil, admin.id]
        );

        // Log failed attempt for security monitoring
        logger.warn('Failed admin login attempt', {
          email,
          adminId: admin.id,
          attemptNumber: attempts,
          isLocked: !!lockedUntil,
          lockedUntil: lockedUntil?.toISOString(),
        });

        throw new Error('INVALID_CREDENTIALS');
      }

      // Check if 2FA is enabled
      if (admin.two_factor_enabled && admin.two_factor_secret) {
        if (!totpCode) {
          // Reset failed attempts on successful password
          await db.query(
            'UPDATE users SET failed_login_attempts = 0, locked_until = NULL WHERE id = $1',
            [admin.id]
          );
          return { requiresTOTP: true };
        }

        // Verify TOTP code
        const verified = speakeasy.totp.verify({
          secret: admin.two_factor_secret,
          encoding: 'base32',
          token: totpCode,
          window: 2, // Allow 2 steps (60 seconds) before/after
        });

        if (!verified) {
          throw new Error('INVALID_TOTP_CODE');
        }
      }

      // Reset failed attempts
      await db.query(
        'UPDATE users SET failed_login_attempts = 0, locked_until = NULL, last_login_at = NOW() WHERE id = $1',
        [admin.id]
      );

      // Generate tokens
      const accessToken = JWTUtils.generateAccessToken(
        admin.id,
        admin.role,
        admin.email
      );

      const refreshToken = JWTUtils.generateRefreshToken(
        admin.id,
        admin.role,
        admin.email
      );

      // Store refresh token
      const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
      await db.query(
        'INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES ($1, $2, $3)',
        [admin.id, refreshToken, expiresAt]
      );

      logger.info('Admin logged in', { adminId: admin.id, email, role: admin.role });

      return {
        accessToken,
        refreshToken,
        expiresIn: 3600,
        admin: {
          id: admin.id,
          first_name: admin.first_name,
          last_name: admin.last_name,
          email: admin.email,
          role: admin.role,
        },
      };
    } catch (error) {
      logger.error('Error in admin login', error);
      throw error;
    }
  }

  /**
   * Get dashboard statistics
   */
  static async getDashboardStats(): Promise<{
    totalUsers: number;
    totalTransactions: number;
    totalRevenue: number;
    activeAgents: number;
    pendingWithdrawals: number;
    pendingKYC: number;
    todayRevenue: number;
    todayTransactions: number;
  }> {
    try {
      // Total users
      const userResult = await db.query<{ count: string }>(
        "SELECT COUNT(*) as count FROM users WHERE role = 'USER'"
      );
      const totalUsers = parseInt(userResult[0]?.count || '0');

      // Total transactions and revenue
      const transactionResult = await db.query<{ count: string; revenue: string }>(
        `SELECT COUNT(*) as count, COALESCE(SUM(amount), 0) as revenue
         FROM transactions WHERE status = 'COMPLETED'`
      );
      const totalTransactions = parseInt(transactionResult[0]?.count || '0');
      const totalRevenue = parseFloat(transactionResult[0]?.revenue || '0');

      // Active agents
      const agentResult = await db.query<{ count: string }>(
        'SELECT COUNT(*) as count FROM agents WHERE active_status = true'
      );
      const activeAgents = parseInt(agentResult[0]?.count || '0');

      // Pending withdrawals
      const withdrawalResult = await db.query<{ count: string }>(
        "SELECT COUNT(*) as count FROM withdrawal_requests WHERE status = 'PENDING'"
      );
      const pendingWithdrawals = parseInt(withdrawalResult[0]?.count || '0');

      // Pending KYC
      const kycResult = await db.query<{ count: string }>(
        "SELECT COUNT(*) as count FROM users WHERE kyc_status = 'SUBMITTED'"
      );
      const pendingKYC = parseInt(kycResult[0]?.count || '0');

      // Today's revenue and transactions
      const todayResult = await db.query<{ count: string; revenue: string }>(
        `SELECT COUNT(*) as count, COALESCE(SUM(amount), 0) as revenue
         FROM transactions
         WHERE status = 'COMPLETED' AND DATE(created_at) = CURRENT_DATE`
      );
      const todayTransactions = parseInt(todayResult[0]?.count || '0');
      const todayRevenue = parseFloat(todayResult[0]?.revenue || '0');

      return {
        totalUsers,
        totalTransactions,
        totalRevenue,
        activeAgents,
        pendingWithdrawals,
        pendingKYC,
        todayRevenue,
        todayTransactions,
      };
    } catch (error) {
      logger.error('Error getting dashboard stats', error);
      throw error;
    }
  }

  /**
   * Get users with filters and pagination
   */
  static async getUsers(
    filters: {
      search?: string;
      role?: UserRole;
      kyc_status?: KYCStatus;
      is_active?: boolean;
    },
    pagination: PaginationParams
  ): Promise<{ users: Partial<User>[]; total: number }> {
    try {
      const conditions: string[] = [];
      const params: any[] = [];
      let paramCount = 1;

      // Build WHERE clause
      if (filters.search) {
        conditions.push(
          `(first_name ILIKE $${paramCount} OR last_name ILIKE $${paramCount} OR email ILIKE $${paramCount} OR phone ILIKE $${paramCount})`
        );
        params.push(`%${filters.search}%`);
        paramCount++;
      }

      if (filters.role) {
        conditions.push(`role = $${paramCount}`);
        params.push(filters.role);
        paramCount++;
      }

      if (filters.kyc_status) {
        conditions.push(`kyc_status = $${paramCount}`);
        params.push(filters.kyc_status);
        paramCount++;
      }

      if (filters.is_active !== undefined) {
        conditions.push(`is_active = $${paramCount}`);
        params.push(filters.is_active);
        paramCount++;
      }

      const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

      // Get total count
      const countQuery = `SELECT COUNT(*) as count FROM users ${whereClause}`;
      const countResult = await db.query<{ count: string }>(countQuery, params);
      const total = parseInt(countResult[0]?.count || '0');

      // Get users
      params.push(pagination.limit, pagination.offset);
      const query = `
        SELECT id, first_name, last_name, email, phone, country_code, role,
               kyc_status, is_active, is_verified, created_at, last_login_at
        FROM users
        ${whereClause}
        ORDER BY created_at DESC
        LIMIT $${paramCount} OFFSET $${paramCount + 1}
      `;

      const users = await db.query<User>(query, params);

      return { users, total };
    } catch (error) {
      logger.error('Error getting users', error);
      throw error;
    }
  }

  /**
   * Get withdrawal requests
   */
  static async getWithdrawals(
    status?: TransactionStatus,
    pagination?: PaginationParams
  ): Promise<{ withdrawals: any[]; total: number }> {
    try {
      const params: any[] = [];
      let whereClause = '';
      let paramCount = 1;

      if (status) {
        whereClause = `WHERE wr.status = $${paramCount}`;
        params.push(status);
        paramCount++;
      }

      // Get total count
      const countQuery = `SELECT COUNT(*) as count FROM withdrawal_requests wr ${whereClause}`;
      const countResult = await db.query<{ count: string }>(countQuery, params);
      const total = parseInt(countResult[0]?.count || '0');

      // Get withdrawals with user info
      if (pagination) {
        params.push(pagination.limit, pagination.offset);
      }

      const query = `
        SELECT wr.id, wr.user_id, wr.amount, wr.fee, wr.net_amount,
               wr.withdrawal_type, wr.destination, wr.status,
               wr.rejection_reason, wr.created_at, wr.approved_at,
               u.first_name, u.last_name, u.email, u.phone,
               ba.bank_name, ba.account_number
        FROM withdrawal_requests wr
        JOIN users u ON wr.user_id = u.id
        LEFT JOIN bank_accounts ba ON wr.bank_account_id = ba.id
        ${whereClause}
        ORDER BY wr.created_at DESC
        ${pagination ? `LIMIT $${paramCount} OFFSET $${paramCount + 1}` : ''}
      `;

      const withdrawals = await db.query(query, params);

      return { withdrawals, total };
    } catch (error) {
      logger.error('Error getting withdrawals', error);
      throw error;
    }
  }

  /**
   * Get agents with filters and pagination
   */
  static async getAgents(
    filters: {
      search?: string;
      active_status?: boolean;
      location?: string;
    },
    pagination: PaginationParams
  ): Promise<{ agents: any[]; total: number }> {
    try {
      const conditions: string[] = [];
      const params: any[] = [];
      let paramCount = 1;

      // Build WHERE clause
      if (filters.search) {
        conditions.push(
          `(u.first_name ILIKE $${paramCount} OR u.last_name ILIKE $${paramCount} OR u.email ILIKE $${paramCount} OR u.phone ILIKE $${paramCount})`
        );
        params.push(`%${filters.search}%`);
        paramCount++;
      }

      if (filters.active_status !== undefined) {
        conditions.push(`a.active_status = $${paramCount}`);
        params.push(filters.active_status);
        paramCount++;
      }

      if (filters.location) {
        conditions.push(`a.location_address ILIKE $${paramCount}`);
        params.push(`%${filters.location}%`);
        paramCount++;
      }

      const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

      // Get total count
      const countQuery = `
        SELECT COUNT(*) as count
        FROM agents a
        JOIN users u ON a.user_id = u.id
        ${whereClause}
      `;
      const countResult = await db.query<{ count: string }>(countQuery, params);
      const total = parseInt(countResult[0]?.count || '0');

      // Get agents with pagination
      // Add pagination params at the end
      const limitParam = paramCount;
      const offsetParam = paramCount + 1;
      params.push(pagination.limit, pagination.offset);

      const query = `
        SELECT
          a.id, a.user_id, a.wallet_balance, a.commission_rate,
          a.total_commission_earned, a.total_transactions_processed, a.active_status,
          a.location_lat, a.location_lng, a.location_address,
          a.verification_status, a.verified_at,
          a.created_at, a.updated_at,
          u.first_name, u.last_name, u.email, u.phone,
          u.kyc_status, u.is_active, u.is_verified,
          u.last_login_at
        FROM agents a
        JOIN users u ON a.user_id = u.id
        ${whereClause}
        ORDER BY a.created_at DESC
        LIMIT $${limitParam} OFFSET $${offsetParam}
      `;

      const agents = await db.query(query, params);

      return { agents, total };
    } catch (error) {
      logger.error('Error getting agents', error);
      throw error;
    }
  }

  /**
   * Get transactions with filters and pagination
   */
  static async getTransactions(
    filters: {
      search?: string;
      type?: string;
      status?: string;
      start_date?: string;
      end_date?: string;
    },
    pagination: PaginationParams
  ): Promise<{ transactions: any[]; total: number }> {
    try {
      const conditions: string[] = [];
      const params: any[] = [];
      let paramCount = 1;

      // Build WHERE clause
      if (filters.search) {
        conditions.push(
          `(t.id::text ILIKE $${paramCount} OR t.transaction_id ILIKE $${paramCount} OR t.from_user_id::text ILIKE $${paramCount} OR t.to_user_id::text ILIKE $${paramCount})`
        );
        params.push(`%${filters.search}%`);
        paramCount++;
      }

      if (filters.type) {
        conditions.push(`t.type = $${paramCount}`);
        params.push(filters.type);
        paramCount++;
      }

      if (filters.status) {
        conditions.push(`t.status = $${paramCount}`);
        params.push(filters.status);
        paramCount++;
      }

      if (filters.start_date) {
        conditions.push(`t.created_at >= $${paramCount}`);
        params.push(filters.start_date);
        paramCount++;
      }

      if (filters.end_date) {
        conditions.push(`t.created_at <= $${paramCount}`);
        params.push(filters.end_date);
        paramCount++;
      }

      const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

      // Get total count
      const countQuery = `
        SELECT COUNT(*) as count
        FROM transactions t
        ${whereClause}
      `;
      const countResult = await db.query<{ count: string }>(countQuery, params);
      const total = parseInt(countResult[0]?.count || '0');

      // Get transactions with pagination
      const limitParam = paramCount;
      const offsetParam = paramCount + 1;
      params.push(pagination.limit, pagination.offset);

      const query = `
        SELECT
          t.id, t.transaction_id, t.type, t.status,
          t.from_user_id, t.to_user_id,
          t.amount, t.fee, t.net_amount,
          t.payment_method, t.deposit_source,
          t.description, t.metadata, t.reference,
          t.created_at, t.updated_at, t.processed_at,
          t.failed_at, t.failure_reason,
          from_user.first_name as from_user_first_name,
          from_user.last_name as from_user_last_name,
          from_user.email as from_user_email,
          from_user.phone as from_user_phone,
          to_user.first_name as to_user_first_name,
          to_user.last_name as to_user_last_name,
          to_user.email as to_user_email,
          to_user.phone as to_user_phone
        FROM transactions t
        LEFT JOIN users from_user ON t.from_user_id = from_user.id
        LEFT JOIN users to_user ON t.to_user_id = to_user.id
        ${whereClause}
        ORDER BY t.created_at DESC
        LIMIT $${limitParam} OFFSET $${offsetParam}
      `;

      const transactions = await db.query(query, params);

      return { transactions, total };
    } catch (error) {
      logger.error('Error getting transactions', error);
      throw error;
    }
  }

  /**
   * Create new agent
   */
  static async createAgent(data: {
    first_name: string;
    last_name: string;
    email: string;
    password: string;
    phone: string;
    country_code?: string;
    location_address?: string;
    commission_rate?: number;
  }): Promise<any> {
    try {
      // Check if user with email already exists
      const existingUser = await db.query(
        'SELECT id FROM users WHERE email = $1',
        [data.email]
      );

      if (existingUser.length > 0) {
        throw new Error('USER_EXISTS');
      }

      // Hash password
      const passwordHash = await PasswordUtils.hash(data.password);

      // Create user with AGENT role
      const userResult = await db.query<User>(
        `INSERT INTO users (
          role, first_name, last_name, email, phone, country_code,
          password_hash, kyc_status, is_active, is_verified
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING id, role, first_name, last_name, email, phone,
                  country_code, kyc_status, is_active, is_verified, created_at`,
        [
          UserRole.AGENT,
          data.first_name,
          data.last_name,
          data.email,
          data.phone,
          data.country_code || '+232',
          passwordHash,
          KYCStatus.PENDING,
          true,
          false,
        ]
      );

      const user = userResult[0];

      // Create agent record
      const agentResult = await db.query(
        `INSERT INTO agents (
          user_id, wallet_balance, active_status, location_address, commission_rate
        ) VALUES ($1, $2, $3, $4, $5)
        RETURNING id, user_id, wallet_balance, active_status, location_address,
                  commission_rate, total_commission_earned, total_transactions_processed,
                  verification_status, created_at, updated_at`,
        [
          user.id,
          0,
          true,
          data.location_address || null,
          data.commission_rate || 2.5,
        ]
      );

      const agent = agentResult[0];

      logger.info('Agent created', { agentId: agent.id, userId: user.id });

      return {
        ...agent,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        phone: user.phone,
        country_code: user.country_code,
        kyc_status: user.kyc_status,
        is_active: user.is_active,
        is_verified: user.is_verified,
      };
    } catch (error) {
      logger.error('Error creating agent', error);
      throw error;
    }
  }

  /**
   * Create new user
   */
  static async createUser(data: {
    first_name: string;
    last_name: string;
    email: string;
    password: string;
    phone?: string;
    country_code?: string;
    role?: UserRole;
  }): Promise<any> {
    try {
      // Check if user with email already exists
      const existingUser = await db.query(
        'SELECT id FROM users WHERE email = $1',
        [data.email]
      );

      if (existingUser.length > 0) {
        throw new Error('USER_EXISTS');
      }

      // Check if phone is provided (required for non-admin users)
      if (!data.phone && data.role !== UserRole.ADMIN && data.role !== UserRole.SUPER_ADMIN) {
        throw new Error('PHONE_REQUIRED');
      }

      // Hash password
      const passwordHash = await PasswordUtils.hash(data.password);

      // Create user with specified role (default to USER)
      const role = data.role || UserRole.USER;

      const userResult = await db.query<User>(
        `INSERT INTO users (
          role, first_name, last_name, email, phone, country_code,
          password_hash, kyc_status, is_active, is_verified
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING id, role, first_name, last_name, email, phone,
                  country_code, kyc_status, is_active,
                  is_verified, created_at`,
        [
          role,
          data.first_name,
          data.last_name,
          data.email,
          data.phone || '',
          data.country_code || '+232',
          passwordHash,
          KYCStatus.PENDING,
          true,
          false,
        ]
      );

      const user = userResult[0];

      // Create wallet for the user
      await db.query(
        'INSERT INTO wallets (user_id, balance, currency) VALUES ($1, $2, $3)',
        [user.id, 0, 'SLL']
      );

      logger.info('User created', { userId: user.id, email: data.email });

      return {
        id: user.id,
        role: user.role,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        phone: user.phone,
        country_code: user.country_code,
        kyc_status: user.kyc_status,
        is_active: user.is_active,
        is_verified: user.is_verified,
        created_at: user.created_at,
      };
    } catch (error) {
      logger.error('Error creating user', error);
      throw error;
    }
  }

  /**
   * Update user status (activate, suspend, deactivate)
   */
  static async updateUserStatus(userId: string, status: string): Promise<any> {
    try {
      // Validate status
      const validStatuses = ['ACTIVE', 'INACTIVE', 'SUSPENDED'];
      if (!validStatuses.includes(status)) {
        throw new Error('INVALID_STATUS');
      }

      // Check if user exists
      const existingUser = await db.query(
        'SELECT id FROM users WHERE id = $1',
        [userId]
      );

      if (existingUser.length === 0) {
        throw new Error('USER_NOT_FOUND');
      }

      // Update user status
      const isActive = status === 'ACTIVE';
      const userResult = await db.query<User>(
        `UPDATE users
         SET is_active = $1, status = $2, updated_at = NOW()
         WHERE id = $3
         RETURNING id, role, first_name, last_name, email, phone,
                   country_code, kyc_status, is_active, status,
                   is_verified, created_at, updated_at`,
        [isActive, status, userId]
      );

      const user = userResult[0];

      logger.info('User status updated', { userId, status });

      return {
        id: user.id,
        role: user.role,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        phone: user.phone,
        country_code: user.country_code,
        kyc_status: user.kyc_status,
        status: user.status || (user.is_active ? 'ACTIVE' : 'INACTIVE'),
        is_active: user.is_active,
        is_verified: user.is_verified,
        created_at: user.created_at,
      };
    } catch (error) {
      logger.error('Error updating user status', error);
      throw error;
    }
  }

  /**
   * Review withdrawal request (approve/reject)
   */
  static async reviewWithdrawal(
    adminId: string,
    withdrawalId: string,
    status: 'COMPLETED' | 'REJECTED',
    reason?: string
  ): Promise<void> {
    try {
      // Get withdrawal request
      const withdrawals = await db.query(
        'SELECT * FROM withdrawal_requests WHERE id = $1',
        [withdrawalId]
      );

      if (withdrawals.length === 0) {
        throw new Error('WITHDRAWAL_NOT_FOUND');
      }

      const withdrawal = withdrawals[0];

      if (withdrawal.status !== 'PENDING') {
        throw new Error('WITHDRAWAL_ALREADY_PROCESSED');
      }

      await db.transaction(async (client) => {
        if (status === 'COMPLETED') {
          // Create transaction
          const transactionId = await client.query(
            `INSERT INTO transactions (
              type, from_user_id, amount, fee, net_amount, status, description
            ) VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING id`,
            [
              'WITHDRAWAL',
              withdrawal.user_id,
              withdrawal.amount,
              withdrawal.fee,
              withdrawal.net_amount,
              'COMPLETED',
              `Withdrawal approved by admin`,
            ]
          );

          // Update withdrawal request
          await client.query(
            `UPDATE withdrawal_requests
             SET status = $1, admin_id = $2, approved_at = NOW(),
                 transaction_id = $3, updated_at = NOW()
             WHERE id = $4`,
            [status, adminId, transactionId.rows[0].id, withdrawalId]
          );

          // Deduct from wallet (already deducted on request, so just update transaction)
          await client.query(
            'UPDATE wallets SET last_transaction_at = NOW() WHERE user_id = $1',
            [withdrawal.user_id]
          );
        } else {
          // Rejected - refund to wallet
          await client.query(
            `UPDATE withdrawal_requests
             SET status = $1, admin_id = $2, rejected_at = NOW(),
                 rejection_reason = $3, updated_at = NOW()
             WHERE id = $4`,
            [status, adminId, reason, withdrawalId]
          );

          // Refund to wallet
          await client.query(
            'UPDATE wallets SET balance = balance + $1 WHERE user_id = $2',
            [withdrawal.amount, withdrawal.user_id]
          );
        }

        // Create notification
        await client.query(
          `INSERT INTO notifications (user_id, type, title, message)
           VALUES ($1, $2, $3, $4)`,
          [
            withdrawal.user_id,
            'WITHDRAWAL',
            status === 'COMPLETED' ? 'Withdrawal Approved' : 'Withdrawal Rejected',
            status === 'COMPLETED'
              ? `Your withdrawal of ${withdrawal.amount} has been approved and processed.`
              : `Your withdrawal of ${withdrawal.amount} was rejected. ${reason || ''}`,
          ]
        );

        // Log admin action
        await client.query(
          `INSERT INTO admin_audit_logs (admin_id, action, entity_type, entity_id, changes)
           VALUES ($1, $2, $3, $4, $5)`,
          [
            adminId,
            status === 'COMPLETED' ? 'APPROVE_WITHDRAWAL' : 'REJECT_WITHDRAWAL',
            'WITHDRAWAL',
            withdrawalId,
            JSON.stringify({ status, reason }),
          ]
        );
      });

      logger.info('Withdrawal reviewed', { adminId, withdrawalId, status });
    } catch (error) {
      logger.error('Error reviewing withdrawal', error);
      throw error;
    }
  }

  /**
   * Review agent credit request
   */
  static async reviewAgentCredit(
    adminId: string,
    requestId: string,
    status: 'COMPLETED' | 'REJECTED',
    reason?: string
  ): Promise<void> {
    try {
      // Get credit request
      const requests = await db.query(
        'SELECT * FROM agent_credit_requests WHERE id = $1',
        [requestId]
      );

      if (requests.length === 0) {
        throw new Error('REQUEST_NOT_FOUND');
      }

      const request = requests[0];

      if (request.status !== 'PENDING') {
        throw new Error('REQUEST_ALREADY_PROCESSED');
      }

      await db.transaction(async (client) => {
        if (status === 'COMPLETED') {
          // Update agent wallet
          await client.query(
            'UPDATE agents SET wallet_balance = wallet_balance + $1 WHERE id = $2',
            [request.amount, request.agent_id]
          );

          // Create transaction record
          const agentUser = await client.query(
            'SELECT user_id FROM agents WHERE id = $1',
            [request.agent_id]
          );

          await client.query(
            `INSERT INTO transactions (
              type, to_user_id, amount, fee, net_amount, status, description, metadata
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
            [
              'AGENT_CREDIT',
              agentUser.rows[0].user_id,
              request.amount,
              0,
              request.amount,
              'COMPLETED',
              'Agent credit approved',
              JSON.stringify({ request_id: requestId }),
            ]
          );

          // Update request
          await client.query(
            `UPDATE agent_credit_requests
             SET status = $1, admin_id = $2, approved_at = NOW()
             WHERE id = $3`,
            [status, adminId, requestId]
          );
        } else {
          // Rejected
          await client.query(
            `UPDATE agent_credit_requests
             SET status = $1, admin_id = $2, rejected_at = NOW(), rejection_reason = $3
             WHERE id = $4`,
            [status, adminId, reason, requestId]
          );
        }

        // Log admin action
        await client.query(
          `INSERT INTO admin_audit_logs (admin_id, action, entity_type, entity_id, changes)
           VALUES ($1, $2, $3, $4, $5)`,
          [
            adminId,
            status === 'COMPLETED' ? 'APPROVE_AGENT_CREDIT' : 'REJECT_AGENT_CREDIT',
            'AGENT_CREDIT',
            requestId,
            JSON.stringify({ status, reason }),
          ]
        );
      });

      logger.info('Agent credit reviewed', { adminId, requestId, status });
    } catch (error) {
      logger.error('Error reviewing agent credit', error);
      throw error;
    }
  }

  /**
   * Get system configuration
   */
  static async getSystemConfig(): Promise<Record<string, any>> {
    try {
      const configs = await db.query<{
        key: string;
        value: string;
        data_type: string;
        category: string;
        description: string;
      }>('SELECT key, value, data_type, category, description FROM system_config ORDER BY category, key');

      const configObject: Record<string, any> = {};

      configs.forEach((config) => {
        let parsedValue: any = config.value;

        // Parse based on data type
        switch (config.data_type) {
          case 'NUMBER':
            parsedValue = parseFloat(config.value);
            break;
          case 'BOOLEAN':
            parsedValue = config.value.toLowerCase() === 'true';
            break;
          case 'JSON':
            parsedValue = JSON.parse(config.value);
            break;
          default:
            parsedValue = config.value;
        }

        configObject[config.key] = {
          value: parsedValue,
          category: config.category,
          description: config.description,
          type: config.data_type,
        };
      });

      return configObject;
    } catch (error) {
      logger.error('Error getting system config', error);
      throw error;
    }
  }

  /**
   * Update system configuration
   */
  static async updateSystemConfig(
    adminId: string,
    config: Record<string, any>
  ): Promise<void> {
    try {
      await db.transaction(async (client) => {
        for (const [key, value] of Object.entries(config)) {
          await client.query(
            'UPDATE system_config SET value = $1, updated_by = $2, updated_at = NOW() WHERE key = $3',
            [String(value), adminId, key]
          );
        }

        // Log admin action
        await client.query(
          `INSERT INTO admin_audit_logs (admin_id, action, entity_type, changes)
           VALUES ($1, $2, $3, $4)`,
          [adminId, 'UPDATE_SYSTEM_CONFIG', 'SYSTEM_CONFIG', JSON.stringify(config)]
        );
      });

      logger.info('System config updated', { adminId, keys: Object.keys(config) });
    } catch (error) {
      logger.error('Error updating system config', error);
      throw error;
    }
  }

  /**
   * Generate report
   */
  static async generateReport(
    type: 'transactions' | 'investments' | 'users',
    format: 'json' | 'csv' | 'pdf',
    dateRange?: { from: Date; to: Date }
  ): Promise<any> {
    try {
      // TODO: Implement CSV and PDF generation
      if (format !== 'json') {
        throw new Error('FORMAT_NOT_SUPPORTED_YET');
      }

      let data: any[] = [];

      switch (type) {
        case 'transactions':
          const transactionQuery = `
            SELECT t.id, t.transaction_id, t.type, t.amount, t.fee, t.net_amount,
                   t.status, t.created_at,
                   u1.email as from_email, u2.email as to_email
            FROM transactions t
            LEFT JOIN users u1 ON t.from_user_id = u1.id
            LEFT JOIN users u2 ON t.to_user_id = u2.id
            ${dateRange ? 'WHERE t.created_at BETWEEN $1 AND $2' : ''}
            ORDER BY t.created_at DESC
          `;
          data = await db.query(
            transactionQuery,
            dateRange ? [dateRange.from, dateRange.to] : []
          );
          break;

        case 'investments':
          const investmentQuery = `
            SELECT i.id, i.category, i.amount, i.tenure_months, i.return_rate,
                   i.expected_return, i.status, i.start_date, i.end_date,
                   u.email as user_email, u.first_name, u.last_name
            FROM investments i
            JOIN users u ON i.user_id = u.id
            ${dateRange ? 'WHERE i.created_at BETWEEN $1 AND $2' : ''}
            ORDER BY i.created_at DESC
          `;
          data = await db.query(
            investmentQuery,
            dateRange ? [dateRange.from, dateRange.to] : []
          );
          break;

        case 'users':
          const userQuery = `
            SELECT u.id, u.first_name, u.last_name, u.email, u.phone, u.role,
                   u.kyc_status, u.is_active, u.created_at, w.balance
            FROM users u
            LEFT JOIN wallets w ON u.id = w.user_id
            ${dateRange ? 'WHERE u.created_at BETWEEN $1 AND $2' : ''}
            ORDER BY u.created_at DESC
          `;
          data = await db.query(userQuery, dateRange ? [dateRange.from, dateRange.to] : []);
          break;

        default:
          throw new Error('INVALID_REPORT_TYPE');
      }

      return {
        type,
        format,
        dateRange,
        generatedAt: new Date(),
        data,
        count: data.length,
      };
    } catch (error) {
      logger.error('Error generating report', error);
      throw error;
    }
  }

  /**
   * Get comprehensive analytics KPIs
   */
  static async getAnalyticsKPI(dateRange?: { from: Date; to: Date }): Promise<any> {
    try {
      const dateFilter = dateRange
        ? `WHERE created_at BETWEEN '${dateRange.from.toISOString()}' AND '${dateRange.to.toISOString()}'`
        : '';

      // Transaction analytics
      const transactionAnalytics = await db.query(`
        SELECT
          COUNT(*) as total_count,
          COUNT(*) FILTER (WHERE status = 'COMPLETED') as completed_count,
          COUNT(*) FILTER (WHERE status = 'FAILED') as failed_count,
          COALESCE(SUM(amount) FILTER (WHERE status = 'COMPLETED'), 0) as total_volume,
          COALESCE(SUM(fee) FILTER (WHERE status = 'COMPLETED'), 0) as total_fees,
          COALESCE(AVG(amount) FILTER (WHERE status = 'COMPLETED'), 0) as avg_transaction_amount
        FROM transactions ${dateFilter}
      `);

      // User analytics
      const userAnalytics = await db.query(`
        SELECT
          COUNT(*) as total_users,
          COUNT(*) FILTER (WHERE is_active = true) as active_users,
          COUNT(*) FILTER (WHERE kyc_status = 'APPROVED') as kyc_approved_users,
          COUNT(*) FILTER (WHERE DATE(created_at) = CURRENT_DATE) as new_users_today
        FROM users WHERE role = 'USER' ${dateRange ? `AND created_at BETWEEN '${dateRange.from.toISOString()}' AND '${dateRange.to.toISOString()}'` : ''}
      `);

      // Investment analytics
      const investmentAnalytics = await db.query(`
        SELECT
          COUNT(*) as total_investments,
          COUNT(*) FILTER (WHERE status = 'ACTIVE') as active_investments,
          COALESCE(SUM(amount), 0) as total_invested,
          COALESCE(SUM(expected_return), 0) as expected_returns
        FROM investments ${dateFilter}
      `);

      // Agent analytics
      const agentAnalytics = await db.query(`
        SELECT
          COUNT(*) as total_agents,
          COUNT(*) FILTER (WHERE active_status = true) as active_agents,
          COALESCE(SUM(total_commission_earned), 0) as total_commissions
        FROM agents
      `);

      return {
        dateRange,
        transactions: transactionAnalytics[0],
        users: userAnalytics[0],
        investments: investmentAnalytics[0],
        agents: agentAnalytics[0],
        generatedAt: new Date(),
      };
    } catch (error) {
      logger.error('Error getting analytics KPI', error);
      throw error;
    }
  }

  /**
   * Get bill payments for admin with filters and pagination
   */
  static async getBillPayments(
    pagination: PaginationParams,
    filters?: {
      billType?: string;
      status?: TransactionStatus;
      fromDate?: Date;
      toDate?: Date;
      search?: string;
    }
  ): Promise<{
    billPayments: any[];
    pagination: {
      page: number;
      limit: number;
      total: number;
      totalPages: number;
    };
  }> {
    try {
      const conditions = ['1=1']; // Always true base condition
      const params: any[] = [];
      let paramCount = 1;

      // Apply filters
      if (filters?.billType) {
        conditions.push(`bp.bill_type = $${paramCount}`);
        params.push(filters.billType);
        paramCount++;
      }

      if (filters?.status) {
        conditions.push(`bp.status = $${paramCount}`);
        params.push(filters.status);
        paramCount++;
      }

      if (filters?.fromDate) {
        conditions.push(`bp.created_at >= $${paramCount}`);
        params.push(filters.fromDate);
        paramCount++;
      }

      if (filters?.toDate) {
        conditions.push(`bp.created_at <= $${paramCount}`);
        params.push(filters.toDate);
        paramCount++;
      }

      if (filters?.search) {
        conditions.push(
          `(bp.bill_id ILIKE $${paramCount} OR bp.bill_holder_name ILIKE $${paramCount} OR t.transaction_id ILIKE $${paramCount})`
        );
        params.push(`%${filters.search}%`);
        paramCount++;
      }

      const whereClause = conditions.join(' AND ');

      // Get total count
      const countResult = await db.query(
        `SELECT COUNT(*) as total FROM bill_payments bp WHERE ${whereClause}`,
        params
      );
      const total = parseInt(countResult[0].total);

      // Get bill payments with details
      const payments = await db.query(
        `SELECT
          bp.id,
          bp.bill_type,
          bp.bill_id,
          bp.bill_holder_name,
          bp.amount,
          bp.provider_transaction_id,
          bp.status,
          bp.processed_at,
          bp.created_at,
          bp.updated_at,
          bp.user_id,
          t.transaction_id,
          t.fee,
          t.description,
          pr.name as provider_name,
          pr.logo_url as provider_logo,
          u.first_name,
          u.last_name,
          u.email
        FROM bill_payments bp
        JOIN transactions t ON bp.transaction_id = t.id
        LEFT JOIN bill_providers pr ON bp.provider_id = pr.id
        LEFT JOIN users u ON bp.user_id = u.id
        WHERE ${whereClause}
        ORDER BY bp.created_at DESC
        LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
        [...params, pagination.limit, pagination.offset]
      );

      // Format bill payments
      const formattedPayments = payments.map((payment: any) => ({
        id: payment.id,
        transaction_id: payment.transaction_id,
        reference_number: payment.provider_transaction_id,
        bill_type: payment.bill_type,
        provider: {
          name: payment.provider_name,
          logo_url: payment.provider_logo,
        },
        account_number: payment.bill_id,
        customer_name: payment.bill_holder_name,
        amount: parseFloat(payment.amount),
        fee: parseFloat(payment.fee || 0),
        total_amount: parseFloat(payment.amount) + parseFloat(payment.fee || 0),
        status: payment.status,
        description: payment.description,
        user: {
          id: payment.user_id,
          name: `${payment.first_name} ${payment.last_name}`,
          email: payment.email,
        },
        created_at: payment.created_at,
        completed_at: payment.processed_at,
        updated_at: payment.updated_at,
      }));

      const totalPages = Math.ceil(total / pagination.limit);

      return {
        billPayments: formattedPayments,
        pagination: {
          page: pagination.page,
          limit: pagination.limit,
          total,
          totalPages,
        },
      };
    } catch (error) {
      logger.error('Error getting bill payments for admin', error);
      throw error;
    }
  }

  /**
   * Get all investments with pagination and filters (Admin)
   */
  static async getInvestments(
    pagination: PaginationParams,
    filters?: {
      category?: string;
      status?: string;
      fromDate?: Date;
      toDate?: Date;
      search?: string;
    }
  ): Promise<{
    investments: any[];
    pagination: {
      page: number;
      limit: number;
      total: number;
      totalPages: number;
    };
  }> {
    try {
      const conditions = ['1=1'];
      const params: any[] = [];
      let paramCount = 1;

      // Apply filters
      if (filters?.category) {
        conditions.push(`i.category = $${paramCount}`);
        params.push(filters.category);
        paramCount++;
      }

      if (filters?.status) {
        conditions.push(`i.status = $${paramCount}`);
        params.push(filters.status);
        paramCount++;
      }

      if (filters?.fromDate) {
        conditions.push(`i.start_date >= $${paramCount}`);
        params.push(filters.fromDate);
        paramCount++;
      }

      if (filters?.toDate) {
        conditions.push(`i.end_date <= $${paramCount}`);
        params.push(filters.toDate);
        paramCount++;
      }

      if (filters?.search) {
        conditions.push(
          `(u.first_name ILIKE $${paramCount} OR u.last_name ILIKE $${paramCount} OR u.email ILIKE $${paramCount} OR i.id::text ILIKE $${paramCount})`
        );
        params.push(`%${filters.search}%`);
        paramCount++;
      }

      const whereClause = conditions.join(' AND ');

      // Get total count
      const countResult = await db.query(
        `SELECT COUNT(*) as total FROM investments i
         JOIN users u ON i.user_id = u.id
         WHERE ${whereClause}`,
        params
      );
      const total = parseInt(countResult[0].total);

      // Get investments with user details
      const investments = await db.query(
        `SELECT
          i.id,
          i.category,
          i.sub_category,
          i.amount,
          i.tenure_months,
          i.return_rate,
          i.expected_return,
          i.actual_return,
          i.start_date,
          i.end_date,
          i.status,
          i.insurance_taken,
          i.insurance_cost,
          i.created_at,
          i.updated_at,
          u.id as user_id,
          u.first_name,
          u.last_name,
          u.email,
          u.phone
        FROM investments i
        JOIN users u ON i.user_id = u.id
        WHERE ${whereClause}
        ORDER BY i.created_at DESC
        LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
        [...params, pagination.limit, pagination.offset]
      );

      // Format investments
      const formattedInvestments = investments.map((inv: any) => ({
        id: inv.id,
        category: inv.category,
        subCategory: inv.sub_category,
        amount: parseFloat(inv.amount),
        tenureMonths: inv.tenure_months,
        returnRate: parseFloat(inv.return_rate),
        expectedReturn: parseFloat(inv.expected_return),
        actualReturn: inv.actual_return ? parseFloat(inv.actual_return) : null,
        startDate: inv.start_date,
        endDate: inv.end_date,
        status: inv.status,
        insuranceTaken: inv.insurance_taken,
        insuranceCost: inv.insurance_cost ? parseFloat(inv.insurance_cost) : null,
        user: {
          id: inv.user_id,
          name: `${inv.first_name} ${inv.last_name}`,
          email: inv.email,
          phone: inv.phone,
        },
        createdAt: inv.created_at,
        updatedAt: inv.updated_at,
      }));

      const totalPages = Math.ceil(total / pagination.limit);

      return {
        investments: formattedInvestments,
        pagination: {
          page: pagination.page,
          limit: pagination.limit,
          total,
          totalPages,
        },
      };
    } catch (error) {
      logger.error('Error getting investments for admin', error);
      throw error;
    }
  }

  /**
   * Get transaction report
   */
  static async getTransactionReport(params: {
    dateRange?: { from: Date; to: Date };
    type?: string;
    status?: string;
    format?: string;
  }): Promise<any> {
    try {
      const conditions: string[] = [];
      const queryParams: any[] = [];
      let paramCount = 1;

      if (params.dateRange) {
        conditions.push(`t.created_at BETWEEN $${paramCount} AND $${paramCount + 1}`);
        queryParams.push(params.dateRange.from, params.dateRange.to);
        paramCount += 2;
      }

      if (params.type) {
        conditions.push(`t.type = $${paramCount}`);
        queryParams.push(params.type);
        paramCount++;
      }

      if (params.status) {
        conditions.push(`t.status = $${paramCount}`);
        queryParams.push(params.status);
        paramCount++;
      }

      const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

      // Get summary statistics
      const summaryResult = await db.query(
        `SELECT
          COUNT(*) as total_count,
          COALESCE(SUM(amount), 0) as total_volume,
          COALESCE(AVG(amount), 0) as avg_amount,
          COUNT(DISTINCT type) as unique_types
        FROM transactions t
        ${whereClause}`,
        queryParams
      );

      // Get breakdown by type
      const typeBreakdown = await db.query(
        `SELECT
          COALESCE(type, 'UNKNOWN') as type,
          COUNT(*) as count,
          COALESCE(SUM(amount), 0) as total_amount
        FROM transactions t
        ${whereClause}
        GROUP BY type`,
        queryParams
      );

      // Get breakdown by status
      const statusBreakdown = await db.query(
        `SELECT
          COALESCE(status, 'UNKNOWN') as status,
          COUNT(*) as count,
          COALESCE(SUM(amount), 0) as total_amount
        FROM transactions t
        ${whereClause}
        GROUP BY status`,
        queryParams
      );

      // Convert to object format
      const byType: Record<string, any> = {};
      typeBreakdown.forEach((row: any) => {
        byType[row.type] = { count: parseInt(row.count), total_amount: parseFloat(row.total_amount) };
      });

      const byStatus: Record<string, any> = {};
      statusBreakdown.forEach((row: any) => {
        byStatus[row.status] = { count: parseInt(row.count), total_amount: parseFloat(row.total_amount) };
      });

      // Get detailed transaction list
      const transactions = await db.query(
        `SELECT
          t.id,
          t.transaction_id,
          t.type,
          t.status,
          t.amount,
          t.fee,
          t.net_amount,
          t.created_at,
          t.processed_at,
          from_user.first_name as from_first_name,
          from_user.last_name as from_last_name,
          from_user.email as from_email,
          to_user.first_name as to_first_name,
          to_user.last_name as to_last_name,
          to_user.email as to_email
        FROM transactions t
        LEFT JOIN users from_user ON t.from_user_id = from_user.id
        LEFT JOIN users to_user ON t.to_user_id = to_user.id
        ${whereClause}
        ORDER BY t.created_at DESC
        LIMIT 100`,
        queryParams
      );

      return {
        transactions,
        summary: {
          ...summaryResult[0],
          by_type: byType,
          by_status: byStatus,
        },
        count: transactions.length,
        dateRange: params.dateRange,
        generatedAt: new Date(),
      };
    } catch (error) {
      logger.error('Error getting transaction report', error);
      throw error;
    }
  }

  /**
   * Get user activity report
   */
  static async getUserActivityReport(params: {
    dateRange?: { from: Date; to: Date };
    format?: string;
  }): Promise<any> {
    try {
      const dateCondition = params.dateRange
        ? `AND u.created_at BETWEEN '${params.dateRange.from.toISOString()}' AND '${params.dateRange.to.toISOString()}'`
        : '';

      // Get user statistics
      const userStats = await db.query(`
        SELECT
          COUNT(*) as total_users,
          COUNT(*) FILTER (WHERE is_active = true) as active_users,
          COUNT(*) FILTER (WHERE kyc_status = 'APPROVED') as kyc_approved_users,
          COUNT(*) FILTER (WHERE kyc_status = 'PENDING') as kyc_pending_users,
          COUNT(*) FILTER (WHERE DATE(created_at) >= CURRENT_DATE - INTERVAL '7 days') as new_users_this_week,
          COUNT(*) FILTER (WHERE DATE(created_at) >= CURRENT_DATE - INTERVAL '30 days') as new_users_this_month,
          COUNT(*) FILTER (WHERE last_login_at >= CURRENT_DATE - INTERVAL '7 days') as active_last_week
        FROM users u
        WHERE role = 'USER' ${dateCondition}
      `);

      // Get user list with activity
      const users = await db.query(`
        SELECT
          u.id,
          u.first_name,
          u.last_name,
          u.email,
          u.phone,
          u.kyc_status,
          u.is_active,
          u.created_at,
          u.last_login_at,
          w.balance,
          (SELECT COUNT(*) FROM transactions WHERE from_user_id = u.id OR to_user_id = u.id) as transaction_count,
          (SELECT COUNT(*) FROM investments WHERE user_id = u.id) as investment_count
        FROM users u
        LEFT JOIN wallets w ON u.id = w.user_id
        WHERE u.role = 'USER' ${dateCondition}
        ORDER BY u.created_at DESC
        LIMIT 100
      `);

      return {
        users,
        summary: userStats[0],
        count: users.length,
        dateRange: params.dateRange,
        generatedAt: new Date(),
      };
    } catch (error) {
      logger.error('Error getting user activity report', error);
      throw error;
    }
  }

  /**
   * Get revenue report
   */
  static async getRevenueReport(params: {
    dateRange?: { from: Date; to: Date };
    groupBy?: string;
    format?: string;
  }): Promise<any> {
    try {
      const dateCondition = params.dateRange
        ? `created_at BETWEEN '${params.dateRange.from.toISOString()}' AND '${params.dateRange.to.toISOString()}' AND`
        : '';

      // Get revenue summary
      const revenueSummary = await db.query(`
        SELECT
          COALESCE(SUM(amount), 0) as total_revenue,
          COALESCE(SUM(fee), 0) as total_fees,
          COALESCE(SUM(net_amount), 0) as net_revenue,
          COUNT(*) as transaction_count,
          COALESCE(AVG(amount), 0) as avg_transaction_value
        FROM transactions
        WHERE ${dateCondition} status = 'COMPLETED'
      `);

      // Get revenue by day/week/month based on groupBy
      const groupByClause = params.groupBy === 'week'
        ? `DATE_TRUNC('week', created_at)`
        : params.groupBy === 'month'
        ? `DATE_TRUNC('month', created_at)`
        : params.groupBy === 'year'
        ? `DATE_TRUNC('year', created_at)`
        : `DATE(created_at)`;

      const revenueOverTime = await db.query(`
        SELECT
          ${groupByClause} as period,
          COALESCE(SUM(amount), 0) as revenue,
          COALESCE(SUM(fee), 0) as fees,
          COUNT(*) as transaction_count
        FROM transactions
        WHERE ${dateCondition} status = 'COMPLETED'
        GROUP BY period
        ORDER BY period DESC
        LIMIT 50
      `);

      // Get revenue by type
      const revenueByType = await db.query(`
        SELECT
          type,
          COALESCE(SUM(amount), 0) as revenue,
          COUNT(*) as count
        FROM transactions
        WHERE ${dateCondition} status = 'COMPLETED'
        GROUP BY type
        ORDER BY revenue DESC
      `);

      return {
        revenue: revenueOverTime,
        total: parseFloat(revenueSummary[0].total_revenue),
        summary: revenueSummary[0],
        byType: revenueByType,
        dateRange: params.dateRange,
        generatedAt: new Date(),
      };
    } catch (error) {
      logger.error('Error getting revenue report', error);
      throw error;
    }
  }

  /**
   * Get investment report
   */
  static async getInvestmentReport(params: {
    dateRange?: { from: Date; to: Date };
    category?: string;
    format?: string;
  }): Promise<any> {
    try {
      const conditions: string[] = [];
      const queryParams: any[] = [];
      let paramCount = 1;

      if (params.dateRange) {
        conditions.push(`i.created_at BETWEEN $${paramCount} AND $${paramCount + 1}`);
        queryParams.push(params.dateRange.from, params.dateRange.to);
        paramCount += 2;
      }

      if (params.category) {
        conditions.push(`i.category = $${paramCount}`);
        queryParams.push(params.category);
        paramCount++;
      }

      const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

      // Get investment summary
      const investmentSummary = await db.query(
        `SELECT
          COUNT(*) as total_investments,
          COUNT(*) FILTER (WHERE status = 'ACTIVE') as active_investments,
          COUNT(*) FILTER (WHERE status = 'MATURED') as matured_investments,
          COALESCE(SUM(amount), 0) as total_amount,
          COALESCE(SUM(expected_return), 0) as expected_returns,
          COALESCE(SUM(actual_return), 0) as actual_returns,
          COALESCE(AVG(return_rate), 0) as avg_return_rate
        FROM investments i
        ${whereClause}`,
        queryParams
      );

      // Get detailed investments
      const investments = await db.query(
        `SELECT
          i.id,
          i.category,
          i.sub_category,
          i.amount,
          i.tenure_months,
          i.return_rate,
          i.expected_return,
          i.actual_return,
          i.start_date,
          i.end_date,
          i.status,
          i.created_at,
          u.first_name,
          u.last_name,
          u.email
        FROM investments i
        JOIN users u ON i.user_id = u.id
        ${whereClause}
        ORDER BY i.created_at DESC
        LIMIT 100`,
        queryParams
      );

      // Get investments by category
      const byCategory = await db.query(
        `SELECT
          category,
          COUNT(*) as count,
          COALESCE(SUM(amount), 0) as total_amount
        FROM investments i
        ${whereClause}
        GROUP BY category
        ORDER BY total_amount DESC`,
        queryParams
      );

      return {
        investments,
        summary: investmentSummary[0],
        byCategory,
        count: investments.length,
        dateRange: params.dateRange,
        generatedAt: new Date(),
      };
    } catch (error) {
      logger.error('Error getting investment report', error);
      throw error;
    }
  }

  /**
   * Get agent performance report
   */
  static async getAgentPerformanceReport(params: {
    dateRange?: { from: Date; to: Date };
    agentId?: string;
    format?: string;
  }): Promise<any> {
    try {
      const conditions: string[] = [];
      const queryParams: any[] = [];
      let paramCount = 1;

      if (params.agentId) {
        conditions.push(`a.id = $${paramCount}`);
        queryParams.push(params.agentId);
        paramCount++;
      }

      const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

      // Get agent summary
      const agentSummary = await db.query(
        `SELECT
          COUNT(*) as total_agents,
          COUNT(*) FILTER (WHERE active_status = true) as active_agents,
          COALESCE(SUM(total_commission_earned), 0) as total_commission,
          COALESCE(SUM(total_transactions_processed), 0) as total_transactions,
          COALESCE(AVG(commission_rate), 0) as avg_commission_rate
        FROM agents a
        ${whereClause}`,
        queryParams
      );

      // Get detailed agent performance
      const agents = await db.query(
        `SELECT
          a.id,
          a.user_id,
          a.wallet_balance,
          a.commission_rate,
          a.total_commission_earned,
          a.total_transactions_processed,
          a.active_status,
          a.location_address,
          a.created_at,
          u.first_name,
          u.last_name,
          u.email,
          u.phone,
          u.last_login_at,
          (
            SELECT COUNT(*)
            FROM transactions t
            WHERE t.metadata::jsonb->>'agent_id' = a.id::text
            ${params.dateRange ? `AND t.created_at BETWEEN '${params.dateRange.from.toISOString()}' AND '${params.dateRange.to.toISOString()}'` : ''}
          ) as period_transactions,
          (
            SELECT COALESCE(SUM(amount * a.commission_rate / 100), 0)
            FROM transactions t
            WHERE t.metadata::jsonb->>'agent_id' = a.id::text
            AND t.status = 'COMPLETED'
            ${params.dateRange ? `AND t.created_at BETWEEN '${params.dateRange.from.toISOString()}' AND '${params.dateRange.to.toISOString()}'` : ''}
          ) as period_commission
        FROM agents a
        JOIN users u ON a.user_id = u.id
        ${whereClause}
        ORDER BY a.total_commission_earned DESC
        LIMIT 100`,
        queryParams
      );

      return {
        agents,
        summary: agentSummary[0],
        count: agents.length,
        dateRange: params.dateRange,
        generatedAt: new Date(),
      };
    } catch (error) {
      logger.error('Error getting agent performance report', error);
      throw error;
    }
  }

  /**
   * Create investment opportunity (Admin only)
   */
  static async createOpportunity(
    adminId: string,
    data: {
      category_id: string;
      title: string;
      description: string;
      min_investment: number;
      max_investment: number;
      tenure_months: number;
      return_rate: number;
      total_units: number;
      image_url?: string;
      metadata?: any;
    }
  ): Promise<any> {
    try {
      // Validate category (only Agriculture and Education)
      const categories = await db.query(
        `SELECT id, name FROM investment_categories WHERE id = $1`,
        [data.category_id]
      );

      if (categories.length === 0) {
        throw new Error('CATEGORY_NOT_FOUND');
      }

      const category = categories[0];
      if (category.name !== 'AGRICULTURE' && category.name !== 'EDUCATION') {
        throw new Error('INVALID_CATEGORY');
      }

      // Check 16 opportunity limit
      const countResult = await db.query(
        `SELECT COUNT(*) as count FROM investment_opportunities WHERE category_id = $1`,
        [data.category_id]
      );

      if (parseInt(countResult[0].count) >= 16) {
        throw new Error('CATEGORY_OPPORTUNITY_LIMIT_REACHED');
      }

      // Insert opportunity
      const result = await db.query(
        `INSERT INTO investment_opportunities (
          category_id, title, description, min_investment, max_investment,
          tenure_months, return_rate, total_units, available_units, image_url, metadata
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        RETURNING *`,
        [
          data.category_id,
          data.title,
          data.description,
          data.min_investment,
          data.max_investment,
          data.tenure_months,
          data.return_rate,
          data.total_units,
          data.total_units, // available_units = total_units initially
          data.image_url || null,
          data.metadata ? JSON.stringify(data.metadata) : null,
        ]
      );

      logger.info('Investment opportunity created', {
        adminId,
        opportunityId: result[0].id,
        category: category.name,
      });

      return this.formatOpportunity(result[0], category.name);
    } catch (error) {
      logger.error('Error creating investment opportunity', error);
      throw error;
    }
  }

  /**
   * Update investment opportunity (Admin only)
   */
  static async updateOpportunity(
    adminId: string,
    opportunityId: string,
    data: {
      title?: string;
      description?: string;
      min_investment?: number;
      max_investment?: number;
      tenure_months?: number;
      return_rate?: number;
      total_units?: number;
      image_url?: string;
      metadata?: any;
    }
  ): Promise<any> {
    try {
      // Check if opportunity exists
      const existing = await db.query(
        `SELECT io.*, ic.name as category_name
         FROM investment_opportunities io
         JOIN investment_categories ic ON io.category_id = ic.id
         WHERE io.id = $1`,
        [opportunityId]
      );

      if (existing.length === 0) {
        throw new Error('OPPORTUNITY_NOT_FOUND');
      }

      // Build update query dynamically
      const updates: string[] = [];
      const params: any[] = [];
      let paramCount = 1;

      if (data.title !== undefined) {
        updates.push(`title = $${paramCount}`);
        params.push(data.title);
        paramCount++;
      }

      if (data.description !== undefined) {
        updates.push(`description = $${paramCount}`);
        params.push(data.description);
        paramCount++;
      }

      if (data.min_investment !== undefined) {
        updates.push(`min_investment = $${paramCount}`);
        params.push(data.min_investment);
        paramCount++;
      }

      if (data.max_investment !== undefined) {
        updates.push(`max_investment = $${paramCount}`);
        params.push(data.max_investment);
        paramCount++;
      }

      if (data.tenure_months !== undefined) {
        updates.push(`tenure_months = $${paramCount}`);
        params.push(data.tenure_months);
        paramCount++;
      }

      if (data.return_rate !== undefined) {
        updates.push(`return_rate = $${paramCount}`);
        params.push(data.return_rate);
        paramCount++;
      }

      if (data.total_units !== undefined) {
        updates.push(`total_units = $${paramCount}`);
        params.push(data.total_units);
        paramCount++;
      }

      if (data.image_url !== undefined) {
        updates.push(`image_url = $${paramCount}`);
        params.push(data.image_url);
        paramCount++;
      }

      if (data.metadata !== undefined) {
        updates.push(`metadata = $${paramCount}`);
        params.push(JSON.stringify(data.metadata));
        paramCount++;
      }

      if (updates.length === 0) {
        return this.formatOpportunity(existing[0], existing[0].category_name);
      }

      params.push(opportunityId);
      const result = await db.query(
        `UPDATE investment_opportunities
         SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP
         WHERE id = $${paramCount}
         RETURNING *`,
        params
      );

      logger.info('Investment opportunity updated', {
        adminId,
        opportunityId,
      });

      return this.formatOpportunity(result[0], existing[0].category_name);
    } catch (error) {
      logger.error('Error updating investment opportunity', error);
      throw error;
    }
  }

  /**
   * Toggle opportunity status (hide/show)
   */
  static async toggleOpportunityStatus(
    adminId: string,
    opportunityId: string,
    isActive: boolean
  ): Promise<any> {
    try {
      const result = await db.query(
        `UPDATE investment_opportunities
         SET is_active = $1, updated_at = CURRENT_TIMESTAMP
         WHERE id = $2
         RETURNING *`,
        [isActive, opportunityId]
      );

      if (result.length === 0) {
        throw new Error('OPPORTUNITY_NOT_FOUND');
      }

      logger.info('Investment opportunity status toggled', {
        adminId,
        opportunityId,
        isActive,
      });

      return { success: true, isActive };
    } catch (error) {
      logger.error('Error toggling opportunity status', error);
      throw error;
    }
  }

  /**
   * Get all opportunities with pagination and filters
   */
  static async getOpportunities(
    pagination: PaginationParams,
    filters?: {
      category?: string;
      is_active?: boolean;
      search?: string;
    }
  ): Promise<{
    opportunities: any[];
    pagination: {
      page: number;
      limit: number;
      total: number;
      totalPages: number;
    };
  }> {
    try {
      const conditions = ['1=1'];
      const params: any[] = [];
      let paramCount = 1;

      if (filters?.category) {
        conditions.push(`ic.name = $${paramCount}`);
        params.push(filters.category);
        paramCount++;
      }

      if (filters?.is_active !== undefined) {
        conditions.push(`io.is_active = $${paramCount}`);
        params.push(filters.is_active);
        paramCount++;
      }

      if (filters?.search) {
        conditions.push(`(io.title ILIKE $${paramCount} OR io.description ILIKE $${paramCount})`);
        params.push(`%${filters.search}%`);
        paramCount++;
      }

      const whereClause = conditions.join(' AND ');

      // Get total count
      const countResult = await db.query(
        `SELECT COUNT(*) as total
         FROM investment_opportunities io
         JOIN investment_categories ic ON io.category_id = ic.id
         WHERE ${whereClause}`,
        params
      );
      const total = parseInt(countResult[0].total);

      // Get opportunities
      const opportunities = await db.query(
        `SELECT io.*, ic.name as category_name, ic.display_name as category_display_name
         FROM investment_opportunities io
         JOIN investment_categories ic ON io.category_id = ic.id
         WHERE ${whereClause}
         ORDER BY io.display_order, io.created_at DESC
         LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
        [...params, pagination.limit, pagination.offset]
      );

      const formattedOpportunities = opportunities.map((opp: any) =>
        this.formatOpportunity(opp, opp.category_name)
      );

      const totalPages = Math.ceil(total / pagination.limit);

      return {
        opportunities: formattedOpportunities,
        pagination: {
          page: pagination.page,
          limit: pagination.limit,
          total,
          totalPages,
        },
      };
    } catch (error) {
      logger.error('Error getting opportunities', error);
      throw error;
    }
  }

  /**
   * Get single opportunity details
   */
  static async getOpportunityDetails(opportunityId: string): Promise<any> {
    try {
      const result = await db.query(
        `SELECT io.*, ic.name as category_name, ic.display_name as category_display_name
         FROM investment_opportunities io
         JOIN investment_categories ic ON io.category_id = ic.id
         WHERE io.id = $1`,
        [opportunityId]
      );

      if (result.length === 0) {
        throw new Error('OPPORTUNITY_NOT_FOUND');
      }

      return this.formatOpportunity(result[0], result[0].category_name);
    } catch (error) {
      logger.error('Error getting opportunity details', error);
      throw error;
    }
  }

  /**
   * Format opportunity object
   */
  private static formatOpportunity(opp: any, categoryName: string): any {
    return {
      id: opp.id,
      categoryId: opp.category_id,
      categoryName: categoryName,
      title: opp.title,
      description: opp.description,
      minInvestment: parseFloat(opp.min_investment),
      maxInvestment: parseFloat(opp.max_investment),
      tenureMonths: opp.tenure_months,
      returnRate: parseFloat(opp.return_rate),
      totalUnits: opp.total_units,
      availableUnits: opp.available_units,
      imageUrl: opp.image_url,
      isActive: opp.is_active,
      displayOrder: opp.display_order,
      metadata: opp.metadata,
      createdAt: opp.created_at,
      updatedAt: opp.updated_at,
    };
  }
}
