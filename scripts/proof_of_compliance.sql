SELECT 
  s.title,
  s.submitted_at,
  ps1.risk_score as original_risk,
  ps2.risk_score as new_risk,
  ps2.improvement_score,
  jsonb_agg(jsonb_build_object(
    'issue', fi.policy_category,
    'fix', fs.suggestion_type,
    'applied', fs.applied,
    'new_score', fs.resulting_risk_score
  )) as fixes_applied
FROM submissions s
JOIN platform_scans ps1 ON s.id = ps1.submission_id AND ps1.scan_version = 1
JOIN platform_scans ps2 ON s.id = ps2.submission_id AND ps2.scan_version = 2
LEFT JOIN flagged_issues fi ON ps2.id = fi.scan_id
LEFT JOIN fix_suggestions fs ON fi.id = fs.issue_id
WHERE s.id = 'submission-uuid'
GROUP BY s.id, ps1.risk_score, ps2.risk_score, ps2.improvement_score;
