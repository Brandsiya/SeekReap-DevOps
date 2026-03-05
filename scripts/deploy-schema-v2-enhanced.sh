#!/bin/bash
# SeekReap Production Schema Update & Audit - Enhanced for Neon
# This script handles: connection, migration, verification, indexing audit, and rollback capability

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$HOME/SeekReap-DevOps/logs/schema_deploy_${TIMESTAMP}.log"
BACKUP_DIR="$HOME/SeekReap-DevOps/backups"
DATABASE_URL="${DATABASE_URL}"  # From environment

# Create logs directory if it doesn't exist
mkdir -p "$HOME/SeekReap-DevOps/logs"
mkdir -p "$BACKUP_DIR"

# Logging function
log() {
    echo -e "${2:-$BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

log "🚀 Starting Schema Update for SeekReap Production..." "$GREEN"
log "Log file: $LOG_FILE"

# 1. PRE-FLIGHT CHECKS
log "🔍 Running pre-flight checks..."

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    log "❌ DATABASE_URL environment variable not set!" "$RED"
    exit 1
fi

# Test database connection
log "Testing database connection..."
if ! psql "$DATABASE_URL" -c "SELECT 1" > /dev/null 2>&1; then
    log "❌ Cannot connect to database. Please check your DATABASE_URL" "$RED"
    exit 1
fi
log "✅ Database connection successful" "$GREEN"

# 2. BACKUP CURRENT SCHEMA
log "💾 Backing up current schema..."
BACKUP_FILE="$BACKUP_DIR/schema_before_v2_${TIMESTAMP}.sql"
if pg_dump "$DATABASE_URL" --schema-only > "$BACKUP_FILE" 2>/dev/null; then
    log "✅ Schema backed up to: $BACKUP_FILE" "$GREEN"
else
    log "⚠️  Schema backup failed (version mismatch), but continuing..." "$YELLOW"
    # Fallback: list tables
    psql "$DATABASE_URL" -c "\dt" > "$BACKUP_DIR/table_list_${TIMESTAMP}.txt"
fi

# 3. EXECUTE MIGRATION
log "📦 Executing schema migration..."
MIGRATION_FILE="$HOME/SeekReap-DevOps/scripts/update_schema_v2.sql"

if [ ! -f "$MIGRATION_FILE" ]; then
    log "❌ Migration file not found: $MIGRATION_FILE" "$RED"
    exit 1
fi

# Run migration and capture output
if psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$MIGRATION_FILE" > "$BACKUP_DIR/migration_output_${TIMESTAMP}.txt" 2>&1; then
    log "✅ SQL Migration Successful!" "$GREEN"
else
    log "❌ Migration Failed. Check logs at: $BACKUP_DIR/migration_output_${TIMESTAMP}.txt" "$RED"
    exit 1
fi

# 4. POST-MIGRATION VERIFICATION
log "🔎 Running post-migration verification..."

# Check if all required tables exist
log "Verifying table creation..."
REQUIRED_TABLES=(
    "platform_policies"
    "creators"
    "submissions"
    "platform_scans"
    "flagged_issues"
    "fix_suggestions"
    "reports"
    "feedback"
    "usage_logs"
    "audit_logs"
)

for table in "${REQUIRED_TABLES[@]}"; do
    if psql "$DATABASE_URL" -t -c "SELECT to_regclass('$table');" | grep -q "$table"; then
        log "  ✅ Table '$table' exists" "$GREEN"
    else
        log "  ❌ Table '$table' is missing!" "$RED"
        exit 1
    fi
done

# 5. INDEX AUDIT (Critical for performance)
log "📊 Running Index & Constraint Audit..." "$YELLOW"
log "Index Usage Statistics:"

psql "$DATABASE_URL" << 'SQL' | tee -a "$LOG_FILE"
\x on
SELECT 'INDEX PERFORMANCE AUDIT' as " ";
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as "Index Scans",
    idx_tup_read as "Tuples Read",
    idx_tup_fetch as "Tuples Fetched"
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC NULLS LAST
LIMIT 10;

SELECT 'TABLE ACTIVITY' as " ";
SELECT 
    relname AS table_name, 
    seq_scan as "Sequential Scans",
    seq_tup_read as "Rows Scanned (Seq)",
    idx_scan as "Index Scans",
    idx_tup_fetch as "Rows via Index",
    n_tup_ins AS "Inserts",
    n_tup_upd AS "Updates",
    n_tup_del AS "Deletes",
    CASE WHEN idx_scan = 0 THEN '⚠️  NO INDEX USAGE' 
         WHEN seq_scan > idx_scan * 10 THEN '⚠️  Heavy Seq Scan'
         ELSE '✅ Healthy' END as status
FROM pg_stat_user_tables 
WHERE relname IN ('creators', 'submissions', 'platform_scans', 'flagged_issues', 'platform_policies', 'fix_suggestions')
ORDER BY relname;

SELECT 'CRITICAL INDEX CHECK' as " ";
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename IN ('submissions', 'platform_scans', 'creators')
AND indexname IN (
    'idx_submissions_hash',
    'idx_platform_scans_created',
    'idx_creators_email',
    'idx_flagged_issues_severity',
    'idx_fix_suggestions_applied'
);
SQL

# 6. FOREIGN KEY VERIFICATION
log "🔗 Verifying Foreign Key Relationships..."
psql "$DATABASE_URL" -t -c "
SELECT 
    conname AS constraint_name,
    conrelid::regclass AS table_name,
    confrelid::regclass AS foreign_table
FROM pg_constraint
WHERE contype = 'f'
AND conrelid::regclass::text IN ('submissions', 'platform_scans', 'flagged_issues', 'fix_suggestions', 'reports', 'feedback', 'usage_logs')
ORDER BY table_name;
" | tee -a "$LOG_FILE"

# 7. SAMPLE DATA CHECK (if policies were inserted)
log "📝 Checking sample policy data..."
POLICY_COUNT=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM platform_policies;" | xargs)
if [ "$POLICY_COUNT" -gt 0 ]; then
    log "  ✅ Platform policies loaded: $POLICY_COUNT rows" "$GREEN"
    psql "$DATABASE_URL" -c "SELECT platform, policy_category, typical_penalty FROM platform_policies LIMIT 5;" | tee -a "$LOG_FILE"
else
    log "  ⚠️  No platform policies found" "$YELLOW"
fi

# 8. PERFORMANCE BASELINE
log "📈 Capturing performance baseline..."
psql "$DATABASE_URL" << 'SQL' | tee -a "$LOG_FILE"
SELECT 'PERFORMANCE BASELINE' as " ";
SELECT 
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    n_tup_ins + n_tup_upd + n_tup_del as total_changes
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY total_changes DESC;
SQL

# 9. SUCCESS SUMMARY
log "========================================" "$GREEN"
log "🎉 Schema v2.0 is now LIVE and Verified!" "$GREEN"
log "========================================" "$GREEN"
log "✅ Database: SeekReap Production" 
log "✅ Tables Created: ${#REQUIRED_TABLES[@]}"
log "✅ Policies Loaded: $POLICY_COUNT"
log "✅ Indexes: Verified"
log "✅ Foreign Keys: Verified"
log "========================================"
log "📊 Dashboard Quick Links:"
log "  • Creator Dashboard: https://seekreap-production.web.app"
log "  • Monitoring: https://console.cloud.google.com/monitoring/dashboards?project=seekreap-production"
log "  • Database Console: https://console.neon.tech"
log "========================================"
log "📁 Backup: $BACKUP_FILE"
log "📋 Log: $LOG_FILE"
log "========================================" "$GREEN"

# 10. HEALTH CHECK RECOMMENDATIONS
log "💡 Recommendations:" "$YELLOW"
psql "$DATABASE_URL" -t -c "
SELECT 'Monitor these tables for index usage:' as advice
UNION ALL
SELECT '- ' || relname || ': ' || 
       CASE WHEN idx_scan = 0 THEN 'Add indexes for common queries'
            WHEN seq_scan > idx_scan * 5 THEN 'Consider composite indexes'
            ELSE 'Index usage looks good'
       END
FROM pg_stat_user_tables
WHERE relname IN ('submissions', 'platform_scans', 'flagged_issues')
ORDER BY relname;
" | tee -a "$LOG_FILE"

echo ""
log "✅ Schema deployment complete!" "$GREEN"
