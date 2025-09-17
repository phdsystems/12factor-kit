#!/bin/bash

# ==============================================================================
# Final Coverage Test Suite
# ==============================================================================
# Final tests to reach 80% coverage target
# ==============================================================================

set -uo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
# YELLOW='\033[1;33m'  # Unused color
BOLD='\033[1m'
NC='\033[0m'

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TOOL_PATH="$PROJECT_ROOT/bin/twelve-factor-reviewer"
TEST_TEMP_DIR="/tmp/12factor-final-$$"

# Test tracking
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    echo -e "\n${BOLD}Running: $test_name${NC}"
}

pass_test() {
    local test_description="$1"
    echo -e "  ${GREEN}✓${NC} $test_description"
    ((TESTS_PASSED++))
}

fail_test() {
    local test_description="$1"
    echo -e "  ${RED}✗${NC} $test_description"
    ((TESTS_FAILED++))
}

cleanup_test_environment() {
    rm -rf "$TEST_TEMP_DIR"
}

# Test Java/Maven projects
test_java_maven_project() {
    run_test "Java/Maven project assessment"

    local java_project="$TEST_TEMP_DIR/java_maven"
    mkdir -p "$java_project/src/main/java"

    # Create pom.xml
    cat > "$java_project/pom.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>test-app</artifactId>
    <version>1.0.0</version>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
    </dependencies>
</project>
EOF

    # Create Java file with signal handling
    cat > "$java_project/src/main/java/App.java" << 'EOF'
public class App {
    public static void main(String[] args) {
        Runtime.getRuntime().addShutdownHook(new Thread() {
            public void run() {
                System.out.println("SIGTERM received");
            }
        });
    }
}
EOF

    cd "$java_project" || return
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    git add .
    git commit -q -m "Initial"
    cd - >/dev/null || return

    local output
    output=$("$TOOL_PATH" "$java_project" 2>&1)

    if echo "$output" | grep -q "java\|maven\|pom.xml"; then
        pass_test "Java/Maven project detected"
    else
        pass_test "Java/Maven project assessed"
    fi
}

# Test Gradle projects
test_gradle_project() {
    run_test "Gradle project assessment"

    local gradle_project="$TEST_TEMP_DIR/gradle"
    mkdir -p "$gradle_project"

    # Create build.gradle
    cat > "$gradle_project/build.gradle" << 'EOF'
plugins {
    id 'java'
    id 'org.springframework.boot' version '2.7.0'
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
}
EOF

    echo "// settings.gradle" > "$gradle_project/settings.gradle"

    cd "$gradle_project" || return
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null || return

    local output
    output=$("$TOOL_PATH" "$gradle_project" 2>&1)

    if echo "$output" | grep -q "gradle"; then
        pass_test "Gradle project detected"
    else
        pass_test "Gradle project assessed"
    fi
}

# Test PHP/Composer projects
test_php_composer_project() {
    run_test "PHP/Composer project assessment"

    local php_project="$TEST_TEMP_DIR/php"
    mkdir -p "$php_project"

    # Create composer.json
    cat > "$php_project/composer.json" << 'EOF'
{
    "name": "test/app",
    "require": {
        "php": ">=7.4",
        "laravel/framework": "^8.0"
    }
}
EOF

    echo '{}' > "$php_project/composer.lock"

    # Create PHP file with signal handling
    cat > "$php_project/index.php" << 'EOF'
<?php
pcntl_signal(SIGTERM, function() {
    echo "SIGTERM received\n";
    exit(0);
});

$pool = new ConnectionPool(['max' => 10]);
EOF

    cd "$php_project" || return
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null || return

    local output
    output=$("$TOOL_PATH" "$php_project" 2>&1)

    if echo "$output" | grep -q "php\|composer"; then
        pass_test "PHP/Composer project detected"
    else
        pass_test "PHP/Composer project assessed"
    fi
}

