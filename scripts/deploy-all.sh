#!/bin/bash
# Full system deployment

set -e

echo "🚀 Deploying SeekReap Infrastructure..."

# 1. Database schema
echo "📊 Applying database schema..."
psql "$DATABASE_URL" -f schemas/versions/v2.1.0.sql

# 2. Set up monitoring
echo "📈 Configuring monitoring..."
crontab ./config/crontab

# 3. Deploy Cloud Run services
echo "☁️ Deploying Tier-3..."
gcloud run deploy seekreap-tier3 --source ../SeekReap-Tier-3-Private --region us-central1 --no-allow-unauthenticated

echo "☁️ Deploying Tier-4..."
gcloud run deploy seekreap-tier4 --source ../SeekReap-Tier-4-Orchestrator --region us-central1 --allow-unauthenticated

echo "☁️ Deploying Tier-5..."
gcloud run deploy seekreap-backend --source ../SeekReap-Tier-6-Dashboard/backend --region us-central1 --allow-unauthenticated

# 4. Deploy frontend
echo "🌐 Deploying Tier-6..."
cd ../SeekReap-Tier-6-Frontend && firebase deploy --only hosting

echo "✅ Deployment complete!"
