-- Add missing index for pgqueuer_schedules
CREATE INDEX IF NOT EXISTS idx_pgqueuer_schedules_perf 
ON pgqueuer_schedules(scheduled_time, status);

-- Verify all critical indexes exist
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename IN ('job_queue', 'content_submissions', 'pgqueuer_schedules', 'analytics_snapshots')
ORDER BY tablename, indexname;

-- Final foreign key check
SELECT
    conname AS constraint_name,
    conrelid::regclass AS table_name,
    confrelid::regclass AS foreign_table
FROM pg_constraint
WHERE contype = 'f'
ORDER BY table_name;
