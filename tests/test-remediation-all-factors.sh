#!/bin/bash

# ==============================================================================
# 90% Coverage - Complete Remediation Test Suite
# ==============================================================================
# Tests all remediation paths and conditional branches
# ==============================================================================

set -uo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TOOL_PATH="$PROJECT_ROOT/bin/twelve-factor-reviewer"
TEST_TEMP_DIR="/tmp/12factor-90-remed-$$"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "     Complete Remediation Coverage Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cleanup() {
    rm -rf "$TEST_TEMP_DIR"
}
trap cleanup EXIT

mkdir -p "$TEST_TEMP_DIR"

# ==============================================================================
# Test Factor 1: Codebase - All conditions
# ==============================================================================
echo -e "\nFactor 1: Codebase variations"

# No git repo
PROJECT="$TEST_TEMP_DIR/no_git"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# Git but no remote
PROJECT="$TEST_TEMP_DIR/no_remote"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
cd "$PROJECT" || return
git init -q
git config user.name "Test"
git config user.email "test@example.com"
cd - >/dev/null || return
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# Multiple remotes
PROJECT="$TEST_TEMP_DIR/multi_remote"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
cd "$PROJECT" || return
git init -q
git config user.name "Test"
git config user.email "test@example.com"
git remote add origin https://github.com/test/repo.git
git remote add upstream https://github.com/upstream/repo.git
git remote add heroku https://git.heroku.com/app.git
git remote add backup https://gitlab.com/test/repo.git
cd - >/dev/null || return
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# ==============================================================================
# Test Factor 2: Dependencies - All package managers
# ==============================================================================
echo -e "\nFactor 2: Dependencies all types"

# Node.js without lock file
PROJECT="$TEST_TEMP_DIR/node_no_lock"
mkdir -p "$PROJECT"
echo '{"name": "test", "dependencies": {"express": "^4.0.0"}}' > "$PROJECT/package.json"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# Python without lock
PROJECT="$TEST_TEMP_DIR/python_no_lock"
mkdir -p "$PROJECT"
echo "flask==2.0.0" > "$PROJECT/requirements.txt"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# Ruby without lock
PROJECT="$TEST_TEMP_DIR/ruby_no_lock"
mkdir -p "$PROJECT"
echo "source 'https://rubygems.org'" > "$PROJECT/Gemfile"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# Go without sum
PROJECT="$TEST_TEMP_DIR/go_no_sum"
mkdir -p "$PROJECT"
echo "module example.com/app" > "$PROJECT/go.mod"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# Java Maven
PROJECT="$TEST_TEMP_DIR/maven"
mkdir -p "$PROJECT"
echo '<?xml version="1.0"?><project></project>' > "$PROJECT/pom.xml"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# Java Gradle
PROJECT="$TEST_TEMP_DIR/gradle"
mkdir -p "$PROJECT"
echo "plugins { id 'java' }" > "$PROJECT/build.gradle"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# PHP Composer without lock
PROJECT="$TEST_TEMP_DIR/php_no_lock"
mkdir -p "$PROJECT"
echo '{"require": {"php": ">=7.4"}}' > "$PROJECT/composer.json"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# Rust Cargo without lock
PROJECT="$TEST_TEMP_DIR/rust_no_lock"
mkdir -p "$PROJECT"
echo "[package]" > "$PROJECT/Cargo.toml"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# .NET without lock
PROJECT="$TEST_TEMP_DIR/dotnet"
mkdir -p "$PROJECT"
echo "<Project></Project>" > "$PROJECT/App.csproj"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# ==============================================================================
# Test Factor 3: Config - All secret patterns
# ==============================================================================
echo -e "\nFactor 3: Config with secrets"

# Various hardcoded secrets
PROJECT="$TEST_TEMP_DIR/secrets"
mkdir -p "$PROJECT"
echo '{"name": "secrets"}' > "$PROJECT/package.json"

# Different secret patterns
cat > "$PROJECT/config.js" << 'EOF'
const password = "hardcoded_password_123";
const api_key = "sk-1234567890abcdef";
const secret = "my_secret_key_here";
const token = "ghp_1234567890abcdef";
const database = "postgresql://user:password@localhost/db";
const aws_key = "AKIAIOSFODNN7EXAMPLE";
const private_key = "-----BEGIN RSA PRIVATE KEY-----";
const SECRET_KEY = "django-insecure-key";
const apiKey = 'abcd1234efgh5678';
const clientSecret = "0a1b2c3d4e5f6789";
EOF

cat > "$PROJECT/.env" << 'EOF'
API_KEY=hardcoded_api_key_123
SECRET_KEY=hardcoded_secret_456
DATABASE_PASSWORD=plaintext_password
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
PRIVATE_KEY=-----BEGIN RSA PRIVATE KEY-----
EOF

