import { PoolClient } from 'pg';
import db from '../database';
import logger from '../utils/logger';
import {
  InvestmentCategory,
  InvestmentCategoryData,
  InvestmentCategoryWithVersions,
  InvestmentTenure,
  InvestmentUnit,
  ProductVersion,
  TenureWithVersionHistory,
  CreateCategoryDTO,
  UpdateCategoryDTO,
  CreateTenureDTO,
  UpdateRateDTO,
  CreateUnitDTO,
  UpdateUnitDTO,
  VersionReport,
  RateChangeHistoryItem,
  RateChangeFilters,
  VersionReportParams,
} from '../types';

export class InvestmentProductService {
  /**
   * Get all investment categories with their tenures and version information
   */
  static async getCategories(): Promise<InvestmentCategoryWithVersions[]> {
    try {
      const categories = await db.query<InvestmentCategoryData>(
        `SELECT id, name, display_name, description, sub_categories,
                icon_url, is_active, created_at, updated_at
         FROM investment_categories
         WHERE is_active = true
         ORDER BY display_name`
      );

      const categoriesWithVersions: InvestmentCategoryWithVersions[] = [];

      for (const category of categories) {
        const tenures = await this.getTenures(category.id);
        categoriesWithVersions.push({
          category,
          tenures,
        });
      }

      return categoriesWithVersions;
    } catch (error) {
      logger.error('Error getting investment categories', error);
      throw error;
    }
  }

  /**
   * Create a new investment category
   */
  static async createCategory(
    data: CreateCategoryDTO
  ): Promise<InvestmentCategoryData> {
    try {
      const result = await db.query<InvestmentCategoryData>(
        `INSERT INTO investment_categories
         (name, display_name, description, sub_categories, icon_url, is_active)
         VALUES ($1, $2, $3, $4, $5, true)
         RETURNING id, name, display_name, description, sub_categories,
                   icon_url, is_active, created_at, updated_at`,
        [
          data.name,
          data.display_name,
          data.description || null,
          data.sub_categories ? JSON.stringify(data.sub_categories) : null,
          data.icon_url || null,
        ]
      );

      logger.info('Investment category created', {
        categoryId: result[0].id,
        name: data.name,
      });

      return result[0];
    } catch (error) {
      logger.error('Error creating investment category', error);
      throw error;
    }
  }

  /**
   * Update an existing investment category
   */
  static async updateCategory(
    categoryId: string,
    data: UpdateCategoryDTO
  ): Promise<InvestmentCategoryData> {
    try {
      const updates: string[] = [];
      const values: any[] = [];
      let paramCounter = 1;

      if (data.display_name !== undefined) {
        updates.push(`display_name = $${paramCounter++}`);
        values.push(data.display_name);
      }

      if (data.description !== undefined) {
        updates.push(`description = $${paramCounter++}`);
        values.push(data.description);
      }

      if (data.sub_categories !== undefined) {
        updates.push(`sub_categories = $${paramCounter++}`);
        values.push(JSON.stringify(data.sub_categories));
      }

      if (data.icon_url !== undefined) {
        updates.push(`icon_url = $${paramCounter++}`);
        values.push(data.icon_url);
      }

      if (data.is_active !== undefined) {
        updates.push(`is_active = $${paramCounter++}`);
        values.push(data.is_active);
      }

      if (updates.length === 0) {
        throw new Error('NO_UPDATES_PROVIDED');
      }

      updates.push(`updated_at = NOW()`);
      values.push(categoryId);

      const result = await db.query<InvestmentCategoryData>(
        `UPDATE investment_categories
         SET ${updates.join(', ')}
         WHERE id = $${paramCounter}
         RETURNING id, name, display_name, description, sub_categories,
                   icon_url, is_active, created_at, updated_at`,
        values
      );

      if (result.length === 0) {
        throw new Error('CATEGORY_NOT_FOUND');
      }

      logger.info('Investment category updated', {
        categoryId,
        updates: Object.keys(data),
      });

      return result[0];
    } catch (error) {
      logger.error('Error updating investment category', error);
      throw error;
    }
  }

