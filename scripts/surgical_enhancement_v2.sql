-- =====================================================
-- SEEKREAP PRODUCTION - SURGICAL SCHEMA ENHANCEMENT v2
-- Preserves all existing data while adding enterprise features
-- =====================================================

-- 1. ENHANCE EXISTING CREATORS TABLE (Preserve all data)
ALTER TABLE creators 
ADD COLUMN IF NOT EXISTS company_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(50) DEFAULT 'active',
ADD COLUMN IF NOT EXISTS billing_cycle DATE,
ADD COLUMN IF NOT EXISTS lifetime_credits_used INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_login_ip INET,
ADD COLUMN IF NOT EXISTS preferences JSONB;

-- 2. ENHANCE SUBMISSIONS TABLE (This is your content_submissions)
-- First, verify we're working with the right table
DO $$
BEGIN
    -- If content_submissions exists, use it as our submissions table
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'content_submissions') THEN
        -- Add missing columns to content_submissions
        ALTER TABLE content_submissions 
        ADD COLUMN IF NOT EXISTS description TEXT,
        ADD COLUMN IF NOT EXISTS content_hash VARCHAR(64),
        ADD COLUMN IF NOT EXISTS content_preview_url TEXT,
        ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1,
        ADD COLUMN IF NOT EXISTS parent_submission_id UUID REFERENCES content_submissions(id),
        ADD COLUMN IF NOT EXISTS last_accessed_at TIMESTAMP,
        ADD COLUMN IF NOT EXISTS metadata JSONB;
        
        -- Create a view to unify access (for backward compatibility)
        CREATE OR REPLACE VIEW submissions AS 
        SELECT * FROM content_submissions;
        
        RAISE NOTICE '✅ Enhanced content_submissions table';
    ELSE
        -- Create submissions if it doesn't exist
        CREATE TABLE IF NOT EXISTS submissions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            creator_id UUID NOT NULL REFERENCES creators(id) ON DELETE CASCADE,
            title VARCHAR(500),
            description TEXT,
            content_type VARCHAR(50) NOT NULL,
            content_url TEXT,
            content_hash VARCHAR(64),
            content_preview_url TEXT,
            version INTEGER DEFAULT 1,
            parent_submission_id UUID REFERENCES submissions(id),
            status VARCHAR(50) DEFAULT 'pending',
            priority INTEGER DEFAULT 0,
            submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            completed_at TIMESTAMP,
            last_accessed_at TIMESTAMP,
            overall_risk_score DECIMAL(5,2),
            risk_level VARCHAR(20),
            flags_count INTEGER DEFAULT 0,
            metadata JSONB
        );
        RAISE NOTICE '✅ Created new submissions table';
    END IF;
END $$;

-- 3. ADD MISSING INDEXES TO EXISTING TABLES (CRITICAL FOR PERFORMANCE)
-- These will dramatically reduce sequential scans

-- Index for job_queue (11,508 seq scans is too high!)
CREATE INDEX IF NOT EXISTS idx_job_queue_status ON job_queue(status, created_at);
CREATE INDEX IF NOT EXISTS idx_job_queue_priority ON job_queue(priority) WHERE status = 'pending';

-- Index for analytics_snapshots (5,951 seq scans!)
CREATE INDEX IF NOT EXISTS idx_analytics_snapshots_creator ON analytics_snapshots(creator_id, snapshot_date);
CREATE INDEX IF NOT EXISTS idx_analytics_snapshots_type ON analytics_snapshots(snapshot_type, created_at);

-- Index for content_submissions (your main submissions table)
CREATE INDEX IF NOT EXISTS idx_content_submissions_hash ON content_submissions(content_hash);
CREATE INDEX IF NOT EXISTS idx_content_submissions_creator_status ON content_submissions(creator_id, status);
CREATE INDEX IF NOT EXISTS idx_content_submissions_risk ON content_submissions(overall_risk_score) WHERE overall_risk_score IS NOT NULL;

-- Index for pgqueuer tables (job queue system)
CREATE INDEX IF NOT EXISTS idx_pgqueuer_status ON pgqueuer(job_status, scheduled_time);
CREATE INDEX IF NOT EXISTS idx_pgqueuer_log_job ON pgqueuer_log(job_id, created_at);

-- 4. ADD FOREIGN KEY CONSTRAINTS (Fix the "0 rows" issue)
-- This ensures data integrity for appeals

-- First, identify any orphaned records and clean them
DO $$
DECLARE
    orphan_count INTEGER;
BEGIN
    -- Check for orphaned flagged_issues
    SELECT COUNT(*) INTO orphan_count FROM flagged_issues fi
    WHERE NOT EXISTS (SELECT 1 FROM platform_scans ps WHERE ps.id = fi.scan_id);
    
    IF orphan_count > 0 THEN
        RAISE NOTICE 'Found % orphaned flagged_issues - archiving...', orphan_count;
        -- Move to audit log instead of deleting
        INSERT INTO audit_logs (event_type, old_values, created_at)
        SELECT 'ORPHAN_FLAGGED_ISSUE', row_to_json(fi), NOW()
        FROM flagged_issues fi
        WHERE NOT EXISTS (SELECT 1 FROM platform_scans ps WHERE ps.id = fi.scan_id);
        
        -- Safe to delete after archiving
        DELETE FROM flagged_issues fi
        WHERE NOT EXISTS (SELECT 1 FROM platform_scans ps WHERE ps.id = fi.scan_id);
    END IF;
