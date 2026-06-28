#!/usr/bin/env bash
# ============================================================
# build.sh — Build frontend (React) and backend (Spring Boot)
# Usage: ./scripts/build.sh
# ============================================================

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="$ROOT/application/frontend"
BACKEND_DIR="$ROOT/application/backend"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[BUILD]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
die()  { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ============================================================
# Preflight Checks
# ============================================================

command -v node >/dev/null 2>&1 || die "Node.js is required"
command -v npm >/dev/null 2>&1 || die "npm is required"

# Maven / Maven Wrapper
if command -v mvn >/dev/null 2>&1; then
    MVN_CMD="mvn"
    log "Using system Maven"
elif [[ -f "$BACKEND_DIR/mvnw" ]]; then
    MVN_CMD="./mvnw"
    chmod +x "$BACKEND_DIR/mvnw"
    log "Using Maven Wrapper"
else
    die "Neither Maven nor Maven Wrapper found."
fi

# Java
command -v java >/dev/null 2>&1 || die "Java is required"

JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)

if [[ "$JAVA_VERSION" -lt 21 ]]; then
    die "Java 21 or higher required. Found Java $JAVA_VERSION"
fi

log "Node Version : $(node -v)"
log "NPM Version  : $(npm -v)"
log "Java Version : $(java -version 2>&1 | head -n1)"

echo
log "Starting Build Pipeline..."
echo

# ============================================================
# Frontend
# ============================================================

log "========================================"
log "Building Frontend (React + Vite)"
log "========================================"

cd "$FRONTEND_DIR"

if [[ ! -f package.json ]]; then
    die "package.json not found in frontend directory."
fi

if [[ ! -d node_modules ]]; then

    if [[ -f package-lock.json ]]; then
        log "Installing dependencies using npm ci..."
        npm ci
    else
        warn "package-lock.json not found."
        warn "Using npm install instead..."
        npm install
    fi

else
    log "node_modules already exists. Skipping install."
fi

log "Running production build..."
npm run build

[[ -d dist ]] || die "Frontend build failed. dist/ folder not found."

DIST_DIR="$ROOT/dist/frontend"

mkdir -p "$DIST_DIR"

tar -czf "$DIST_DIR/dist.tar.gz" -C dist .

log "Frontend archive created:"
echo "  $DIST_DIR/dist.tar.gz"

echo

# ============================================================
# Backend
# ============================================================

log "========================================"
log "Building Backend (Spring Boot)"
log "========================================"

cd "$BACKEND_DIR"

log "Running Maven package..."

$MVN_CMD clean package -DskipTests

JAR_SRC=$(find target -maxdepth 1 -name "*.jar" \
! -name "*sources.jar" \
! -name "*javadoc.jar" | head -n 1)

[[ -f "$JAR_SRC" ]] || die "No executable JAR found inside target/"

BACKEND_DIST="$ROOT/dist/backend"

mkdir -p "$BACKEND_DIST"

cp "$JAR_SRC" "$BACKEND_DIST/app.jar"

SIZE=$(du -sh "$BACKEND_DIST/app.jar" | cut -f1)

log "Backend JAR copied:"
echo "  $BACKEND_DIST/app.jar ($SIZE)"

echo

# ============================================================
# Summary
# ============================================================

log "========================================"
log "BUILD SUCCESSFUL"
log "========================================"

echo
echo "Artifacts:"
echo
echo "Frontend:"
echo "  dist/frontend/dist.tar.gz"
echo
echo "Backend:"
echo "  dist/backend/app.jar"
echo
echo "Next Step:"
echo "  ./scripts/deploy.sh"
echo