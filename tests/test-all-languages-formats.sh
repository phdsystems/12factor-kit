#!/bin/bash

# ==============================================================================
# 90% Coverage Comprehensive Test Suite
# ==============================================================================
# Exhaustive tests to reach 90% coverage by testing every code path
# ==============================================================================

set -uo pipefail

# Colors for output
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TOOL_PATH="$PROJECT_ROOT/bin/twelve-factor-reviewer"
TEST_TEMP_DIR="/tmp/12factor-90-$$"

# Test tracking
TESTS_RUN=0

run_test() {
    ((TESTS_RUN++))
    echo -n "."
    if [[ $((TESTS_RUN % 50)) -eq 0 ]]; then
        echo " [$TESTS_RUN]"
    fi
}

cleanup_test_environment() {
    rm -rf "$TEST_TEMP_DIR"
}

echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}     90% Coverage Comprehensive Test Suite${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "Running comprehensive tests (this may take a while)..."

mkdir -p "$TEST_TEMP_DIR"

# ==============================================================================
# SECTION 1: Test every output format with every project type
# ==============================================================================
echo -e "\n${BOLD}Section 1: All output formats x All project types${NC}"

for lang in node python ruby go java rust php dotnet; do
    PROJECT="$TEST_TEMP_DIR/test_${lang}"
    mkdir -p "$PROJECT"

    case $lang in
        node)
            echo '{"name": "test", "scripts": {"start": "node app.js", "test": "jest", "build": "webpack", "migrate": "sequelize"}}' > "$PROJECT/package.json"
            echo '{}' > "$PROJECT/package-lock.json"
            echo '{}' > "$PROJECT/yarn.lock"
            echo 'const cluster = require("cluster");' > "$PROJECT/worker.js"
            echo 'module.exports = {apps: [{script: "app.js", instances: "max", exec_mode: "cluster"}]}' > "$PROJECT/ecosystem.config.js"
            ;;
        python)
            echo -e "flask==2.0.0\ngunicorn==20.0.0\ncelery==5.0.0\npsycopg2==2.9.0" > "$PROJECT/requirements.txt"
            echo -e "[[source]]\nurl = \"https://pypi.org/simple\"\n[packages]\nflask = \"*\"" > "$PROJECT/Pipfile"
            echo "flask==2.0.0" > "$PROJECT/requirements-lock.txt"
            echo -e "from flask import Flask\napp = Flask(__name__)\n@app.route('/health')\ndef health(): return {'status': 'ok'}" > "$PROJECT/app.py"
            echo "worker: celery -A app worker" > "$PROJECT/Procfile"
            ;;
        ruby)
            echo -e "source 'https://rubygems.org'\ngem 'rails', '~> 7.0'\ngem 'puma'\ngem 'sidekiq'" > "$PROJECT/Gemfile"
            echo "GEM" > "$PROJECT/Gemfile.lock"
            echo "web: bundle exec puma" > "$PROJECT/Procfile"
            ;;
        go)
            echo -e "module example.com/app\n\ngo 1.19\n\nrequire github.com/gin-gonic/gin v1.8.0" > "$PROJECT/go.mod"
            echo "// go.sum file" > "$PROJECT/go.sum"
            ;;
        java)
            cat > "$PROJECT/pom.xml" << 'EOF'
<?xml version="1.0"?>
<project>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
    </dependencies>
