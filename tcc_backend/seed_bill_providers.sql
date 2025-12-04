-- =====================================================
-- Bill Providers Seed Data
-- Sample providers for testing bill payment functionality
-- =====================================================

-- Clear existing providers (optional - remove if you want to keep existing data)
-- DELETE FROM bill_providers;

-- =====================================================
-- ELECTRICITY PROVIDERS
-- =====================================================

INSERT INTO bill_providers (id, name, type, logo_url, is_active, metadata) VALUES
(
    uuid_generate_v4(),
    'EDSA (Electricity Distribution and Supply Authority)',
    'ELECTRICITY',
    'https://example.com/logos/edsa.png',
    true,
    '{"fields_required": ["account_number", "meter_number"], "description": "National electricity provider", "website": "https://edsa.sl"}'::jsonb
),
(
    uuid_generate_v4(),
    'KARPOWERSHIP',
    'ELECTRICITY',
    'https://example.com/logos/karpowership.png',
    true,
    '{"fields_required": ["account_number"], "description": "Powership electricity provider", "website": "https://karpowership.com"}'::jsonb
);

-- =====================================================
-- WATER PROVIDERS
-- =====================================================

INSERT INTO bill_providers (id, name, type, logo_url, is_active, metadata) VALUES
(
    uuid_generate_v4(),
    'GUMA Valley Water Company',
    'WATER',
    'https://example.com/logos/guma.png',
    true,
    '{"fields_required": ["account_number", "meter_number"], "description": "Freetown water supply", "website": "https://guma.sl"}'::jsonb
),
(
    uuid_generate_v4(),
    'SALWACO',
    'WATER',
    'https://example.com/logos/salwaco.png',
    true,
    '{"fields_required": ["account_number"], "description": "Sierra Leone Water Company", "website": "https://salwaco.sl"}'::jsonb
);

-- =====================================================
-- DSTV / SATELLITE TV PROVIDERS
-- =====================================================

INSERT INTO bill_providers (id, name, type, logo_url, is_active, metadata) VALUES
(
    uuid_generate_v4(),
    'DStv',
    'DSTV',
    'https://example.com/logos/dstv.png',
    true,
    '{"fields_required": ["smartcard_number"], "description": "Digital satellite television", "website": "https://dstv.com"}'::jsonb
),
(
    uuid_generate_v4(),
    'GOtv',
    'DSTV',
    'https://example.com/logos/gotv.png',
    true,
    '{"fields_required": ["iuc_number"], "description": "Digital terrestrial television", "website": "https://gotvafrica.com"}'::jsonb
),
(
    uuid_generate_v4(),
    'StarTimes',
    'DSTV',
    'https://example.com/logos/startimes.png',
    true,
    '{"fields_required": ["smartcard_number"], "description": "Digital television service", "website": "https://startimes.com"}'::jsonb
);

-- =====================================================
-- INTERNET PROVIDERS
-- =====================================================

INSERT INTO bill_providers (id, name, type, logo_url, is_active, metadata) VALUES
(
    uuid_generate_v4(),
    'Africell',
    'INTERNET',
    'https://example.com/logos/africell.png',
    true,
    '{"fields_required": ["account_number"], "description": "Home broadband internet", "website": "https://africell.sl"}'::jsonb
),
(
    uuid_generate_v4(),
    'Orange Sierra Leone',
    'INTERNET',
    'https://example.com/logos/orange.png',
    true,
    '{"fields_required": ["account_number"], "description": "Home internet service", "website": "https://orange.sl"}'::jsonb
),
(
    uuid_generate_v4(),
    'Sierratel',
    'INTERNET',
    'https://example.com/logos/sierratel.png',
    true,
    '{"fields_required": ["account_number", "phone_number"], "description": "National telecom internet", "website": "https://sierratel.sl"}'::jsonb
);

-- =====================================================
-- MOBILE PROVIDERS
-- =====================================================

INSERT INTO bill_providers (id, name, type, logo_url, is_active, metadata) VALUES
(
    uuid_generate_v4(),
    'Africell Mobile',
    'MOBILE',
    'https://example.com/logos/africell-mobile.png',
    true,
    '{"fields_required": ["phone_number"], "description": "Mobile airtime and data", "website": "https://africell.sl"}'::jsonb
),
(
    uuid_generate_v4(),
    'Orange Mobile',
    'MOBILE',
    'https://example.com/logos/orange-mobile.png',
    true,
    '{"fields_required": ["phone_number"], "description": "Mobile airtime and data", "website": "https://orange.sl"}'::jsonb
),
(
    uuid_generate_v4(),
    'Qcell',
    'MOBILE',
    'https://example.com/logos/qcell.png',
    true,
    '{"fields_required": ["phone_number"], "description": "Mobile airtime and data", "website": "https://qcell.sl"}'::jsonb
);

-- =====================================================
-- Verify inserted data
-- =====================================================

SELECT
    type as category,
    COUNT(*) as provider_count
FROM bill_providers
WHERE is_active = true
GROUP BY type
ORDER BY type;

-- Display all providers
SELECT
    name,
    type as category,
    is_active,
    metadata->>'description' as description
FROM bill_providers
ORDER BY type, name;
