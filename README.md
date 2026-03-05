```markdown
# 🚀 SeekReap-DevOps

Enterprise-grade infrastructure management for SeekReap's Pre-Flag Minimization service. This repository contains all deployment scripts, database schemas, monitoring tools, and automation for the entire SeekReap platform.

## 📋 Overview

SeekReap helps content creators protect their revenue by identifying demonetization risks before posting and preparing evidence-backed appeals.

| Tier | Component | Technology | Purpose |
|------|-----------|------------|---------|
| Tier-3 | Core Engine | Cloud Run (FastAPI) | Content analysis & policy checking |
| Tier-4 | Orchestrator | Cloud Run (Flask) | Workflow coordination |
| Tier-5 | Backend API | Cloud Run | Business logic & data serving |
| Tier-6 | Frontend | Firebase Hosting | Creator dashboard |

## 🗂️ Repository Structure

```

SeekReap-DevOps/
├── scripts/           # Deployment & maintenance scripts
│   ├── deploy-all.sh  # Full system deployment
│   ├── db_autotune_enhanced.sh  # Weekly database maintenance
│   ├── auto_tune_runner.sh      # Manual tune-up runner
│   └── surgical_deploy.sh       # Schema enhancement
│
├── schemas/           # Database schema versions
│   ├── versions/
│   │   ├── v2.0.0.sql  # Initial enhanced schema
│   │   └── v2.1.0.sql  # Current with improvement_score
│   ├── health_check_comprehensive.sql  # Full health check
│   ├── monitor_recovery_fixed.sql      # Queue monitoring
│   ├── check_stalled_jobs_fixed.sql    # Stalled job detection
│   └── queue_inspector.sql             # Queue analysis
│
├── config/            # Configuration files
│   ├── crontab        # Automated maintenance schedule
│   └── dashboard.yaml # Monitoring dashboard config
│
├── monitoring/        # Health check queries
├── backups/           # Database backups (gitignored)
├── logs/              # Operation logs (gitignored)
└── docs/              # Additional documentation

```

## 🚀 Quick Start

### Prerequisites
- PostgreSQL client (psql)
- Google Cloud SDK (gcloud)
- Firebase CLI
- Access to Neon database

### Environment Variables
```bash
export DATABASE_URL="postgresql://user:pass@host:5432/db?sslmode=require"
export GCP_PROJECT="seekreap-production"
```

Deploy Everything

```bash
git clone https://github.com/Brandsiya/SeekReap-DevOps.git
cd SeekReap-DevOps
./scripts/deploy-all.sh
```

📊 Monitoring & Maintenance

Automated Tasks (via crontab)

Schedule Task Description
Sunday 12:05 AM db_autotune_enhanced.sh Weekly database maintenance
Daily 2 AM Health Check Full system health report
1st of month 3 AM VACUUM ANALYZE Monthly cleanup
Every 15 min Stalled Job Check Detect failing jobs

Manual Health Checks

```bash
# Full system status
./scripts/verify-services.sh

# Queue analysis
psql $DATABASE_URL -f schemas/queue_inspector.sql

# Stalled jobs
psql $DATABASE_URL -f schemas/check_stalled_jobs_fixed.sql
```

🔧 Key Scripts

Script Purpose
deploy-all.sh Complete system deployment
db_autotune_enhanced.sh Weekly maintenance
surgical_deploy.sh Schema enhancements
verify-services.sh Service health check
test_creator_flow_fixed.sql Test data setup

📈 Database Schema (v2.1.0)

Core Tables

· creators - User accounts with subscription tiers
· content_submissions - Videos/content being analyzed
· platform_scans - Risk analysis results per platform
· flagged_issues - Specific policy violations
· fix_suggestions - Automated remediation advice
· job_queue - Background processing queue

Key Indexes

```sql
-- Performance critical indexes
CREATE INDEX IF NOT EXISTS idx_job_queue_status ON job_queue(status, created_at);
CREATE INDEX IF NOT EXISTS idx_content_submissions_hash ON content_submissions(content_hash);
CREATE INDEX IF NOT EXISTS idx_flagged_issues_severity ON flagged_issues(severity);
```

🔐 Security & Compliance

· Foreign Key Constraints - Data integrity enforced
· Audit Logs - Complete change history
· IP Tracking - GDPR/CCPA ready
· Backup Rotation - 30-day retention

📊 Current Production Status

Service Status URL
Tier-3 Core Engine ✅ Active https://seekreap-tier3-tif2gmgi4q-uc.a.run.app
Tier-4 Orchestrator ✅ Active https://seekreap-tier4-tif2gmgi4q-uc.a.run.app
Tier-5 Backend ✅ Active https://seekreap-backend-tif2gmgi4q-uc.a.run.app
Tier-6 Frontend ✅ Active https://seekreap-production.web.app

🤝 Contributing

1. Fork the repository
2. Create a feature branch (git checkout -b feature/AmazingFeature)
3. Commit changes (git commit -m 'Add AmazingFeature')
4. Push to branch (git push origin feature/AmazingFeature)
5. Open a Pull Request

📝 License

Copyright © 2026 SeekReap. All rights reserved.

🏆 Acknowledgments

· Built with Cloud Run, Neon PostgreSQL, and Firebase
· Monitoring with Google Cloud Operations
· Automated with crontab and bash scripts

---

⭐ Star this repo if you find it useful!

```
