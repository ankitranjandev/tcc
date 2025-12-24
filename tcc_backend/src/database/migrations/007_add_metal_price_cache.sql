-- Migration: Add Metal Price Cache Table
-- Date: 2024-12-23
-- Description: Adds persistent caching for metal prices to minimize API calls
--              and stay within the 100 requests/month limit

-- =====================================================
-- 1. CREATE METAL PRICE CACHE TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS metal_price_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metal_symbol VARCHAR(10) NOT NULL, -- e.g., 'XAU', 'XAG', 'XPT'
    base_currency VARCHAR(3) NOT NULL, -- e.g., 'SLL', 'USD'
    price_per_ounce DECIMAL(20, 6) NOT NULL, -- Price per troy ounce
    price_per_gram DECIMAL(20, 6) NOT NULL, -- Price per gram
    price_per_kilogram DECIMAL(20, 6) NOT NULL, -- Price per kilogram
    api_timestamp BIGINT NOT NULL, -- Timestamp from API response
    cached_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(metal_symbol, base_currency)
);

-- Add indexes for quick lookups
CREATE INDEX idx_metal_price_cache_symbol ON metal_price_cache(metal_symbol);
CREATE INDEX idx_metal_price_cache_currency ON metal_price_cache(base_currency);
CREATE INDEX idx_metal_price_cache_expires ON metal_price_cache(expires_at);
CREATE INDEX idx_metal_price_cache_lookup ON metal_price_cache(metal_symbol, base_currency, expires_at);

-- Add trigger to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_metal_price_cache_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_metal_price_cache_timestamp
    BEFORE UPDATE ON metal_price_cache
    FOR EACH ROW
    EXECUTE FUNCTION update_metal_price_cache_timestamp();

-- =====================================================
-- 2. CREATE FUNCTION TO UPSERT METAL PRICES
-- =====================================================

CREATE OR REPLACE FUNCTION upsert_metal_price(
    p_metal_symbol VARCHAR(10),
    p_base_currency VARCHAR(3),
    p_price_per_ounce DECIMAL(20, 6),
    p_price_per_gram DECIMAL(20, 6),
    p_price_per_kilogram DECIMAL(20, 6),
    p_api_timestamp BIGINT,
    p_ttl_seconds INT DEFAULT 86400
)
RETURNS UUID AS $$
DECLARE
    v_id UUID;
    v_expires_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Calculate expiration time
    v_expires_at := CURRENT_TIMESTAMP + (p_ttl_seconds || ' seconds')::INTERVAL;

    -- Insert or update the cache entry
    INSERT INTO metal_price_cache (
        metal_symbol,
        base_currency,
        price_per_ounce,
        price_per_gram,
        price_per_kilogram,
        api_timestamp,
        cached_at,
        expires_at
    ) VALUES (
        p_metal_symbol,
        p_base_currency,
        p_price_per_ounce,
        p_price_per_gram,
        p_price_per_kilogram,
        p_api_timestamp,
        CURRENT_TIMESTAMP,
        v_expires_at
    )
    ON CONFLICT (metal_symbol, base_currency)
    DO UPDATE SET
        price_per_ounce = EXCLUDED.price_per_ounce,
        price_per_gram = EXCLUDED.price_per_gram,
        price_per_kilogram = EXCLUDED.price_per_kilogram,
        api_timestamp = EXCLUDED.api_timestamp,
        cached_at = CURRENT_TIMESTAMP,
        expires_at = v_expires_at,
        updated_at = CURRENT_TIMESTAMP
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. CREATE FUNCTION TO GET CACHED METAL PRICE
-- =====================================================

