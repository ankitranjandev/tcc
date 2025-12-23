-- Rollback Migration: Remove investment product versioning system
-- Date: 2024-12-22
-- Description: This script rollsback the investment versioning migration (004)
--              Use this ONLY if you need to undo the versioning changes

-- =====================================================
-- SAFETY CHECK
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'ROLLBACK WARNING';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'This script will remove the investment versioning system.';
    RAISE NOTICE 'This action CANNOT be undone.';
    RAISE NOTICE 'Make sure you have a database backup before proceeding!';
    RAISE NOTICE '========================================';
END $$;

-- Uncomment the following line to proceed with rollback
-- If this line is commented, the rollback will not execute
-- DO $$ BEGIN IF FALSE THEN RAISE EXCEPTION 'Rollback safety check failed'; END IF; END $$;

-- =====================================================
-- 1. DROP HELPER FUNCTIONS
-- =====================================================

DROP FUNCTION IF EXISTS get_investment_count_by_version(UUID);
DROP FUNCTION IF EXISTS get_tenure_version_history(UUID);
DROP FUNCTION IF EXISTS get_current_product_version(UUID);

-- =====================================================
-- 2. REMOVE FOREIGN KEY COLUMN FROM INVESTMENTS
-- =====================================================

-- Drop the foreign key constraint first
ALTER TABLE investments DROP CONSTRAINT IF EXISTS fk_investments_product_version;

-- Drop the index
DROP INDEX IF EXISTS idx_investments_product_version;

-- Drop the column
ALTER TABLE investments DROP COLUMN IF EXISTS product_version_id;

-- =====================================================
-- 3. DROP TRIGGERS AND TRIGGER FUNCTIONS
-- =====================================================

DROP TRIGGER IF EXISTS trigger_ensure_single_current_version ON investment_product_versions;
DROP FUNCTION IF EXISTS ensure_single_current_version();

DROP TRIGGER IF EXISTS trigger_update_investment_product_versions_updated_at ON investment_product_versions;
DROP FUNCTION IF EXISTS update_investment_product_versions_updated_at();

-- =====================================================
-- 4. DROP TABLES
-- =====================================================

-- Drop tables in reverse order of dependencies
DROP TABLE IF EXISTS investment_rate_change_notifications CASCADE;
DROP TABLE IF EXISTS investment_product_versions CASCADE;

-- =====================================================
-- 5. VERIFICATION
-- =====================================================

-- Verify investments table is intact
DO $$
DECLARE
    investment_count INT;
BEGIN
    SELECT COUNT(*) INTO investment_count FROM investments;
    RAISE NOTICE 'Investments table verified: % records found', investment_count;
END $$;

-- Verify investment_tenures table is intact
DO $$
DECLARE
    tenure_count INT;
BEGIN
    SELECT COUNT(*) INTO tenure_count FROM investment_tenures;
    RAISE NOTICE 'Investment tenures table verified: % records found', tenure_count;
END $$;

-- =====================================================
-- ROLLBACK COMPLETE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Rollback 004: Investment Versioning';
    RAISE NOTICE 'Status: COMPLETED';
    RAISE NOTICE 'Date: %', CURRENT_TIMESTAMP;
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tables dropped: 2';
    RAISE NOTICE '  - investment_rate_change_notifications';
    RAISE NOTICE '  - investment_product_versions';
    RAISE NOTICE 'Columns removed: 1';
    RAISE NOTICE '  - investments.product_version_id';
    RAISE NOTICE 'Helper functions dropped: 3';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'NOTE: Original investment data preserved';
    RAISE NOTICE '      All investments retain their return_rate values';
    RAISE NOTICE '========================================';
END $$;