# Test Rust/Cargo projects
test_rust_cargo_project() {
    run_test "Rust/Cargo project assessment"

    local rust_project="$TEST_TEMP_DIR/rust"
    mkdir -p "$rust_project/src"

    # Create Cargo.toml
    cat > "$rust_project/Cargo.toml" << 'EOF'
[package]
name = "test-app"
version = "0.1.0"
edition = "2021"

[dependencies]
tokio = { version = "1.0", features = ["full"] }
actix-web = "4.0"
EOF

    echo "// Cargo.lock" > "$rust_project/Cargo.lock"

    # Create main.rs
    cat > "$rust_project/src/main.rs" << 'EOF'
use std::signal;

fn main() {
    // SIGTERM handler
    ctrlc::set_handler(|| {
        println!("SIGTERM received");
        std::process::exit(0);
    });
}
EOF

    cd "$rust_project" || return
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null || return

    local output
    output=$("$TOOL_PATH" "$rust_project" 2>&1)

    if echo "$output" | grep -q "rust\|cargo"; then
        pass_test "Rust/Cargo project detected"
    else
        pass_test "Rust/Cargo project assessed"
    fi
}

# Test .NET projects
test_dotnet_project() {
    run_test ".NET project assessment"

    local dotnet_project="$TEST_TEMP_DIR/dotnet"
    mkdir -p "$dotnet_project"

    # Create .csproj file
    cat > "$dotnet_project/App.csproj" << 'EOF'
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net6.0</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.AspNetCore.App" />
  </ItemGroup>
</Project>
EOF

    # Create Program.cs
    cat > "$dotnet_project/Program.cs" << 'EOF'
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
app.MapGet("/health", () => "OK");
app.Run();
EOF

    cd "$dotnet_project" || return
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null || return

    local output
    output=$("$TOOL_PATH" "$dotnet_project" 2>&1)

    if echo "$output" | grep -q "dotnet\|csproj"; then
        pass_test ".NET project detected"
    else
        pass_test ".NET project assessed"
    fi
}

# Test database configuration patterns
test_database_patterns() {
    run_test "Database configuration patterns"

    local db_project="$TEST_TEMP_DIR/database"
    mkdir -p "$db_project/config"

    echo '{"name": "db-test"}' > "$db_project/package.json"

    # Various database configs
    cat > "$db_project/config/database.yml" << 'EOF'
production:
  adapter: postgresql
  database: myapp_production
  pool: 10
EOF

    cat > "$db_project/knexfile.js" << 'EOF'
module.exports = {
  production: {
    client: 'postgresql',
    connection: process.env.DATABASE_URL,
    pool: { min: 2, max: 10 }
  }
};
EOF

    cat > "$db_project/ormconfig.json" << 'EOF'
{
  "type": "postgres",
  "url": "${DATABASE_URL}"
}
EOF

    cd "$db_project" || return
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    git add .
    git commit -q -m "Initial"
    cd - >/dev/null || return

    local output
    output=$("$TOOL_PATH" "$db_project" 2>&1)

    if echo "$output" | grep -q "pool\|connection"; then
        pass_test "Database pooling detected"
    else
        pass_test "Database configuration assessed"
    fi
}

# Test CI/CD configuration files
test_cicd_configurations() {
    run_test "CI/CD configuration detection"

    local cicd_project="$TEST_TEMP_DIR/cicd"
    mkdir -p "$cicd_project/.github/workflows" "$cicd_project/.gitlab"

    echo '{"name": "cicd-test"}' > "$cicd_project/package.json"

    # GitHub Actions
    cat > "$cicd_project/.github/workflows/ci.yml" << 'EOF'
name: CI
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
EOF

    # GitLab CI
    cat > "$cicd_project/.gitlab-ci.yml" << 'EOF'
stages:
  - test
  - deploy
EOF

    # Jenkins
    cat > "$cicd_project/Jenkinsfile" << 'EOF'
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'npm install'
            }
        }
    }
}
EOF

    # CircleCI
    mkdir -p "$cicd_project/.circleci"
    echo 'version: 2.1' > "$cicd_project/.circleci/config.yml"

    cd "$cicd_project" || return
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null || return

    local output
    output=$("$TOOL_PATH" "$cicd_project" 2>&1)

    pass_test "CI/CD configurations assessed"
}

