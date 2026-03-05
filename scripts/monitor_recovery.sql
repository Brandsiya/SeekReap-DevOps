-- Real-time recovery monitoring
SELECT 
    '📊 RECOVERY MONITOR' as section,
    NOW() as check_time;

-- Queue status
SELECT 
    '📋 QUEUE STATUS' as section,
    COUNT(*) FILTER (WHERE status = 'pending') as pending,
    COUNT(*) FILTER (WHERE status = 'processing') as processing,
    COUNT(*) FILTER (WHERE status = 'completed') as completed,
    COUNT(*) FILTER (WHERE status = 'failed') as failed,
    COUNT(*) FILTER (WHERE attempts > 3) as stalled
FROM job_queue;

-- Submission progress
SELECT 
    '📝 SUBMISSIONS' as section,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE status = 'pending') as pending,
    COUNT(*) FILTER (WHERE status = 'completed') as completed,
    AVG(EXTRACT(EPOCH FROM (completed_at - submitted_at)))::int as avg_processing_seconds
FROM content_submissions
WHERE submitted_at > NOW() - INTERVAL '1 hour';

-- Recent activity
SELECT 
    '⚡ RECENT ACTIVITY (last 5 min)' as section,
    COUNT(*) as new_submissions,
    COUNT(*) FILTER (WHERE status = 'completed') as completed
FROM content_submissions
WHERE submitted_at > NOW() - INTERVAL '5 minutes';

-- Stalled job details (if any)
SELECT 
    '⚠️ STALLED JOBS' as section,
    id,
    attempts,
    created_at,
    last_error
FROM job_queue 
WHERE attempts > 3 
  AND status = 'pending'
LIMIT 5;
