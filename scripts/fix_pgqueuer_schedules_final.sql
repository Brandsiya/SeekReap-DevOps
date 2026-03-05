-- Add performance index for time-based queries (this will fix the 2,973 seq scans!)
CREATE INDEX IF NOT EXISTS idx_pgqueuer_schedules_time 
ON pgqueuer_schedules(scheduled_time);

-- Add composite index for status + time (most common query pattern)
CREATE INDEX IF NOT EXISTS idx_pgqueuer_schedules_status_time 
ON pgqueuer_schedules(status, scheduled_time);

-- Add conditional index for pending jobs (if you have a status column)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'pgqueuer_schedules' AND column_name = 'status') THEN
        CREATE INDEX IF NOT EXISTS idx_pgqueuer_schedules_pending 
        ON pgqueuer_schedules(scheduled_time) 
        WHERE status = 'pending';
    END IF;
END $$;

-- Verify the new indexes
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'pgqueuer_schedules'
ORDER BY indexname;

-- Show the expected improvement
SELECT 
    '✅ Added performance indexes to pgqueuer_schedules' as "Result",
    'The 2,973 sequential scans should now use these indexes!' as "Impact";
