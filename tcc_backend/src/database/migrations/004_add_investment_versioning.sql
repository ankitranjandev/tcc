-- Migration: Add investment product versioning system
-- Date: 2024-12-22
-- Description: This migration adds formal versioning for investment products to track rate changes,
--              preserve existing investment rates, and enable admin management with notifications.

-- =====================================================
-- 1. CREATE NEW TABLES
-- =====================================================

-- Investment Product Versions Table
-- Tracks complete version history of investment product rates
CREATE TABLE IF NOT EXISTS investment_product_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenure_id UUID NOT NULL,
    version_number INT NOT NULL,
    return_percentage DECIMAL(5, 2) NOT NULL,
    effective_from TIMESTAMP WITH TIME ZONE NOT NULL,
    effective_until TIMESTAMP WITH TIME ZONE,
    is_current BOOLEAN DEFAULT FALSE,
    change_reason TEXT,
    changed_by UUID,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT positive_version CHECK (version_number > 0),
    CONSTRAINT positive_return CHECK (return_percentage >= 0),
    CONSTRAINT valid_effective_dates CHECK (effective_until IS NULL OR effective_until > effective_from),
    UNIQUE(tenure_id, version_number),

    -- Foreign key constraints
    CONSTRAINT fk_product_versions_tenure
        FOREIGN KEY (tenure_id)
        REFERENCES investment_tenures(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_product_versions_changed_by
        FOREIGN KEY (changed_by)
        REFERENCES users(id)
        ON DELETE SET NULL
);

-- Create indexes for better query performance
CREATE INDEX idx_product_versions_tenure ON investment_product_versions(tenure_id);
CREATE INDEX idx_product_versions_current ON investment_product_versions(is_current) WHERE is_current = TRUE;
CREATE INDEX idx_product_versions_effective ON investment_product_versions(effective_from, effective_until);
CREATE INDEX idx_product_versions_changed_by ON investment_product_versions(changed_by);

-- Add comments for documentation
COMMENT ON TABLE investment_product_versions IS 'Complete version history of investment product rates';
COMMENT ON COLUMN investment_product_versions.tenure_id IS 'Reference to the investment tenure';
COMMENT ON COLUMN investment_product_versions.version_number IS 'Sequential version number for this tenure';
COMMENT ON COLUMN investment_product_versions.return_percentage IS 'Interest rate for this version';
COMMENT ON COLUMN investment_product_versions.effective_from IS 'When this version became effective';
COMMENT ON COLUMN investment_product_versions.effective_until IS 'When this version was superseded (NULL if current)';
COMMENT ON COLUMN investment_product_versions.is_current IS 'Only one version per tenure_id should have is_current = TRUE';
COMMENT ON COLUMN investment_product_versions.change_reason IS 'Admin explanation for rate change';
COMMENT ON COLUMN investment_product_versions.changed_by IS 'Admin user who made the change';
COMMENT ON COLUMN investment_product_versions.metadata IS 'Additional version metadata in JSON format';

-- Investment Rate Change Notifications Table
-- Tracks which users have been notified about rate changes
CREATE TABLE IF NOT EXISTS investment_rate_change_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    version_id UUID NOT NULL,
    user_id UUID,
    notification_id UUID,
    category investment_category NOT NULL,
    tenure_months INT NOT NULL,
    old_rate DECIMAL(5, 2) NOT NULL,
    new_rate DECIMAL(5, 2) NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Foreign key constraints
    CONSTRAINT fk_rate_notifications_version
        FOREIGN KEY (version_id)
        REFERENCES investment_product_versions(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_rate_notifications_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_rate_notifications_notification
        FOREIGN KEY (notification_id)
        REFERENCES notifications(id)
        ON DELETE SET NULL
);

-- Create indexes for better query performance
CREATE INDEX idx_rate_notifications_version ON investment_rate_change_notifications(version_id);
CREATE INDEX idx_rate_notifications_user ON investment_rate_change_notifications(user_id);
CREATE INDEX idx_rate_notifications_category ON investment_rate_change_notifications(category);
CREATE INDEX idx_rate_notifications_sent ON investment_rate_change_notifications(sent_at DESC);

-- Add comments for documentation
COMMENT ON TABLE investment_rate_change_notifications IS 'Tracks rate change notifications sent to users';
COMMENT ON COLUMN investment_rate_change_notifications.version_id IS 'Product version that triggered notification';
COMMENT ON COLUMN investment_rate_change_notifications.user_id IS 'User who received the notification';
COMMENT ON COLUMN investment_rate_change_notifications.notification_id IS 'Reference to notification record';
COMMENT ON COLUMN investment_rate_change_notifications.category IS 'Investment category (AGRICULTURE, EDUCATION, MINERALS)';
COMMENT ON COLUMN investment_rate_change_notifications.tenure_months IS 'Tenure duration in months';
COMMENT ON COLUMN investment_rate_change_notifications.old_rate IS 'Previous interest rate';
COMMENT ON COLUMN investment_rate_change_notifications.new_rate IS 'New interest rate';
COMMENT ON COLUMN investment_rate_change_notifications.sent_at IS 'When notification was sent';
COMMENT ON COLUMN investment_rate_change_notifications.read_at IS 'When user read the notification';

