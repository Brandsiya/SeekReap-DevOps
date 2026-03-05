#!/bin/bash
# SeekReap Schema Audit Only (Skip Migration)

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$HOME/SeekReap-DevOps/logs/schema_audit_${TIMESTAMP}.log"

mkdir -p "$HOME/SeekReap-DevOps/logs"

echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] Starting Schema Audit...${NC}" | tee -a "$LOG_FILE"

# Test connection
if ! psql "$DATABASE_URL" -c "SELECT 1" > /dev/null 2>&1; then
    echo -e "${RED}❌ Cannot connect to database${NC}" | tee -a "$LOG_FILE"
    exit 1
fi

echo -e "${GREEN}✅ Database connection successful${NC}" | tee -a "$LOG_FILE"

# Run comprehensive audit
psql "$DATABASE_URL" << 'SQL' | tee -a "$LOG_FILE"
\x on
SELECT '📊 SEEKREAP SCHEMA AUDIT REPORT' as " ";
SELECT CURRENT_TIMESTAMP as "Audit Time";

SELECT '📋 TABLE INVENTORY' as " ";
SELECT 
    tablename,
    tableowner,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

SELECT '🔑 PRIMARY KEYS' as " ";
SELECT
    tc.table_name, 
    kc.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kc 
    ON kc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'PRIMARY KEY'
    AND tc.table_schema = 'public'
ORDER BY tc.table_name;

SELECT '🔗 FOREIGN KEYS' as " ";
SELECT
    conname AS constraint_name,
    conrelid::regclass AS table_name,
    confrelid::regclass AS foreign_table
FROM pg_constraint
WHERE contype = 'f' AND conrelid::regclass::text IN (
    'submissions', 'platform_scans', 'flagged_issues', 
    'fix_suggestions', 'reports', 'feedback', 'usage_logs'
);

SELECT '📈 INDEX USAGE STATISTICS' as " ";
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan as "Index Scans"
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

SELECT '📊 TABLE ACTIVITY' as " ";
SELECT
    relname AS table_name,
    n_tup_ins AS "Inserts",
    n_tup_upd AS "Updates",
    n_tup_del AS "Deletes",
    seq_scan as "Seq Scans",
    idx_scan as "Idx Scans"
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY relname;

SELECT '✅ SCHEMA STATUS' as " ";
SELECT 
    'All tables present' as status
WHERE (
    SELECT COUNT(*) = 10
    FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename IN (
        'platform_policies', 'creators', 'submissions', 'platform_scans',
        'flagged_issues', 'fix_suggestions', 'reports', 'feedback',
        'usage_logs', 'audit_logs'
    )
) IS TRUE;
SQL

echo -e "${GREEN}========================================${NC}" | tee -a "$LOG_FILE"
echo -e "${GREEN}✅ Schema Audit Complete!${NC}" | tee -a "$LOG_FILE"
echo -e "${GREEN}📋 Log saved to: $LOG_FILE${NC}" | tee -a "$LOG_FILE"
echo -e "${GREEN}========================================${NC}" | tee -a "$LOG_FILE"
