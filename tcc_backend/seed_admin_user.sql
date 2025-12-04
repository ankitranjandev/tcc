-- =====================================================
-- Create Default Admin User
-- =====================================================
-- This script creates a default super admin user for initial setup
--
-- Default credentials:
--   Email: admin@tcc.sl
--   Password: Admin@123456
--
-- IMPORTANT: Change the password immediately after first login!
-- =====================================================

-- Check if admin user already exists
DO $$
BEGIN
    -- Only create if no admin users exist
    IF NOT EXISTS (
        SELECT 1 FROM users
        WHERE role IN ('ADMIN', 'SUPER_ADMIN')
    ) THEN
        -- Create super admin user
        -- Password hash for 'Admin@123456' using bcrypt (cost factor 12)
        INSERT INTO users (
            id,
            role,
            first_name,
            last_name,
            email,
            phone,
            country_code,
            password_hash,
            kyc_status,
            is_active,
            is_verified,
            email_verified,
            phone_verified,
            created_at,
            updated_at
        ) VALUES (
            uuid_generate_v4(),
            'SUPER_ADMIN',
            'System',
            'Administrator',
            'admin@tcc.sl',
            '+23276000000',
            '+232',
            '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYfL5MvP8am',  -- Password: Admin@123456
            'APPROVED',
            true,
            true,
            true,
            true,
            NOW(),
            NOW()
        );

        RAISE NOTICE 'Default super admin user created successfully!';
        RAISE NOTICE 'Email: admin@tcc.sl';
        RAISE NOTICE 'Password: Admin@123456';
        RAISE NOTICE 'IMPORTANT: Please change the password after first login!';
    ELSE
        RAISE NOTICE 'Admin user(s) already exist. Skipping creation.';
    END IF;
END $$;

-- Verify the admin user was created
SELECT
    id,
    role,
    first_name,
    last_name,
    email,
    is_active,
    created_at
FROM users
WHERE role IN ('ADMIN', 'SUPER_ADMIN')
ORDER BY created_at;
