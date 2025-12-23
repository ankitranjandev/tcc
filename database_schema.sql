-- =====================================================
-- TCC APP - PostgreSQL Database Schema
-- Target: African Market (Sierra Leone)
-- Currency: Sierra Leonean Leone (SLL)
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- ENUMS
-- =====================================================

CREATE TYPE user_role AS ENUM ('USER', 'AGENT', 'ADMIN', 'SUPER_ADMIN');
CREATE TYPE kyc_status AS ENUM ('PENDING', 'SUBMITTED', 'APPROVED', 'REJECTED');
CREATE TYPE transaction_type AS ENUM ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER', 'BILL_PAYMENT', 'INVESTMENT', 'VOTE', 'COMMISSION', 'AGENT_CREDIT');
CREATE TYPE transaction_status AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED');
CREATE TYPE payment_method AS ENUM ('BANK_TRANSFER', 'MOBILE_MONEY', 'AGENT', 'BANK_RECEIPT');
CREATE TYPE deposit_source AS ENUM ('BANK_DEPOSIT', 'AGENT', 'AIRTEL_MONEY', 'INTERNET_BANKING', 'ORANGE_MONEY');
CREATE TYPE investment_category AS ENUM ('AGRICULTURE', 'EDUCATION', 'MINERALS');
CREATE TYPE investment_status AS ENUM ('ACTIVE', 'MATURED', 'WITHDRAWN', 'CANCELLED');
CREATE TYPE bill_type AS ENUM ('WATER', 'ELECTRICITY', 'DSTV', 'INTERNET', 'MOBILE', 'OTHER');
CREATE TYPE poll_status AS ENUM ('DRAFT', 'ACTIVE', 'PAUSED', 'CLOSED');
CREATE TYPE notification_type AS ENUM ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER', 'BILL_PAYMENT', 'INVESTMENT', 'KYC', 'SECURITY', 'ANNOUNCEMENT', 'VOTE');
CREATE TYPE document_type AS ENUM ('NATIONAL_ID', 'PASSPORT', 'DRIVERS_LICENSE', 'VOTER_CARD', 'BANK_RECEIPT', 'AGREEMENT', 'INSURANCE_POLICY');

-- =====================================================
-- CORE TABLES
-- =====================================================

-- Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role user_role NOT NULL DEFAULT 'USER',
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    country_code VARCHAR(5) NOT NULL DEFAULT '+232', -- Sierra Leone
    password_hash VARCHAR(255) NOT NULL,
    profile_picture_url TEXT,
    kyc_status kyc_status NOT NULL DEFAULT 'PENDING',
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMP WITH TIME ZONE,
    password_changed_at TIMESTAMP WITH TIME ZONE,
    failed_login_attempts INT DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(255),
    deletion_requested_at TIMESTAMP WITH TIME ZONE,
    deletion_scheduled_for TIMESTAMP WITH TIME ZONE,
    referral_code VARCHAR(10) UNIQUE, -- User's own referral code
    referred_by UUID REFERENCES users(id) ON DELETE SET NULL, -- Who referred this user
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_kyc_status ON users(kyc_status);
CREATE INDEX idx_users_deletion_scheduled ON users(deletion_scheduled_for) WHERE deletion_scheduled_for IS NOT NULL;
CREATE INDEX idx_users_referral_code ON users(referral_code) WHERE referral_code IS NOT NULL;
CREATE INDEX idx_users_referred_by ON users(referred_by) WHERE referred_by IS NOT NULL;

-- Wallets Table
CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(3) NOT NULL DEFAULT 'TCC',
    last_transaction_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_balance CHECK (balance >= 0),
    UNIQUE(user_id)
);

CREATE INDEX idx_wallets_user ON wallets(user_id);

-- Transactions Table
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id VARCHAR(50) UNIQUE NOT NULL, -- Human-readable ID
    type transaction_type NOT NULL,
    from_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    to_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    amount DECIMAL(15, 2) NOT NULL,
    fee DECIMAL(15, 2) DEFAULT 0.00,
    net_amount DECIMAL(15, 2) NOT NULL, -- amount - fee
    status transaction_status NOT NULL DEFAULT 'PENDING',
    payment_method payment_method,
    deposit_source deposit_source,
    reference VARCHAR(255), -- External reference (payment gateway ID, bank receipt number, etc.)
    description TEXT,
    metadata JSONB, -- Flexible field for additional data
    ip_address INET,
    user_agent TEXT,
    processed_at TIMESTAMP WITH TIME ZONE,
    failed_at TIMESTAMP WITH TIME ZONE,
    failure_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_amount CHECK (amount > 0),
    CONSTRAINT positive_fee CHECK (fee >= 0)
);

CREATE INDEX idx_transactions_id ON transactions(transaction_id);
CREATE INDEX idx_transactions_from_user ON transactions(from_user_id);
CREATE INDEX idx_transactions_to_user ON transactions(to_user_id);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_created_at ON transactions(created_at DESC);
CREATE INDEX idx_transactions_metadata ON transactions USING GIN (metadata);

-- =====================================================
-- AGENT TABLES
-- =====================================================

-- Agents Table
CREATE TABLE agents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    wallet_balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    active_status BOOLEAN DEFAULT FALSE,
    verification_status kyc_status NOT NULL DEFAULT 'PENDING',
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    location_address TEXT,
    commission_rate DECIMAL(5, 2) DEFAULT 0.00, -- Percentage
    total_commission_earned DECIMAL(15, 2) DEFAULT 0.00,
    total_transactions_processed INT DEFAULT 0,
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_wallet_balance CHECK (wallet_balance >= 0),
    CONSTRAINT valid_commission_rate CHECK (commission_rate >= 0 AND commission_rate <= 100),
    UNIQUE(user_id)
);

CREATE INDEX idx_agents_user ON agents(user_id);
CREATE INDEX idx_agents_active_status ON agents(active_status);
CREATE INDEX idx_agents_location ON agents(location_lat, location_lng);

-- Agent Credit Requests Table
CREATE TABLE agent_credit_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    amount DECIMAL(15, 2) NOT NULL,
    receipt_url TEXT NOT NULL,
    deposit_date DATE NOT NULL,
    deposit_time TIME NOT NULL,
    bank_name VARCHAR(255),
    status transaction_status DEFAULT 'PENDING',
    admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
    rejection_reason TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    rejected_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_amount CHECK (amount > 0)
);

CREATE INDEX idx_agent_credit_requests_agent ON agent_credit_requests(agent_id);
CREATE INDEX idx_agent_credit_requests_status ON agent_credit_requests(status);
CREATE INDEX idx_agent_credit_requests_admin ON agent_credit_requests(admin_id);

-- Agent Commissions Table
CREATE TABLE agent_commissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    commission_amount DECIMAL(15, 2) NOT NULL,
    commission_rate DECIMAL(5, 2) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL, -- 'DEPOSIT', 'WITHDRAWAL'
    paid BOOLEAN DEFAULT FALSE,
    paid_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_commission CHECK (commission_amount >= 0)
);

CREATE INDEX idx_agent_commissions_agent ON agent_commissions(agent_id);
CREATE INDEX idx_agent_commissions_transaction ON agent_commissions(transaction_id);
CREATE INDEX idx_agent_commissions_paid ON agent_commissions(paid);
CREATE INDEX idx_agent_commissions_created_at ON agent_commissions(created_at DESC);

-- Agent Reviews/Ratings Table
CREATE TABLE agent_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    rating INT NOT NULL,
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_rating CHECK (rating >= 1 AND rating <= 5),
    UNIQUE(transaction_id) -- One review per transaction
);

CREATE INDEX idx_agent_reviews_agent ON agent_reviews(agent_id);
CREATE INDEX idx_agent_reviews_user ON agent_reviews(user_id);
CREATE INDEX idx_agent_reviews_rating ON agent_reviews(rating);

-- =====================================================
-- KYC & VERIFICATION TABLES
-- =====================================================

-- KYC Documents Table
CREATE TABLE kyc_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    document_type document_type NOT NULL,
    document_url TEXT NOT NULL,
    document_number VARCHAR(100),
    status kyc_status DEFAULT 'SUBMITTED',
    rejection_reason TEXT,
    verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_kyc_documents_user ON kyc_documents(user_id);
CREATE INDEX idx_kyc_documents_status ON kyc_documents(status);
CREATE INDEX idx_kyc_documents_type ON kyc_documents(document_type);