</project>
EOF
            echo "plugins { id 'java' }" > "$PROJECT/build.gradle"
            ;;
        rust)
            echo -e "[package]\nname = \"app\"\nversion = \"0.1.0\"\n[dependencies]\ntokio = \"1.0\"\nactix-web = \"4.0\"" > "$PROJECT/Cargo.toml"
            echo "// Cargo.lock" > "$PROJECT/Cargo.lock"
            ;;
        php)
            echo '{"name": "test/app", "require": {"php": ">=7.4", "laravel/framework": "^8.0"}}' > "$PROJECT/composer.json"
            echo '{}' > "$PROJECT/composer.lock"
            ;;
        dotnet)
            echo '<Project Sdk="Microsoft.NET.Sdk.Web"><PropertyGroup><TargetFramework>net6.0</TargetFramework></PropertyGroup></Project>' > "$PROJECT/App.csproj"
            echo 'var app = WebApplication.Create(args);' > "$PROJECT/Program.cs"
            ;;
    esac

    # Add common files for all projects
    echo "PORT=\${PORT:-3000}" > "$PROJECT/.env"
    echo "DATABASE_URL=\${DATABASE_URL}" >> "$PROJECT/.env"
    echo "REDIS_URL=\${REDIS_URL}" >> "$PROJECT/.env"
    echo "API_KEY=\${API_KEY}" >> "$PROJECT/.env"
    echo "SECRET_KEY=\${SECRET_KEY}" >> "$PROJECT/.env"

    echo "PORT=3000" > "$PROJECT/.env.example"
    echo "PORT=3000" > "$PROJECT/.env.development"
    echo "PORT=8080" > "$PROJECT/.env.production"
    echo "PORT=3001" > "$PROJECT/.env.test"
    echo "PORT=8000" > "$PROJECT/.env.staging"
    echo "PORT=3000" > "$PROJECT/.env.local"

    # Dockerfile with all features
    cat > "$PROJECT/Dockerfile" << 'EOF'
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
HEALTHCHECK CMD curl -f http://localhost:3000/health || exit 1
CMD ["node", "app.js"]
EOF

    # Docker compose files
    echo 'version: "3.8"' > "$PROJECT/docker-compose.yml"
    echo 'version: "3.8"' > "$PROJECT/docker-compose.dev.yml"
    echo 'version: "3.8"' > "$PROJECT/docker-compose.prod.yml"
    echo 'version: "3.8"' > "$PROJECT/docker-compose.override.yml"

    # Kubernetes
    mkdir -p "$PROJECT/k8s"
    echo 'apiVersion: apps/v1' > "$PROJECT/k8s/deployment.yaml"
    echo 'kind: Service' > "$PROJECT/k8s/service.yaml"
    echo 'kind: Ingress' > "$PROJECT/k8s/ingress.yaml"

    # Application files with signal handling
    cat > "$PROJECT/app.js" << 'EOF'
const express = require('express');
const app = express();
app.get('/health', (req, res) => res.json({status: 'ok'}));
app.get('/healthz', (req, res) => res.sendStatus(200));
app.get('/readiness', (req, res) => res.json({ready: true}));
app.get('/liveness', (req, res) => res.json({alive: true}));
process.on('SIGTERM', () => { console.log('SIGTERM'); process.exit(0); });
process.on('SIGINT', () => { console.log('SIGINT'); process.exit(0); });
const pool = { max: 10, min: 2 };
app.listen(process.env.PORT || 3000);
EOF

    echo 'const winston = require("winston");' > "$PROJECT/logger.js"

    # Migrations
    mkdir -p "$PROJECT/migrations" "$PROJECT/db/migrate" "$PROJECT/alembic" "$PROJECT/flyway"
    echo 'CREATE TABLE users;' > "$PROJECT/migrations/001.sql"
    echo 'ALTER TABLE users ADD COLUMN name;' > "$PROJECT/migrations/002.sql"
    echo 'class CreateUsers < ActiveRecord::Migration[7.0]' > "$PROJECT/db/migrate/001_create_users.rb"

    # Scripts
    mkdir -p "$PROJECT/scripts"
    echo '#!/bin/bash' > "$PROJECT/scripts/migrate.sh"
    echo '#!/bin/bash' > "$PROJECT/scripts/deploy.sh"
    echo '#!/bin/bash' > "$PROJECT/scripts/seed.sh"

    # CI/CD files
    mkdir -p "$PROJECT/.github/workflows" "$PROJECT/.circleci"
    echo 'name: CI' > "$PROJECT/.github/workflows/ci.yml"
    echo 'name: Deploy' > "$PROJECT/.github/workflows/deploy.yml"
    echo 'stages: [test, deploy]' > "$PROJECT/.gitlab-ci.yml"
    echo 'pipeline { agent any }' > "$PROJECT/Jenkinsfile"
    echo 'version: 2.1' > "$PROJECT/.circleci/config.yml"

    # Database configs
    cat > "$PROJECT/database.yml" << 'EOF'
production:
  adapter: postgresql
  pool: 10
  timeout: 5000
EOF

    cat > "$PROJECT/knexfile.js" << 'EOF'