  /**
   * Deactivate an investment category
   */
  static async deactivateCategory(categoryId: string): Promise<void> {
    try {
      const result = await db.query(
        `UPDATE investment_categories
         SET is_active = false, updated_at = NOW()
         WHERE id = $1
         RETURNING id`,
        [categoryId]
      );

      if (result.length === 0) {
        throw new Error('CATEGORY_NOT_FOUND');
      }

      logger.info('Investment category deactivated', { categoryId });
    } catch (error) {
      logger.error('Error deactivating investment category', error);
      throw error;
    }
  }

  /**
   * Get all tenures for a category with version history
   */
  static async getTenures(
    categoryId: string
  ): Promise<TenureWithVersionHistory[]> {
    try {
      const tenures = await db.query<InvestmentTenure>(
        `SELECT id, category_id, duration_months, return_percentage,
                agreement_template_url, is_active, created_at, updated_at
         FROM investment_tenures
         WHERE category_id = $1 AND is_active = true
         ORDER BY duration_months`,
        [categoryId]
      );

      const tenuresWithHistory: TenureWithVersionHistory[] = [];

      for (const tenure of tenures) {
        // Get current version
        const currentVersion = await this.getCurrentVersion(tenure.id);

        // Get version history
        const versionHistory = await this.getTenureVersionHistory(tenure.id);

        // Get investment count and total amount
        const stats = await db.query<any>(
          `SELECT COUNT(*) as investment_count,
                  COALESCE(SUM(amount), 0) as total_amount
           FROM investments
           WHERE tenure_id = $1`,
          [tenure.id]
        );

        tenuresWithHistory.push({
          tenure,
          current_version: currentVersion,
          version_history: versionHistory,
          investment_count: parseInt(stats[0].investment_count),
          total_amount: parseFloat(stats[0].total_amount),
        });
      }

      return tenuresWithHistory;
    } catch (error) {
      logger.error('Error getting investment tenures', error);
      throw error;
    }
  }

  /**
   * Create a new investment tenure
   */
  static async createTenure(
    categoryId: string,
    data: CreateTenureDTO
  ): Promise<InvestmentTenure> {
    try {
      const result = await db.transaction(async (client: PoolClient) => {
        // Create tenure
        const tenures = await client.query<InvestmentTenure>(
          `INSERT INTO investment_tenures
           (category_id, duration_months, return_percentage, agreement_template_url, is_active)
           VALUES ($1, $2, $3, $4, true)
           RETURNING id, category_id, duration_months, return_percentage,
                     agreement_template_url, is_active, created_at, updated_at`,
          [
            categoryId,
            data.duration_months,
            data.return_percentage,
            data.agreement_template_url || null,
          ]
        );

        const tenure = tenures.rows[0];

        // Create initial version (version 1)
        await client.query(
          `INSERT INTO investment_product_versions
           (tenure_id, version_number, return_percentage, effective_from,
            is_current, change_reason, metadata)
           VALUES ($1, 1, $2, NOW(), true, $3, $4)`,
          [
            tenure.id,
            data.return_percentage,
            'Initial version on tenure creation',
            JSON.stringify({ initial: true }),
          ]
        );

        logger.info('Investment tenure created', {
          tenureId: tenure.id,
          categoryId,
          durationMonths: data.duration_months,
          returnPercentage: data.return_percentage,
        });

        return tenure;
      });

      return result;
    } catch (error) {
      logger.error('Error creating investment tenure', error);
      throw error;
    }
  }