-- =====================================================
-- 2. MODIFY EXISTING TABLES
-- =====================================================

-- Add product_version_id column to investments table
ALTER TABLE investments
ADD COLUMN IF NOT EXISTS product_version_id UUID;

-- Add foreign key constraint
ALTER TABLE investments
ADD CONSTRAINT fk_investments_product_version
    FOREIGN KEY (product_version_id)
    REFERENCES investment_product_versions(id)
    ON DELETE SET NULL;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_investments_product_version ON investments(product_version_id);

-- Add comment for documentation
COMMENT ON COLUMN investments.product_version_id IS 'Links investment to the specific product version at creation time';

-- =====================================================
-- 3. CREATE TRIGGERS
-- =====================================================

-- Add trigger to update updated_at timestamp for investment_product_versions
CREATE OR REPLACE FUNCTION update_investment_product_versions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_investment_product_versions_updated_at
    BEFORE UPDATE ON investment_product_versions
    FOR EACH ROW
    EXECUTE FUNCTION update_investment_product_versions_updated_at();

-- Function to ensure only one current version per tenure
CREATE OR REPLACE FUNCTION ensure_single_current_version()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_current = TRUE THEN
        -- Set all other versions for this tenure to non-current
        UPDATE investment_product_versions
        SET is_current = FALSE, updated_at = CURRENT_TIMESTAMP
        WHERE tenure_id = NEW.tenure_id
        AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ensure_single_current_version
    BEFORE INSERT OR UPDATE ON investment_product_versions
    FOR EACH ROW
    WHEN (NEW.is_current = TRUE)
    EXECUTE FUNCTION ensure_single_current_version();

-- =====================================================
-- 4. DATA MIGRATION
-- =====================================================

-- Create initial version 1 for all existing tenures
-- This preserves the current state as version 1
INSERT INTO investment_product_versions (
    tenure_id,
    version_number,
    return_percentage,
    effective_from,
    effective_until,
    is_current,
    change_reason,
    metadata
)
SELECT
    id as tenure_id,
    1 as version_number,
    return_percentage,
    COALESCE(created_at, CURRENT_TIMESTAMP) as effective_from,
    NULL as effective_until,
    TRUE as is_current,
    'Initial version from migration' as change_reason,
    jsonb_build_object(
        'migrated', true,
        'migration_date', CURRENT_TIMESTAMP,
        'original_rate', return_percentage
    ) as metadata
FROM investment_tenures
WHERE is_active = TRUE
ON CONFLICT (tenure_id, version_number) DO NOTHING;

-- Link all existing investments to their product versions
-- This ensures backward compatibility and data integrity
UPDATE investments i
SET product_version_id = ipv.id
FROM investment_tenures it
JOIN investment_product_versions ipv ON it.id = ipv.tenure_id AND ipv.version_number = 1
WHERE i.tenure_id = it.id
AND i.product_version_id IS NULL;

-- =====================================================
-- 5. HELPER FUNCTIONS
-- =====================================================

