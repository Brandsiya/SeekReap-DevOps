# SeekReap Database Schemas

## Version History

### v2.1.0 (Current)
- Added `improvement_score` to track risk reduction
- Enhanced `creators` with subscription fields
- Added foreign key constraints for data integrity
- Created performance indexes for job_queue

### v2.0.0 (Initial Enhanced)
- Platform policies table
- Submissions tracking
- Fix suggestions with effectiveness scoring

## Key Tables

- `creators` - User accounts with subscription tiers
- `content_submissions` - Videos/content being analyzed
- `platform_scans` - Risk analysis results per platform
- `flagged_issues` - Specific policy violations
- `fix_suggestions` - Automated remediation advice
- `job_queue` - Background processing queue

## Indexes

Critical performance indexes:
- `idx_job_queue_status` - Fast queue lookups
- `idx_content_submissions_hash` - Duplicate detection
- `idx_flagged_issues_severity` - Risk prioritization
