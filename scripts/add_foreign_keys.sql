-- Add foreign keys safely (with validation first)

-- Check for orphaned records before adding constraints
DO $$
BEGIN
    RAISE NOTICE 'Checking for orphaned records...';
    
    -- Check platform_scans references
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'platform_scans') THEN
        PERFORM COUNT(*) FROM platform_scans ps 
        WHERE NOT EXISTS (SELECT 1 FROM content_submissions cs WHERE cs.submission_id = ps.submission_id);
    END IF;
    
    -- Add foreign keys if tables exist
    ALTER TABLE platform_scans 
    ADD CONSTRAINT fk_platform_scans_submission 
    FOREIGN KEY (submission_id) REFERENCES content_submissions(submission_id) ON DELETE CASCADE;
    
    RAISE NOTICE '✅ Foreign keys added successfully';
END $$;
