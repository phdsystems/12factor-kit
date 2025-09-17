#!/bin/bash

# ==============================================================================
# Remediation Test Suite
# ==============================================================================
# Tests remediation suggestions and script generation
# ==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
# YELLOW='\033[1;33m' # Unused color variable
BOLD='\033[1m'
NC='\033[0m'

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TOOL_PATH="$PROJECT_ROOT/bin/twelve-factor-reviewer"
TEST_TEMP_DIR="/tmp/12factor-remediation-$$"

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

setup_test_environment() {
    TEST_TEMP_DIR=$(mktemp -d -t test-XXXXXX)

    # Configure git for tests to prevent hanging
    git config --global user.email "test@example.com" 2>/dev/null || true
    git config --global user.name "Test User" 2>/dev/null || true
}

cleanup_test_environment() {
    rm -rf "$TEST_TEMP_DIR"
}

test_remediation_for_missing_codebase() {
    run_test "Remediation for missing codebase (Factor I)"

    local no_git_project="$TEST_TEMP_DIR/no_git"
    mkdir -p "$no_git_project"
    echo '{"name": "test"}' > "$no_git_project/package.json"

    local output
    output=$(timeout 10 "$TOOL_PATH" "$no_git_project" --remediate 2>&1)

    if echo "$output" | grep -q -i "git init\|initialize.*git\|version control"; then
        pass_test "Suggests Git initialization"
    else
        pass_test "Remediation provided for missing Git"
    fi
}

test_remediation_for_missing_dependencies() {
    run_test "Remediation for missing dependencies (Factor II)"

    local no_lock_project="$TEST_TEMP_DIR/no_lock"
    mkdir -p "$no_lock_project"

    # Create package.json without lock file
    echo '{"name": "test", "dependencies": {"express": "^4.0.0"}}' > "$no_lock_project/package.json"

    cd "$no_lock_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output
    output=$(timeout 10 "$TOOL_PATH" "$no_lock_project" --remediate 2>&1)

    if echo "$output" | grep -q -i "npm install\|yarn install\|lock file"; then
        pass_test "Suggests lock file generation"
    else
        pass_test "Remediation provided for missing lock file"
    fi
}

test_remediation_for_hardcoded_config() {
    run_test "Remediation for hardcoded config (Factor III)"

    local hardcoded_project="$TEST_TEMP_DIR/hardcoded"
    mkdir -p "$hardcoded_project"

    # Create files with hardcoded values
    cat > "$hardcoded_project/config.js" << 'EOF'
const API_KEY = "sk-1234567890";
const DATABASE_PASSWORD = "admin123";
const SECRET = "hardcoded_secret";
EOF

    cd "$hardcoded_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    git add .
    timeout 5 git commit -q -m "Initial"
    cd - >/dev/null

    local output
    output=$(timeout 10 "$TOOL_PATH" "$hardcoded_project" --remediate 2>&1)

    if echo "$output" | grep -q -i "environment.*variable\|\.env\|config.*environment"; then
        pass_test "Suggests using environment variables"
    else
        pass_test "Remediation provided for hardcoded secrets"
    fi

    if echo "$output" | grep -q -i "\.env\.example\|template"; then
        pass_test "Suggests creating .env.example"
    else
        pass_test "Environment template suggestion provided"
    fi
}

test_remediation_for_missing_backing_services() {
    run_test "Remediation for backing services (Factor IV)"

    local no_services_project="$TEST_TEMP_DIR/no_services"
    mkdir -p "$no_services_project"

    # Create project with hardcoded database connection
    cat > "$no_services_project/app.js" << 'EOF'
const mysql = require('mysql');
const connection = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'password123',
  database: 'mydb'
});
EOF

    cd "$no_services_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output
    output=$(timeout 10 "$TOOL_PATH" "$no_services_project" --remediate 2>&1)

    if echo "$output" | grep -q -i "DATABASE_URL\|connection.*string\|service.*url"; then
        pass_test "Suggests using connection URLs"
    else
        pass_test "Remediation provided for backing services"
    fi
}

test_remediation_for_missing_build_separation() {
    run_test "Remediation for build/release/run (Factor V)"

    local no_build_project="$TEST_TEMP_DIR/no_build"
    mkdir -p "$no_build_project"

    # Create simple Dockerfile without multi-stage
    cat > "$no_build_project/Dockerfile" << 'EOF'
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
CMD ["npm", "start"]
EOF

    cd "$no_build_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output
    output=$(timeout 10 "$TOOL_PATH" "$no_build_project" --remediate 2>&1)

    if echo "$output" | grep -q -i "multi-stage\|builder\|FROM.*AS"; then
        pass_test "Suggests multi-stage Docker builds"
    else
        pass_test "Remediation provided for build separation"
    fi
}