  /**
   * Update tenure rate - creates a new version
   * This is the critical method for rate versioning
   */
  static async updateTenureRate(
    tenureId: string,
    newRate: number,
    changeReason: string,
    adminId: string
  ): Promise<ProductVersion> {
    try {
      const result = await db.transaction(async (client: PoolClient) => {
        // 1. Get current version
        const currentVersions = await client.query<ProductVersion>(
          `SELECT * FROM investment_product_versions
           WHERE tenure_id = $1 AND is_current = TRUE`,
          [tenureId]
        );

        if (currentVersions.rows.length === 0) {
          throw new Error('NO_CURRENT_VERSION_FOUND');
        }

        const currentVersion = currentVersions.rows[0];

        // Check if rate has actually changed
        if (parseFloat(currentVersion.return_percentage as any) === newRate) {
          throw new Error('RATE_UNCHANGED');
        }

        // 2. Close current version
        await client.query(
          `UPDATE investment_product_versions
           SET is_current = FALSE,
               effective_until = NOW(),
               updated_at = NOW()
           WHERE id = $1`,
          [currentVersion.id]
        );

        // 3. Create new version
        const newVersions = await client.query<ProductVersion>(
          `INSERT INTO investment_product_versions
           (tenure_id, version_number, return_percentage, effective_from,
            is_current, change_reason, changed_by)
           VALUES ($1, $2, $3, NOW(), TRUE, $4, $5)
           RETURNING *`,
          [
            tenureId,
            currentVersion.version_number + 1,
            newRate,
            changeReason,
            adminId,
          ]
        );

        const newVersion = newVersions.rows[0];

        // 4. Update investment_tenures table for backward compatibility
        await client.query(
          `UPDATE investment_tenures
           SET return_percentage = $1, updated_at = NOW()
           WHERE id = $2`,
          [newRate, tenureId]
        );

        // 5. Get tenure and category details for notifications
        const tenures = await client.query<any>(
          `SELECT it.*, ic.name as category, ic.display_name as category_display
           FROM investment_tenures it
           JOIN investment_categories ic ON it.category_id = ic.id
           WHERE it.id = $1`,
          [tenureId]
        );

        if (tenures.rows.length === 0) {
          throw new Error('TENURE_NOT_FOUND');
        }

        const tenure = tenures.rows[0];

        // 6. Find all users with active investments in this product
        const usersToNotify = await client.query<any>(
          `SELECT DISTINCT user_id
           FROM investments
           WHERE tenure_id = $1 AND status = 'ACTIVE'`,
          [tenureId]
        );

        // 7. Create notifications for each user
        for (const user of usersToNotify.rows) {
          // Create notification
          const notification = await client.query<any>(
            `INSERT INTO notifications
             (user_id, type, title, message, data, is_read)
             VALUES ($1, $2, $3, $4, $5, false)
             RETURNING id`,
            [
              user.user_id,
              'INVESTMENT',
              'Investment Rate Update',
              `The return rate for ${tenure.category_display} - ${tenure.duration_months} months has changed from ${currentVersion.return_percentage}% to ${newRate}%. Your existing investments remain at the original rate.`,
              JSON.stringify({
                version_id: newVersion.id,
                category: tenure.category,
                tenure_months: tenure.duration_months,
                old_rate: currentVersion.return_percentage,
                new_rate: newRate,
                change_reason: changeReason,
              }),
            ]
          );

          // Track notification in rate change notifications table
          await client.query(
            `INSERT INTO investment_rate_change_notifications
             (version_id, user_id, notification_id, category, tenure_months,
              old_rate, new_rate)
             VALUES ($1, $2, $3, $4, $5, $6, $7)`,
            [
              newVersion.id,
              user.user_id,
              notification.rows[0].id,
              tenure.category,
              tenure.duration_months,
              currentVersion.return_percentage,
              newRate,
            ]
          );
        }

        // 8. Log admin action in audit trail (if audit trail exists)
        try {
          await client.query(
            `INSERT INTO admin_audit_logs
             (admin_id, action, entity_type, entity_id, changes, ip_address)
             VALUES ($1, $2, $3, $4, $5, $6)`,
            [
              adminId,
              'UPDATE_INVESTMENT_RATE',
              'INVESTMENT_TENURE',
              tenureId,
              JSON.stringify({
                old_rate: currentVersion.return_percentage,
                new_rate: newRate,
                old_version: currentVersion.version_number,
                new_version: newVersion.version_number,
                change_reason: changeReason,
                users_notified: usersToNotify.rows.length,
              }),
              null, // IP address can be passed from controller if needed
            ]
          );
        } catch (auditError) {
          // If audit logging fails, log it but don't fail the transaction
          logger.warn('Failed to create audit log entry', auditError);
        }

        logger.info('Investment rate updated', {
          tenureId,
          category: tenure.category,
          tenureMonths: tenure.duration_months,
          oldRate: currentVersion.return_percentage,
          newRate,
          newVersionId: newVersion.id,
          usersNotified: usersToNotify.rows.length,
          adminId,
        });

        return newVersion;
      });

      return result;
    } catch (error) {
      logger.error('Error updating tenure rate', error);
      throw error;
    }
  }

