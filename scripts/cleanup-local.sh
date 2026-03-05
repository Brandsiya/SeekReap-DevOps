#!/bin/bash
echo "🧹 Cleaning up local environment..."

# Clean Python cache
find ~ -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
find ~ -type f -name "*.pyc" -delete

# Clean gcloud staging
rm -rf ~/google-cloud-sdk/.staging/*

# Check disk space
df -h /

# Show top directories by size
du -sh ~/* | sort -h | tail -10

echo "✅ Cleanup complete!"
