#!/bin/bash
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}   SeekReap Services Verification       ${NC}"
echo -e "${YELLOW}========================================${NC}"

# Get auth token for private services
TOKEN=$(gcloud auth print-identity-token)

# Function to check service
check_service() {
    local name=$1
    local url=$2
    local auth=$3
    
    echo -n "$name: "
    
    if [ "$auth" = "true" ]; then
        curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" "$url/health" | grep -q "200" && \
            echo -e "${GREEN}✅ OK${NC}" || echo -e "${RED}❌ Failed${NC}"
    else
        curl -s -o /dev/null -w "%{http_code}" "$url/health" | grep -q "200" && \
            echo -e "${GREEN}✅ OK${NC}" || echo -e "${RED}❌ Failed${NC}"
    fi
}

# Check each service
check_service "Tier-3 Core Engine" "https://seekreap-tier3-tif2gmgi4q-uc.a.run.app" "true"
check_service "Tier-4 Orchestrator" "https://seekreap-tier4-tif2gmgi4q-uc.a.run.app" "false"
check_service "Tier-5 Backend" "https://seekreap-backend-tif2gmgi4q-uc.a.run.app" "false"

# Check frontend separately
echo -n "Tier-6 Frontend: "
curl -s -o /dev/null -w "%{http_code}" "https://seekreap-production.web.app" | grep -q "200" && \
    echo -e "${GREEN}✅ OK${NC}" || echo -e "${RED}❌ Failed${NC}"

echo -e "${YELLOW}========================================${NC}"