-- Bank Accounts Table
CREATE TABLE bank_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    bank_name VARCHAR(255) NOT NULL,
    branch_address VARCHAR(500),
    account_number VARCHAR(50) NOT NULL,
    account_holder_name VARCHAR(255) NOT NULL,
    swift_code VARCHAR(20), -- For international transfers
    routing_number VARCHAR(20),
    is_primary BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    verification_otp VARCHAR(10),
    otp_sent_at TIMESTAMP WITH TIME ZONE,
    otp_verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bank_accounts_user ON bank_accounts(user_id);
CREATE INDEX idx_bank_accounts_verified ON bank_accounts(is_verified);

-- =====================================================
-- INVESTMENT TABLES
-- =====================================================

-- Investment Categories Table
CREATE TABLE investment_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name investment_category NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    sub_categories JSONB, -- Array of sub-category names
    icon_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(name)
);

-- Investment Tenures Table
CREATE TABLE investment_tenures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES investment_categories(id) ON DELETE CASCADE,
    duration_months INT NOT NULL,
    return_percentage DECIMAL(5, 2) NOT NULL,
    agreement_template_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_duration CHECK (duration_months > 0),
    CONSTRAINT positive_return CHECK (return_percentage >= 0)
);

CREATE INDEX idx_investment_tenures_category ON investment_tenures(category_id);
CREATE INDEX idx_investment_tenures_active ON investment_tenures(is_active);

-- Investment Units Table (Lot/Plot/Farm pricing from Figma)
CREATE TABLE investment_units (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category investment_category NOT NULL,
    unit_name VARCHAR(50) NOT NULL, -- 'Lot', 'Plot', 'Farm'
    unit_price DECIMAL(15, 2) NOT NULL, -- Price in TCC Coins
    description TEXT,
    icon_url TEXT,
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_price CHECK (unit_price > 0),
    UNIQUE(category, unit_name)
);

CREATE INDEX idx_investment_units_category ON investment_units(category);
CREATE INDEX idx_investment_units_active ON investment_units(is_active);

-- Investment Opportunities Table (Admin-created investment products)
CREATE TABLE investment_opportunities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES investment_categories(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    min_investment DECIMAL(15, 2) NOT NULL,
    max_investment DECIMAL(15, 2) NOT NULL,
    tenure_months INT NOT NULL,
    return_rate DECIMAL(5, 2) NOT NULL, -- Annual percentage return
    total_units INT NOT NULL DEFAULT 0,
    available_units INT NOT NULL DEFAULT 0,
    image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    display_order INT DEFAULT 0,
    metadata JSONB, -- Additional flexible data
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_min_investment CHECK (min_investment > 0),
    CONSTRAINT positive_max_investment CHECK (max_investment >= min_investment),
    CONSTRAINT positive_tenure CHECK (tenure_months > 0),
    CONSTRAINT positive_return_rate CHECK (return_rate >= 0),
    CONSTRAINT positive_total_units CHECK (total_units >= 0),
    CONSTRAINT positive_available_units CHECK (available_units >= 0 AND available_units <= total_units)
);

CREATE INDEX idx_inv_opp_category ON investment_opportunities(category_id);
CREATE INDEX idx_inv_opp_active ON investment_opportunities(is_active);
CREATE INDEX idx_inv_opp_display_order ON investment_opportunities(display_order);
CREATE INDEX idx_inv_opp_category_active ON investment_opportunities(category_id, is_active);
CREATE INDEX idx_inv_opp_metadata ON investment_opportunities USING GIN (metadata);

-- Investments Table
CREATE TABLE investments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category investment_category NOT NULL,
    sub_category VARCHAR(100),
    opportunity_id UUID REFERENCES investment_opportunities(id) ON DELETE SET NULL,
    tenure_id UUID NOT NULL REFERENCES investment_tenures(id),
    amount DECIMAL(15, 2) NOT NULL,
    tenure_months INT NOT NULL,
    return_rate DECIMAL(5, 2) NOT NULL,
    expected_return DECIMAL(15, 2) NOT NULL,
    actual_return DECIMAL(15, 2),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    agreement_url TEXT,
    insurance_taken BOOLEAN DEFAULT FALSE,
    insurance_cost DECIMAL(15, 2),
    status investment_status DEFAULT 'ACTIVE',
    transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    withdrawal_transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    withdrawn_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_amount CHECK (amount > 0),
    CONSTRAINT valid_dates CHECK (end_date > start_date)
);

CREATE INDEX idx_investments_user ON investments(user_id);
CREATE INDEX idx_investments_status ON investments(status);
CREATE INDEX idx_investments_category ON investments(category);
CREATE INDEX idx_investments_opportunity ON investments(opportunity_id);
CREATE INDEX idx_investments_end_date ON investments(end_date);

-- Investment Tenure Change Requests Table
CREATE TABLE investment_tenure_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    investment_id UUID NOT NULL REFERENCES investments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    old_tenure_months INT NOT NULL,
    new_tenure_months INT NOT NULL,
    old_return_rate DECIMAL(5, 2) NOT NULL,
    new_return_rate DECIMAL(5, 2) NOT NULL,
    status transaction_status DEFAULT 'PENDING',
    admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
    rejection_reason TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    rejected_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_investment_tenure_requests_investment ON investment_tenure_requests(investment_id);
CREATE INDEX idx_investment_tenure_requests_status ON investment_tenure_requests(status);

-- Investment Returns Table (Manual entry by admin)
CREATE TABLE investment_returns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    investment_id UUID NOT NULL REFERENCES investments(id) ON DELETE CASCADE,
    return_date DATE NOT NULL,
    calculated_amount DECIMAL(15, 2) NOT NULL, -- Expected return
    actual_amount DECIMAL(15, 2), -- Actual return (admin enters)
    actual_rate DECIMAL(5, 2), -- Actual percentage return
    status VARCHAR(20) DEFAULT 'PENDING', -- 'PENDING', 'PAID', 'PARTIALLY_PAID'
    notes TEXT,
    processed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    processed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_calculated CHECK (calculated_amount >= 0)
);

CREATE INDEX idx_investment_returns_investment ON investment_returns(investment_id);
CREATE INDEX idx_investment_returns_status ON investment_returns(status);
CREATE INDEX idx_investment_returns_return_date ON investment_returns(return_date);
CREATE INDEX idx_investment_returns_processed_by ON investment_returns(processed_by);

-- =====================================================
-- BILL PAYMENT TABLES
-- =====================================================

-- Bill Providers Table
CREATE TABLE bill_providers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    type bill_type NOT NULL,
    logo_url TEXT,
    api_endpoint TEXT,
    api_key_encrypted TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bill_providers_type ON bill_providers(type);
CREATE INDEX idx_bill_providers_active ON bill_providers(is_active);

-- Bill Payments Table
CREATE TABLE bill_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider_id UUID REFERENCES bill_providers(id) ON DELETE SET NULL,
    bill_type bill_type NOT NULL,
    bill_id VARCHAR(100) NOT NULL,
    bill_holder_name VARCHAR(255),
    amount DECIMAL(15, 2) NOT NULL,
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    provider_transaction_id VARCHAR(255),
    status transaction_status DEFAULT 'PENDING',
    receipt_url TEXT,
    processed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_amount CHECK (amount > 0)
);

CREATE INDEX idx_bill_payments_user ON bill_payments(user_id);
CREATE INDEX idx_bill_payments_status ON bill_payments(status);
CREATE INDEX idx_bill_payments_provider ON bill_payments(provider_id);

-- =====================================================
-- E-VOTING TABLES
-- =====================================================

-- Polls Table
CREATE TABLE polls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    question TEXT NOT NULL,
    options JSONB NOT NULL, -- Array of option strings
    voting_charge DECIMAL(15, 2) NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    status poll_status DEFAULT 'DRAFT',
    created_by_admin_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    total_votes INT DEFAULT 0,
    total_revenue DECIMAL(15, 2) DEFAULT 0.00,
    results JSONB, -- Option-wise vote count
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_charge CHECK (voting_charge >= 0),
    CONSTRAINT valid_time_range CHECK (end_time > start_time)
);

CREATE INDEX idx_polls_status ON polls(status);
CREATE INDEX idx_polls_created_by ON polls(created_by_admin_id);
CREATE INDEX idx_polls_start_time ON polls(start_time);
CREATE INDEX idx_polls_end_time ON polls(end_time);

-- Votes Table
CREATE TABLE votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    poll_id UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    selected_option VARCHAR(255) NOT NULL,
    amount_paid DECIMAL(15, 2) NOT NULL,
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    voted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(poll_id, user_id) -- One vote per user per poll
);

CREATE INDEX idx_votes_poll ON votes(poll_id);
CREATE INDEX idx_votes_user ON votes(user_id);
CREATE INDEX idx_votes_voted_at ON votes(voted_at);

