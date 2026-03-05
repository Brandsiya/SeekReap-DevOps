#!/bin/bash
# Simple auto-tune runner for UserLAnd
# Run this manually or set up with Termux shortcuts

echo "========================================"
echo "🚀 SeekReap Database Auto-Tune"
echo "========================================"
echo ""

# Run the enhanced tune script
~/SeekReap-DevOps/scripts/db_autotune_enhanced.sh

echo ""
echo "✅ Auto-tune completed at $(date)"
echo "📊 Check logs in ~/SeekReap-DevOps/logs/"
echo ""
