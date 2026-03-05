-- SEEKREAP TEST FLOW - IDEMPOTENT CREATOR SETUP
-- Run this anytime to reset test data without errors

-- 1. Create/Update test creator (idempotent)
WITH creator AS (
    INSERT INTO creators (
        email, 
        name, 
        subscription_tier, 
        credits_remaining,
        last_login_ip,
        updated_at
    ) VALUES (
        'test@creator.com', 
        'Test Creator', 
        'pro', 
        100,
        '127.0.0.1',
        NOW()
    )
    ON CONFLICT (email) 
    DO UPDATE SET 
        last_login_ip = EXCLUDED.last_login_ip,
        updated_at = NOW(),
        credits_remaining = EXCLUDED.credits_remaining
    RETURNING id, email, subscription_tier, credits_remaining
)
SELECT 
    '✅ Creator ready' as operation,
    id,
    email,
    subscription_tier,
    credits_remaining
FROM creator;

-- 2. Show current creator stats
SELECT 
    '📊 Creator stats' as info,
    COUNT(*) as total_creators,
    COUNT(*) FILTER (WHERE subscription_tier = 'pro') as pro_creators,
    AVG(credits_remaining)::int as avg_credits
FROM creators;

-- 3. Check if we have any test submissions
SELECT 
    '📝 Test submissions' as info,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE status = 'pending') as pending,
    COUNT(*) FILTER (WHERE status = 'completed') as completed
FROM content_submissions 
WHERE creator_id = (SELECT id FROM creators WHERE email = 'test@creator.com');

-- 4. Verify foreign keys are working (should return 0 if clean)
SELECT 
    '🔗 Orphan check' as info,
    COUNT(*) as orphaned_records
FROM flagged_issues fi
WHERE NOT EXISTS (SELECT 1 FROM platform_scans ps WHERE ps.id = fi.scan_id);
