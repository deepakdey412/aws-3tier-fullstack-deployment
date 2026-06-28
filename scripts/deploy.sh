#!/usr/bin/env bash
# ============================================================
# deploy.sh — Upload artifacts to S3 and trigger ASG refresh
# Usage: ./scripts/deploy.sh
# Prereqs: terraform apply completed, AWS CLI configured,
#          build.sh run first
# ============================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT/terraform/environments/prod"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[DEPLOY]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}   $*"; }
die()  { echo -e "${RED}[ERROR]${NC}  $*" >&2; exit 1; }

# ── Preflight ─────────────────────────────
command -v aws     >/dev/null 2>&1 || die "AWS CLI required (https://aws.amazon.com/cli/)"
command -v terraform >/dev/null 2>&1 || die "Terraform required"

[[ -f "$ROOT/dist/frontend/dist.tar.gz" ]] || die "Frontend build not found — run ./scripts/build.sh first"
[[ -f "$ROOT/dist/backend/app.jar"      ]] || die "Backend JAR not found — run ./scripts/build.sh first"

# ── Pull Terraform outputs ────────────────
log "Reading Terraform outputs…"
cd "$TF_DIR"

S3_BUCKET=$(terraform output -raw s3_bucket_name    2>/dev/null) || die "Cannot read s3_bucket_name from Terraform output"
WEB_ASG=$(terraform output -raw web_asg_name        2>/dev/null) || die "Cannot read web_asg_name"
APP_ASG=$(terraform output -raw app_asg_name        2>/dev/null) || die "Cannot read app_asg_name"

# Read AWS region from terraform.tfvars file
AWS_REGION=$(grep -E '^aws_region' "$TF_DIR/terraform.tfvars" 2>/dev/null | cut -d'"' -f2 || echo "ap-south-1")

log "S3 bucket : $S3_BUCKET"
log "Web ASG   : $WEB_ASG"
log "App ASG   : $APP_ASG"
log "Region    : $AWS_REGION"
echo ""

# ── Upload Frontend ───────────────────────
log "=== Uploading Frontend build to S3 ==="
aws s3 cp "$ROOT/dist/frontend/dist.tar.gz" \
  "s3://$S3_BUCKET/builds/frontend/dist.tar.gz" \
  --region "$AWS_REGION"
log "Frontend uploaded ✓"
echo ""

# ── Upload Backend ────────────────────────
log "=== Uploading Backend JAR to S3 ==="
aws s3 cp "$ROOT/dist/backend/app.jar" \
  "s3://$S3_BUCKET/builds/backend/app.jar" \
  --region "$AWS_REGION"
log "Backend JAR uploaded ✓"
echo ""

# ── Trigger Web ASG Instance Refresh ──────
log "=== Triggering Web ASG instance refresh ==="
REFRESH_ID_WEB=$(aws autoscaling start-instance-refresh \
  --auto-scaling-group-name "$WEB_ASG" \
  --preferences '{"MinHealthyPercentage":50,"InstanceWarmup":120}' \
  --region "$AWS_REGION" \
  --query 'InstanceRefreshId' \
  --output text)
log "Web refresh started: $REFRESH_ID_WEB"

# ── Trigger App ASG Instance Refresh ──────
log "=== Triggering App ASG instance refresh ==="
REFRESH_ID_APP=$(aws autoscaling start-instance-refresh \
  --auto-scaling-group-name "$APP_ASG" \
  --preferences '{"MinHealthyPercentage":50,"InstanceWarmup":180}' \
  --region "$AWS_REGION" \
  --query 'InstanceRefreshId' \
  --output text)
log "App refresh started: $REFRESH_ID_APP"
echo ""

# ── Show DNS ──────────────────────────────
WEB_ALB=$(terraform output -raw web_alb_dns_name 2>/dev/null || echo "check terraform output")
log "=== Deployment Initiated ==="
echo ""
echo "  Artifacts are in S3. Instances are being refreshed."
echo "  New instances will pull fresh builds on startup."
echo ""
echo "  Web ALB URL : http://$WEB_ALB"
echo ""
echo "  Monitor refresh progress:"
echo "    aws autoscaling describe-instance-refreshes \\"
echo "      --auto-scaling-group-name $WEB_ASG \\"
echo "      --region $AWS_REGION"
echo ""
echo "  Next step:  ./scripts/verify.sh"