CREATE OR REPLACE FUNCTION get_cached_metal_price(
    p_metal_symbol VARCHAR(10),
    p_base_currency VARCHAR(3)
)
RETURNS TABLE(
    id UUID,
    metal_symbol VARCHAR(10),
    base_currency VARCHAR(3),
    price_per_ounce DECIMAL(20, 6),
    price_per_gram DECIMAL(20, 6),
    price_per_kilogram DECIMAL(20, 6),
    api_timestamp BIGINT,
    cached_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_expired BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        mpc.id,
        mpc.metal_symbol,
        mpc.base_currency,
        mpc.price_per_ounce,
        mpc.price_per_gram,
        mpc.price_per_kilogram,
        mpc.api_timestamp,
        mpc.cached_at,
        mpc.expires_at,
        CURRENT_TIMESTAMP > mpc.expires_at AS is_expired
    FROM metal_price_cache mpc
    WHERE mpc.metal_symbol = p_metal_symbol
      AND mpc.base_currency = p_base_currency
    ORDER BY mpc.cached_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 4. CREATE FUNCTION TO CLEAN UP EXPIRED CACHE
-- =====================================================

CREATE OR REPLACE FUNCTION cleanup_expired_metal_prices()
RETURNS INT AS $$
DECLARE
    v_deleted_count INT;
BEGIN
    -- Delete cache entries that have been expired for more than 7 days
    DELETE FROM metal_price_cache
    WHERE expires_at < CURRENT_TIMESTAMP - INTERVAL '7 days';

    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 5. CREATE VIEW FOR CURRENT METAL PRICES
-- =====================================================

CREATE OR REPLACE VIEW v_current_metal_prices AS
SELECT
    mpc.id,
    mpc.metal_symbol,
    mpc.base_currency,
    mpc.price_per_ounce,
    mpc.price_per_gram,
    mpc.price_per_kilogram,
    mpc.api_timestamp,
    mpc.cached_at,
    mpc.expires_at,
    CASE
        WHEN CURRENT_TIMESTAMP > mpc.expires_at THEN true
        ELSE false
    END AS is_expired,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - mpc.cached_at)) AS seconds_since_cached,
    EXTRACT(EPOCH FROM (mpc.expires_at - CURRENT_TIMESTAMP)) AS seconds_until_expiry
FROM metal_price_cache mpc
WHERE CURRENT_TIMESTAMP <= mpc.expires_at + INTERVAL '7 days'
ORDER BY mpc.metal_symbol, mpc.base_currency, mpc.cached_at DESC;

-- =====================================================
-- 6. ADD COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON TABLE metal_price_cache IS 'Persistent cache for metal prices from external API to minimize API calls';
COMMENT ON COLUMN metal_price_cache.metal_symbol IS 'Metal symbol (e.g., XAU for Gold, XAG for Silver, XPT for Platinum)';
COMMENT ON COLUMN metal_price_cache.base_currency IS 'Base currency for the price (e.g., SLL, USD)';
COMMENT ON COLUMN metal_price_cache.price_per_ounce IS 'Price per troy ounce (31.1034768 grams)';
COMMENT ON COLUMN metal_price_cache.price_per_gram IS 'Price per gram';
COMMENT ON COLUMN metal_price_cache.price_per_kilogram IS 'Price per kilogram';
COMMENT ON COLUMN metal_price_cache.api_timestamp IS 'Unix timestamp from the API response';
COMMENT ON COLUMN metal_price_cache.expires_at IS 'When this cache entry expires';

COMMENT ON FUNCTION upsert_metal_price IS 'Insert or update a metal price in the cache';
COMMENT ON FUNCTION get_cached_metal_price IS 'Get a cached metal price if it exists';
COMMENT ON FUNCTION cleanup_expired_metal_prices IS 'Remove cache entries that have been expired for more than 7 days';

-- =====================================================
-- VALIDATION
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Migration 007: Metal Price Cache';
    RAISE NOTICE 'Status: COMPLETED';
    RAISE NOTICE 'Date: %', CURRENT_TIMESTAMP;
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tables created: 1 (metal_price_cache)';
    RAISE NOTICE 'Indexes created: 4';
    RAISE NOTICE 'Functions created: 4';
    RAISE NOTICE 'Views created: 1';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Benefits:';
    RAISE NOTICE '  - Persistent caching across server restarts';
    RAISE NOTICE '  - Reduced API calls (stay within 100/month limit)';
    RAISE NOTICE '  - 24-hour cache TTL by default';
    RAISE NOTICE '  - Automatic cleanup of old cache entries';
    RAISE NOTICE '========================================';
END $$;