-- Function to get current version for a tenure
CREATE OR REPLACE FUNCTION get_current_product_version(p_tenure_id UUID)
RETURNS TABLE (
    id UUID,
    version_number INT,
    return_percentage DECIMAL(5, 2),
    effective_from TIMESTAMP WITH TIME ZONE,
    change_reason TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ipv.id,
        ipv.version_number,
        ipv.return_percentage,
        ipv.effective_from,
        ipv.change_reason
    FROM investment_product_versions ipv
    WHERE ipv.tenure_id = p_tenure_id
    AND ipv.is_current = TRUE
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Function to get version history for a tenure
CREATE OR REPLACE FUNCTION get_tenure_version_history(p_tenure_id UUID)
RETURNS TABLE (
    id UUID,
    version_number INT,
    return_percentage DECIMAL(5, 2),
    effective_from TIMESTAMP WITH TIME ZONE,
    effective_until TIMESTAMP WITH TIME ZONE,
    is_current BOOLEAN,
    change_reason TEXT,
    changed_by UUID,
    admin_name VARCHAR(255)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ipv.id,
        ipv.version_number,
        ipv.return_percentage,
        ipv.effective_from,
        ipv.effective_until,
        ipv.is_current,
        ipv.change_reason,
        ipv.changed_by,
        COALESCE(u.full_name, 'System') as admin_name
    FROM investment_product_versions ipv
    LEFT JOIN users u ON ipv.changed_by = u.id
    WHERE ipv.tenure_id = p_tenure_id
    ORDER BY ipv.version_number DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get investment count per version
CREATE OR REPLACE FUNCTION get_investment_count_by_version(p_tenure_id UUID)
RETURNS TABLE (
    version_id UUID,
    version_number INT,
    return_percentage DECIMAL(5, 2),
    investment_count BIGINT,
    total_amount DECIMAL(15, 2),
    active_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ipv.id as version_id,
        ipv.version_number,
        ipv.return_percentage,
        COUNT(i.id) as investment_count,
        COALESCE(SUM(i.amount), 0) as total_amount,
        COUNT(CASE WHEN i.status = 'ACTIVE' THEN 1 END) as active_count
    FROM investment_product_versions ipv
    LEFT JOIN investments i ON i.product_version_id = ipv.id
    WHERE ipv.tenure_id = p_tenure_id
    GROUP BY ipv.id, ipv.version_number, ipv.return_percentage
    ORDER BY ipv.version_number DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 6. VALIDATION QUERIES
-- =====================================================

-- Verify all active tenures have at least one version
-- This should return 0 rows
DO $$
DECLARE
    tenure_without_version_count INT;
BEGIN
    SELECT COUNT(*) INTO tenure_without_version_count
    FROM investment_tenures it
    WHERE it.is_active = TRUE
    AND NOT EXISTS (
        SELECT 1 FROM investment_product_versions ipv
        WHERE ipv.tenure_id = it.id
    );

    IF tenure_without_version_count > 0 THEN
        RAISE WARNING 'Found % active tenures without versions', tenure_without_version_count;
    ELSE
        RAISE NOTICE 'All active tenures have at least one version';
    END IF;
END $$;

-- Verify all active tenures have exactly one current version
-- This should return 0 rows
DO $$
DECLARE
    tenure_with_multiple_current INT;
    tenure_without_current INT;
BEGIN
    -- Check for multiple current versions
    SELECT COUNT(*) INTO tenure_with_multiple_current
    FROM (
        SELECT tenure_id
        FROM investment_product_versions
        WHERE is_current = TRUE
        GROUP BY tenure_id
        HAVING COUNT(*) > 1
    ) sub;

    -- Check for tenures without current version
    SELECT COUNT(*) INTO tenure_without_current
    FROM investment_tenures it
    WHERE it.is_active = TRUE
    AND NOT EXISTS (
        SELECT 1 FROM investment_product_versions ipv
        WHERE ipv.tenure_id = it.id AND ipv.is_current = TRUE
    );

    IF tenure_with_multiple_current > 0 THEN
        RAISE WARNING 'Found % tenures with multiple current versions', tenure_with_multiple_current;
    END IF;

    IF tenure_without_current > 0 THEN
        RAISE WARNING 'Found % active tenures without a current version', tenure_without_current;
    END IF;

    IF tenure_with_multiple_current = 0 AND tenure_without_current = 0 THEN
        RAISE NOTICE 'Version consistency validated successfully';
    END IF;
END $$;

-- Verify all existing investments are linked to a version
DO $$
DECLARE
    unlinked_investment_count INT;
BEGIN
    SELECT COUNT(*) INTO unlinked_investment_count
    FROM investments
    WHERE product_version_id IS NULL;

    IF unlinked_investment_count > 0 THEN
        RAISE WARNING 'Found % investments not linked to a product version', unlinked_investment_count;
    ELSE
        RAISE NOTICE 'All investments successfully linked to product versions';
    END IF;
END $$;

-- =====================================================
-- 7. GRANT PERMISSIONS
-- =====================================================

-- Grant permissions (adjust based on your roles)
GRANT SELECT, INSERT, UPDATE ON investment_product_versions TO authenticated;
GRANT SELECT ON investment_product_versions TO anon;
GRANT ALL ON investment_product_versions TO service_role;

GRANT SELECT, INSERT, UPDATE ON investment_rate_change_notifications TO authenticated;
GRANT SELECT ON investment_rate_change_notifications TO anon;
GRANT ALL ON investment_rate_change_notifications TO service_role;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================

-- Log migration completion
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Migration 004: Investment Versioning';
    RAISE NOTICE 'Status: COMPLETED';
    RAISE NOTICE 'Date: %', CURRENT_TIMESTAMP;
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tables created: 2';
    RAISE NOTICE '  - investment_product_versions';
    RAISE NOTICE '  - investment_rate_change_notifications';
    RAISE NOTICE 'Columns added: 1';
    RAISE NOTICE '  - investments.product_version_id';
    RAISE NOTICE 'Helper functions created: 3';
    RAISE NOTICE '  - get_current_product_version';
    RAISE NOTICE '  - get_tenure_version_history';
    RAISE NOTICE '  - get_investment_count_by_version';
    RAISE NOTICE '========================================';
END $$;
