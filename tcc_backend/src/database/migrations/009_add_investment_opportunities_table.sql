-- Migration: Add Investment Opportunities Table
-- Description: Creates investment_opportunities table and related structures for admin-created investment products
-- Author: Claude Code
-- Date: 2025-12-25

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- Investment Categories Table (if not exists)
-- ============================================
CREATE TABLE IF NOT EXISTS investment_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    image_url TEXT,
    metadata JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    display_order INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add indexes if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_investment_categories_active') THEN
        CREATE INDEX idx_investment_categories_active ON investment_categories(is_active);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_investment_categories_display_order') THEN
        CREATE INDEX idx_investment_categories_display_order ON investment_categories(display_order);
    END IF;
END $$;

-- ============================================
-- Investment Opportunities Table
-- ============================================
CREATE TABLE IF NOT EXISTS investment_opportunities (
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

-- Add comment to table
COMMENT ON TABLE investment_opportunities IS 'Admin-created investment products that users can invest in';

-- ============================================
-- Indexes for Performance
-- ============================================
CREATE INDEX IF NOT EXISTS idx_inv_opp_category ON investment_opportunities(category_id);
CREATE INDEX IF NOT EXISTS idx_inv_opp_active ON investment_opportunities(is_active);
CREATE INDEX IF NOT EXISTS idx_inv_opp_display_order ON investment_opportunities(display_order);
CREATE INDEX IF NOT EXISTS idx_inv_opp_category_active ON investment_opportunities(category_id, is_active);
CREATE INDEX IF NOT EXISTS idx_inv_opp_metadata ON investment_opportunities USING GIN (metadata);

-- ============================================
-- Trigger for Updated At
-- ============================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_investment_opportunities_updated_at') THEN
        CREATE TRIGGER update_investment_opportunities_updated_at
        BEFORE UPDATE ON investment_opportunities
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- ============================================
-- Seed Default Categories (if empty)
-- ============================================
INSERT INTO investment_categories (name, description, is_active, display_order)
VALUES
    ('Agriculture', 'Invest in agricultural projects and farming initiatives', TRUE, 1),
    ('Education', 'Invest in educational institutions and programs', TRUE, 2),
    ('Minerals', 'Invest in mineral extraction and trading', TRUE, 3),
    ('Real Estate', 'Invest in real estate development projects', TRUE, 4),
    ('Technology', 'Invest in technology startups and innovation', TRUE, 5)
ON CONFLICT DO NOTHING;

-- ============================================
-- Sample Investment Opportunities (Optional)
-- ============================================
-- Add some sample opportunities for testing
DO $$
DECLARE
    v_agriculture_cat_id UUID;
    v_education_cat_id UUID;
    v_minerals_cat_id UUID;
BEGIN
    -- Get category IDs
    SELECT id INTO v_agriculture_cat_id FROM investment_categories WHERE name = 'Agriculture' LIMIT 1;
    SELECT id INTO v_education_cat_id FROM investment_categories WHERE name = 'Education' LIMIT 1;
    SELECT id INTO v_minerals_cat_id FROM investment_categories WHERE name = 'Minerals' LIMIT 1;

    -- Add sample opportunities if categories exist and table is empty
    IF v_agriculture_cat_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM investment_opportunities LIMIT 1) THEN
        -- Agriculture opportunities
        INSERT INTO investment_opportunities (
            category_id, title, description, min_investment, max_investment,
            tenure_months, return_rate, total_units, available_units, is_active, display_order
        ) VALUES
        (v_agriculture_cat_id, 'Rice Farming Project', 'Invest in sustainable rice farming with guaranteed returns',
         100.00, 50000.00, 12, 15.00, 100, 100, TRUE, 1),
        (v_agriculture_cat_id, 'Cassava Production', 'Support cassava farming and processing initiatives',
         50.00, 30000.00, 6, 10.00, 150, 150, TRUE, 2);
    END IF;

    IF v_education_cat_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM investment_opportunities WHERE category_id = v_education_cat_id) THEN
        -- Education opportunities
        INSERT INTO investment_opportunities (
            category_id, title, description, min_investment, max_investment,
            tenure_months, return_rate, total_units, available_units, is_active, display_order
        ) VALUES
        (v_education_cat_id, 'School Infrastructure', 'Fund school building and facility improvements',
         500.00, 100000.00, 24, 12.00, 50, 50, TRUE, 1),
        (v_education_cat_id, 'Student Dormitory', 'Invest in student housing development',
         1000.00, 150000.00, 36, 14.00, 30, 30, TRUE, 2);
    END IF;

    IF v_minerals_cat_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM investment_opportunities WHERE category_id = v_minerals_cat_id) THEN
        -- Minerals opportunities
        INSERT INTO investment_opportunities (
            category_id, title, description, min_investment, max_investment,
            tenure_months, return_rate, total_units, available_units, is_active, display_order
        ) VALUES
        (v_minerals_cat_id, 'Gold Mining Project', 'Invest in gold extraction and trading',
         500.00, 200000.00, 18, 18.00, 75, 75, TRUE, 1),
        (v_minerals_cat_id, 'Diamond Trading', 'Participate in diamond mining and export',
         1000.00, 250000.00, 24, 20.00, 40, 40, TRUE, 2);
    END IF;
END $$;

-- ============================================
-- Migration Complete
-- ============================================