-- =====================================================
-- ADMIN TABLES
-- =====================================================

-- Admins Table
CREATE TABLE admins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    admin_role user_role NOT NULL DEFAULT 'ADMIN',
    permissions JSONB, -- Array of permission strings
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id),
    CONSTRAINT valid_admin_role CHECK (admin_role IN ('ADMIN', 'SUPER_ADMIN'))
);

CREATE INDEX idx_admins_user ON admins(user_id);
CREATE INDEX idx_admins_role ON admins(admin_role);

-- Admin Audit Logs Table
CREATE TABLE admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL, -- e.g., 'APPROVE_KYC', 'REJECT_WITHDRAWAL', 'UPDATE_RETURN_RATE'
    entity_type VARCHAR(50), -- e.g., 'USER', 'INVESTMENT', 'AGENT'
    entity_id UUID,
    changes JSONB, -- Before/after values
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_admin_audit_logs_admin ON admin_audit_logs(admin_id);
CREATE INDEX idx_admin_audit_logs_entity ON admin_audit_logs(entity_type, entity_id);
CREATE INDEX idx_admin_audit_logs_action ON admin_audit_logs(action);
CREATE INDEX idx_admin_audit_logs_created_at ON admin_audit_logs(created_at DESC);

-- =====================================================
-- SYSTEM CONFIGURATION TABLES
-- =====================================================

-- System Configuration Table
CREATE TABLE system_config (
    key VARCHAR(100) PRIMARY KEY,
    value TEXT NOT NULL,
    category VARCHAR(50) NOT NULL, -- e.g., 'TRANSACTION_LIMITS', 'FEES', 'SECURITY'
    data_type VARCHAR(20) NOT NULL, -- 'STRING', 'NUMBER', 'BOOLEAN', 'JSON'
    description TEXT,
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_system_config_category ON system_config(category);

-- Default system configuration
INSERT INTO system_config (key, value, category, data_type, description) VALUES
('MIN_DEPOSIT_AMOUNT', '1000', 'TRANSACTION_LIMITS', 'NUMBER', 'Minimum deposit amount in SLL'),
('MAX_DEPOSIT_AMOUNT', '10000000', 'TRANSACTION_LIMITS', 'NUMBER', 'Maximum deposit amount in SLL'),
('MIN_WITHDRAWAL_AMOUNT', '1000', 'TRANSACTION_LIMITS', 'NUMBER', 'Minimum withdrawal amount in SLL'),
('MAX_WITHDRAWAL_AMOUNT', '5000000', 'TRANSACTION_LIMITS', 'NUMBER', 'Maximum withdrawal amount in SLL'),
('MIN_TRANSFER_AMOUNT', '100', 'TRANSACTION_LIMITS', 'NUMBER', 'Minimum transfer amount in SLL'),
('MAX_TRANSFER_AMOUNT', '2000000', 'TRANSACTION_LIMITS', 'NUMBER', 'Maximum transfer amount in SLL'),
('DAILY_DEPOSIT_LIMIT', '50000000', 'TRANSACTION_LIMITS', 'NUMBER', 'Daily deposit limit in SLL'),
('DAILY_WITHDRAWAL_LIMIT', '20000000', 'TRANSACTION_LIMITS', 'NUMBER', 'Daily withdrawal limit in SLL'),
('DAILY_TRANSFER_LIMIT', '5000000', 'TRANSACTION_LIMITS', 'NUMBER', 'Daily transfer limit in SLL'),
('DEPOSIT_FEE_PERCENT', '0', 'FEES', 'NUMBER', 'Deposit fee percentage'),
('WITHDRAWAL_FEE_PERCENT', '2', 'FEES', 'NUMBER', 'Withdrawal fee percentage'),
('TRANSFER_FEE_PERCENT', '1', 'FEES', 'NUMBER', 'Transfer fee percentage'),
('OTP_EXPIRY_MINUTES', '5', 'SECURITY', 'NUMBER', 'OTP expiration time in minutes'),
('OTP_LENGTH', '6', 'SECURITY', 'NUMBER', 'OTP code length'),
('MAX_OTP_ATTEMPTS', '3', 'SECURITY', 'NUMBER', 'Maximum OTP attempts before blocking'),
('SESSION_TIMEOUT_MINUTES', '30', 'SECURITY', 'NUMBER', 'Session timeout in minutes'),
('MAX_LOGIN_ATTEMPTS', '5', 'SECURITY', 'NUMBER', 'Maximum failed login attempts before lockout'),
('ACCOUNT_LOCKOUT_MINUTES', '30', 'SECURITY', 'NUMBER', 'Account lockout duration in minutes'),
('PASSWORD_MIN_LENGTH', '8', 'SECURITY', 'NUMBER', 'Minimum password length'),
('ACCOUNT_DELETION_GRACE_DAYS', '30', 'SECURITY', 'NUMBER', 'Days before account is permanently deleted');

-- =====================================================
-- REFERRAL SYSTEM TABLES
-- =====================================================

-- Referrals Table
CREATE TABLE referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referred_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reward_amount DECIMAL(15, 2) DEFAULT 0.00,
    reward_type VARCHAR(20) DEFAULT 'COINS', -- 'COINS', 'BONUS', 'PERCENTAGE'
    status VARCHAR(20) DEFAULT 'PENDING', -- 'PENDING', 'APPROVED', 'PAID'
    conditions_met BOOLEAN DEFAULT FALSE,
    conditions JSONB, -- e.g., {"kyc_completed": true, "first_deposit": 1000}
    paid_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(referred_id) -- Each user can only be referred once
);

CREATE INDEX idx_referrals_referrer ON referrals(referrer_id);
CREATE INDEX idx_referrals_referred ON referrals(referred_id);
CREATE INDEX idx_referrals_status ON referrals(status);

-- =====================================================
-- SECURITY & SESSION TABLES
-- =====================================================

-- User Sessions Table
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    refresh_token_hash VARCHAR(255) UNIQUE,
    device_info JSONB, -- {device_type, os, browser, app_version}
    ip_address INET,
    location VARCHAR(255), -- City, Country from IP
    is_active BOOLEAN DEFAULT TRUE,
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_sessions_user ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_token ON user_sessions(token_hash);
CREATE INDEX idx_user_sessions_active ON user_sessions(is_active);
CREATE INDEX idx_user_sessions_expires ON user_sessions(expires_at);

-- API Keys Table (for admin/partner integrations)
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key_hash VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    admin_id UUID REFERENCES users(id) ON DELETE CASCADE,
    partner_name VARCHAR(255), -- For partner integrations
    permissions JSONB NOT NULL, -- Array of allowed endpoints/actions
    rate_limit INT DEFAULT 100, -- Requests per minute
    last_used_at TIMESTAMP WITH TIME ZONE,
    usage_count INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP WITH TIME ZONE,
    revoked_at TIMESTAMP WITH TIME ZONE,
    revoked_by UUID REFERENCES users(id) ON DELETE SET NULL,
    revoke_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_api_keys_hash ON api_keys(key_hash);
CREATE INDEX idx_api_keys_admin ON api_keys(admin_id);
CREATE INDEX idx_api_keys_active ON api_keys(is_active);
CREATE INDEX idx_api_keys_expires ON api_keys(expires_at);

-- Security Events Table
CREATE TABLE security_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL, -- 'FAILED_LOGIN', 'PASSWORD_CHANGE', 'SUSPICIOUS_TRANSACTION', etc.
    severity VARCHAR(20) NOT NULL, -- 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    description TEXT,
    ip_address INET,
    device_info JSONB,
    location VARCHAR(255),
    metadata JSONB, -- Additional context
    resolved BOOLEAN DEFAULT FALSE,
    resolved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_security_events_user ON security_events(user_id);
CREATE INDEX idx_security_events_type ON security_events(event_type);
CREATE INDEX idx_security_events_severity ON security_events(severity);
CREATE INDEX idx_security_events_resolved ON security_events(resolved);
CREATE INDEX idx_security_events_created_at ON security_events(created_at DESC);

-- =====================================================
-- NOTIFICATION TABLES
-- =====================================================

-- Notification Preferences Table
CREATE TABLE notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    push_enabled BOOLEAN DEFAULT TRUE,
    email_enabled BOOLEAN DEFAULT TRUE,
    sms_enabled BOOLEAN DEFAULT FALSE,
    notification_types JSONB DEFAULT '{"DEPOSIT":true,"WITHDRAWAL":true,"TRANSFER":true,"BILL_PAYMENT":true,"INVESTMENT":true,"KYC":true,"SECURITY":true,"ANNOUNCEMENT":true,"VOTE":false}'::jsonb,
    quiet_hours_start TIME, -- e.g., '22:00:00'
    quiet_hours_end TIME, -- e.g., '08:00:00'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