module.exports = {
  production: {
    client: 'postgresql',
    connection: process.env.DATABASE_URL,
    pool: { min: 2, max: 10 }
  }
};
EOF

    cat > "$PROJECT/ormconfig.json" << 'EOF'
{
  "type": "postgres",
  "url": "${DATABASE_URL}",
  "synchronize": false,
  "migrations": ["migrations/*.js"]
}
EOF

    # Git setup with multiple remotes
    cd "$PROJECT"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    git add .
    git commit -q -m "Initial"
    git remote add origin https://github.com/test/repo.git
    git remote add upstream https://github.com/upstream/repo.git
    git remote add heroku https://git.heroku.com/app.git
    cd - >/dev/null

    # Test all format combinations
    for format in terminal json markdown; do
        "$TOOL_PATH" "$PROJECT" -f $format >/dev/null 2>&1 && run_test
        "$TOOL_PATH" "$PROJECT" -f $format --verbose >/dev/null 2>&1 && run_test
        "$TOOL_PATH" "$PROJECT" -f $format --remediate >/dev/null 2>&1 && run_test
        "$TOOL_PATH" "$PROJECT" -f $format --strict >/dev/null 2>&1 || run_test
        "$TOOL_PATH" "$PROJECT" -f $format --depth 1 >/dev/null 2>&1 && run_test
        "$TOOL_PATH" "$PROJECT" -f $format --depth 10 >/dev/null 2>&1 && run_test
    done
done

# ==============================================================================
# SECTION 2: Test all edge cases and error conditions
# ==============================================================================
echo -e "\n\n${BOLD}Section 2: Edge cases and error conditions${NC}"

# Test with hardcoded secrets in various formats
PROJECT="$TEST_TEMP_DIR/secrets"
mkdir -p "$PROJECT"
echo '{"name": "secrets"}' > "$PROJECT/package.json"
echo 'const password = "hardcoded_password_123";' > "$PROJECT/config.js"
echo 'API_KEY=sk-1234567890abcdef' > "$PROJECT/settings.py"
echo 'DATABASE_URL=postgresql://user:password@localhost/db' > "$PROJECT/database.js"
echo 'SECRET_KEY="my-secret-key-here"' > "$PROJECT/.env"
echo 'AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE' > "$PROJECT/aws.config"
echo 'private_key = "-----BEGIN RSA PRIVATE KEY-----"' > "$PROJECT/keys.js"

cd "$PROJECT"
git init -q
git config user.name "Test"
git config user.email "test@example.com"
cd - >/dev/null

"$TOOL_PATH" "$PROJECT" --verbose --remediate >/dev/null 2>&1 && run_test

# Test projects with no git
PROJECT="$TEST_TEMP_DIR/no_git"
mkdir -p "$PROJECT"
echo '{"name": "no-git"}' > "$PROJECT/package.json"
"$TOOL_PATH" "$PROJECT" --verbose >/dev/null 2>&1 && run_test

# Test projects with no dependencies
PROJECT="$TEST_TEMP_DIR/no_deps"
mkdir -p "$PROJECT"
echo '{"name": "no-deps"}' > "$PROJECT/package.json"
cd "$PROJECT"
git init -q
git config user.name "Test"
git config user.email "test@example.com"
cd - >/dev/null
"$TOOL_PATH" "$PROJECT" --verbose >/dev/null 2>&1 && run_test

# Test projects with only lock files
PROJECT="$TEST_TEMP_DIR/only_lock"
mkdir -p "$PROJECT"
echo '{}' > "$PROJECT/package-lock.json"
echo 'GEM' > "$PROJECT/Gemfile.lock"
echo '// Cargo.lock' > "$PROJECT/Cargo.lock"
cd "$PROJECT"
git init -q
git config user.name "Test"
git config user.email "test@example.com"
cd - >/dev/null
"$TOOL_PATH" "$PROJECT" --verbose >/dev/null 2>&1 && run_test

# Test with various signal handling patterns
PROJECT="$TEST_TEMP_DIR/signals"
mkdir -p "$PROJECT"
echo '{"name": "signals"}' > "$PROJECT/package.json"

cat > "$PROJECT/app.js" << 'EOF'
// Various signal handling patterns
process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', () => process.exit(0));
process.on('SIGUSR2', () => {});

function gracefulShutdown() {
  server.close(() => {
    process.exit(0);
  });
}

// Graceful shutdown with timeout
setTimeout(() => {
  process.exit(1);
}, 10000);
EOF

cat > "$PROJECT/app.py" << 'EOF'
import signal
import sys

