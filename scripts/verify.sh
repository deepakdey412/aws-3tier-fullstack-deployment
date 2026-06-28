#!/usr/bin/env bash
# ============================================================
# verify.sh — Health check the full 3-tier stack post-deploy
# Usage: ./scripts/verify.sh [--wait]
# ============================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT/terraform/environments/prod"
WAIT_MODE="${1:-}"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}✓${NC}  $*"; }
fail() { echo -e "  ${RED}✗${NC}  $*"; FAILURES=$((FAILURES+1)); }
info() { echo -e "  ${BLUE}ℹ${NC}  $*"; }
FAILURES=0

# ── Read Terraform outputs ────────────────
cd "$TF_DIR"
WEB_ALB=$(terraform output -raw web_alb_dns_name 2>/dev/null) || { echo "Run terraform apply first"; exit 1; }
S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null)
WEB_ASG=$(terraform output -raw web_asg_name     2>/dev/null)
APP_ASG=$(terraform output -raw app_asg_name     2>/dev/null)
AWS_REGION=$(grep -E '^aws_region' terraform.tfvars 2>/dev/null | cut -d'"' -f2 || echo "ap-south-1")

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   3-Tier AWS App — Verification Report       ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── 1. Web ALB Health ─────────────────────
echo "── 1. Web ALB (Internet-Facing) ──────────────"
WEB_URL="http://$WEB_ALB"

if [[ "$WAIT_MODE" == "--wait" ]]; then
  info "Waiting for ALB to respond (up to 5 min)…"
  for i in $(seq 1 30); do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$WEB_URL" 2>/dev/null || echo "000")
    [[ "$HTTP_CODE" =~ ^[23] ]] && break
    echo "  Attempt $i/30 — got $HTTP_CODE, retrying in 10s…"
    sleep 10
  done
fi

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$WEB_URL" 2>/dev/null || echo "000")
if [[ "$HTTP_CODE" =~ ^[23] ]]; then
  ok "Web ALB responding: HTTP $HTTP_CODE → $WEB_URL"
else
  fail "Web ALB not responding (got HTTP $HTTP_CODE) → $WEB_URL"
fi

# ── 2. API Health endpoint ────────────────
echo ""
echo "── 2. Backend API (/api/health) ──────────────"
API_URL="$WEB_URL/api/health"
API_CODE=$(curl -s -o /tmp/api_health.json -w "%{http_code}" --max-time 10 "$API_URL" 2>/dev/null || echo "000")
if [[ "$API_CODE" == "200" ]]; then
  HEALTH_STATUS=$(python3 -c "import json,sys; d=json.load(open('/tmp/api_health.json')); print(d.get('data',{}).get('status','?'))" 2>/dev/null || echo "?")
  ok "API health check: HTTP 200 — status=$HEALTH_STATUS"
else
  fail "API health check failed: HTTP $API_CODE → $API_URL"
fi

# ── 3. Items CRUD smoke test ──────────────
echo ""
echo "── 3. CRUD Smoke Test ────────────────────────"
ITEMS_URL="$WEB_URL/api/items"

# Create
CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$ITEMS_URL" \
  -H "Content-Type: application/json" \
  -d '{"name":"verify-test-item","description":"Created by verify.sh","quantity":1}' \
  --max-time 15 2>/dev/null || echo -e "\n000")

HTTP_CODE=$(echo "$CREATE_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$CREATE_RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" =~ ^20[01]$ ]]; then
  ITEM_ID=$(echo "$RESPONSE_BODY" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('id',''))" 2>/dev/null || echo "")
  if [[ -n "$ITEM_ID" ]]; then
    ok "POST /api/items → HTTP $HTTP_CODE, created id=$ITEM_ID"
  else
    ok "POST /api/items → HTTP $HTTP_CODE (success)"
  fi
else
  fail "POST /api/items → HTTP $HTTP_CODE"
  ITEM_ID=""  # Set empty to avoid unbound variable
fi

# Read all
LIST_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$ITEMS_URL" --max-time 10 2>/dev/null || echo "000")
[[ "$LIST_CODE" == "200" ]] && ok "GET /api/items → HTTP 200" || fail "GET /api/items → HTTP $LIST_CODE"

# Update (only if we created an item)
if [[ -n "${ITEM_ID:-}" && "$ITEM_ID" != "None" && "$ITEM_ID" != "" ]]; then
  UPD_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$ITEMS_URL/$ITEM_ID" \
    -H "Content-Type: application/json" \
    -d '{"name":"verify-test-item","description":"Updated by verify.sh","quantity":99}' \
    --max-time 10 2>/dev/null || echo "000")
  [[ "$UPD_CODE" == "200" ]] && ok "PUT /api/items/$ITEM_ID → HTTP 200" || fail "PUT /api/items/$ITEM_ID → HTTP $UPD_CODE"

  # Delete
  DEL_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$ITEMS_URL/$ITEM_ID" --max-time 10 2>/dev/null || echo "000")
  [[ "$DEL_CODE" == "200" ]] && ok "DELETE /api/items/$ITEM_ID → HTTP 200" || fail "DELETE /api/items/$ITEM_ID → HTTP $DEL_CODE"
fi

# ── 4. ASG Status ─────────────────────────
echo ""
echo "── 4. Auto Scaling Groups ────────────────────"
check_asg() {
  local name="$1" label="$2"
  local COUNT
  COUNT=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$name" \
    --region "$AWS_REGION" \
    --query 'AutoScalingGroups[0].Instances[?LifecycleState==`InService`] | length(@)' \
    --output text 2>/dev/null || echo "0")
  if [[ "$COUNT" -gt 0 ]]; then
    ok "$label ASG: $COUNT instance(s) InService"
  else
    fail "$label ASG: 0 instances InService — check AWS console"
  fi
}
check_asg "$WEB_ASG" "Web"
check_asg "$APP_ASG" "App"

# ── 5. S3 Artifacts ───────────────────────
echo ""
echo "── 5. S3 Build Artifacts ─────────────────────"
check_s3() {
  local key="$1"
  aws s3 ls "s3://$S3_BUCKET/$key" --region "$AWS_REGION" >/dev/null 2>&1 \
    && ok "s3://$S3_BUCKET/$key ✓" \
    || fail "s3://$S3_BUCKET/$key — not found (run deploy.sh)"
}
check_s3 "builds/frontend/dist.tar.gz"
check_s3 "builds/backend/app.jar"

# ── Summary ───────────────────────────────
echo ""
echo "══════════════════════════════════════════════"
if [[ "$FAILURES" -eq 0 ]]; then
  echo -e "  ${GREEN}All checks passed ✓${NC}"
  echo ""
  echo "  App URL : $WEB_URL"
else
  echo -e "  ${RED}$FAILURES check(s) failed ✗${NC}"
  echo "  Review the failures above and check:"
  echo "    • AWS Console → EC2 → Target Groups (health)"
  echo "    • Instance logs: /var/log/userdata.log"
  echo "    • App logs: /opt/app/logs/spring.log"
fi
echo "══════════════════════════════════════════════"
echo ""
exit $FAILURES
