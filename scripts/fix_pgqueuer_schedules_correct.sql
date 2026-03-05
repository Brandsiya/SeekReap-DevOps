-- First, let's examine the table structure
SELECT 
    column_name, 
    data_type 
FROM information_schema.columns 
WHERE table_name = 'pgqueuer_schedules'
ORDER BY ordinal_position;

-- Check the enum values
SELECT enum_range(NULL::pgqueuer_status) as status_values;

-- Based on typical pgqueuer, create index on created_at for time-based queries
CREATE INDEX IF NOT EXISTS idx_pgqueuer_schedules_created 
ON pgqueuer_schedules(created_at);

-- If there's an updated_at column, index that too
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'pgqueuer_schedules' AND column_name = 'updated_at') THEN
        CREATE INDEX IF NOT EXISTS idx_pgqueuer_schedules_updated 
        ON pgqueuer_schedules(updated_at);
    END IF;
END $$;

-- Index on status for filtering (using actual enum values from your system)
DO $$
DECLARE
    status_exists boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pgqueuer_schedules' AND column_name = 'status'
    ) INTO status_exists;
    
    IF status_exists THEN
        EXECUTE 'CREATE INDEX IF NOT EXISTS idx_pgqueuer_schedules_status 
                 ON pgqueuer_schedules(status)';
        RAISE NOTICE '✅ Created status index';
    END IF;
END $$;

-- Show all indexes now
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'pgqueuer_schedules'
ORDER BY indexname;

-- Recommendations
SELECT 
    'Based on your query patterns, you may want to add:' as advice
UNION ALL
SELECT '- Index on (status, created_at) if you filter by status and time'
UNION ALL
SELECT '- Index on (entrypoint) if you look up by entrypoint'
UNION ALL
SELECT 'Run: EXPLAIN ANALYZE your_query to see what indexes would help';
