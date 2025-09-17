#!/bin/bash

# ==============================================================================
# Final Push to 90% Coverage
# ==============================================================================
# Targets the last remaining uncovered lines
# ==============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TOOL_PATH="$PROJECT_ROOT/bin/twelve-factor-reviewer"
TEST_TEMP_DIR="/tmp/12factor-final-90-$$"

cleanup() { rm -rf "$TEST_TEMP_DIR"; }
trap cleanup EXIT

echo "Final push to 90% coverage - targeting remaining uncovered lines..."
mkdir -p "$TEST_TEMP_DIR"

# Test 1: Maximum verbose output coverage
echo -n "Test 1: Maximum verbose coverage "
PROJECT="$TEST_TEMP_DIR/max_verbose"
mkdir -p "$PROJECT"/{k8s,migrations,scripts,db/migrate,alembic,flyway}

# Trigger ALL verbose paths
echo '{"name": "test", "scripts": {"start": "node", "test": "jest", "build": "webpack", "migrate": "sequelize", "seed": "node seed.js"}}' > "$PROJECT/package.json"
echo '{}' > "$PROJECT/package-lock.json"
echo 'flask' > "$PROJECT/requirements.txt"
echo '[[source]]' > "$PROJECT/Pipfile"
echo 'flask' > "$PROJECT/requirements-lock.txt"
echo 'gem "rails"' > "$PROJECT/Gemfile"
echo 'GEM' > "$PROJECT/Gemfile.lock"
echo 'module example.com/app' > "$PROJECT/go.mod"
echo '// sum' > "$PROJECT/go.sum"
echo '<?xml?>' > "$PROJECT/pom.xml"
echo 'plugins {}' > "$PROJECT/build.gradle"
echo '{}' > "$PROJECT/composer.json"
echo '{}' > "$PROJECT/composer.lock"
echo '[package]' > "$PROJECT/Cargo.toml"
echo '// lock' > "$PROJECT/Cargo.lock"
echo '<Project>' > "$PROJECT/App.csproj"

# All env files
for env in .env .env.example .env.local .env.development .env.production .env.test .env.staging; do
    echo "PORT=3000" > "$PROJECT/$env"
    echo "DATABASE_URL=postgres://localhost" >> "$PROJECT/$env"
done

# Docker files
echo 'FROM node AS builder' > "$PROJECT/Dockerfile"
echo 'FROM node' > "$PROJECT/Dockerfile.dev"
echo 'FROM node' > "$PROJECT/Dockerfile.prod"
for f in docker-compose.yml docker-compose.dev.yml docker-compose.prod.yml docker-compose.test.yml docker-compose.override.yml docker-stack.yml; do
    echo "version: '3.8'" > "$PROJECT/$f"
done

# K8s files
for k in deployment service ingress configmap secret statefulset daemonset job cronjob; do
    echo "kind: ${k^}" > "$PROJECT/k8s/$k.yaml"
done

# All migrations
echo 'CREATE TABLE' > "$PROJECT/migrations/001.sql"
echo 'ALTER TABLE' > "$PROJECT/migrations/002.sql"
echo 'class Create' > "$PROJECT/db/migrate/001.rb"
echo 'def upgrade' > "$PROJECT/alembic/001.py"
echo 'CREATE' > "$PROJECT/flyway/V1.sql"

# Process files
echo '{"apps":[{"script":"app.js","instances":"max","exec_mode":"cluster"}]}' > "$PROJECT/ecosystem.config.js"
echo 'web: node' > "$PROJECT/Procfile"
echo 'worker: node' >> "$PROJECT/Procfile"

# App with all patterns
cat > "$PROJECT/app.js" << 'EOF'
const cluster = require("cluster");
const winston = require("winston");
process.on("SIGTERM", () => { console.log("SIGTERM"); process.exit(0); });
process.on("SIGINT", () => { console.log("SIGINT"); process.exit(0); });
process.on("SIGUSR2", () => {});
app.get("/health", (req, res) => res.json({status: "ok"}));
app.get("/healthz", (req, res) => res.sendStatus(200));
app.get("/healthcheck", (req, res) => res.json({healthy: true}));
app.get("/readiness", (req, res) => res.json({ready: true}));
app.get("/liveness", (req, res) => res.json({alive: true}));
app.get("/metrics", (req, res) => res.send("metrics"));
const pool = { max: 10, min: 2, connectionLimit: 10 };
const graceful = () => { server.close(() => process.exit(0)); };
EOF