  /**
   * Get current version for a tenure
   */
  static async getCurrentVersion(tenureId: string): Promise<ProductVersion> {
    try {
      const result = await db.query<ProductVersion>(
        `SELECT * FROM investment_product_versions
         WHERE tenure_id = $1 AND is_current = TRUE
         LIMIT 1`,
        [tenureId]
      );

      if (result.length === 0) {
        throw new Error('NO_CURRENT_VERSION_FOUND');
      }

      return result[0];
    } catch (error) {
      logger.error('Error getting current version', error);
      throw error;
    }
  }

  /**
   * Get complete version history for a tenure
   */
  static async getTenureVersionHistory(
    tenureId: string
  ): Promise<ProductVersion[]> {
    try {
      const result = await db.query<any>(
        `SELECT
          ipv.*,
          COALESCE(u.first_name || ' ' || u.last_name, 'System') as admin_name
         FROM investment_product_versions ipv
         LEFT JOIN users u ON ipv.changed_by = u.id
         WHERE ipv.tenure_id = $1
         ORDER BY ipv.version_number DESC`,
        [tenureId]
      );

      return result;
    } catch (error) {
      logger.error('Error getting tenure version history', error);
      throw error;
    }
  }

  /**
   * Get all investment units for a category
   */
  static async getUnits(
    category: InvestmentCategory
  ): Promise<InvestmentUnit[]> {
    try {
      const result = await db.query<InvestmentUnit>(
        `SELECT id, category, unit_name, unit_price, description,
                icon_url, display_order, is_active, created_at, updated_at
         FROM investment_units
         WHERE category = $1 AND is_active = true
         ORDER BY display_order, unit_name`,
        [category]
      );

      return result;
    } catch (error) {
      logger.error('Error getting investment units', error);
      throw error;
    }
  }

  /**
   * Create a new investment unit
   */
  static async createUnit(data: CreateUnitDTO): Promise<InvestmentUnit> {
    try {
      const result = await db.query<InvestmentUnit>(
        `INSERT INTO investment_units
         (category, unit_name, unit_price, description, icon_url, display_order, is_active)
         VALUES ($1, $2, $3, $4, $5, $6, true)
         RETURNING id, category, unit_name, unit_price, description,
                   icon_url, display_order, is_active, created_at, updated_at`,
        [
          data.category,
          data.unit_name,
          data.unit_price,
          data.description || null,
          data.icon_url || null,
          data.display_order || 0,
        ]
      );

      logger.info('Investment unit created', {
        unitId: result[0].id,
        category: data.category,
        unitName: data.unit_name,
      });

      return result[0];
    } catch (error) {
      logger.error('Error creating investment unit', error);
      throw error;
    }
  }

