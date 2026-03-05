-- Real-time recovery monitoring
SELECT 
    '📊 RECOVERY MONITOR' as section,
    NOW() as check_time;

-- Queue status with correct columns
SELECT 
    '📋 QUEUE STATUS' as section,
    COUNT(*) FILTER (WHERE status = 'pending') as pending,
    COUNT(*) FILTER (WHERE status = 'processing') as processing,
    COUNT(*) FILTER (WHERE status = 'completed') as completed,
    COUNT(*) FILTER (WHERE status = 'failed') as failed,
    COUNT(*) FILTER (WHERE attempts > 3) as stalled,
    MIN(created_at) FILTER (WHERE status = 'pending') as oldest_pending
FROM job_queue;

-- Job types in queue
SELECT 
    '📦 JOB TYPES' as section,
    job_type,
    COUNT(*) as count
FROM job_queue
WHERE status = 'pending'
GROUP BY job_type
ORDER BY count DESC;

-- Recent activity (last 5 min)
SELECT 
    '⚡ RECENT ACTIVITY' as section,
    COUNT(*) as total_jobs,
    COUNT(*) FILTER (WHERE status = 'completed') as completed,
    COUNT(*) FILTER (WHERE status = 'failed') as failed
FROM job_queue
WHERE created_at > NOW() - INTERVAL '5 minutes';

-- Stalled job details (using correct column names)
SELECT 
    '⚠️ STALLED JOBS DETAIL' as section,
    job_id,
    creator_id,
    content_id,
    job_type,
    attempts,
    created_at,
    failure_reason
FROM job_queue
WHERE attempts > 3 
  AND status = 'pending'
ORDER BY attempts DESC, created_at DESC
LIMIT 10;

-- Queue processing rate
SELECT 
    '⚙️ PROCESSING RATE' as section,
    COUNT(*) as jobs_last_hour,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_last_hour,
    ROUND(COUNT(*) FILTER (WHERE status = 'completed') / 60.0, 2) as jobs_per_minute
FROM job_queue
WHERE created_at > NOW() - INTERVAL '1 hour';