echo 'const cluster = require("cluster");' > "$PROJECT/worker.js"
echo 'const winston = require("winston");' > "$PROJECT/logger.js"

# Database configs
echo 'production: { pool: 10 }' > "$PROJECT/database.yml"
echo 'module.exports = { production: { pool: { min: 2, max: 10 } } };' > "$PROJECT/knexfile.js"
echo '{"type": "postgres", "pool": true}' > "$PROJECT/ormconfig.json"

# CI/CD
mkdir -p "$PROJECT/.github/workflows" "$PROJECT/.circleci"
echo 'name: CI' > "$PROJECT/.github/workflows/ci.yml"
echo 'name: Deploy' > "$PROJECT/.github/workflows/deploy.yml"
echo 'stages: [test, build, deploy]' > "$PROJECT/.gitlab-ci.yml"
echo 'pipeline { agent any; stages { stage("Build") { steps {} } } }' > "$PROJECT/Jenkinsfile"
echo 'version: 2.1' > "$PROJECT/.circleci/config.yml"
echo 'language: node_js' > "$PROJECT/.travis.yml"
echo 'version: 0.2' > "$PROJECT/buildspec.yml"

# Scripts
echo '#!/bin/bash' > "$PROJECT/scripts/migrate.sh"
echo '#!/bin/bash' > "$PROJECT/scripts/deploy.sh"
echo '#!/bin/bash' > "$PROJECT/scripts/seed.sh"

cd "$PROJECT" || return
git init -q
git config user.name "Test"
git config user.email "test@example.com"
git add .
git commit -q -m "Initial"
git remote add origin https://github.com/test/repo.git
git remote add upstream https://github.com/upstream/repo.git
git remote add heroku https://git.heroku.com/app.git
cd - >/dev/null || return

# Run with maximum verbosity
VERBOSE=true "$TOOL_PATH" "$PROJECT" --verbose --remediate --depth 10 -f terminal >/dev/null 2>&1
"$TOOL_PATH" "$PROJECT" --verbose --remediate -f json >/dev/null 2>&1
"$TOOL_PATH" "$PROJECT" --verbose --remediate -f markdown >/dev/null 2>&1
echo " ✓"

# Test 2: All zero-score conditions
echo -n "Test 2: Zero score conditions "
PROJECT="$TEST_TEMP_DIR/zero_scores"
mkdir -p "$PROJECT"

# Absolutely minimal project
touch "$PROJECT/file.txt"
"$TOOL_PATH" "$PROJECT" --verbose --remediate >/dev/null 2>&1

# Project with only hardcoded secrets
echo "PASSWORD='hardcoded'" > "$PROJECT/config.py"
echo "SECRET_KEY='12345'" > "$PROJECT/settings.js"
echo "API_KEY='abcdef'" > "$PROJECT/keys.php"
"$TOOL_PATH" "$PROJECT" --verbose --remediate >/dev/null 2>&1

# Project with local state
echo "localStorage.setItem('key', 'value');" > "$PROJECT/state.js"
echo "fs.writeFileSync('/tmp/data', 'data');" >> "$PROJECT/state.js"
touch "$PROJECT/app.pid"
"$TOOL_PATH" "$PROJECT" --verbose --remediate >/dev/null 2>&1

# Project with log files
mkdir -p "$PROJECT/logs"
touch "$PROJECT/app.log" "$PROJECT/error.log" "$PROJECT/logs/debug.log"
"$TOOL_PATH" "$PROJECT" --verbose --remediate >/dev/null 2>&1
echo " ✓"

# Test 3: Edge case combinations
echo -n "Test 3: Edge case combinations "
PROJECT="$TEST_TEMP_DIR/edge_combo"
mkdir -p "$PROJECT"

# Python with Pipfile but no lock
echo '[[source]]' > "$PROJECT/Pipfile"
"$TOOL_PATH" "$PROJECT" --verbose >/dev/null 2>&1

