-- Run this weekly to check if indexes are being used
SELECT 
    relname AS table_name,
    n_live_tup AS row_count,
    seq_scan,
    idx_scan,
    CASE 
        WHEN n_live_tup > 1000 THEN 
            CASE 
                WHEN idx_scan = 0 THEN '⚠️  CRITICAL - Add indexes!'
                WHEN seq_scan > idx_scan * 5 THEN '⚠️  Warning - High seq scans'
                ELSE '✅ Healthy'
            END
        ELSE '🟢 Small table - OK'
    END AS status
FROM pg_stat_user_tables
WHERE relname IN ('job_queue', 'content_submissions', 'pgqueuer_schedules', 'analytics_snapshots')
ORDER BY n_live_tup DESC;