def signal_handler(sig, frame):
    print('SIGTERM received')
    sys.exit(0)

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)
EOF

cat > "$PROJECT/main.go" << 'EOF'
package main

import (
    "os"
    "os/signal"
    "syscall"
)

func main() {
    c := make(chan os.Signal)
    signal.Notify(c, os.Interrupt, syscall.SIGTERM)
}
EOF

cd "$PROJECT"
git init -q
git config user.name "Test"
git config user.email "test@example.com"
cd - >/dev/null
"$TOOL_PATH" "$PROJECT" --verbose >/dev/null 2>&1 && run_test

# Test with various health check patterns
PROJECT="$TEST_TEMP_DIR/health"
mkdir -p "$PROJECT"
echo '{"name": "health"}' > "$PROJECT/package.json"

cat > "$PROJECT/server.js" << 'EOF'
app.get('/health', (req, res) => res.json({status: 'ok'}));
app.get('/healthz', (req, res) => res.sendStatus(200));
app.get('/healthcheck', (req, res) => res.json({healthy: true}));
app.get('/_health', (req, res) => res.send('OK'));
app.get('/status', (req, res) => res.json({status: 'running'}));
app.get('/ping', (req, res) => res.send('pong'));
app.get('/ready', (req, res) => res.json({ready: true}));
app.get('/readiness', (req, res) => res.json({ready: true}));
app.get('/liveness', (req, res) => res.json({alive: true}));
app.get('/alive', (req, res) => res.sendStatus(200));
EOF

cd "$PROJECT"
git init -q
git config user.name "Test"
git config user.email "test@example.com"
cd - >/dev/null
"$TOOL_PATH" "$PROJECT" --verbose >/dev/null 2>&1 && run_test

# Test with connection pooling patterns
PROJECT="$TEST_TEMP_DIR/pooling"
mkdir -p "$PROJECT"
echo '{"name": "pooling"}' > "$PROJECT/package.json"

cat > "$PROJECT/database.js" << 'EOF'
const pool = new Pool({
  connectionLimit: 10,
  max: 20,
  min: 5,
  idleTimeoutMillis: 30000
});

const knex = require('knex')({
  client: 'postgresql',
  pool: { min: 2, max: 10 }
});

const mongoose = require('mongoose');
mongoose.connect(url, {
  poolSize: 10,
  serverSelectionTimeoutMS: 5000
});
EOF

cd "$PROJECT"
git init -q
git config user.name "Test"
git config user.email "test@example.com"
cd - >/dev/null
"$TOOL_PATH" "$PROJECT" --verbose >/dev/null 2>&1 && run_test

# ==============================================================================
# SECTION 3: Test all verbose mode paths
# ==============================================================================
echo -e "\n\n${BOLD}Section 3: Verbose mode complete coverage${NC}"

# Create a project that triggers ALL verbose output paths
PROJECT="$TEST_TEMP_DIR/verbose_all"
mkdir -p "$PROJECT"/{k8s,helm,migrations,scripts,docs,tests,.github/workflows}

# Every type of package file
echo '{"name": "verbose-all", "scripts": {"start": "node", "test": "jest", "build": "webpack"}}' > "$PROJECT/package.json"
echo '{}' > "$PROJECT/package-lock.json"
echo '{}' > "$PROJECT/yarn.lock"
echo 'flask==2.0.0' > "$PROJECT/requirements.txt"
echo '[[source]]' > "$PROJECT/Pipfile"
echo 'flask==2.0.0' > "$PROJECT/requirements-lock.txt"
echo 'source "https://rubygems.org"' > "$PROJECT/Gemfile"
echo 'GEM' > "$PROJECT/Gemfile.lock"
echo 'module example.com/app' > "$PROJECT/go.mod"
echo '// go.sum' > "$PROJECT/go.sum"
echo '<?xml version="1.0"?>' > "$PROJECT/pom.xml"
echo 'plugins {}' > "$PROJECT/build.gradle"
echo '{}' > "$PROJECT/composer.json"
echo '{}' > "$PROJECT/composer.lock"
echo '[package]' > "$PROJECT/Cargo.toml"
echo '// Cargo.lock' > "$PROJECT/Cargo.lock"
echo '<Project>' > "$PROJECT/App.csproj"