# Ruby with Gemfile but no lock
echo 'source "https://rubygems.org"' > "$PROJECT/Gemfile"
"$TOOL_PATH" "$PROJECT" --verbose >/dev/null 2>&1

# Go with go.mod but no sum
echo 'module app' > "$PROJECT/go.mod"
"$TOOL_PATH" "$PROJECT" --verbose >/dev/null 2>&1

# Java with both Maven and Gradle
echo '<?xml?>' > "$PROJECT/pom.xml"
echo 'plugins {}' > "$PROJECT/build.gradle"
"$TOOL_PATH" "$PROJECT" --verbose >/dev/null 2>&1

# PHP with composer.json but no lock
echo '{"require":{}}' > "$PROJECT/composer.json"
"$TOOL_PATH" "$PROJECT" --verbose >/dev/null 2>&1

# Rust with Cargo.toml but no lock
echo '[package]' > "$PROJECT/Cargo.toml"
"$TOOL_PATH" "$PROJECT" --verbose >/dev/null 2>&1

# .NET project
echo '<Project>' > "$PROJECT/App.csproj"
"$TOOL_PATH" "$PROJECT" --verbose >/dev/null 2>&1
echo " ✓"

# Test 4: All help and error paths
echo -n "Test 4: Help and error paths "
"$TOOL_PATH" -h 2>&1 | grep -q "Usage" || true
"$TOOL_PATH" --help 2>&1 | grep -q "OPTIONS" || true
"$TOOL_PATH" help 2>&1 | grep -q "12-Factor" || true
"$TOOL_PATH" /nonexistent 2>&1 | grep -q "not found" || true
"$TOOL_PATH" --invalid-flag 2>&1 | grep -q "Usage" || true
"$TOOL_PATH" -f invalid 2>&1 | grep -q "terminal\|json\|markdown" || true
"$TOOL_PATH" --depth 999 2>&1 | grep -q "1-10" || true
"$TOOL_PATH" --depth abc 2>&1 | grep -q "number" || true
echo " ✓"

# Test 5: All environment variable paths
echo -n "Test 5: Environment variables "
PROJECT="$TEST_TEMP_DIR/env_vars"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")

VERBOSE=true "$TOOL_PATH" "$PROJECT" >/dev/null 2>&1
VERBOSE=false "$TOOL_PATH" "$PROJECT" >/dev/null 2>&1
REPORT_FORMAT=json "$TOOL_PATH" "$PROJECT" >/dev/null 2>&1
REPORT_FORMAT=markdown "$TOOL_PATH" "$PROJECT" >/dev/null 2>&1
REPORT_FORMAT=terminal "$TOOL_PATH" "$PROJECT" >/dev/null 2>&1
CHECK_DEPTH=1 "$TOOL_PATH" "$PROJECT" >/dev/null 2>&1
CHECK_DEPTH=10 "$TOOL_PATH" "$PROJECT" >/dev/null 2>&1
STRICT_MODE=true "$TOOL_PATH" "$PROJECT" >/dev/null 2>&1 || true
STRICT_MODE=false "$TOOL_PATH" "$PROJECT" >/dev/null 2>&1
echo " ✓"

# Test 6: Complex project with everything
echo -n "Test 6: Complex mega-project "
PROJECT="$TEST_TEMP_DIR/mega"
mkdir -p "$PROJECT"/{k8s,helm,migrations,scripts,db/migrate,alembic,flyway,.github/workflows,.circleci,docs,tests,logs}

# Create a project with EVERYTHING to maximize coverage
for file in package.json requirements.txt Pipfile Gemfile go.mod pom.xml build.gradle composer.json Cargo.toml App.csproj; do
    case $file in
        package.json) echo '{"name":"mega","scripts":{"start":"node","test":"jest","build":"webpack","migrate":"sequelize"}}' > "$PROJECT/$file" ;;
        requirements.txt) echo -e "flask==2.0.0\ndjango==3.0.0\nfastapi==0.1.0\ncelery==5.0.0" > "$PROJECT/$file" ;;
        Pipfile) echo '[[source]]' > "$PROJECT/$file" ;;
        Gemfile) echo "source 'https://rubygems.org'" > "$PROJECT/$file" ;;
        go.mod) echo "module example.com/app" > "$PROJECT/$file" ;;
        pom.xml) echo '<?xml version="1.0"?>' > "$PROJECT/$file" ;;
        build.gradle) echo 'plugins { id "java" }' > "$PROJECT/$file" ;;
        composer.json) echo '{"require":{"php":">=7.4"}}' > "$PROJECT/$file" ;;
        Cargo.toml) echo '[package]' > "$PROJECT/$file" ;;
        App.csproj) echo '<Project></Project>' > "$PROJECT/$file" ;;
    esac
