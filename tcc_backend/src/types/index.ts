import { Request } from 'express';

export enum UserRole {
  USER = 'USER',
  AGENT = 'AGENT',
  ADMIN = 'ADMIN',
  SUPER_ADMIN = 'SUPER_ADMIN',
}

export enum KYCStatus {
  PENDING = 'PENDING',
  SUBMITTED = 'SUBMITTED',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
}

export enum TransactionType {
  DEPOSIT = 'DEPOSIT',
  WITHDRAWAL = 'WITHDRAWAL',
  TRANSFER = 'TRANSFER',
  BILL_PAYMENT = 'BILL_PAYMENT',
  INVESTMENT = 'INVESTMENT',
  INVESTMENT_RETURN = 'INVESTMENT_RETURN',
  VOTE = 'VOTE',
  COMMISSION = 'COMMISSION',
  AGENT_CREDIT = 'AGENT_CREDIT',
  REFUND = 'REFUND',
}

export enum TransactionStatus {
  PENDING = 'PENDING',
  PROCESSING = 'PROCESSING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
  CANCELLED = 'CANCELLED',
}

export enum PaymentMethod {
  BANK_TRANSFER = 'BANK_TRANSFER',
  MOBILE_MONEY = 'MOBILE_MONEY',
  AGENT = 'AGENT',
  BANK_RECEIPT = 'BANK_RECEIPT',
}

export enum DepositSource {
  BANK_DEPOSIT = 'BANK_DEPOSIT',
  AGENT = 'AGENT',
  AIRTEL_MONEY = 'AIRTEL_MONEY',
  INTERNET_BANKING = 'INTERNET_BANKING',
  ORANGE_MONEY = 'ORANGE_MONEY',
}

export enum InvestmentCategory {
  AGRICULTURE = 'AGRICULTURE',
  EDUCATION = 'EDUCATION',
  MINERALS = 'MINERALS',
}

export enum InvestmentStatus {
  ACTIVE = 'ACTIVE',
  MATURED = 'MATURED',
  WITHDRAWN = 'WITHDRAWN',
  CANCELLED = 'CANCELLED',
}

export enum BillType {
  WATER = 'WATER',
  ELECTRICITY = 'ELECTRICITY',
  DSTV = 'DSTV',
  INTERNET = 'INTERNET',
  MOBILE = 'MOBILE',
  OTHER = 'OTHER',
}

export enum ElectionStatus {
  ACTIVE = 'active',
  ENDED = 'ended',
  PAUSED = 'paused',
}

export enum PollStatus {
  DRAFT = 'DRAFT',
  ACTIVE = 'ACTIVE',
  PAUSED = 'PAUSED',
  CLOSED = 'CLOSED',
}

export enum NotificationType {
  DEPOSIT = 'DEPOSIT',
  WITHDRAWAL = 'WITHDRAWAL',
  TRANSFER = 'TRANSFER',
  BILL_PAYMENT = 'BILL_PAYMENT',
  INVESTMENT = 'INVESTMENT',
  KYC = 'KYC',
  SECURITY = 'SECURITY',
  ANNOUNCEMENT = 'ANNOUNCEMENT',
  VOTE = 'VOTE',
}

export enum DocumentType {
  NATIONAL_ID = 'NATIONAL_ID',
  PASSPORT = 'PASSPORT',
  DRIVERS_LICENSE = 'DRIVERS_LICENSE',
  VOTER_CARD = 'VOTER_CARD',
  BANK_RECEIPT = 'BANK_RECEIPT',
  AGREEMENT = 'AGREEMENT',
  INSURANCE_POLICY = 'INSURANCE_POLICY',
}

export enum AuditActionType {
  MANUAL_CREDIT = 'MANUAL_CREDIT',
  MANUAL_DEBIT = 'MANUAL_DEBIT',
  BALANCE_CORRECTION = 'BALANCE_CORRECTION',
  REFUND = 'REFUND',
}

export interface User {
  id: string;
  role: UserRole;
  first_name: string;
  last_name: string;
  email: string;
  phone: string;
  country_code: string;
  password_hash: string;
  profile_picture_url?: string;
  kyc_status: KYCStatus;
  is_active: boolean;
  is_verified: boolean;
  email_verified: boolean;
  phone_verified: boolean;
  last_login_at?: Date;
  password_changed_at?: Date;
  failed_login_attempts: number;
  locked_until?: Date;
  two_factor_enabled: boolean;
  two_factor_secret?: string;
  deletion_requested_at?: Date;
  deletion_scheduled_for?: Date;
  referral_code?: string;
  referred_by?: string;
  stripe_customer_id?: string;
  created_at: Date;
  updated_at: Date;
}

