-- Migration: Add Currency Investment Feature
-- Description: Allows users to invest TCC coins in foreign currencies (EUR, GBP, JPY, AUD, CAD, CHF, CNY)
-- Author: Claude Code
-- Date: 2024-12-25

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- Currency Investment Status Type
-- ============================================
DO $$ BEGIN
    CREATE TYPE currency_investment_status AS ENUM ('ACTIVE', 'SOLD');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ============================================
-- Currency Investments Table
-- ============================================
CREATE TABLE IF NOT EXISTS currency_investments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    currency_code VARCHAR(3) NOT NULL,
    amount_invested DECIMAL(15, 2) NOT NULL,          -- TCC amount invested
    currency_amount DECIMAL(15, 6) NOT NULL,          -- Foreign currency purchased
    purchase_rate DECIMAL(15, 6) NOT NULL,            -- Rate at time of purchase (1 TCC = X currency)
    status VARCHAR(20) DEFAULT 'ACTIVE',              -- ACTIVE, SOLD
    sold_at TIMESTAMP WITH TIME ZONE,
    sold_rate DECIMAL(15, 6),                         -- Rate at time of sale
    sold_amount_tcc DECIMAL(15, 2),                   -- TCC received after sale
    profit_loss DECIMAL(15, 2),                       -- Calculated profit/loss
    transaction_id UUID REFERENCES transactions(id),   -- Buy transaction
    sell_transaction_id UUID REFERENCES transactions(id), -- Sell transaction
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT positive_investment CHECK (amount_invested > 0),
    CONSTRAINT positive_currency_amount CHECK (currency_amount > 0),
    CONSTRAINT valid_currency_code CHECK (currency_code IN ('EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'CHF', 'CNY'))
);

-- Add comment to table
COMMENT ON TABLE currency_investments IS 'Stores user currency investment holdings for the currency investment feature';

-- ============================================
-- Currency Investment Limits Table
-- ============================================
CREATE TABLE IF NOT EXISTS currency_investment_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    currency_code VARCHAR(3) NOT NULL UNIQUE,
    min_investment DECIMAL(15, 2) NOT NULL DEFAULT 10.00,
    max_investment DECIMAL(15, 2) NOT NULL DEFAULT 100000.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT valid_limit_currency CHECK (currency_code IN ('EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'CHF', 'CNY')),
    CONSTRAINT positive_limits CHECK (min_investment > 0 AND max_investment > min_investment)
);

-- Add comment to table
COMMENT ON TABLE currency_investment_limits IS 'Configuration table for min/max investment limits per currency';

-- ============================================
-- Indexes for Performance
-- ============================================
CREATE INDEX IF NOT EXISTS idx_currency_investments_user ON currency_investments(user_id);
CREATE INDEX IF NOT EXISTS idx_currency_investments_status ON currency_investments(status);
CREATE INDEX IF NOT EXISTS idx_currency_investments_currency ON currency_investments(currency_code);
CREATE INDEX IF NOT EXISTS idx_currency_investments_created ON currency_investments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_currency_investments_user_status ON currency_investments(user_id, status);

-- ============================================
-- Seed Default Investment Limits
-- ============================================
INSERT INTO currency_investment_limits (currency_code, min_investment, max_investment, is_active) VALUES
    ('EUR', 10.00, 100000.00, TRUE),
    ('GBP', 10.00, 100000.00, TRUE),
    ('JPY', 10.00, 100000.00, TRUE),
    ('AUD', 10.00, 100000.00, TRUE),
    ('CAD', 10.00, 100000.00, TRUE),
    ('CHF', 10.00, 100000.00, TRUE),
    ('CNY', 10.00, 100000.00, TRUE)
ON CONFLICT (currency_code) DO NOTHING;

-- ============================================
-- Trigger for Updated At
-- ============================================
CREATE OR REPLACE FUNCTION update_currency_investment_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_currency_investment_updated_at ON currency_investments;
CREATE TRIGGER trigger_currency_investment_updated_at
    BEFORE UPDATE ON currency_investments
    FOR EACH ROW
    EXECUTE FUNCTION update_currency_investment_updated_at();

DROP TRIGGER IF EXISTS trigger_currency_investment_limits_updated_at ON currency_investment_limits;
CREATE TRIGGER trigger_currency_investment_limits_updated_at
    BEFORE UPDATE ON currency_investment_limits
    FOR EACH ROW
    EXECUTE FUNCTION update_currency_investment_updated_at();

-- ============================================
-- Summary View for Currency Holdings
-- ============================================
CREATE OR REPLACE VIEW currency_investment_summary AS
SELECT
    user_id,
    currency_code,
    COUNT(*) FILTER (WHERE status = 'ACTIVE') as active_count,
    SUM(amount_invested) FILTER (WHERE status = 'ACTIVE') as total_invested,
    SUM(currency_amount) FILTER (WHERE status = 'ACTIVE') as total_currency_held,
    AVG(purchase_rate) FILTER (WHERE status = 'ACTIVE') as avg_purchase_rate,
    COUNT(*) FILTER (WHERE status = 'SOLD') as sold_count,
    SUM(profit_loss) FILTER (WHERE status = 'SOLD') as realized_profit_loss
FROM currency_investments
GROUP BY user_id, currency_code;

COMMENT ON VIEW currency_investment_summary IS 'Aggregated summary of currency investments per user and currency';

-- ============================================
-- Migration Complete
-- ============================================