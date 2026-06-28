#!/usr/bin/env bash
# ============================================================
# validate-project.sh — Validate project structure and files
# Usage: ./scripts/validate-project.sh
# ============================================================
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}✓${NC}  $*"; }
fail() { echo -e "  ${RED}✗${NC}  $*"; FAILED=1; }
FAILED=0

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   Project Structure Validation                ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

check_file() {
  local file="$1"
  local desc="$2"
  if [[ -f "$ROOT/$file" ]]; then
    ok "$desc"
  else
    fail "$desc missing: $file"
  fi
}

check_dir() {
  local dir="$1"
  local desc="$2"
  if [[ -d "$ROOT/$dir" ]]; then
    ok "$desc"
  else
    fail "$desc missing: $dir"
  fi
}

# Project Root Files
echo "── Project Root ───────────────────────────────"
check_file "README.md" "README.md"
check_file ".gitignore" ".gitignore"
check_file ".gitattributes" ".gitattributes"

# Application Structure
echo ""
echo "── Application (Frontend + Backend) ───────────"
check_dir "application" "application directory"
check_dir "application/frontend" "frontend directory"
check_dir "application/backend" "backend directory"

# Frontend
echo ""
echo "── Frontend (React + Vite) ────────────────────"
check_file "application/frontend/package.json" "package.json"
check_file "application/frontend/vite.config.js" "vite.config.js"
check_file "application/frontend/index.html" "index.html"
check_file "application/frontend/.eslintrc.cjs" "ESLint config"
check_file "application/frontend/src/main.jsx" "Main entry"
check_file "application/frontend/src/App.jsx" "App component"
check_file "application/frontend/src/index.css" "Global styles"
check_file "application/frontend/src/services/itemService.js" "API service"
check_file "application/frontend/src/hooks/useItems.js" "Items hook"
check_file "application/frontend/src/components/ItemForm.jsx" "ItemForm component"
check_file "application/frontend/src/components/ItemTable.jsx" "ItemTable component"
check_file "application/frontend/src/components/SearchBar.jsx" "SearchBar component"

# Backend
echo ""
echo "── Backend (Spring Boot) ──────────────────────"
check_file "application/backend/pom.xml" "pom.xml"
check_file "application/backend/src/main/resources/application.yml" "application.yml"
check_file "application/backend/src/main/java/com/app/crud/CrudApplication.java" "Main application"
check_file "application/backend/src/main/java/com/app/crud/model/Item.java" "Item model"
check_file "application/backend/src/main/java/com/app/crud/repository/ItemRepository.java" "Item repository"
check_file "application/backend/src/main/java/com/app/crud/service/ItemService.java" "Item service"
check_file "application/backend/src/main/java/com/app/crud/controller/ItemController.java" "Item controller"
check_file "application/backend/src/main/java/com/app/crud/controller/HealthController.java" "Health controller"
check_file "application/backend/src/main/java/com/app/crud/dto/ItemDto.java" "Item DTO"
check_file "application/backend/src/main/java/com/app/crud/dto/ApiResponse.java" "API Response DTO"
check_file "application/backend/src/main/java/com/app/crud/config/WebConfig.java" "Web config"
check_file "application/backend/src/main/java/com/app/crud/config/GlobalExceptionHandler.java" "Exception handler"

# Terraform
echo ""
echo "── Terraform (Infrastructure) ────────────────"
check_file "terraform/environments/prod/main.tf" "Main config"
check_file "terraform/environments/prod/variables.tf" "Variables"
check_file "terraform/environments/prod/outputs.tf" "Outputs"
check_file "terraform/environments/prod/terraform.tfvars" "Terraform vars"
check_file "terraform/environments/prod/templates/web-userdata.sh.tpl" "Web user-data"
check_file "terraform/environments/prod/templates/app-userdata.sh.tpl" "App user-data"

# Terraform Modules
check_dir "terraform/modules/vpc" "VPC module"
check_dir "terraform/modules/alb" "ALB module"
check_dir "terraform/modules/asg" "ASG module"
check_dir "terraform/modules/rds" "RDS module"
check_dir "terraform/modules/s3" "S3 module"
check_dir "terraform/modules/iam" "IAM module"
check_dir "terraform/modules/security-groups" "Security groups module"
check_dir "terraform/modules/cloudwatch" "CloudWatch module"

# Terraform Backend
check_dir "terraform/backend-setup" "Terraform backend setup"
check_file "terraform/backend-setup/main.tf" "Backend main.tf"
check_file "terraform/backend-setup/variables.tf" "Backend variables.tf"
check_file "terraform/backend-setup/outputs.tf" "Backend outputs.tf"

# Scripts
echo ""
echo "── Scripts ────────────────────────────────────"
check_file "scripts/build.sh" "build.sh"
check_file "scripts/deploy.sh" "deploy.sh"
check_file "scripts/verify.sh" "verify.sh"
check_file "scripts/check-prerequisites.sh" "check-prerequisites.sh"
check_file "scripts/validate-project.sh" "validate-project.sh"

# Build directories
echo ""
echo "── Build Directories ──────────────────────────"
check_dir "dist" "dist directory"
check_dir "dist/frontend" "dist/frontend"
check_dir "dist/backend" "dist/backend"

# Validate critical file contents
echo ""
echo "── Content Validation ─────────────────────────"

if grep -q "db_address" "$ROOT/terraform/environments/prod/main.tf" 2>/dev/null; then
  ok "Terraform uses db_address correctly"
else
  fail "Terraform should use module.rds.db_address"
fi

if grep -q "eslint" "$ROOT/application/frontend/package.json" 2>/dev/null; then
  ok "Frontend has eslint dependency"
else
  fail "Frontend missing eslint dependency"
fi

if grep -q "root" "$ROOT/application/frontend/index.html" 2>/dev/null; then
  ok "Frontend index.html has root div"
else
  fail "Frontend index.html missing root div"
fi

# Summary
echo ""
echo "══════════════════════════════════════════════"
if [[ "$FAILED" -eq 0 ]]; then
  echo -e "  ${GREEN}Project structure is valid ✓${NC}"
  echo ""
  echo "  Next steps:"
  echo "    1. ./scripts/check-prerequisites.sh"
  echo "    2. Configure terraform/environments/prod/terraform.tfvars"
  echo "    3. ./scripts/build.sh"
  echo "    4. cd terraform/environments/prod && terraform init && terraform apply"
  echo "    5. ./scripts/deploy.sh"
  echo "    6. ./scripts/verify.sh --wait"
else
  echo -e "  ${RED}Project structure has issues ✗${NC}"
  echo "  Please fix the issues above"
fi
echo "══════════════════════════════════════════════"
echo ""

exit $FAILED