export interface AuthRequest extends Request {
  user?: {
    id: string;
    role: UserRole;
    email: string;
  };
}

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  message?: string;
  error?: {
    code: string;
    message: string;
    details?: any;
    timestamp?: string;
    request_id?: string;
  };
  meta?: {
    pagination?: {
      page: number;
      limit: number;
      total: number;
      totalPages: number;
    };
  };
}

export interface JWTPayload {
  sub: string;
  role: UserRole;
  email: string;
  iat?: number;
  exp?: number;
}

export interface Transaction {
  id: string;
  transaction_id: string;
  type: TransactionType;
  from_user_id?: string;
  to_user_id?: string;
  amount: number;
  fee: number;
  net_amount: number;
  status: TransactionStatus;
  payment_method?: PaymentMethod;
  deposit_source?: DepositSource;
  reference?: string;
  description?: string;
  metadata?: any;
  stripe_payment_intent_id?: string;
  payment_gateway_response?: any;
  ip_address?: string;
  user_agent?: string;
  processed_at?: Date;
  failed_at?: Date;
  failure_reason?: string;
  created_at: Date;
  updated_at: Date;
}

export interface Wallet {
  id: string;
  user_id: string;
  balance: number;
  currency: string;
  last_transaction_at?: Date;
  created_at: Date;
  updated_at: Date;
}

export interface OTP {
  id: string;
  phone: string;
  country_code: string;
  otp: string;
  purpose: 'REGISTRATION' | 'LOGIN' | 'PHONE_CHANGE' | 'PASSWORD_RESET' | 'WITHDRAWAL' | 'TRANSFER' | 'BILL_PAYMENT' | 'VOTE';
  is_verified: boolean;
  attempts: number;
  expires_at: Date;
  created_at: Date;
}

export interface RefreshToken {
  id: string;
  user_id: string;
  token: string;
  expires_at: Date;
  created_at: Date;
}

export interface PaginationParams {
  page: number;
  limit: number;
  offset: number;
}

export interface Agent {
  id: string;
  user_id: string;
  wallet_balance: number;
  active_status: boolean;
  verification_status: KYCStatus;
  location_lat?: number;
  location_lng?: number;
  location_address?: string;
  commission_rate: number;
  total_commission_earned: number;
  total_transactions_processed: number;
  verified_at?: Date;
  verified_by?: string;
  created_at: Date;
  updated_at: Date;
}

export interface Investment {
  id: string;
  user_id: string;
  category: InvestmentCategory;
  sub_category?: string;
  amount: number;
  tenure_months: number;
  return_percentage: number;
  expected_return: number;
  status: InvestmentStatus;
  has_insurance: boolean;
  insurance_amount?: number;
  start_date: Date;
  maturity_date: Date;
  actual_return?: number;
  withdrawn_at?: Date;
  early_withdrawal_penalty?: number;
  created_at: Date;
  updated_at: Date;
}

export interface BillPayment {
  id: string;
  user_id: string;
  bill_type: BillType;
  provider_name: string;
  provider_id?: string;
  account_number: string;
  customer_name: string;
  amount: number;
  fee: number;
  total_amount: number;
  status: TransactionStatus;
  reference_number?: string;
  transaction_id?: string;
  created_at: Date;
  updated_at: Date;
}

export interface Poll {
  id: string;
  title: string;
  description: string;
  vote_charge: number;
  status: PollStatus;
  start_date: Date;
  end_date: Date;
  total_votes: number;
  total_revenue: number;
  created_by: string;
  created_at: Date;
  updated_at: Date;
}

export interface PollOption {
  id: string;
  poll_id: string;
  option_text: string;
  votes_count: number;
  revenue: number;
  display_order: number;
}

export interface Notification {
  id: string;
  user_id: string;
  type: NotificationType;
  title: string;
  message: string;
  data?: any;
  is_read: boolean;
  read_at?: Date;
  created_at: Date;
}

export interface WalletAuditTrail {
  id: string;
  user_id: string;
  admin_id: string;
  action_type: AuditActionType;
  amount: number;
  balance_before: number;
  balance_after: number;
  reason: string;
  notes?: string;
  transaction_id?: string;
  ip_address?: string;
  created_at: Date;
}

// Investment Product Versioning Types
export interface ProductVersion {
  id: string;
  tenure_id: string;
  version_number: number;
  return_percentage: number;
  effective_from: Date;
  effective_until?: Date;
  is_current: boolean;
  change_reason?: string;
  changed_by?: string;
  metadata?: any;
  created_at: Date;
  updated_at: Date;
}