  /**
   * Update an existing investment unit
   */
  static async updateUnit(
    unitId: string,
    data: UpdateUnitDTO
  ): Promise<InvestmentUnit> {
    try {
      const updates: string[] = [];
      const values: any[] = [];
      let paramCounter = 1;

      if (data.unit_name !== undefined) {
        updates.push(`unit_name = $${paramCounter++}`);
        values.push(data.unit_name);
      }

      if (data.unit_price !== undefined) {
        updates.push(`unit_price = $${paramCounter++}`);
        values.push(data.unit_price);
      }

      if (data.description !== undefined) {
        updates.push(`description = $${paramCounter++}`);
        values.push(data.description);
      }

      if (data.icon_url !== undefined) {
        updates.push(`icon_url = $${paramCounter++}`);
        values.push(data.icon_url);
      }

      if (data.display_order !== undefined) {
        updates.push(`display_order = $${paramCounter++}`);
        values.push(data.display_order);
      }

      if (data.is_active !== undefined) {
        updates.push(`is_active = $${paramCounter++}`);
        values.push(data.is_active);
      }

      if (updates.length === 0) {
        throw new Error('NO_UPDATES_PROVIDED');
      }

      updates.push(`updated_at = NOW()`);
      values.push(unitId);

      const result = await db.query<InvestmentUnit>(
        `UPDATE investment_units
         SET ${updates.join(', ')}
         WHERE id = $${paramCounter}
         RETURNING id, category, unit_name, unit_price, description,
                   icon_url, display_order, is_active, created_at, updated_at`,
        values
      );

      if (result.length === 0) {
        throw new Error('UNIT_NOT_FOUND');
      }

      logger.info('Investment unit updated', {
        unitId,
        updates: Object.keys(data),
      });

      return result[0];
    } catch (error) {
      logger.error('Error updating investment unit', error);
      throw error;
    }
  }

  /**
   * Delete an investment unit (soft delete)
   */
  static async deleteUnit(unitId: string): Promise<void> {
    try {
      const result = await db.query(
        `UPDATE investment_units
         SET is_active = false, updated_at = NOW()
         WHERE id = $1
         RETURNING id`,
        [unitId]
      );

      if (result.length === 0) {
        throw new Error('UNIT_NOT_FOUND');
      }

      logger.info('Investment unit deleted', { unitId });
    } catch (error) {
      logger.error('Error deleting investment unit', error);
      throw error;
    }
  }

  /**
   * Get rate change history with filters
   */
  static async getRateChangeHistory(
    filters: RateChangeFilters
  ): Promise<RateChangeHistoryItem[]> {
    try {
      let query = `
        SELECT
          ipv.id as version_id,
          ipv.tenure_id,
          ic.name as category,
          ic.display_name as category_display_name,
          it.duration_months as tenure_months,
          ipv.version_number,
          LAG(ipv.return_percentage) OVER (PARTITION BY ipv.tenure_id ORDER BY ipv.version_number) as old_rate,
          ipv.return_percentage as new_rate,
          ipv.change_reason,
          ipv.changed_by,
          COALESCE(u.first_name || ' ' || u.last_name, 'System') as admin_name,
          ipv.effective_from,
          COUNT(DISTINCT ircn.user_id) as users_notified,
          COUNT(DISTINCT CASE WHEN i.status = 'ACTIVE' THEN i.id END) as active_investments
        FROM investment_product_versions ipv
        JOIN investment_tenures it ON ipv.tenure_id = it.id
        JOIN investment_categories ic ON it.category_id = ic.id
        LEFT JOIN users u ON ipv.changed_by = u.id
        LEFT JOIN investment_rate_change_notifications ircn ON ircn.version_id = ipv.id
        LEFT JOIN investments i ON i.tenure_id = ipv.tenure_id
        WHERE ipv.version_number > 1
      `;

      const params: any[] = [];
      let paramCounter = 1;

      if (filters.category) {
        query += ` AND ic.name = $${paramCounter++}`;
        params.push(filters.category);
      }

      if (filters.from_date) {
        query += ` AND ipv.effective_from >= $${paramCounter++}`;
        params.push(filters.from_date);
      }

      if (filters.to_date) {
        query += ` AND ipv.effective_from <= $${paramCounter++}`;
        params.push(filters.to_date);
      }

      if (filters.admin_id) {
        query += ` AND ipv.changed_by = $${paramCounter++}`;
        params.push(filters.admin_id);
      }

      query += `
        GROUP BY ipv.id, ipv.tenure_id, ic.name, ic.display_name,
                 it.duration_months, ipv.version_number, ipv.return_percentage,
                 ipv.change_reason, ipv.changed_by, u.first_name, u.last_name,
                 ipv.effective_from
        ORDER BY ipv.effective_from DESC
      `;

      const result = await db.query<any>(query, params);

      return result.map((row) => ({
        version_id: row.version_id,
        tenure_id: row.tenure_id,
        category: row.category,
        category_display_name: row.category_display_name,
        tenure_months: row.tenure_months,
        version_number: row.version_number,
        old_rate: parseFloat(row.old_rate || 0),
        new_rate: parseFloat(row.new_rate),
        change_reason: row.change_reason,
        changed_by: row.changed_by,
        admin_name: row.admin_name,
        effective_from: row.effective_from,
        users_notified: parseInt(row.users_notified || 0),
        active_investments: parseInt(row.active_investments || 0),
      }));
    } catch (error) {
      logger.error('Error getting rate change history', error);
      throw error;
    }
  }