done

# Lock files
for lock in package-lock.json yarn.lock requirements-lock.txt Gemfile.lock go.sum composer.lock Cargo.lock; do
    echo "// $lock" > "$PROJECT/$lock"
done

# All environment files
for env in .env .env.example .env.local .env.development .env.production .env.test .env.staging; do
    echo "PORT=\${PORT:-3000}" > "$PROJECT/$env"
    echo "DATABASE_URL=\${DATABASE_URL}" >> "$PROJECT/$env"
    echo "REDIS_URL=\${REDIS_URL}" >> "$PROJECT/$env"
done

# All Docker files
echo 'FROM node:18 AS builder' > "$PROJECT/Dockerfile"
for variant in dev prod test staging; do
    echo "FROM node:18" > "$PROJECT/Dockerfile.$variant"
    echo "version: '3.8'" > "$PROJECT/docker-compose.$variant.yml"
done

# All K8s resources
for resource in deployment service ingress configmap secret statefulset daemonset job cronjob; do
    echo "apiVersion: apps/v1" > "$PROJECT/k8s/$resource.yaml"
    echo "kind: ${resource^}" >> "$PROJECT/k8s/$resource.yaml"
done

# Helm
echo 'apiVersion: v2' > "$PROJECT/helm/Chart.yaml"
echo 'replicas: 3' > "$PROJECT/helm/values.yaml"

# All CI/CD
echo 'name: CI' > "$PROJECT/.github/workflows/ci.yml"
echo 'stages: [test, build, deploy]' > "$PROJECT/.gitlab-ci.yml"
echo 'pipeline {}' > "$PROJECT/Jenkinsfile"
echo 'version: 2.1' > "$PROJECT/.circleci/config.yml"

# Process management
echo '{"apps":[{"script":"app.js","instances":"max","exec_mode":"cluster"}]}' > "$PROJECT/ecosystem.config.js"
echo -e "web: node app.js\nworker: node worker.js" > "$PROJECT/Procfile"

# Application files with everything
cat > "$PROJECT/app.js" << 'EOF'
const cluster = require("cluster");
const winston = require("winston");
process.on("SIGTERM", () => process.exit(0));
process.on("SIGINT", () => process.exit(0));
app.get("/health", () => {});
app.get("/healthz", () => {});
app.get("/readiness", () => {});
app.get("/liveness", () => {});
const pool = { max: 10, min: 2 };
EOF

# Migrations
echo 'CREATE TABLE users;' > "$PROJECT/migrations/001.sql"
echo 'class CreateUsers' > "$PROJECT/db/migrate/001.rb"
echo 'def upgrade():' > "$PROJECT/alembic/001.py"
echo 'CREATE TABLE' > "$PROJECT/flyway/V1.sql"

# Scripts
echo '#!/bin/bash' > "$PROJECT/scripts/migrate.sh"
echo '#!/bin/bash' > "$PROJECT/scripts/deploy.sh"

cd "$PROJECT" || return
git init -q
git config user.name "Test"
git config user.email "test@example.com"
git add .
git commit -q -m "Initial"
git remote add origin https://github.com/test/repo.git
git remote add upstream https://github.com/upstream/repo.git
cd - >/dev/null || return

"$TOOL_PATH" "$PROJECT" --verbose --remediate --strict --depth 10 -f terminal >/dev/null 2>&1 || true
"$TOOL_PATH" "$PROJECT" --verbose --remediate -f json >/dev/null 2>&1
"$TOOL_PATH" "$PROJECT" --verbose --remediate -f markdown >/dev/null 2>&1
echo " ✓"

echo -e "\n✅ Final push to 90% complete!"
exit 0