CREATE INDEX idx_notification_preferences_user ON notification_preferences(user_id);

-- Notifications Table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type notification_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSONB, -- Additional data for the notification
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- Push Notification Tokens Table
CREATE TABLE push_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform VARCHAR(20) NOT NULL, -- 'IOS', 'ANDROID', 'WEB'
    device_id VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_push_tokens_user ON push_tokens(user_id);
CREATE INDEX idx_push_tokens_active ON push_tokens(is_active);

-- =====================================================
-- SUPPORT TABLES
-- =====================================================

-- Support Tickets Table (Email-based for now)
CREATE TABLE support_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id VARCHAR(20) UNIQUE NOT NULL, -- e.g., 'TCC-12345'
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    email VARCHAR(255) NOT NULL,
    subject VARCHAR(500) NOT NULL,
    message TEXT NOT NULL,
    attachments JSONB, -- Array of file URLs
    status VARCHAR(20) DEFAULT 'OPEN', -- OPEN, IN_PROGRESS, RESOLVED, CLOSED
    priority VARCHAR(20) DEFAULT 'NORMAL', -- LOW, NORMAL, HIGH, URGENT
    assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_support_tickets_user ON support_tickets(user_id);
CREATE INDEX idx_support_tickets_status ON support_tickets(status);
CREATE INDEX idx_support_tickets_assigned_to ON support_tickets(assigned_to);

-- =====================================================
-- OTP TABLES
-- =====================================================

-- OTP Codes Table
CREATE TABLE otp_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    phone VARCHAR(20),
    email VARCHAR(255),
    code VARCHAR(10) NOT NULL,
    purpose VARCHAR(50) NOT NULL, -- 'REGISTRATION', 'LOGIN', 'FORGOT_PASSWORD', 'VERIFY_PHONE', 'BANK_VERIFICATION', etc.
    attempts INT DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT max_attempts CHECK (attempts <= 3)
);

CREATE INDEX idx_otp_codes_phone ON otp_codes(phone);
CREATE INDEX idx_otp_codes_email ON otp_codes(email);
CREATE INDEX idx_otp_codes_expires_at ON otp_codes(expires_at);

-- =====================================================
-- WITHDRAWAL REQUESTS TABLE
-- =====================================================

CREATE TABLE withdrawal_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(15, 2) NOT NULL,
    fee DECIMAL(15, 2) NOT NULL,
    net_amount DECIMAL(15, 2) NOT NULL,
    withdrawal_type VARCHAR(20) NOT NULL, -- 'WALLET', 'INVESTMENT'
    investment_id UUID REFERENCES investments(id) ON DELETE CASCADE,
    destination VARCHAR(20) NOT NULL, -- 'BANK', 'MOBILE_MONEY'
    bank_account_id UUID REFERENCES bank_accounts(id) ON DELETE SET NULL,
    mobile_money_number VARCHAR(20),
    status transaction_status DEFAULT 'PENDING',
    admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
    rejection_reason TEXT,
    transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    approved_at TIMESTAMP WITH TIME ZONE,
    rejected_at TIMESTAMP WITH TIME ZONE,
    processed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_amount CHECK (amount > 0)
);

CREATE INDEX idx_withdrawal_requests_user ON withdrawal_requests(user_id);
CREATE INDEX idx_withdrawal_requests_status ON withdrawal_requests(status);
CREATE INDEX idx_withdrawal_requests_admin ON withdrawal_requests(admin_id);

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables with updated_at column
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_wallets_updated_at BEFORE UPDATE ON wallets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_agents_updated_at BEFORE UPDATE ON agents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_agent_credit_requests_updated_at BEFORE UPDATE ON agent_credit_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_kyc_documents_updated_at BEFORE UPDATE ON kyc_documents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_bank_accounts_updated_at BEFORE UPDATE ON bank_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_investment_categories_updated_at BEFORE UPDATE ON investment_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_investment_tenures_updated_at BEFORE UPDATE ON investment_tenures FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_investment_units_updated_at BEFORE UPDATE ON investment_units FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_investment_opportunities_updated_at BEFORE UPDATE ON investment_opportunities FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_investments_updated_at BEFORE UPDATE ON investments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_investment_returns_updated_at BEFORE UPDATE ON investment_returns FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_investment_tenure_requests_updated_at BEFORE UPDATE ON investment_tenure_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_bill_providers_updated_at BEFORE UPDATE ON bill_providers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_bill_payments_updated_at BEFORE UPDATE ON bill_payments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_polls_updated_at BEFORE UPDATE ON polls FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_admins_updated_at BEFORE UPDATE ON admins FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_push_tokens_updated_at BEFORE UPDATE ON push_tokens FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_support_tickets_updated_at BEFORE UPDATE ON support_tickets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_withdrawal_requests_updated_at BEFORE UPDATE ON withdrawal_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_referrals_updated_at BEFORE UPDATE ON referrals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_api_keys_updated_at BEFORE UPDATE ON api_keys FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_notification_preferences_updated_at BEFORE UPDATE ON notification_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCTIONS FOR BUSINESS LOGIC
-- =====================================================

-- Function to enforce maximum 16 opportunities per category
CREATE OR REPLACE FUNCTION check_category_opportunity_limit()
RETURNS TRIGGER AS $$
DECLARE
    opportunity_count INT;
BEGIN
    -- Count existing opportunities for this category
    SELECT COUNT(*) INTO opportunity_count
    FROM investment_opportunities
    WHERE category_id = NEW.category_id;

    -- Allow updates to existing records
    IF TG_OP = 'UPDATE' THEN
        RETURN NEW;
    END IF;

    -- Check limit for new records
    IF opportunity_count >= 16 THEN
        RAISE EXCEPTION 'Maximum 16 opportunities allowed per category. Category % already has % opportunities.',
            NEW.category_id, opportunity_count;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to enforce opportunity limit
CREATE TRIGGER enforce_opportunity_limit
BEFORE INSERT ON investment_opportunities
FOR EACH ROW
EXECUTE FUNCTION check_category_opportunity_limit();

-- Function to generate transaction ID
CREATE OR REPLACE FUNCTION generate_transaction_id()
RETURNS TEXT AS $$
DECLARE
    new_id TEXT;
BEGIN
    new_id := 'TXN' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || LPAD(FLOOR(RANDOM() * 999999)::TEXT, 6, '0');
    RETURN new_id;
END;
$$ LANGUAGE plpgsql;

-- Function to generate support ticket ID
CREATE OR REPLACE FUNCTION generate_ticket_id()
RETURNS TEXT AS $$
DECLARE
    new_id TEXT;
BEGIN
    new_id := 'TCC' || LPAD(FLOOR(RANDOM() * 99999)::TEXT, 5, '0');
    RETURN new_id;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate transaction ID
CREATE OR REPLACE FUNCTION set_transaction_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.transaction_id IS NULL THEN
        NEW.transaction_id := generate_transaction_id();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_transaction_id_trigger
BEFORE INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION set_transaction_id();

-- Trigger to auto-generate ticket ID
CREATE OR REPLACE FUNCTION set_ticket_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ticket_id IS NULL THEN
        NEW.ticket_id := generate_ticket_id();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_ticket_id_trigger
BEFORE INSERT ON support_tickets
FOR EACH ROW
EXECUTE FUNCTION set_ticket_id();

-- =====================================================
-- SEED DATA FOR INVESTMENT CATEGORIES
-- =====================================================

INSERT INTO investment_categories (name, display_name, description, sub_categories, is_active) VALUES
('AGRICULTURE', 'Agriculture', 'Invest in agricultural projects', '["Land Lease", "Production", "Processing", "Marketing"]', true),
('EDUCATION', 'Education', 'Invest in educational institutions', '["Institution", "Housing/Dormitory"]', true),
('MINERALS', 'Minerals', 'Invest in mineral extraction and trading', '["Gold", "Platinum", "Silver", "Diamond"]', true);

-- Sample investment tenures (Admin can add more)
INSERT INTO investment_tenures (category_id, duration_months, return_percentage, is_active)
SELECT id, 6, 5.0, true FROM investment_categories WHERE name = 'AGRICULTURE';

INSERT INTO investment_tenures (category_id, duration_months, return_percentage, is_active)
SELECT id, 12, 10.0, true FROM investment_categories WHERE name = 'AGRICULTURE';

