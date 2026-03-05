-- =====================================================
-- SeekReap Pre-Flag Minimization - Enhanced Schema v2
-- =====================================================

-- 1. PLATFORM POLICIES (Centralized rules per platform)
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

-- 2. CREATORS (Enhanced)
CREATE TABLE IF NOT EXISTS creators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    company_name VARCHAR(255),
    subscription_tier VARCHAR(50) DEFAULT 'free',
    subscription_status VARCHAR(50) DEFAULT 'active',
    billing_cycle DATE,
    credits_remaining INTEGER DEFAULT 10,
    lifetime_credits_used INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_active TIMESTAMP,
    last_login_ip INET,
    preferences JSONB
);

-- 3. CONTENT SUBMISSIONS (Enhanced)
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

-- 4. PLATFORM SCANS (with improvement tracking)
CREATE TABLE IF NOT EXISTS platform_scans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id UUID NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
    platform VARCHAR(50) NOT NULL,
    risk_score DECIMAL(5,2) NOT NULL,
    risk_level VARCHAR(20) NOT NULL,
    scan_duration_ms INTEGER,
    compute_cost_cents INTEGER,
    findings JSONB NOT NULL,
    scan_version INTEGER DEFAULT 1,
    previous_scan_id UUID REFERENCES platform_scans(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    improvement_score DECIMAL(5,2),
    UNIQUE(submission_id, platform, scan_version)
);

-- 5. FLAGGED ISSUES (with policy links)
CREATE TABLE IF NOT EXISTS flagged_issues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scan_id UUID NOT NULL REFERENCES platform_scans(id) ON DELETE CASCADE,
    policy_id UUID REFERENCES platform_policies(id),
    policy_category VARCHAR(100) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    confidence DECIMAL(5,2),
    timestamp_start DECIMAL(10,2),
    timestamp_end DECIMAL(10,2),
    text_snippet TEXT,
    image_coordinates JSONB,
    detection_method VARCHAR(100),
    ai_explanation TEXT,
    matched_terms TEXT[],
    confidence_factors JSONB,
    policy_reference TEXT,
    policy_effective_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. FIX SUGGESTIONS (with effectiveness tracking)
CREATE TABLE IF NOT EXISTS fix_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id UUID NOT NULL REFERENCES flagged_issues(id) ON DELETE CASCADE,
    suggestion_type VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    action_url TEXT,
    original_content TEXT,
    suggested_content TEXT,
    applied BOOLEAN DEFAULT false,
    applied_by VARCHAR(50),
    applied_at TIMESTAMP,
    resulting_risk_score DECIMAL(5,2),
    effectiveness_score DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. REPORTS (with access tracking)
CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id UUID NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
    creator_id UUID NOT NULL REFERENCES creators(id),
    report_url TEXT NOT NULL,
    report_format VARCHAR(20) DEFAULT 'pdf',
    report_size_bytes INTEGER,
    access_count INTEGER DEFAULT 0,
    last_accessed_at TIMESTAMP,
    accessed_by_ips INET[],
    shared_with_platform BOOLEAN DEFAULT false,
    shared_at TIMESTAMP,
    platform_appeal_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL '90 days'),
    archived_at TIMESTAMP
);

-- 8. FEEDBACK (granular tracking)
CREATE TABLE IF NOT EXISTS feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scan_id UUID NOT NULL REFERENCES platform_scans(id) ON DELETE CASCADE,
    creator_id UUID NOT NULL REFERENCES creators(id),
    issue_ids UUID[] NOT NULL,
    feedback_type VARCHAR(20) NOT NULL,
    accuracy_rating INTEGER CHECK (accuracy_rating >= 1 AND accuracy_rating <= 5),
    agreed_with_severity BOOLEAN,
    suggested_severity VARCHAR(20),
    comments TEXT,
    user_expected_outcome TEXT,
    resolved BOOLEAN DEFAULT false,
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. USAGE LOGS (detailed billing)
CREATE TABLE IF NOT EXISTS usage_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES creators(id),
    action_type VARCHAR(50) NOT NULL,
    platform VARCHAR(50),
    credits_used INTEGER DEFAULT 1,
    actual_cost_cents INTEGER,
    billing_code VARCHAR(100),
    submission_id UUID REFERENCES submissions(id),
    scan_id UUID REFERENCES platform_scans(id),
    report_id UUID REFERENCES reports(id),
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. AUDIT LOGS (compliance)
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

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_platform_policies_effective ON platform_policies(platform, effective_date);
CREATE INDEX IF NOT EXISTS idx_creators_email ON creators(email);
CREATE INDEX IF NOT EXISTS idx_creators_tier_status ON creators(subscription_tier, subscription_status);
CREATE INDEX IF NOT EXISTS idx_submissions_creator_status ON submissions(creator_id, status);
CREATE INDEX IF NOT EXISTS idx_submissions_hash ON submissions(content_hash);
CREATE INDEX IF NOT EXISTS idx_platform_scans_created ON platform_scans(created_at);
CREATE INDEX IF NOT EXISTS idx_flagged_issues_severity ON flagged_issues(severity);
CREATE INDEX IF NOT EXISTS idx_fix_suggestions_applied ON fix_suggestions(applied);
CREATE INDEX IF NOT EXISTS idx_reports_expires ON reports(expires_at);
CREATE INDEX IF NOT EXISTS idx_usage_logs_creator_date ON usage_logs(creator_id, created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_creator_time ON audit_logs(creator_id, created_at);

-- Insert sample platform policies (for testing)
INSERT INTO platform_policies (platform, policy_version, effective_date, policy_category, severity_threshold, policy_reference_url, typical_penalty)
VALUES 
    ('youtube', '2025-03', CURRENT_DATE, 'copyright', 0.8, 'https://support.google.com/youtube/answer/2797449', 'strike'),
    ('youtube', '2025-03', CURRENT_DATE, 'hate_speech', 0.7, 'https://support.google.com/youtube/answer/2801939', 'demonetization'),
    ('tiktok', '2025-03', CURRENT_DATE, 'adult_content', 0.6, 'https://www.tiktok.com/community-guidelines', 'ban'),
    ('instagram', '2025-03', CURRENT_DATE, 'violence', 0.75, 'https://help.instagram.com/477434105621119', 'removed')
ON CONFLICT DO NOTHING;

-- Verification query
SELECT 'Schema v2 installed successfully!' as status, 
       COUNT(*) as total_tables 
FROM information_schema.tables 
WHERE table_schema = 'public';
