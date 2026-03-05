-- Quick queue overview
SELECT 
    '📊 QUEUE OVERVIEW' as report;

SELECT 
    status,
    COUNT(*) as count,
    MIN(created_at) as oldest,
    MAX(created_at) as newest,
    ROUND(AVG(EXTRACT(EPOCH FROM (NOW() - created_at))/60)::numeric, 2) as avg_age_minutes
FROM job_queue
GROUP BY status
ORDER BY 
    CASE status 
        WHEN 'pending' THEN 1
        WHEN 'processing' THEN 2
        WHEN 'completed' THEN 3
        WHEN 'failed' THEN 4
        ELSE 5
    END;

-- Pending jobs breakdown by age
SELECT 
    '⏱️ PENDING JOBS AGE' as section,
    CASE 
        WHEN created_at < NOW() - INTERVAL '1 hour' THEN '> 1 hour'
        WHEN created_at < NOW() - INTERVAL '30 minutes' THEN '30-60 min'
        WHEN created_at < NOW() - INTERVAL '15 minutes' THEN '15-30 min'
        WHEN created_at < NOW() - INTERVAL '5 minutes' THEN '5-15 min'
        ELSE '< 5 min'
    END as age_bucket,
    COUNT(*) as count
FROM job_queue
WHERE status = 'pending'
GROUP BY age_bucket
ORDER BY MIN(created_at) DESC;

-- Top 5 oldest pending jobs
SELECT 
    '📌 OLDEST PENDING JOBS' as section,
    job_id,
    creator_id,
    job_type,
    created_at,
    AGE(NOW(), created_at) as waiting_time
FROM job_queue
WHERE status = 'pending'
ORDER BY created_at ASC
LIMIT 5;