INSERT INTO investment_tenures (category_id, duration_months, return_percentage, is_active)
SELECT id, 24, 20.0, true FROM investment_categories WHERE name = 'AGRICULTURE';

-- =====================================================
-- SEED DATA FOR INVESTMENT UNITS (from Figma)
-- =====================================================

INSERT INTO investment_units (category, unit_name, unit_price, description, display_order, is_active) VALUES
('AGRICULTURE', 'Lot', 234.00, '1 Lot = 234 TCC Coins - Small agricultural investment unit', 1, true),
('AGRICULTURE', 'Plot', 1000.00, '1 Plot = 1000 TCC Coins - Medium agricultural investment unit', 2, true),
('AGRICULTURE', 'Farm', 2340.00, '1 Farm = 2340 TCC Coins - Large agricultural investment unit', 3, true),
('EDUCATION', 'Institution', 5000.00, 'Institution investment - Educational facility', 1, true),
('EDUCATION', 'Housing/Dormitory', 3000.00, 'Housing/Dormitory investment - Student accommodation', 2, true),
('MINERALS', 'Gold', 500.00, 'Gold mining investment unit', 1, true),
('MINERALS', 'Platinum', 750.00, 'Platinum mining investment unit', 2, true),
('MINERALS', 'Silver', 400.00, 'Silver mining investment unit', 3, true),
('MINERALS', 'Diamond', 1000.00, 'Diamond mining investment unit', 4, true);

-- =====================================================
-- MIGRATE EXISTING SUB-CATEGORIES TO OPPORTUNITIES
-- =====================================================

-- Convert Agriculture and Education sub-categories to investment opportunities
INSERT INTO investment_opportunities (
    category_id,
    title,
    description,
    min_investment,
    max_investment,
    tenure_months,
    return_rate,
    total_units,
    available_units,
    is_active,
    display_order
)
SELECT
    ic.id as category_id,
    sub_cat::TEXT as title,
    CASE
        WHEN ic.name = 'AGRICULTURE' THEN
            CASE sub_cat::TEXT
                WHEN 'Land Lease' THEN 'Invest in agricultural land leasing projects with guaranteed returns'
                WHEN 'Production' THEN 'Support crop and livestock production initiatives'
                WHEN 'Processing' THEN 'Invest in agricultural processing facilities and equipment'
                WHEN 'Marketing' THEN 'Fund agricultural marketing and distribution networks'
                ELSE 'Agricultural investment opportunity'
            END
        WHEN ic.name = 'EDUCATION' THEN
            CASE sub_cat::TEXT
                WHEN 'Institution' THEN 'Invest in educational institutions and facilities'
                WHEN 'Housing/Dormitory' THEN 'Support student housing and dormitory development'
                ELSE 'Educational investment opportunity'
            END
        ELSE 'Investment opportunity'
    END as description,
    CASE ic.name
        WHEN 'AGRICULTURE' THEN 1000.00
        WHEN 'EDUCATION' THEN 5000.00
        ELSE 1000.00
    END as min_investment,
    CASE ic.name
        WHEN 'AGRICULTURE' THEN 100000.00
        WHEN 'EDUCATION' THEN 500000.00
        ELSE 100000.00
    END as max_investment,
    12 as tenure_months,
    CASE ic.name
        WHEN 'AGRICULTURE' THEN 15.0
        WHEN 'EDUCATION' THEN 12.0
        ELSE 10.0
    END as return_rate,
    100 as total_units,
    100 as available_units,
    true as is_active,
    row_number() OVER (PARTITION BY ic.id ORDER BY sub_cat::TEXT) as display_order
FROM investment_categories ic,
LATERAL jsonb_array_elements_text(ic.sub_categories) sub_cat
WHERE ic.name IN ('AGRICULTURE', 'EDUCATION')
  AND ic.sub_categories IS NOT NULL;

-- =====================================================
-- CREATE DEFAULT SUPER ADMIN
-- =====================================================
-- Password: Admin@123 (Should be changed on first login)
-- This is a hashed password placeholder - actual hash will be generated by backend

INSERT INTO users (role, first_name, last_name, email, phone, country_code, password_hash, is_active, is_verified, email_verified, phone_verified, kyc_status)
VALUES ('SUPER_ADMIN', 'Super', 'Admin', 'admin@tccapp.com', '232XXXXXXXX', '+232', '$2b$10$placeholder_hash', true, true, true, true, 'APPROVED');

INSERT INTO admins (user_id, admin_role, is_active)
SELECT id, 'SUPER_ADMIN', true FROM users WHERE email = 'admin@tccapp.com';

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE users IS 'Core users table for all user types (USER, AGENT, ADMIN)';
COMMENT ON TABLE wallets IS 'User wallet balances in Sierra Leonean Leone (SLL)';
COMMENT ON TABLE transactions IS 'All financial transactions in the system';
COMMENT ON TABLE agents IS 'Agent-specific information and wallet';
COMMENT ON TABLE investments IS 'User investment records with returns tracking';
COMMENT ON TABLE polls IS 'E-voting polls created by admins';
COMMENT ON TABLE votes IS 'User votes on polls (non-anonymous)';
COMMENT ON COLUMN system_config.value IS 'All values stored as TEXT, cast based on data_type';
COMMENT ON TABLE referrals IS 'Referral rewards tracking system';
COMMENT ON TABLE user_sessions IS 'Active user sessions with JWT tokens';
COMMENT ON TABLE api_keys IS 'API keys for admin and partner integrations';
COMMENT ON TABLE security_events IS 'Security and suspicious activity tracking';
COMMENT ON TABLE agent_commissions IS 'Agent commission tracking per transaction';
COMMENT ON TABLE agent_reviews IS 'User reviews and ratings for agents';
COMMENT ON TABLE investment_units IS 'Investment unit pricing (Lot/Plot/Farm from Figma)';
COMMENT ON TABLE investment_returns IS 'Manual investment return entry by admin';
COMMENT ON TABLE notification_preferences IS 'User notification preferences and quiet hours';

-- =====================================================
-- CRITICAL MISSING TABLES (LLD GAPS)
-- =====================================================

-- File Uploads Table (Centralized file management)
CREATE TABLE file_uploads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    file_type VARCHAR(50) NOT NULL, -- 'KYC_DOCUMENT', 'RECEIPT', 'PROFILE_PICTURE', 'AGENT_LICENSE', 'SUPPORT_ATTACHMENT'
    original_filename VARCHAR(255) NOT NULL,
    stored_filename VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    checksum VARCHAR(64), -- SHA-256 hash for integrity
    metadata JSONB, -- Additional file metadata
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_file_size CHECK (file_size > 0 AND file_size <= 10485760) -- Max 10MB
);

CREATE INDEX idx_file_uploads_user ON file_uploads(user_id);
CREATE INDEX idx_file_uploads_type ON file_uploads(file_type);
CREATE INDEX idx_file_uploads_created_at ON file_uploads(created_at DESC);
CREATE INDEX idx_file_uploads_checksum ON file_uploads(checksum);

-- Notification Templates Table (SMS/Email template management)
CREATE TABLE notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_code VARCHAR(50) UNIQUE NOT NULL, -- 'OTP_SMS', 'WELCOME_EMAIL', 'TRANSFER_SUCCESS', etc.
    channel VARCHAR(20) NOT NULL, -- 'SMS', 'EMAIL', 'PUSH'
    subject VARCHAR(255), -- For emails
    body_template TEXT NOT NULL, -- With {{variables}}
    variables JSONB, -- List of required variables ['otp', 'name', 'amount']
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notification_templates_code ON notification_templates(template_code);
CREATE INDEX idx_notification_templates_channel ON notification_templates(channel);

-- User Devices Table (Device fingerprinting and trust)
CREATE TABLE user_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(255) NOT NULL,
    device_type VARCHAR(50) NOT NULL, -- 'iOS', 'Android', 'Web'
    device_name VARCHAR(255),
    device_model VARCHAR(255),
    os_version VARCHAR(50),
    app_version VARCHAR(20),
    fingerprint VARCHAR(255), -- Device fingerprint hash
    is_trusted BOOLEAN DEFAULT FALSE,
    is_blocked BOOLEAN DEFAULT FALSE,
    trust_score INT DEFAULT 0, -- 0-100 trust score
    last_used_at TIMESTAMP WITH TIME ZONE,
    last_location VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, device_id)
);

CREATE INDEX idx_user_devices_user ON user_devices(user_id);
CREATE INDEX idx_user_devices_fingerprint ON user_devices(fingerprint);
CREATE INDEX idx_user_devices_trusted ON user_devices(is_trusted);