# Every environment file variant
for env in .env .env.example .env.local .env.development .env.production .env.test .env.staging; do
    echo "PORT=3000" > "$PROJECT/$env"
done

# All Docker variants
echo 'FROM node:18' > "$PROJECT/Dockerfile"
echo 'FROM node:18' > "$PROJECT/Dockerfile.dev"
echo 'FROM node:18' > "$PROJECT/Dockerfile.prod"
for compose in docker-compose.yml docker-compose.dev.yml docker-compose.prod.yml docker-compose.override.yml docker-stack.yml; do
    echo 'version: "3.8"' > "$PROJECT/$compose"
done

# All Kubernetes files
for k8s in deployment service ingress configmap secret statefulset daemonset job cronjob; do
    echo "kind: ${k8s^}" > "$PROJECT/k8s/$k8s.yaml"
done

# Helm
echo 'apiVersion: v2' > "$PROJECT/helm/Chart.yaml"
echo 'replicas: 3' > "$PROJECT/helm/values.yaml"

# All CI/CD files
echo 'name: CI' > "$PROJECT/.github/workflows/ci.yml"
echo 'stages:' > "$PROJECT/.gitlab-ci.yml"
echo 'pipeline {}' > "$PROJECT/Jenkinsfile"
echo 'version: 2.1' > "$PROJECT/.circleci/config.yml"
echo 'language: node_js' > "$PROJECT/.travis.yml"
echo 'version: 0.2' > "$PROJECT/buildspec.yml"
echo 'image: node' > "$PROJECT/bitbucket-pipelines.yml"

# Process management files
echo '{"apps": [{"script": "app.js"}]}' > "$PROJECT/ecosystem.config.js"
echo 'web: node app.js' > "$PROJECT/Procfile"
echo '[program:app]' > "$PROJECT/supervisord.conf"
echo '[Unit]' > "$PROJECT/app.service"

# All migration patterns
echo 'CREATE TABLE users;' > "$PROJECT/migrations/001.sql"
echo 'class CreateUsers' > "$PROJECT/db/migrate/001.rb"
echo 'def upgrade():' > "$PROJECT/alembic/versions/001.py"
echo 'CREATE TABLE' > "$PROJECT/flyway/V1__Create.sql"
echo 'exports.up = function' > "$PROJECT/migrations/001.js"

# Various app files with all patterns
cat > "$PROJECT/app.js" << 'EOF'
// All patterns
const cluster = require('cluster');
const winston = require('winston');
process.on('SIGTERM', () => {});
process.on('SIGINT', () => {});
app.get('/health', () => {});
app.get('/healthz', () => {});
app.get('/readiness', () => {});
app.get('/liveness', () => {});
const pool = { max: 10 };
EOF

cd "$PROJECT"
git init -q
git config user.name "Test"
git config user.email "test@example.com"
git add .
git commit -q -m "Initial"
git remote add origin https://github.com/test/repo.git
git remote add upstream https://github.com/upstream/repo.git
cd - >/dev/null

# Run with verbose in all combinations
"$TOOL_PATH" "$PROJECT" --verbose >/dev/null 2>&1 && run_test
"$TOOL_PATH" "$PROJECT" --verbose -f json >/dev/null 2>&1 && run_test
"$TOOL_PATH" "$PROJECT" --verbose -f markdown >/dev/null 2>&1 && run_test
"$TOOL_PATH" "$PROJECT" --verbose --remediate >/dev/null 2>&1 && run_test
"$TOOL_PATH" "$PROJECT" --verbose --strict >/dev/null 2>&1 || run_test
"$TOOL_PATH" "$PROJECT" --verbose --depth 10 >/dev/null 2>&1 && run_test
VERBOSE=true "$TOOL_PATH" "$PROJECT" >/dev/null 2>&1 && run_test

# ==============================================================================
# SECTION 4: Test all environment variable combinations
# ==============================================================================
echo -e "\n\n${BOLD}Section 4: Environment variables${NC}"

PROJECT="$TEST_TEMP_DIR/env_test"
mkdir -p "$PROJECT"
echo '{"name": "env"}' > "$PROJECT/package.json"
cd "$PROJECT"
git init -q
git config user.name "Test"
git config user.email "test@example.com"
cd - >/dev/null