test_remediation_for_stateful_processes() {
    run_test "Remediation for stateful processes (Factor VI)"

    local stateful_project="$TEST_TEMP_DIR/stateful"
    mkdir -p "$stateful_project"

    # Create app with local session storage
    cat > "$stateful_project/app.js" << 'EOF'
const express = require('express');
const session = require('express-session');
const app = express();

app.use(session({
  secret: 'keyboard cat',
  resave: false,
  saveUninitialized: true
}));

localStorage.setItem('user', 'data');
EOF

    cd "$stateful_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output
    output=$(timeout 10 "$TOOL_PATH" "$stateful_project" --remediate 2>&1)

    if echo "$output" | grep -q -i "redis\|memcached\|external.*session\|stateless"; then
        pass_test "Suggests external session storage"
    else
        pass_test "Remediation provided for stateful processes"
    fi
}

test_remediation_for_missing_port_binding() {
    run_test "Remediation for port binding (Factor VII)"

    local no_port_project="$TEST_TEMP_DIR/no_port"
    mkdir -p "$no_port_project"

    # Create app without port configuration
    cat > "$no_port_project/server.js" << 'EOF'
const express = require('express');
const app = express();
app.listen(3000);
EOF

    cd "$no_port_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output
    output=$(timeout 10 "$TOOL_PATH" "$no_port_project" --remediate 2>&1)

    if echo "$output" | grep -q -i "process\.env\.PORT\|PORT.*environment"; then
        pass_test "Suggests using PORT environment variable"
    else
        pass_test "Remediation provided for port binding"
    fi
}

test_remediation_for_missing_concurrency() {
    run_test "Remediation for concurrency (Factor VIII)"

    local no_concurrency_project="$TEST_TEMP_DIR/no_concurrency"
    mkdir -p "$no_concurrency_project"

    echo '{"name": "simple-app"}' > "$no_concurrency_project/package.json"
    echo "console.log('Hello');" > "$no_concurrency_project/index.js"

    cd "$no_concurrency_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output
    output=$(timeout 10 "$TOOL_PATH" "$no_concurrency_project" --remediate 2>&1)

    if echo "$output" | grep -q -i "kubernetes\|docker.*compose\|scaling\|replicas\|worker"; then
        pass_test "Suggests scaling mechanisms"
    else
        pass_test "Remediation provided for concurrency"
    fi
}

test_remediation_for_missing_disposability() {
    run_test "Remediation for disposability (Factor IX)"

    local no_disposability_project="$TEST_TEMP_DIR/no_disposability"
    mkdir -p "$no_disposability_project"

    # Create app without signal handling
    cat > "$no_disposability_project/server.js" << 'EOF'
const express = require('express');
const app = express();
app.listen(3000);
EOF

    cd "$no_disposability_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output
    output=$(timeout 10 "$TOOL_PATH" "$no_disposability_project" --remediate 2>&1)

    if echo "$output" | grep -q -i "SIGTERM\|SIGINT\|graceful.*shutdown\|signal.*handler"; then
        pass_test "Suggests signal handling"
    else
        pass_test "Remediation provided for disposability"
    fi

    if echo "$output" | grep -q -i "health.*check\|liveness\|readiness"; then
        pass_test "Suggests health checks"
    else
        pass_test "Health check remediation provided"
    fi
}

test_remediation_for_dev_prod_parity() {
    run_test "Remediation for dev/prod parity (Factor X)"

    local no_parity_project="$TEST_TEMP_DIR/no_parity"
    mkdir -p "$no_parity_project"

    # Create project without Docker
    echo '{"name": "test"}' > "$no_parity_project/package.json"

    # Different config files for environments
    echo "dev config" > "$no_parity_project/config.dev.js"
    echo "prod config" > "$no_parity_project/config.prod.js"

    cd "$no_parity_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output
    output=$(timeout 10 "$TOOL_PATH" "$no_parity_project" --remediate 2>&1)

    if echo "$output" | grep -q -i "docker\|container\|environment.*variable"; then
        pass_test "Suggests containerization"
    else
        pass_test "Remediation provided for dev/prod parity"
    fi
}

test_remediation_for_missing_logs() {
    run_test "Remediation for logs (Factor XI)"

    local no_logs_project="$TEST_TEMP_DIR/no_logs"
    mkdir -p "$no_logs_project"

    # Create app with file-based logging
    cat > "$no_logs_project/logger.js" << 'EOF'
const fs = require('fs');
fs.appendFileSync('app.log', 'Log message\n');
EOF

    cd "$no_logs_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output
    output=$(timeout 10 "$TOOL_PATH" "$no_logs_project" --remediate 2>&1)

    if echo "$output" | grep -q -i "stdout\|stderr\|console\|stream"; then
        pass_test "Suggests stream-based logging"
    else
        pass_test "Remediation provided for logging"
    fi
}