-- Rate Limiting Table (API rate limit tracking)
CREATE TABLE rate_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    identifier VARCHAR(255) NOT NULL, -- user_id, ip_address, api_key
    endpoint VARCHAR(255) NOT NULL,
    request_count INT DEFAULT 1,
    window_start TIMESTAMP WITH TIME ZONE NOT NULL,
    window_end TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(identifier, endpoint, window_start)
);

CREATE INDEX idx_rate_limits_identifier ON rate_limits(identifier);
CREATE INDEX idx_rate_limits_window ON rate_limits(window_end);

-- Transaction Reversals Table
CREATE TABLE transaction_reversals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    original_transaction_id UUID NOT NULL REFERENCES transactions(id),
    reversal_transaction_id UUID REFERENCES transactions(id),
    reason VARCHAR(255) NOT NULL,
    reversal_type VARCHAR(20) DEFAULT 'FULL', -- 'FULL', 'PARTIAL'
    reversal_amount DECIMAL(15, 2),
    initiated_by UUID REFERENCES users(id),
    approved_by UUID REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'PENDING', -- 'PENDING', 'APPROVED', 'REJECTED', 'COMPLETED'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT positive_amount CHECK (reversal_amount > 0)
);

CREATE INDEX idx_transaction_reversals_original ON transaction_reversals(original_transaction_id);
CREATE INDEX idx_transaction_reversals_status ON transaction_reversals(status);

-- Scheduled Transactions Table (Recurring payments)
CREATE TABLE scheduled_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type transaction_type NOT NULL,
    recipient_id UUID REFERENCES users(id),
    bill_provider_id UUID REFERENCES bill_providers(id),
    amount DECIMAL(15, 2) NOT NULL,
    frequency VARCHAR(20) NOT NULL, -- 'ONCE', 'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'
    frequency_interval INT DEFAULT 1, -- Every N days/weeks/months
    next_execution_date DATE NOT NULL,
    last_execution_date DATE,
    total_executions INT DEFAULT 0,
    max_executions INT, -- NULL for unlimited
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_amount CHECK (amount > 0),
    CONSTRAINT valid_frequency_interval CHECK (frequency_interval > 0)
);

CREATE INDEX idx_scheduled_transactions_user ON scheduled_transactions(user_id);
CREATE INDEX idx_scheduled_transactions_next_date ON scheduled_transactions(next_execution_date);
CREATE INDEX idx_scheduled_transactions_active ON scheduled_transactions(is_active);

-- Password History Table (Prevent password reuse)
CREATE TABLE password_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_password_history_user ON password_history(user_id);
CREATE INDEX idx_password_history_created ON password_history(created_at DESC);

-- IP Access Control Table (Blacklist/Whitelist)
CREATE TABLE ip_access_control (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ip_address INET NOT NULL,
    ip_range_start INET,
    ip_range_end INET,
    type VARCHAR(20) NOT NULL, -- 'BLACKLIST', 'WHITELIST'
    reason TEXT,
    severity VARCHAR(20) DEFAULT 'MEDIUM', -- 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    expires_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(ip_address, type)
);

CREATE INDEX idx_ip_access_control_ip ON ip_access_control(ip_address);
CREATE INDEX idx_ip_access_control_type ON ip_access_control(type);
CREATE INDEX idx_ip_access_control_expires ON ip_access_control(expires_at);

-- Transaction Limits Table (Dynamic user limits)
CREATE TABLE user_transaction_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    limit_type VARCHAR(30) NOT NULL, -- 'DAILY_COUNT', 'DAILY_VOLUME', 'MONTHLY_VOLUME'
    limit_value DECIMAL(15, 2) NOT NULL,
    current_value DECIMAL(15, 2) DEFAULT 0,
    reset_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, limit_type)
);

CREATE INDEX idx_user_transaction_limits_user ON user_transaction_limits(user_id);
CREATE INDEX idx_user_transaction_limits_reset ON user_transaction_limits(reset_at);

-- Fraud Detection Logs Table
CREATE TABLE fraud_detection_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    transaction_id UUID REFERENCES transactions(id),
    detection_type VARCHAR(50) NOT NULL, -- 'VELOCITY', 'AMOUNT', 'LOCATION', 'DEVICE', 'PATTERN'
    risk_score INT NOT NULL, -- 0-100
    details JSONB NOT NULL, -- Detection details
    action_taken VARCHAR(30), -- 'BLOCKED', 'FLAGGED', 'ALLOWED', 'MANUAL_REVIEW'
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_fraud_detection_user ON fraud_detection_logs(user_id);
CREATE INDEX idx_fraud_detection_transaction ON fraud_detection_logs(transaction_id);
CREATE INDEX idx_fraud_detection_type ON fraud_detection_logs(detection_type);
CREATE INDEX idx_fraud_detection_risk ON fraud_detection_logs(risk_score);

-- Comprehensive Audit Log Table
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(50) NOT NULL,
    operation VARCHAR(10) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE', 'SELECT'
    record_id UUID NOT NULL,
    user_id UUID,
    old_data JSONB,
    new_data JSONB,
    changed_fields TEXT[], -- Array of changed field names
    ip_address INET,
    user_agent TEXT,
    session_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_log_table ON audit_log(table_name);
CREATE INDEX idx_audit_log_operation ON audit_log(operation);
CREATE INDEX idx_audit_log_record ON audit_log(record_id);
CREATE INDEX idx_audit_log_user ON audit_log(user_id);
CREATE INDEX idx_audit_log_created ON audit_log(created_at DESC);

-- Partition by month for performance
-- CREATE TABLE audit_log_2025_10 PARTITION OF audit_log
--     FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

-- =====================================================
-- BUSINESS LOGIC FUNCTIONS AND PROCEDURES
-- =====================================================

-- Calculate Transaction Fee with complex logic
CREATE OR REPLACE FUNCTION calculate_transaction_fee(
    p_transaction_type transaction_type,
    p_amount DECIMAL(15, 2),
    p_user_id UUID
) RETURNS DECIMAL(15, 2) AS $$
DECLARE
    v_fee_rate DECIMAL(5, 2);
    v_minimum_fee DECIMAL(15, 2);
    v_maximum_fee DECIMAL(15, 2);
    v_calculated_fee DECIMAL(15, 2);
    v_user_kyc_status kyc_status;
    v_user_role user_role;
    v_monthly_volume DECIMAL(15, 2);
BEGIN
    -- Get user details
    SELECT kyc_status, role INTO v_user_kyc_status, v_user_role
    FROM users WHERE id = p_user_id;

    -- Get monthly volume for volume discounts
    SELECT COALESCE(SUM(amount), 0) INTO v_monthly_volume
    FROM transactions
    WHERE from_user_id = p_user_id
    AND created_at >= DATE_TRUNC('month', CURRENT_DATE)
    AND status = 'COMPLETED';

    -- Base fee rates by transaction type
    v_fee_rate := CASE p_transaction_type
        WHEN 'WITHDRAWAL' THEN 2.0
        WHEN 'TRANSFER' THEN 1.0
        WHEN 'BILL_PAYMENT' THEN 1.5
        WHEN 'DEPOSIT' THEN 0.0
        ELSE 0.5
    END;

    -- Apply KYC discount
    IF v_user_kyc_status = 'APPROVED' THEN
        v_fee_rate := v_fee_rate * 0.9; -- 10% discount for KYC approved
    END IF;

    -- Apply volume discount
    IF v_monthly_volume > 10000000 THEN
        v_fee_rate := v_fee_rate * 0.7; -- 30% discount for high volume
    ELSIF v_monthly_volume > 5000000 THEN
        v_fee_rate := v_fee_rate * 0.85; -- 15% discount
    ELSIF v_monthly_volume > 1000000 THEN
        v_fee_rate := v_fee_rate * 0.95; -- 5% discount
    END IF;

    -- Calculate fee
    v_calculated_fee := p_amount * v_fee_rate / 100;

    -- Apply minimum and maximum limits
    v_minimum_fee := CASE p_transaction_type
        WHEN 'WITHDRAWAL' THEN 50.00
        WHEN 'TRANSFER' THEN 10.00
        WHEN 'BILL_PAYMENT' THEN 25.00
        ELSE 0.00
    END;

    v_maximum_fee := CASE p_transaction_type
        WHEN 'WITHDRAWAL' THEN 5000.00
        WHEN 'TRANSFER' THEN 2000.00
        WHEN 'BILL_PAYMENT' THEN 1000.00
        ELSE 500.00
    END;

    -- Apply limits
    IF v_calculated_fee < v_minimum_fee THEN
        v_calculated_fee := v_minimum_fee;
    ELSIF v_calculated_fee > v_maximum_fee THEN
        v_calculated_fee := v_maximum_fee;
    END IF;

    RETURN v_calculated_fee;