  /**
   * Get version-based report for investments
   */
  static async getVersionBasedReport(
    params: VersionReportParams
  ): Promise<VersionReport[]> {
    try {
      let query = `
        SELECT
          it.id as tenure_id,
          ic.name as category,
          it.duration_months as tenure_months,
          ipv.id as version_id,
          ipv.version_number,
          ipv.return_percentage,
          ipv.effective_from,
          ipv.effective_until,
          ipv.is_current,
          COUNT(DISTINCT i.id) as investment_count,
          COALESCE(SUM(i.amount), 0) as total_amount,
          COUNT(DISTINCT CASE WHEN i.status = 'ACTIVE' THEN i.id END) as active_count
        FROM investment_tenures it
        JOIN investment_categories ic ON it.category_id = ic.id
        JOIN investment_product_versions ipv ON ipv.tenure_id = it.id
        LEFT JOIN investments i ON i.product_version_id = ipv.id
        WHERE it.is_active = true
      `;

      const params_values: any[] = [];
      let paramCounter = 1;

      if (params.category) {
        query += ` AND ic.name = $${paramCounter++}`;
        params_values.push(params.category);
      }

      if (params.tenure_id) {
        query += ` AND it.id = $${paramCounter++}`;
        params_values.push(params.tenure_id);
      }

      if (params.from_date) {
        query += ` AND ipv.effective_from >= $${paramCounter++}`;
        params_values.push(params.from_date);
      }

      if (params.to_date) {
        query += ` AND ipv.effective_from <= $${paramCounter++}`;
        params_values.push(params.to_date);
      }

      query += `
        GROUP BY it.id, ic.name, it.duration_months, ipv.id, ipv.version_number,
                 ipv.return_percentage, ipv.effective_from, ipv.effective_until, ipv.is_current
        ORDER BY it.id, ipv.version_number DESC
      `;

      const result = await db.query<any>(query, params_values);

      // Group by tenure
      const reportMap = new Map<string, VersionReport>();

      for (const row of result) {
        if (!reportMap.has(row.tenure_id)) {
          reportMap.set(row.tenure_id, {
            tenure_id: row.tenure_id,
            category: row.category,
            tenure_months: row.tenure_months,
            versions: [],
            summary: {
              total_versions: 0,
              total_investments: 0,
              total_amount: 0,
              current_rate: 0,
            },
          });
        }

        const report = reportMap.get(row.tenure_id)!;

        report.versions.push({
          version_id: row.version_id,
          version_number: row.version_number,
          return_percentage: parseFloat(row.return_percentage),
          effective_from: row.effective_from,
          effective_until: row.effective_until,
          is_current: row.is_current,
          investment_count: parseInt(row.investment_count),
          total_amount: parseFloat(row.total_amount),
          active_count: parseInt(row.active_count),
        });

        report.summary.total_versions = report.versions.length;
        report.summary.total_investments += parseInt(row.investment_count);
        report.summary.total_amount += parseFloat(row.total_amount);

        if (row.is_current) {
          report.summary.current_rate = parseFloat(row.return_percentage);
        }
      }

      return Array.from(reportMap.values());
    } catch (error) {
      logger.error('Error getting version based report', error);
      throw error;
    }
  }
}