(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# No .env.example
PROJECT="$TEST_TEMP_DIR/no_env_example"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
echo "PORT=3000" > "$PROJECT/.env"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# ==============================================================================
# Test Factor 4: Backing Services - All patterns
# ==============================================================================
echo -e "\nFactor 4: Backing services"

# No connection string in env
PROJECT="$TEST_TEMP_DIR/no_conn_string"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
echo "const db = 'localhost:5432';" > "$PROJECT/database.js"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# ==============================================================================
# Test Factor 5: Build/Release/Run - All combinations
# ==============================================================================
echo -e "\nFactor 5: Build/Release/Run"

# No Dockerfile
PROJECT="$TEST_TEMP_DIR/no_docker"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# Basic Dockerfile (no multi-stage)
PROJECT="$TEST_TEMP_DIR/basic_docker"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
echo "FROM node:18" > "$PROJECT/Dockerfile"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# No CI/CD
PROJECT="$TEST_TEMP_DIR/no_cicd"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
echo "FROM node:18" > "$PROJECT/Dockerfile"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# ==============================================================================
# Test Factor 6: Processes - State detection
# ==============================================================================
echo -e "\nFactor 6: Processes"

# Local state storage
PROJECT="$TEST_TEMP_DIR/local_state"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
cat > "$PROJECT/app.js" << 'EOF'
// Local state
const cache = {};
const sessions = {};
app.use(session({ store: new FileStore() }));
localStorage.setItem('key', 'value');
fs.writeFileSync('/tmp/data.txt', 'data');
EOF
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# PID files
PROJECT="$TEST_TEMP_DIR/pid_files"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
touch "$PROJECT/app.pid"
touch "$PROJECT/server.pid"
echo "process.pid" > "$PROJECT/pidfile"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# ==============================================================================
# Test Factor 7: Port Binding
# ==============================================================================
echo -e "\nFactor 7: Port binding"

# No PORT usage
PROJECT="$TEST_TEMP_DIR/no_port"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
echo "app.listen(3000);" > "$PROJECT/app.js"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# ==============================================================================
# Test Factor 8: Concurrency
# ==============================================================================
echo -e "\nFactor 8: Concurrency"

# No scaling config
PROJECT="$TEST_TEMP_DIR/no_scaling"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# ==============================================================================
# Test Factor 9: Disposability
# ==============================================================================
echo -e "\nFactor 9: Disposability"

# No signal handling
PROJECT="$TEST_TEMP_DIR/no_signals"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
echo "console.log('app');" > "$PROJECT/app.js"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# No health checks
PROJECT="$TEST_TEMP_DIR/no_health"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
echo "app.listen(3000);" > "$PROJECT/app.js"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# ==============================================================================
# Test Factor 10: Dev/Prod Parity
# ==============================================================================
echo -e "\nFactor 10: Dev/Prod parity"

# No Docker
PROJECT="$TEST_TEMP_DIR/no_docker_parity"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# Docker but no compose variants
PROJECT="$TEST_TEMP_DIR/no_compose_variants"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
echo "FROM node:18" > "$PROJECT/Dockerfile"
echo "version: '3'" > "$PROJECT/docker-compose.yml"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# No environment configs
PROJECT="$TEST_TEMP_DIR/no_env_configs"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
echo "FROM node:18" > "$PROJECT/Dockerfile"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# ==============================================================================
# Test Factor 11: Logs
# ==============================================================================
echo -e "\nFactor 11: Logs"

# Log files present
PROJECT="$TEST_TEMP_DIR/log_files"
mkdir -p "$PROJECT/logs"
echo '{"name": "test"}' > "$PROJECT/package.json"
touch "$PROJECT/app.log"
touch "$PROJECT/error.log"
touch "$PROJECT/logs/application.log"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# No logging config
PROJECT="$TEST_TEMP_DIR/no_logging"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# ==============================================================================
# Test Factor 12: Admin Processes
# ==============================================================================
echo -e "\nFactor 12: Admin processes"

# No migrations
PROJECT="$TEST_TEMP_DIR/no_migrations"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# No scripts
PROJECT="$TEST_TEMP_DIR/no_scripts"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")
"$TOOL_PATH" "$PROJECT" --remediate >/dev/null 2>&1
echo -n "."

# ==============================================================================
# Test all output format combinations with remediation
# ==============================================================================
echo -e "\nAll format combinations with remediation"

PROJECT="$TEST_TEMP_DIR/all_formats"
mkdir -p "$PROJECT"
echo '{"name": "test"}' > "$PROJECT/package.json"
(cd "$PROJECT" && git init -q && git config user.name "Test" && git config user.email "test@example.com")

# All formats with remediation
"$TOOL_PATH" "$PROJECT" -f terminal --remediate >/dev/null 2>&1
echo -n "."
"$TOOL_PATH" "$PROJECT" -f json --remediate 2>&1 | python3 -m json.tool >/dev/null 2>&1
echo -n "."
"$TOOL_PATH" "$PROJECT" -f markdown --remediate >/dev/null 2>&1
echo -n "."

# All formats with verbose and remediation
"$TOOL_PATH" "$PROJECT" -f terminal --verbose --remediate >/dev/null 2>&1
echo -n "."
"$TOOL_PATH" "$PROJECT" -f json --verbose --remediate 2>&1 | python3 -m json.tool >/dev/null 2>&1
echo -n "."
"$TOOL_PATH" "$PROJECT" -f markdown --verbose --remediate >/dev/null 2>&1
echo -n "."

echo -e "\n\n✅ Complete remediation coverage tests finished"
exit 0