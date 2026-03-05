-- Add performance index for pgqueuer_schedules
CREATE INDEX IF NOT EXISTS idx_pgqueuer_schedules_time_status 
ON pgqueuer_schedules(scheduled_time, status);

-- Add index for next-job lookup (common pattern)
CREATE INDEX IF NOT EXISTS idx_pgqueuer_schedules_next 
ON pgqueuer_schedules(status, scheduled_time) 
WHERE status = 'pending';

-- Verify all indexes now
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'pgqueuer_schedules'
ORDER BY indexname;

-- Check if this will fix the seq scans
SELECT '✅ After these indexes, the 2,973 sequential scans should drop to near zero!' as "Result";