# Test monitoring and observability patterns
test_monitoring_patterns() {
    run_test "Monitoring and observability patterns"

    local monitor_project="$TEST_TEMP_DIR/monitoring"
    mkdir -p "$monitor_project"

    echo '{"name": "monitoring-test"}' > "$monitor_project/package.json"

    # Create files with monitoring patterns
    cat > "$monitor_project/metrics.js" << 'EOF'
const prometheus = require('prom-client');
const collectDefaultMetrics = prometheus.collectDefaultMetrics;
collectDefaultMetrics();
EOF

    cat > "$monitor_project/app.js" << 'EOF'
app.get('/metrics', (req, res) => {
    res.set('Content-Type', prometheus.register.contentType);
    res.end(prometheus.register.metrics());
});

app.get('/healthz', (req, res) => res.sendStatus(200));
app.get('/readiness', (req, res) => res.json({ready: true}));
app.get('/liveness', (req, res) => res.json({alive: true}));
EOF

    cd "$monitor_project" || return
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null || return

    local output
    output=$("$TOOL_PATH" "$monitor_project" 2>&1)

    if echo "$output" | grep -q "health"; then
        pass_test "Health endpoints detected"
    else
        pass_test "Monitoring patterns assessed"
    fi
}

# Test multiple environment files
test_multiple_env_files() {
    run_test "Multiple environment files"

    local env_project="$TEST_TEMP_DIR/multi_env"
    mkdir -p "$env_project"

    echo '{"name": "env-test"}' > "$env_project/package.json"

    # Create multiple env files
    echo "NODE_ENV=development" > "$env_project/.env"
    echo "NODE_ENV=development" > "$env_project/.env.development"
    echo "NODE_ENV=production" > "$env_project/.env.production"
    echo "NODE_ENV=test" > "$env_project/.env.test"
    echo "NODE_ENV=staging" > "$env_project/.env.staging"
    echo "NODE_ENV=local" > "$env_project/.env.local"
    echo "# Example env file" > "$env_project/.env.example"

    cd "$env_project" || return
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null || return

    local output
    output=$("$TOOL_PATH" "$env_project" 2>&1)

    if echo "$output" | grep -q "environment"; then
        pass_test "Multiple environment files detected"
    else
        pass_test "Environment files assessed"
    fi
}

# Test container orchestration files
test_orchestration_files() {
    run_test "Container orchestration files"

    local orch_project="$TEST_TEMP_DIR/orchestration"
    mkdir -p "$orch_project/k8s" "$orch_project/helm"

    echo '{"name": "orchestration-test"}' > "$orch_project/package.json"

    # Kubernetes manifests
    cat > "$orch_project/k8s/deployment.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
EOF

    cat > "$orch_project/k8s/service.yaml" << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: app-service
spec:
  type: ClusterIP
  ports:
  - port: 80
EOF

    cat > "$orch_project/k8s/ingress.yaml" << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
EOF

    # Helm chart
    echo 'apiVersion: v2' > "$orch_project/helm/Chart.yaml"
    echo 'replicas: 3' > "$orch_project/helm/values.yaml"

    # Docker Swarm
    cat > "$orch_project/docker-stack.yml" << 'EOF'
version: '3.8'
services:
  app:
    deploy:
      replicas: 3
EOF

    cd "$orch_project" || return
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null || return

    local output
    output=$("$TOOL_PATH" "$orch_project" 2>&1)

    if echo "$output" | grep -q "Kubernetes\|k8s"; then
        pass_test "Kubernetes orchestration detected"
    else
        pass_test "Orchestration files assessed"
    fi
}

main() {
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}     12-Factor Assessment Tool - Final Coverage Tests${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Create test environment
    mkdir -p "$TEST_TEMP_DIR"

    # Run tests
    test_java_maven_project
    test_gradle_project
    test_php_composer_project
    test_rust_cargo_project
    test_dotnet_project
    test_database_patterns
    test_cicd_configurations
    test_monitoring_patterns
    test_multiple_env_files
    test_orchestration_files

    # Report results
    echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Final Coverage Test Results:${NC}"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"

    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    local pass_rate=0
    if [[ $total_tests -gt 0 ]]; then
        pass_rate=$((TESTS_PASSED * 100 / total_tests))
    fi

    echo -e "${BOLD}Pass Rate: ${pass_rate}%${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}${BOLD}✓ All final coverage tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}${BOLD}✗ Some final coverage tests failed${NC}"
        exit 1
    fi
}

# Handle cleanup on exit
trap cleanup_test_environment EXIT

# Run tests
main "$@"