END;
$$ LANGUAGE plpgsql;

-- Calculate Agent Commission with tiered structure
CREATE OR REPLACE FUNCTION calculate_agent_commission(
    p_transaction_amount DECIMAL(15, 2),
    p_agent_id UUID,
    p_transaction_type VARCHAR(20)
) RETURNS DECIMAL(15, 2) AS $$
DECLARE
    v_base_rate DECIMAL(5, 2) := 0.5;
    v_tier_bonus DECIMAL(5, 2) := 0;
    v_volume_bonus DECIMAL(5, 2) := 0;
    v_total_rate DECIMAL(5, 2);
    v_commission DECIMAL(15, 2);
    v_monthly_volume DECIMAL(15, 2);
    v_agent_rating DECIMAL(3, 2);
BEGIN
    -- Get agent's monthly volume
    SELECT COALESCE(SUM(commission_amount), 0) INTO v_monthly_volume
    FROM agent_commissions
    WHERE agent_id = p_agent_id
    AND created_at >= DATE_TRUNC('month', CURRENT_DATE);

    -- Get agent's average rating
    SELECT AVG(rating) INTO v_agent_rating
    FROM agent_reviews
    WHERE agent_id = p_agent_id;

    -- Volume-based tier bonus
    IF v_monthly_volume > 100000 THEN
        v_tier_bonus := 0.3; -- Platinum tier
    ELSIF v_monthly_volume > 50000 THEN
        v_tier_bonus := 0.2; -- Gold tier
    ELSIF v_monthly_volume > 20000 THEN
        v_tier_bonus := 0.1; -- Silver tier
    ELSE
        v_tier_bonus := 0; -- Bronze tier
    END IF;

    -- Rating bonus
    IF v_agent_rating >= 4.5 THEN
        v_volume_bonus := v_volume_bonus + 0.1;
    END IF;

    -- Transaction type bonus
    IF p_transaction_type = 'DEPOSIT' THEN
        v_base_rate := v_base_rate + 0.1; -- Higher rate for deposits
    END IF;

    -- Calculate total rate
    v_total_rate := v_base_rate + v_tier_bonus + v_volume_bonus;

    -- Calculate commission
    v_commission := p_transaction_amount * v_total_rate / 100;

    -- Apply min/max limits
    IF v_commission < 10 THEN
        v_commission := 10; -- Minimum commission
    ELSIF v_commission > 5000 THEN
        v_commission := 5000; -- Maximum commission
    END IF;

    RETURN v_commission;
END;
$$ LANGUAGE plpgsql;

-- Check Transaction Velocity for Fraud Detection
CREATE OR REPLACE FUNCTION check_transaction_velocity(
    p_user_id UUID,
    p_amount DECIMAL(15, 2)
) RETURNS BOOLEAN AS $$
DECLARE
    v_count_1min INT;
    v_count_1hour INT;
    v_count_1day INT;
    v_sum_1day DECIMAL(15, 2);
    v_risk_score INT := 0;
BEGIN
    -- Count transactions in last minute
    SELECT COUNT(*) INTO v_count_1min
    FROM transactions
    WHERE from_user_id = p_user_id
    AND created_at >= CURRENT_TIMESTAMP - INTERVAL '1 minute';

    -- Count transactions in last hour
    SELECT COUNT(*) INTO v_count_1hour
    FROM transactions
    WHERE from_user_id = p_user_id
    AND created_at >= CURRENT_TIMESTAMP - INTERVAL '1 hour';

    -- Count and sum transactions in last day
    SELECT COUNT(*), COALESCE(SUM(amount), 0)
    INTO v_count_1day, v_sum_1day
    FROM transactions
    WHERE from_user_id = p_user_id
    AND created_at >= CURRENT_TIMESTAMP - INTERVAL '1 day';

    -- Check velocity limits
    IF v_count_1min > 3 THEN
        v_risk_score := v_risk_score + 50;
    END IF;

    IF v_count_1hour > 20 THEN
        v_risk_score := v_risk_score + 30;
    END IF;

    IF v_count_1day > 50 THEN
        v_risk_score := v_risk_score + 20;
    END IF;

    IF v_sum_1day + p_amount > 10000000 THEN
        v_risk_score := v_risk_score + 40;
    END IF;

    -- Log if suspicious
    IF v_risk_score > 50 THEN
        INSERT INTO fraud_detection_logs (
            user_id, detection_type, risk_score, details, action_taken
        ) VALUES (
            p_user_id, 'VELOCITY', v_risk_score,
            jsonb_build_object(
                'count_1min', v_count_1min,
                'count_1hour', v_count_1hour,
                'count_1day', v_count_1day,
                'sum_1day', v_sum_1day,
                'current_amount', p_amount
            ),
            CASE WHEN v_risk_score > 80 THEN 'BLOCKED' ELSE 'FLAGGED' END
        );

        RETURN FALSE; -- Transaction should be blocked or flagged
    END IF;

    RETURN TRUE; -- Transaction is safe
END;
$$ LANGUAGE plpgsql;

-- Process Matured Investments (to be called daily via cron)
CREATE OR REPLACE FUNCTION process_matured_investments()
RETURNS TABLE(processed_count INT, total_amount DECIMAL) AS $$
DECLARE
    v_investment RECORD;
    v_count INT := 0;
    v_total DECIMAL(15, 2) := 0;
    v_transaction_id UUID;
BEGIN
    FOR v_investment IN
        SELECT * FROM investments
        WHERE status = 'ACTIVE'
        AND end_date <= CURRENT_DATE
    LOOP
        -- Create credit transaction
        v_transaction_id := uuid_generate_v4();

        INSERT INTO transactions (
            id, type, to_user_id, amount, fee, net_amount, status, description
        ) VALUES (
            v_transaction_id,
            'INVESTMENT',
            v_investment.user_id,
            v_investment.expected_return,
            0,
            v_investment.expected_return,
            'COMPLETED',
            'Investment maturity payout - ' || v_investment.category
        );

        -- Update investment status
        UPDATE investments
        SET status = 'MATURED',
            actual_return = expected_return,
            withdrawal_transaction_id = v_transaction_id,
            withdrawn_at = CURRENT_TIMESTAMP
        WHERE id = v_investment.id;

        -- Update wallet balance
        UPDATE wallets
        SET balance = balance + v_investment.expected_return,
            last_transaction_at = CURRENT_TIMESTAMP
        WHERE user_id = v_investment.user_id;

        -- Create notification
        INSERT INTO notifications (
            user_id, type, title, message, data
        ) VALUES (
            v_investment.user_id,
            'INVESTMENT',
            'Investment Matured!',
            'Your ' || v_investment.category || ' investment of ' ||
            v_investment.amount || ' has matured. ' ||
            v_investment.expected_return || ' has been credited to your wallet.',
            jsonb_build_object(
                'investment_id', v_investment.id,
                'amount', v_investment.amount,
                'return', v_investment.expected_return
            )
        );

        v_count := v_count + 1;
        v_total := v_total + v_investment.expected_return;
    END LOOP;

    RETURN QUERY SELECT v_count, v_total;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- CRITICAL TRIGGERS
-- =====================================================

-- Comprehensive Audit Trigger
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    v_old_data JSONB;
    v_new_data JSONB;
    v_changed_fields TEXT[];
