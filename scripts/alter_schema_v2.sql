-- =====================================================
-- Alter existing tables to match new schema
-- =====================================================

-- Add missing columns to creators
ALTER TABLE creators 
ADD COLUMN IF NOT EXISTS company_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(50) DEFAULT 'active',
ADD COLUMN IF NOT EXISTS billing_cycle DATE,
ADD COLUMN IF NOT EXISTS lifetime_credits_used INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_login_ip INET,
ADD COLUMN IF NOT EXISTS preferences JSONB;

-- Add missing columns to submissions
ALTER TABLE submissions
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS content_hash VARCHAR(64),
ADD COLUMN IF NOT EXISTS content_preview_url TEXT,
ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS parent_submission_id UUID REFERENCES submissions(id),
ADD COLUMN IF NOT EXISTS last_accessed_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS metadata JSONB;

-- Create new tables that don't exist
CREATE TABLE IF NOT EXISTS platform_policies (...); -- Full definition from your script
CREATE TABLE IF NOT EXISTS platform_scans (...);
CREATE TABLE IF NOT EXISTS flagged_issues (...);
CREATE TABLE IF NOT EXISTS fix_suggestions (...);
CREATE TABLE IF NOT EXISTS reports (...);
CREATE TABLE IF NOT EXISTS feedback (...);
CREATE TABLE IF NOT EXISTS usage_logs (...);
CREATE TABLE IF NOT EXISTS audit_logs (...);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_creators_tier_status ON creators(subscription_tier, subscription_status);
CREATE INDEX IF NOT EXISTS idx_submissions_hash ON submissions(content_hash);
-- ... rest of indexes