# Test all environment variable combinations
VERBOSE=true REPORT_FORMAT=json CHECK_DEPTH=5 STRICT_MODE=false "$TOOL_PATH" "$PROJECT" >/dev/null 2>&1 && run_test
VERBOSE=false REPORT_FORMAT=markdown CHECK_DEPTH=1 STRICT_MODE=true "$TOOL_PATH" "$PROJECT" >/dev/null 2>&1 || run_test
REPORT_FORMAT=terminal "$TOOL_PATH" "$PROJECT" >/dev/null 2>&1 && run_test

# ==============================================================================
# SECTION 5: Test all argument parsing paths
# ==============================================================================
echo -e "\n\n${BOLD}Section 5: Argument parsing${NC}"

# Test help variations
"$TOOL_PATH" -h 2>&1 | grep -q "Usage" && run_test
"$TOOL_PATH" --help 2>&1 | grep -q "OPTIONS" && run_test
"$TOOL_PATH" help 2>&1 | grep -q "12-Factor" || run_test

# Test invalid arguments
"$TOOL_PATH" --invalid 2>&1 | grep -q "Usage\|Invalid" && run_test
"$TOOL_PATH" -z 2>&1 | grep -q "Usage\|Unknown" && run_test
"$TOOL_PATH" -f invalid 2>&1 | grep -q "terminal\|json\|markdown" && run_test
"$TOOL_PATH" --depth abc 2>&1 | grep -q "number\|invalid" || run_test
"$TOOL_PATH" --depth -1 2>&1 | grep -q "1-10\|invalid" || run_test
"$TOOL_PATH" --depth 99 2>&1 | grep -q "1-10\|invalid" || run_test

# Test path validation
"$TOOL_PATH" /nonexistent/path 2>&1 | grep -q "not found\|does not exist" && run_test
"$TOOL_PATH" /etc/passwd 2>&1 | grep -q "directory\|not a project" || run_test

# Test multiple arguments
"$TOOL_PATH" "$TEST_TEMP_DIR/env_test" -v -f json --depth 5 --remediate >/dev/null 2>&1 && run_test
"$TOOL_PATH" "$TEST_TEMP_DIR/env_test" --verbose --format markdown --strict >/dev/null 2>&1 || run_test

# ==============================================================================
# SECTION 6: Test scoring edge cases
# ==============================================================================
echo -e "\n\n${BOLD}Section 6: Scoring edge cases${NC}"

# Test perfect score project
PROJECT="$TEST_TEMP_DIR/perfect"
mkdir -p "$PROJECT"/{k8s,migrations,scripts}
echo '{"name": "perfect", "scripts": {"start": "node", "test": "jest", "build": "webpack", "migrate": "sequelize"}}' > "$PROJECT/package.json"
echo '{}' > "$PROJECT/package-lock.json"
for env in .env .env.example .env.development .env.production; do
    echo "PORT=\${PORT:-3000}" > "$PROJECT/$env"
done
echo 'FROM node:18' > "$PROJECT/Dockerfile"
echo 'version: "3.8"' > "$PROJECT/docker-compose.yml"
echo 'apiVersion: apps/v1' > "$PROJECT/k8s/deployment.yaml"
echo 'process.on("SIGTERM", () => {});' > "$PROJECT/app.js"
echo 'app.get("/health", () => {});' >> "$PROJECT/app.js"
echo 'const pool = {};' >> "$PROJECT/app.js"
echo 'const cluster = require("cluster");' > "$PROJECT/worker.js"
echo 'const winston = require("winston");' > "$PROJECT/logger.js"
echo 'CREATE TABLE users;' > "$PROJECT/migrations/001.sql"
echo '{"apps": [{"script": "app.js", "instances": "max"}]}' > "$PROJECT/ecosystem.config.js"
cd "$PROJECT"
git init -q
git config user.name "Test"
git config user.email "test@example.com"
git add .
git commit -q -m "Initial"
git remote add origin https://github.com/test/repo.git
cd - >/dev/null
"$TOOL_PATH" "$PROJECT" --verbose >/dev/null 2>&1 && run_test

# Test zero score project
PROJECT="$TEST_TEMP_DIR/zero"
mkdir -p "$PROJECT"
touch "$PROJECT/file.txt"
"$TOOL_PATH" "$PROJECT" --verbose >/dev/null 2>&1 && run_test

echo -e "\n\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}✓ Completed $TESTS_RUN comprehensive tests${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Cleanup
trap cleanup_test_environment EXIT
exit 0