export interface InvestmentTenure {
  id: string;
  category_id: string;
  duration_months: number;
  return_percentage: number;
  agreement_template_url?: string;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface InvestmentCategoryData {
  id: string;
  name: InvestmentCategory;
  display_name: string;
  description?: string;
  sub_categories?: string[];
  icon_url?: string;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface InvestmentUnit {
  id: string;
  category: InvestmentCategory;
  unit_name: string;
  unit_price: number;
  description?: string;
  icon_url?: string;
  display_order: number;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface TenureWithVersionHistory {
  tenure: InvestmentTenure;
  current_version: ProductVersion;
  version_history: ProductVersion[];
  investment_count: number;
  total_amount: number;
}

export interface InvestmentCategoryWithVersions {
  category: InvestmentCategoryData;
  tenures: TenureWithVersionHistory[];
}

export interface RateChangeNotification {
  id: string;
  version_id: string;
  user_id: string;
  notification_id?: string;
  category: InvestmentCategory;
  tenure_months: number;
  old_rate: number;
  new_rate: number;
  sent_at: Date;
  read_at?: Date;
  created_at: Date;
}

export interface RateChangeHistoryItem {
  version_id: string;
  tenure_id: string;
  category: InvestmentCategory;
  category_display_name: string;
  tenure_months: number;
  version_number: number;
  old_rate: number;
  new_rate: number;
  change_reason?: string;
  changed_by?: string;
  admin_name?: string;
  effective_from: Date;
  users_notified: number;
  active_investments: number;
}

export interface VersionReport {
  tenure_id: string;
  category: InvestmentCategory;
  tenure_months: number;
  versions: {
    version_id: string;
    version_number: number;
    return_percentage: number;
    effective_from: Date;
    effective_until?: Date;
    is_current: boolean;
    investment_count: number;
    total_amount: number;
    active_count: number;
  }[];
  summary: {
    total_versions: number;
    total_investments: number;
    total_amount: number;
    current_rate: number;
  };
}

// DTOs for Investment Product Management
export interface CreateCategoryDTO {
  name: InvestmentCategory;
  display_name: string;
  description?: string;
  sub_categories?: string[];
  icon_url?: string;
}

export interface UpdateCategoryDTO {
  display_name?: string;
  description?: string;
  sub_categories?: string[];
  icon_url?: string;
  is_active?: boolean;
}

export interface CreateTenureDTO {
  category_id: string;
  duration_months: number;
  return_percentage: number;
  agreement_template_url?: string;
}

export interface UpdateRateDTO {
  new_rate: number;
  change_reason: string;
}

export interface CreateUnitDTO {
  category: InvestmentCategory;
  unit_name: string;
  unit_price: number;
  description?: string;
  icon_url?: string;
  display_order?: number;
}

export interface UpdateUnitDTO {
  unit_name?: string;
  unit_price?: number;
  description?: string;
  icon_url?: string;
  display_order?: number;
  is_active?: boolean;
}

export interface VersionReportParams {
  category?: InvestmentCategory;
  tenure_id?: string;
  from_date?: Date;
  to_date?: Date;
}

export interface RateChangeFilters {
  category?: InvestmentCategory;
  from_date?: Date;
  to_date?: Date;
  admin_id?: string;
}

// E-Voting Types
export interface Election {
  id: string;
  title: string;
  question: string;
  voting_charge: number;
  start_time: Date;
  end_time: Date;
  status: ElectionStatus;
  created_by?: string;
  created_at: Date;
  updated_at: Date;
  ended_at?: Date;
  total_votes: number;
  total_revenue: number;
}

export interface ElectionOption {
  id: string;
  election_id: string;
  option_text: string;
  vote_count: number;
  created_at: Date;
}

export interface ElectionVote {
  id: string;
  election_id: string;
  option_id: string;
  user_id: string;
  vote_charge: number;
  voted_at: Date;
}

export interface ElectionWithOptions extends Election {
  options: ElectionOption[];
}

export interface ElectionResult extends ElectionWithOptions {
  user_vote?: {
    option_id: string;
    voted_at: Date;
  };
}

export interface ElectionStats extends Election {
  options: (ElectionOption & {
    percentage: number;
  })[];
  voters: {
    user_id: string;
    first_name: string;
    last_name: string;
    option_id: string;
    option_text: string;
    voted_at: Date;
    vote_charge: number;
  }[];
}

// DTOs for E-Voting
export interface CreateElectionDTO {
  title: string;
  question: string;
  options: string[];
  voting_charge: number;
  end_time: Date;
}

export interface UpdateElectionDTO {
  title?: string;
  question?: string;
  options?: string[];
  voting_charge?: number;
  end_time?: Date;
}

export interface CastVoteDTO {
  election_id: string;
  option_id: string;
}
