-- Identify jobs that are failing repeatedly
SELECT 
    '🔍 STALLED JOBS REPORT' as section,
    NOW() as check_time;

-- Jobs with multiple failures
SELECT 
    job_id,
    creator_id,
    content_id,
    job_type,
    attempts,
    created_at,
    failure_reason,
    submission_id
FROM job_queue 
WHERE attempts > 3 
  AND status = 'pending'
ORDER BY attempts DESC, created_at DESC;

-- Summary by failure reason
SELECT 
    SUBSTRING(COALESCE(failure_reason, 'Unknown') FROM 1 FOR 50) as error_preview,
    COUNT(*) as count,
    MAX(attempts) as max_attempts,
    array_agg(DISTINCT job_type) as job_types
FROM job_queue 
WHERE attempts > 3 
  AND status = 'pending'
GROUP BY error_preview
ORDER BY count DESC;

-- Total stalled count
SELECT 
    COUNT(*) as total_stalled_jobs
FROM job_queue 
WHERE attempts > 3 
  AND status = 'pending';
