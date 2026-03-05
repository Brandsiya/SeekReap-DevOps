-- Identify jobs that are failing repeatedly
SELECT 
    id,
    attempts,
    created_at,
    last_error,
    payload->>'content_url' as content_url,
    payload->>'platform' as platform
FROM job_queue 
WHERE attempts > 3 
  AND status = 'pending'
ORDER BY attempts DESC, created_at DESC;

-- Summary of stalled jobs by error type
SELECT 
    SUBSTRING(last_error FROM 1 FOR 100) as error_preview,
    COUNT(*) as count,
    MAX(attempts) as max_attempts
FROM job_queue 
WHERE attempts > 3 
  AND status = 'pending'
GROUP BY error_preview
ORDER BY count DESC;
