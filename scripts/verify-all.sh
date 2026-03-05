#!/bin/bash
echo "======================================"
echo "🔍 SeekReap Services Verification"
echo "======================================"

# Get tokens
TOKEN=$(gcloud auth print-identity-token)

# Tier-3 (Private)
echo -n "Tier-3 Core Engine: "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" https://seekreap-tier3-tif2gmgi4q-uc.a.run.app/health)
if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ OK (HTTP $HTTP_CODE)"
else
  echo "❌ FAILED (HTTP $HTTP_CODE)"
fi

# Tier-3 Database Health
echo -n "Tier-3 Database: "
curl -s -H "Authorization: Bearer $TOKEN" https://seekreap-tier3-tif2gmgi4q-uc.a.run.app/health/db | grep -q "connected" && echo "✅ OK" || echo "❌ FAILED"

# Tier-4 (Public)
echo -n "Tier-4 Orchestrator: "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://seekreap-tier4-tif2gmgi4q-uc.a.run.app/health)
if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ OK (HTTP $HTTP_CODE)"
else
  echo "❌ FAILED (HTTP $HTTP_CODE)"
fi

# Tier-4 Database Health
echo -n "Tier-4 Database: "
curl -s https://seekreap-tier4-tif2gmgi4q-uc.a.run.app/health/db | grep -q "connected" && echo "✅ OK" || echo "❌ FAILED"

# Tier-5 Backend
echo -n "Tier-5 Backend: "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://seekreap-backend-tif2gmgi4q-uc.a.run.app/health)
if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ OK (HTTP $HTTP_CODE)"
else
  echo "❌ FAILED (HTTP $HTTP_CODE)"
fi

# Tier-6 Frontend
echo -n "Tier-6 Frontend: "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://seekreap-production.web.app)
if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ OK (HTTP $HTTP_CODE)"
else
  echo "❌ FAILED (HTTP $HTTP_CODE)"
fi

echo "======================================"
