-- Comprehensive Health Check for Tier-5 Backend
-- Returns JSON that can be served by your API

WITH db_stats AS (
    SELECT 
        COUNT(*) as total_tables,
        SUM(pg_total_relation_size(schemaname||'.'||tablename)) as total_size_bytes
    FROM pg_tables 
    WHERE schemaname = 'public'
),
creator_stats AS (
    SELECT 
        COUNT(*) as total_creators,
        COUNT(*) FILTER (WHERE subscription_tier = 'free') as free_creators,
        COUNT(*) FILTER (WHERE subscription_tier = 'pro') as pro_creators,
        COUNT(*) FILTER (WHERE subscription_tier = 'enterprise') as enterprise_creators,
        SUM(credits_remaining) as total_credits_remaining
    FROM creators
),
submission_stats AS (
    SELECT 
        COUNT(*) as total_submissions,
        COUNT(*) FILTER (WHERE status = 'pending') as pending_submissions,
        COUNT(*) FILTER (WHERE status = 'completed') as completed_submissions,
        COUNT(*) FILTER (WHERE status = 'failed') as failed_submissions,
        AVG(overall_risk_score) FILTER (WHERE overall_risk_score IS NOT NULL) as avg_risk_score
    FROM content_submissions
),
queue_stats AS (
    SELECT 
        COUNT(*) as pending_jobs,
        COUNT(*) FILTER (WHERE attempts > 3) as stalled_jobs
    FROM job_queue 
    WHERE status = 'pending'
),
policy_stats AS (
    SELECT 
        COUNT(*) as total_policies,
        jsonb_agg(DISTINCT platform) as platforms_covered
    FROM platform_policies
),
index_stats AS (
    SELECT 
        COUNT(*) as total_indexes,
        COUNT(*) FILTER (WHERE idx_scan = 0) as unused_indexes
    FROM pg_stat_user_indexes
    WHERE schemaname = 'public'
)
SELECT 
    jsonb_build_object(
        'status', 'healthy',
        'timestamp', NOW(),
        'database', jsonb_build_object(
            'tables', (SELECT total_tables FROM db_stats),
            'size_mb', ROUND((SELECT total_size_bytes FROM db_stats) / 1024.0 / 1024.0, 2),
            'indexes', (SELECT total_indexes FROM index_stats),
            'unused_indexes', (SELECT unused_indexes FROM index_stats)
        ),
        'creators', jsonb_build_object(
            'total', (SELECT total_creators FROM creator_stats),
            'free', (SELECT free_creators FROM creator_stats),
            'pro', (SELECT pro_creators FROM creator_stats),
            'enterprise', (SELECT enterprise_creators FROM creator_stats),
            'credits_remaining', (SELECT total_credits_remaining FROM creator_stats)
        ),
        'submissions', jsonb_build_object(
            'total', (SELECT total_submissions FROM submission_stats),
            'pending', (SELECT pending_submissions FROM submission_stats),
            'completed', (SELECT completed_submissions FROM submission_stats),
            'failed', (SELECT failed_submissions FROM submission_stats),
            'avg_risk', ROUND(COALESCE((SELECT avg_risk_score FROM submission_stats), 0)::numeric, 2)
        ),
        'queue', jsonb_build_object(
            'pending_jobs', (SELECT pending_jobs FROM queue_stats),
            'stalled_jobs', (SELECT stalled_jobs FROM queue_stats)
        ),
        'policies', jsonb_build_object(
            'total', (SELECT total_policies FROM policy_stats),
            'platforms', (SELECT platforms_covered FROM policy_stats)
        )
    ) as health_check;