END $$;

-- Now add foreign key constraints
ALTER TABLE platform_scans 
ADD CONSTRAINT fk_platform_scans_submission 
FOREIGN KEY (submission_id) REFERENCES content_submissions(id) ON DELETE CASCADE;

ALTER TABLE flagged_issues 
ADD CONSTRAINT fk_flagged_issues_scan 
FOREIGN KEY (scan_id) REFERENCES platform_scans(id) ON DELETE CASCADE;

ALTER TABLE fix_suggestions 
ADD CONSTRAINT fk_fix_suggestions_issue 
FOREIGN KEY (issue_id) REFERENCES flagged_issues(id) ON DELETE CASCADE;

ALTER TABLE reports 
ADD CONSTRAINT fk_reports_submission 
FOREIGN KEY (submission_id) REFERENCES content_submissions(id) ON DELETE CASCADE;

ALTER TABLE feedback 
ADD CONSTRAINT fk_feedback_scan 
FOREIGN KEY (scan_id) REFERENCES platform_scans(id) ON DELETE CASCADE;

ALTER TABLE usage_logs 
ADD CONSTRAINT fk_usage_logs_submission 
FOREIGN KEY (submission_id) REFERENCES content_submissions(id) ON DELETE SET NULL;

-- 5. CREATE NEW TABLES IF THEY DON'T EXIST
CREATE TABLE IF NOT EXISTS platform_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    platform VARCHAR(50) NOT NULL,
    policy_version VARCHAR(50),
    effective_date DATE NOT NULL,
    policy_category VARCHAR(100) NOT NULL,
    severity_threshold DECIMAL(5,2),
    policy_reference_url TEXT,
    policy_summary TEXT,
    typical_penalty VARCHAR(50),
    appeals_possible BOOLEAN DEFAULT true,
    appeal_deadline_days INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(platform, policy_version, policy_category)
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES creators(id),
    event_type VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. INSERT SAMPLE PLATFORM POLICIES (if not exists)
INSERT INTO platform_policies (platform, policy_version, effective_date, policy_category, severity_threshold, policy_reference_url, typical_penalty)
SELECT 'youtube', '2025-03', CURRENT_DATE, 'copyright', 0.8, 'https://support.google.com/youtube/answer/2797449', 'strike'
WHERE NOT EXISTS (SELECT 1 FROM platform_policies WHERE platform='youtube' AND policy_category='copyright');

INSERT INTO platform_policies (platform, policy_version, effective_date, policy_category, severity_threshold, policy_reference_url, typical_penalty)
SELECT 'youtube', '2025-03', CURRENT_DATE, 'hate_speech', 0.7, 'https://support.google.com/youtube/answer/2801939', 'demonetization'
WHERE NOT EXISTS (SELECT 1 FROM platform_policies WHERE platform='youtube' AND policy_category='hate_speech');

INSERT INTO platform_policies (platform, policy_version, effective_date, policy_category, severity_threshold, policy_reference_url, typical_penalty)
SELECT 'tiktok', '2025-03', CURRENT_DATE, 'adult_content', 0.6, 'https://www.tiktok.com/community-guidelines', 'ban'
WHERE NOT EXISTS (SELECT 1 FROM platform_policies WHERE platform='tiktok' AND policy_category='adult_content');

INSERT INTO platform_policies (platform, policy_version, effective_date, policy_category, severity_threshold, policy_reference_url, typical_penalty)
SELECT 'instagram', '2025-03', CURRENT_DATE, 'violence', 0.75, 'https://help.instagram.com/477434105621119', 'removed'
WHERE NOT EXISTS (SELECT 1 FROM platform_policies WHERE platform='instagram' AND policy_category='violence');

-- 7. VERIFICATION QUERIES
SELECT '✅ SURGICAL ENHANCEMENT COMPLETE' as status;

-- Show index improvements
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as "Current Scans"
FROM pg_stat_user_indexes 
WHERE indexname LIKE 'idx_%' 
ORDER BY idx_scan DESC NULLS LAST
LIMIT 10;

-- Show foreign keys now
SELECT
    conname AS constraint_name,
    conrelid::regclass AS table_name,
    confrelid::regclass AS foreign_table
FROM pg_constraint
WHERE contype = 'f' 
ORDER BY table_name;

-- Show tables with sequential scan risk
SELECT 
    relname AS table_name, 
    seq_scan, 
    idx_scan,
    ROUND(100.0 * idx_scan / NULLIF(seq_scan + idx_scan, 0), 2) as index_usage_pct
FROM pg_stat_user_tables 
WHERE seq_scan > 1000
ORDER BY seq_scan DESC;
