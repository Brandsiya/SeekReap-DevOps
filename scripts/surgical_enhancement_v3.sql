-- Set search path explicitly to avoid "relation not found" errors
SET search_path TO public, pg_catalog;

-- 1. ENHANCE CREATORS
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'creators') THEN
        ALTER TABLE public.creators ADD COLUMN IF NOT EXISTS company_name VARCHAR(255);
        ALTER TABLE public.creators ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(50) DEFAULT 'active';
        ALTER TABLE public.creators ADD COLUMN IF NOT EXISTS billing_cycle DATE;
        ALTER TABLE public.creators ADD COLUMN IF NOT EXISTS last_login_ip INET;
        RAISE NOTICE '✅ public.creators enhanced';
    END IF;
END $$;

-- 2. ENHANCE CONTENT_SUBMISSIONS
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'content_submissions') THEN
        ALTER TABLE public.content_submissions ADD COLUMN IF NOT EXISTS content_hash VARCHAR(64);
        ALTER TABLE public.content_submissions ADD COLUMN IF NOT EXISTS overall_risk_score DECIMAL(5,2);
        ALTER TABLE public.content_submissions ADD COLUMN IF NOT EXISTS risk_level VARCHAR(20);
        RAISE NOTICE '✅ public.content_submissions enhanced';
    END IF;
END $$;

-- 3. PERFORMANCE INDEXES (Force Public Schema)
CREATE INDEX IF NOT EXISTS idx_job_queue_perf ON public.job_queue(status, created_at);
CREATE INDEX IF NOT EXISTS idx_submissions_perf_hash ON public.content_submissions(content_hash);

-- 4. CREATE NEW SUPPORT TABLES
CREATE TABLE IF NOT EXISTS public.platform_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    platform VARCHAR(50) NOT NULL,
    policy_category VARCHAR(100) NOT NULL,
    typical_penalty VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. FINAL VERIFICATION
SELECT tablename, tableowner FROM pg_tables WHERE schemaname = 'public' AND tablename IN ('creators', 'content_submissions', 'platform_policies');
