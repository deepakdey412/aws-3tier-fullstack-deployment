#!/usr/bin/env bash
# ============================================================
# check-prerequisites.sh — Verify all required tools are installed
# Usage: ./scripts/check-prerequisites.sh
# Compatible with: Linux, macOS, WSL, Git Bash (Windows)
# Note : other can also change this, I made it on my understanding
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC}  $*"; }
fail() { echo -e "  ${RED}✗${NC}  $*"; FAILED=1; }
warn() { echo -e "  ${YELLOW}!${NC}  $*"; }

FAILED=0

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Prerequisites Check                        ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ============================================================
# Node.js
# ============================================================
echo "── Node.js ────────────────────────────────────"

if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    NODE_MAJOR=${NODE_VERSION#v}
    NODE_MAJOR=${NODE_MAJOR%%.*}

    if [[ "$NODE_MAJOR" -ge 18 ]]; then
        ok "Node.js $NODE_VERSION (required: v18+)"
    else
        fail "Node.js $NODE_VERSION (required: v18+)"
    fi
else
    fail "Node.js not found (install from https://nodejs.org/)"
fi

if command -v npm >/dev/null 2>&1; then
    ok "npm $(npm --version)"
else
    fail "npm not found"
fi

# ============================================================
# Java
# ============================================================
echo ""
echo "── Java ───────────────────────────────────────"

if command -v java >/dev/null 2>&1; then
    JAVA_VERSION=$(java -version 2>&1 | awk -F\" '/version/ {print $2}')
    JAVA_MAJOR=${JAVA_VERSION%%.*}

    if [[ "$JAVA_MAJOR" -ge 21 ]]; then
        ok "Java $JAVA_VERSION (required: 21+)"
    else
        fail "Java $JAVA_VERSION (required: 21+)"
    fi
else
    fail "Java not found (install JDK 21+ from https://adoptium.net/)"
fi

# ============================================================
# Maven
# ============================================================
echo ""
echo "── Maven ──────────────────────────────────────"

if command -v mvn >/dev/null 2>&1; then
    MVN_VERSION=$(mvn --version | awk 'NR==1{print $3}')
    ok "Maven $MVN_VERSION"
else
    fail "Maven not found (install from https://maven.apache.org/)"
fi

# ============================================================
# Terraform
# ============================================================
echo ""
echo "── Terraform ──────────────────────────────────"

if command -v terraform >/dev/null 2>&1; then
    TF_VERSION=$(terraform version | awk 'NR==1{print $2}')
    ok "Terraform $TF_VERSION"
else
    fail "Terraform not found (install from https://terraform.io/)"
fi

# ============================================================
# AWS CLI
# ============================================================
echo ""
echo "── AWS CLI ────────────────────────────────────"

if command -v aws >/dev/null 2>&1; then
    AWS_VERSION=$(aws --version 2>&1 | awk '{print $1}' | cut -d/ -f2)
    ok "AWS CLI $AWS_VERSION"

    if aws sts get-caller-identity >/dev/null 2>&1; then
        AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)

        AWS_ARN=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null)
        AWS_USER="${AWS_ARN##*/}"

        ok "AWS credentials configured (Account: $AWS_ACCOUNT, User: $AWS_USER)"
    else
        warn "AWS CLI installed but not configured (run 'aws configure')"
    fi
else
    fail "AWS CLI not found (install from https://aws.amazon.com/cli/)"
fi

# ============================================================
# Git
# ============================================================
echo ""
echo "── Git ────────────────────────────────────────"

if command -v git >/dev/null 2>&1; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    ok "Git $GIT_VERSION"
else
    warn "Git not found (recommended for version control)"
fi

# ============================================================
# Additional Tools
# ============================================================
echo ""
echo "── Additional Tools ───────────────────────────"

if command -v curl >/dev/null 2>&1; then
    ok "curl installed"
else
    warn "curl not found (needed for API testing)"
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo "══════════════════════════════════════════════"

if [[ "$FAILED" -eq 0 ]]; then
    echo -e "  ${GREEN}All required tools are installed ✓${NC}"
    echo ""
    echo "  Next steps:"
    echo "    1. Configure Terraform: cd terraform/environments/prod"
    echo "    2. Edit terraform.tfvars with your settings"
    echo "    3. Run: terraform init"
    echo "    4. Run: terraform apply"
    echo "    5. Build: ./scripts/build.sh"
    echo "    6. Deploy: ./scripts/deploy.sh"
else
    echo -e "  ${RED}Some required tools are missing ✗${NC}"
    echo "  Please install the missing tools and try again"
fi

echo "══════════════════════════════════════════════"
echo ""

exit "$FAILED"