BEGIN
    -- Prepare old and new data
    IF TG_OP = 'DELETE' THEN
        v_old_data := to_jsonb(OLD);
        v_new_data := NULL;
    ELSIF TG_OP = 'UPDATE' THEN
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);
        -- Calculate changed fields
        SELECT ARRAY_AGG(key) INTO v_changed_fields
        FROM jsonb_each(v_old_data) o
        FULL OUTER JOIN jsonb_each(v_new_data) n USING (key)
        WHERE o.value IS DISTINCT FROM n.value;
    ELSE -- INSERT
        v_old_data := NULL;
        v_new_data := to_jsonb(NEW);
    END IF;

    -- Insert audit log
    INSERT INTO audit_log (
        table_name, operation, record_id, user_id,
        old_data, new_data, changed_fields, ip_address
    ) VALUES (
        TG_TABLE_NAME,
        TG_OP,
        CASE
            WHEN TG_OP = 'DELETE' THEN OLD.id
            ELSE NEW.id
        END,
        current_setting('app.current_user_id', true)::UUID,
        v_old_data,
        v_new_data,
        v_changed_fields,
        current_setting('app.client_ip', true)::INET
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Apply audit trigger to critical tables
CREATE TRIGGER audit_users AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
CREATE TRIGGER audit_wallets AFTER INSERT OR UPDATE OR DELETE ON wallets
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
CREATE TRIGGER audit_transactions AFTER INSERT OR UPDATE OR DELETE ON transactions
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
CREATE TRIGGER audit_investments AFTER INSERT OR UPDATE OR DELETE ON investments
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
CREATE TRIGGER audit_agents AFTER INSERT OR UPDATE OR DELETE ON agents
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- Wallet Balance Update Trigger (Atomic transaction processing)
CREATE OR REPLACE FUNCTION update_wallet_balance()
RETURNS TRIGGER AS $$
DECLARE
    v_sender_balance DECIMAL(15, 2);
    v_receiver_balance DECIMAL(15, 2);
BEGIN
    -- Only process when transaction becomes completed
    IF NEW.status = 'COMPLETED' AND OLD.status != 'COMPLETED' THEN

        -- Start atomic transaction
        IF NEW.from_user_id IS NOT NULL THEN
            -- Lock sender wallet and check balance
            SELECT balance INTO v_sender_balance
            FROM wallets
            WHERE user_id = NEW.from_user_id
            FOR UPDATE;

            -- Verify sufficient balance
            IF v_sender_balance < (NEW.amount + NEW.fee) THEN
                RAISE EXCEPTION 'Insufficient balance for transaction';
            END IF;

            -- Debit sender
            UPDATE wallets
            SET balance = balance - (NEW.amount + NEW.fee),
                last_transaction_at = CURRENT_TIMESTAMP
            WHERE user_id = NEW.from_user_id;
        END IF;

        -- Credit receiver
        IF NEW.to_user_id IS NOT NULL THEN
            UPDATE wallets
            SET balance = balance + NEW.amount,
                last_transaction_at = CURRENT_TIMESTAMP
            WHERE user_id = NEW.to_user_id;
        END IF;

        -- Update transaction limits
        UPDATE user_transaction_limits
        SET current_value = current_value + NEW.amount,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = NEW.from_user_id
        AND limit_type = 'DAILY_VOLUME'
        AND reset_at > CURRENT_TIMESTAMP;

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_wallet_on_transaction
AFTER UPDATE ON transactions
FOR EACH ROW
EXECUTE FUNCTION update_wallet_balance();

-- Password History Trigger
CREATE OR REPLACE FUNCTION save_password_history()
RETURNS TRIGGER AS $$
DECLARE
    v_password_reuse_count INT := 5; -- Last 5 passwords cannot be reused
BEGIN
    IF NEW.password_hash IS DISTINCT FROM OLD.password_hash THEN
        -- Check if password was used before
        IF EXISTS (
            SELECT 1 FROM password_history
            WHERE user_id = NEW.id
            AND password_hash = NEW.password_hash
            ORDER BY created_at DESC
            LIMIT v_password_reuse_count
        ) THEN
            RAISE EXCEPTION 'Password has been used recently. Please choose a different password.';
        END IF;

        -- Save to history
        INSERT INTO password_history (user_id, password_hash)
        VALUES (NEW.id, NEW.password_hash);

        -- Clean old history (keep only last 10)
        DELETE FROM password_history
        WHERE user_id = NEW.id
        AND id NOT IN (
            SELECT id FROM password_history
            WHERE user_id = NEW.id
            ORDER BY created_at DESC
            LIMIT 10
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_password_reuse
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION save_password_history();

-- Update transaction limits trigger
CREATE OR REPLACE FUNCTION reset_transaction_limits()
RETURNS void AS $$
BEGIN
    -- Reset daily limits
    UPDATE user_transaction_limits
    SET current_value = 0,
        reset_at = CURRENT_TIMESTAMP + INTERVAL '1 day'
    WHERE limit_type LIKE 'DAILY_%'
    AND reset_at <= CURRENT_TIMESTAMP;

    -- Reset monthly limits
    UPDATE user_transaction_limits
    SET current_value = 0,
        reset_at = DATE_TRUNC('month', CURRENT_TIMESTAMP) + INTERVAL '1 month'
    WHERE limit_type LIKE 'MONTHLY_%'
    AND reset_at <= CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- MATERIALIZED VIEWS FOR PERFORMANCE
-- =====================================================

-- User Dashboard View
CREATE MATERIALIZED VIEW vw_user_dashboard AS
SELECT
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    u.phone,
    u.kyc_status,
    u.is_verified,
    w.balance as wallet_balance,
    w.currency,
    COUNT(DISTINCT t.id) as total_transactions,
    COUNT(DISTINCT CASE WHEN DATE(t.created_at) = CURRENT_DATE THEN t.id END) as transactions_today,
    COUNT(DISTINCT i.id) as active_investments,
    COALESCE(SUM(i.amount), 0) as total_invested,
    COALESCE(SUM(i.expected_return), 0) as expected_returns
FROM users u
LEFT JOIN wallets w ON u.id = w.user_id
LEFT JOIN transactions t ON (u.id = t.from_user_id OR u.id = t.to_user_id)
    AND t.status = 'COMPLETED'
LEFT JOIN investments i ON u.id = i.user_id AND i.status = 'ACTIVE'
WHERE u.role = 'USER'
GROUP BY u.id, u.first_name, u.last_name, u.email, u.phone,
         u.kyc_status, u.is_verified, w.balance, w.currency;

CREATE UNIQUE INDEX ON vw_user_dashboard(id);
REFRESH MATERIALIZED VIEW CONCURRENTLY vw_user_dashboard;

-- Agent Performance View
CREATE MATERIALIZED VIEW vw_agent_performance AS
SELECT
    a.id,
    a.user_id,
    u.first_name || ' ' || u.last_name as agent_name,
    a.wallet_balance,
    a.active_status,
    a.total_commission_earned,
    a.total_transactions_processed,
    COUNT(DISTINCT DATE(ac.created_at)) as days_active,
    COUNT(DISTINCT ac.transaction_id) FILTER (WHERE DATE(ac.created_at) = CURRENT_DATE) as transactions_today,
    COALESCE(SUM(ac.commission_amount) FILTER (WHERE DATE(ac.created_at) = CURRENT_DATE), 0) as commission_today,
    COALESCE(AVG(ar.rating), 0) as average_rating,
    COUNT(DISTINCT ar.id) as total_reviews,
    a.location_lat,
    a.location_lng,
    a.location_address
FROM agents a
JOIN users u ON a.user_id = u.id
LEFT JOIN agent_commissions ac ON a.id = ac.agent_id
LEFT JOIN agent_reviews ar ON a.id = ar.agent_id
GROUP BY a.id, a.user_id, u.first_name, u.last_name, a.wallet_balance,
         a.active_status, a.total_commission_earned, a.total_transactions_processed,
         a.location_lat, a.location_lng, a.location_address;

CREATE UNIQUE INDEX ON vw_agent_performance(id);
REFRESH MATERIALIZED VIEW CONCURRENTLY vw_agent_performance;

-- =====================================================
-- SEED DATA FOR NEW TABLES
-- =====================================================

-- Insert notification templates
INSERT INTO notification_templates (template_code, channel, subject, body_template, variables) VALUES
('OTP_SMS', 'SMS', NULL, 'Your TCC verification code is {{otp}}. Valid for 5 minutes.', '["otp"]'::jsonb),
('WELCOME_EMAIL', 'EMAIL', 'Welcome to TCC!', 'Hello {{name}}, Welcome to TCC. Your account has been created successfully.', '["name"]'::jsonb),
('TRANSFER_SUCCESS', 'PUSH', NULL, 'Transfer of {{amount}} to {{recipient}} successful', '["amount", "recipient"]'::jsonb),
('KYC_APPROVED', 'EMAIL', 'KYC Verification Approved', 'Congratulations {{name}}! Your KYC has been approved.', '["name"]'::jsonb),
('INVESTMENT_MATURED', 'PUSH', NULL, 'Your {{category}} investment of {{amount}} has matured!', '["category", "amount"]'::jsonb);

-- Update triggers list for new tables
CREATE TRIGGER update_file_uploads_updated_at BEFORE UPDATE ON file_uploads FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_notification_templates_updated_at BEFORE UPDATE ON notification_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_devices_updated_at BEFORE UPDATE ON user_devices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_scheduled_transactions_updated_at BEFORE UPDATE ON scheduled_transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_transaction_limits_updated_at BEFORE UPDATE ON user_transaction_limits FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- END OF SCHEMA
-- =====================================================