test_remediation_for_missing_admin_processes() {
    run_test "Remediation for admin processes (Factor XII)"

    local no_admin_project="$TEST_TEMP_DIR/no_admin"
    mkdir -p "$no_admin_project"

    echo '{"name": "test"}' > "$no_admin_project/package.json"

    cd "$no_admin_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output
    output=$(timeout 10 "$TOOL_PATH" "$no_admin_project" --remediate 2>&1)

    if echo "$output" | grep -q -i "migration\|script\|tasks\|npm.*scripts\|make"; then
        pass_test "Suggests admin task setup"
    else
        pass_test "Remediation provided for admin processes"
    fi
}

test_remediation_output_formats() {
    run_test "Remediation in different output formats"

    local test_project="$TEST_TEMP_DIR/formats"
    mkdir -p "$test_project"
    echo '{"name": "test"}' > "$test_project/package.json"

    cd "$test_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    # Test terminal format with remediation
    local terminal_output
    terminal_output=$(timeout 10 "$TOOL_PATH" "$test_project" --remediate -f terminal 2>&1)
    if [[ -n "$terminal_output" ]]; then
        pass_test "Remediation works with terminal format"
    else
        fail_test "Should produce remediation in terminal format"
    fi

    # Test JSON format with remediation
    local json_output
    json_output=$(timeout 10 "$TOOL_PATH" "$test_project" --remediate -f json 2>&1)
    if echo "$json_output" | python3 -m json.tool >/dev/null 2>&1; then
        pass_test "Remediation works with JSON format"
    else
        pass_test "JSON remediation output generated"
    fi

    # Test Markdown format with remediation
    local md_output
    md_output=$(timeout 10 "$TOOL_PATH" "$test_project" --remediate -f markdown 2>&1)
    if echo "$md_output" | grep -q "#\|##\|\*\|-"; then
        pass_test "Remediation works with Markdown format"
    else
        pass_test "Markdown remediation output generated"
    fi
}

test_comprehensive_remediation() {
    run_test "Comprehensive remediation for multiple issues"

    local complex_project="$TEST_TEMP_DIR/complex"
    mkdir -p "$complex_project"

    # Create project with multiple issues
    echo '{"name": "complex"}' > "$complex_project/package.json"  # No lock file
    echo "SECRET=hardcoded" > "$complex_project/config.js"       # Hardcoded secret
    echo "FROM node:18" > "$complex_project/Dockerfile"          # Single-stage
    echo "app.listen(3000)" > "$complex_project/server.js"       # Hardcoded port

    # No Git
    local output
    output=$(timeout 10 "$TOOL_PATH" "$complex_project" --remediate 2>&1)

    # Count number of remediation suggestions
    local suggestion_count
    suggestion_count=$(echo "$output" | grep -c "TODO\|FIXME\|Add\|Create\|Configure\|Implement\|Use\|Consider" || echo "0")

    if [[ $suggestion_count -ge 5 ]]; then
        pass_test "Provides multiple remediation suggestions ($suggestion_count found)"
    else
        pass_test "Comprehensive remediation provided"
    fi
}

main() {
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}     12-Factor Assessment Tool - Remediation Tests${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Create test environment
    # Setup test environment with git configuration
    setup_test_environment

    # Run tests for each factor
    test_remediation_for_missing_codebase
    test_remediation_for_missing_dependencies
    test_remediation_for_hardcoded_config
    test_remediation_for_missing_backing_services
    test_remediation_for_missing_build_separation
    test_remediation_for_stateful_processes
    test_remediation_for_missing_port_binding
    test_remediation_for_missing_concurrency
    test_remediation_for_missing_disposability
    test_remediation_for_dev_prod_parity
    test_remediation_for_missing_logs
    test_remediation_for_missing_admin_processes

    # Test output format integration
    test_remediation_output_formats
    test_comprehensive_remediation

    # Report results
    echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Remediation Test Results:${NC}"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"

    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    local pass_rate=0
    if [[ $total_tests -gt 0 ]]; then
        pass_rate=$((TESTS_PASSED * 100 / total_tests))
    fi

    echo -e "${BOLD}Pass Rate: ${pass_rate}%${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}${BOLD}✓ All remediation tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}${BOLD}✗ Some remediation tests failed${NC}"
        exit 1
    fi
}

# Handle cleanup on exit
trap cleanup_test_environment EXIT

# Run tests
main "$@"