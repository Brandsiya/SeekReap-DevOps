#!/bin/bash
# SeekReap Production Database Auto-Tune
# Runs weekly maintenance to prevent bloat and optimize performance

set -e

# Configuration
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="$HOME/SeekReap-DevOps/logs/maintenance.log"
REPORT_FILE="$HOME/SeekReap-DevOps/logs/maintenance_report_$(date '+%Y%m%d').txt"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}[$TIMESTAMP] Starting SeekReap Database Auto-Tune${NC}" | tee -a "$LOG_FILE"

# Pre-maintenance snapshot
echo -e "${YELLOW}📊 Pre-maintenance table stats:${NC}" | tee -a "$LOG_FILE"
psql "$DATABASE_URL" -t -c "
SELECT 
    relname AS table_name,
    n_live_tup AS live_rows,
    n_dead_tup AS dead_rows,
    seq_scan,
    idx_scan,
    pg_size_pretty(pg_total_relation_size(relid)) AS size
FROM pg_stat_user_tables 
WHERE relname IN ('job_queue', 'pgqueuer_schedules', 'content_submissions', 'pgqueuer')
ORDER BY n_live_tup DESC;
" | tee -a "$REPORT_FILE"

# Run maintenance
echo -e "${YELLOW}🔧 Running maintenance operations...${NC}" | tee -a "$LOG_FILE"

# Vacuum high-churn tables
psql "$DATABASE_URL" << 'SQL' >> "$LOG_FILE" 2>&1
VACUUM (VERBOSE, ANALYZE) public.job_queue;
VACUUM (VERBOSE, ANALYZE) public.pgqueuer;
VACUUM (VERBOSE, ANALYZE) public.pgqueuer_schedules;
VACUUM (VERBOSE, ANALYZE) public.content_submissions;
SQL

# Reindex if table is large enough to benefit
JOB_QUEUE_SIZE=$(psql "$DATABASE_URL" -t -c "SELECT pg_total_relation_size('job_queue');")
if [ "$JOB_QUEUE_SIZE" -gt 10000000 ]; then  # 10MB threshold
    echo -e "${YELLOW}🔄 Reindexing job_queue (size: $(numfmt --to=iec $JOB_QUEUE_SIZE))${NC}" | tee -a "$LOG_FILE"
    psql "$DATABASE_URL" -c "REINDEX TABLE CONCURRENTLY public.job_queue;" >> "$LOG_FILE" 2>&1
fi

# Update statistics
echo -e "${YELLOW}📊 Updating statistics...${NC}" | tee -a "$LOG_FILE"
psql "$DATABASE_URL" -c "ANALYZE;" >> "$LOG_FILE" 2>&1

# Post-maintenance snapshot
echo -e "${YELLOW}📈 Post-maintenance table stats:${NC}" | tee -a "$LOG_FILE"
psql "$DATABASE_URL" -t -c "
SELECT 
    relname AS table_name,
    n_live_tup AS live_rows,
    n_dead_tup AS dead_rows,
    seq_scan,
    idx_scan,
    pg_size_pretty(pg_total_relation_size(relid)) AS size
FROM pg_stat_user_tables 
WHERE relname IN ('job_queue', 'pgqueuer_schedules', 'content_submissions', 'pgqueuer')
ORDER BY n_live_tup DESC;
" | tee -a "$REPORT_FILE"

# Check for tables needing attention
echo -e "${YELLOW}🔍 Health check:${NC}" | tee -a "$LOG_FILE"
psql "$DATABASE_URL" -t -c "
SELECT 
    relname,
    CASE 
        WHEN n_dead_tup > 1000 THEN '⚠️  High dead tuples - VACUUM more frequently'
        WHEN seq_scan > idx_scan * 10 AND n_live_tup > 1000 THEN '⚠️  High seq scans - Check indexes'
        ELSE '✅ Healthy'
    END AS recommendation
FROM pg_stat_user_tables
WHERE relname IN ('job_queue', 'pgqueuer', 'content_submissions')
AND n_live_tup > 1000;
" | tee -a "$REPORT_FILE"

echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] Auto-Tune complete! Report saved to: $REPORT_FILE${NC}" | tee -a "$LOG_FILE"
