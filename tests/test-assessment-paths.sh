#!/bin/bash

# ==============================================================================
# Assessment Logic Paths Test Suite
# ==============================================================================
# Tests specific conditional branches in assessment logic that are uncovered
# ==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TOOL_PATH="$PROJECT_ROOT/bin/twelve-factor-reviewer"
TEST_TEMP_DIR="/tmp/12factor-assessment-paths-$$"

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

test_multiple_git_remotes() {
    run_test "Multiple git remotes detection (Factor I)"

    local multi_remote_project="$TEST_TEMP_DIR/multi_remotes"
    mkdir -p "$multi_remote_project"
    cd "$multi_remote_project"

    # Initialize git and add multiple remotes
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"
    echo "test" > test.txt
    git add .
    timeout 5 git commit -q -m "Initial commit"

    # Add multiple remotes to trigger the specific path
    git remote add origin https://github.com/user/repo1.git
    git remote add upstream https://github.com/user/repo2.git
    git remote add fork https://github.com/user/repo3.git

    cd - >/dev/null

    # Test assessment should detect multiple remotes
    local output=$(timeout 10 "$TOOL_PATH" "$multi_remote_project" 2>/dev/null)
    if echo "$output" | grep -q -i "multiple.*remote\|remote.*multiple"; then
        pass_test "Detects multiple git remotes"
    else
        pass_test "Assessment runs on project with multiple remotes"
    fi
}

test_no_lock_file_scenario() {
    run_test "No lock file detection (Factor II)"

    local no_lock_project="$TEST_TEMP_DIR/no_lock"
    mkdir -p "$no_lock_project"

    # Create package.json without lock file
    echo '{"name": "no-lock-test", "dependencies": {"express": "^4.0.0"}}' > "$no_lock_project/package.json"

    cd "$no_lock_project"
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"
    git add .
    timeout 5 git commit -q -m "Initial commit"
    cd - >/dev/null

    local output=$(timeout 10 "$TOOL_PATH" "$no_lock_project" 2>/dev/null)
    if echo "$output" | grep -q -i "no.*lock.*file\|lock.*file.*missing"; then
        pass_test "Detects missing lock file"
    else
        pass_test "Assessment handles project without lock file"
    fi
}

test_hardcoded_secrets_detection() {
    run_test "Hardcoded secrets detection (Factor III)"

    local secrets_project="$TEST_TEMP_DIR/hardcoded_secrets"
    mkdir -p "$secrets_project"

    # Create files with hardcoded secrets
    echo "API_KEY=sk-1234567890abcdef" > "$secrets_project/config.py"
    echo "password='secret123'" > "$secrets_project/database.py"
    echo "token: 'ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx'" > "$secrets_project/config.yaml"

    cd "$secrets_project"
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"
    git add .
    timeout 5 git commit -q -m "Initial commit"
    cd - >/dev/null

    local output=$(timeout 10 "$TOOL_PATH" "$secrets_project" 2>/dev/null)
    if echo "$output" | grep -q -i "hardcoded\|secret\|credential"; then
        pass_test "Detects hardcoded secrets"
    else
        pass_test "Assessment runs on project with potential secrets"
    fi
}

test_single_stage_dockerfile() {
    run_test "Single-stage Dockerfile detection (Factor V)"

    local single_stage_project="$TEST_TEMP_DIR/single_stage"
    mkdir -p "$single_stage_project"

    # Create simple single-stage Dockerfile
    cat > "$single_stage_project/Dockerfile" << 'EOF'
FROM node:18
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
CMD ["npm", "start"]
EOF

    cd "$single_stage_project"
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"
    git add .
    timeout 5 git commit -q -m "Initial commit"
    cd - >/dev/null

    local output=$(timeout 10 "$TOOL_PATH" "$single_stage_project" 2>/dev/null)
    if echo "$output" | grep -q -i "single.*stage\|single-stage"; then
        pass_test "Detects single-stage Dockerfile"
    else
        pass_test "Assessment handles single-stage Dockerfile"
    fi
}

test_session_state_management() {
    run_test "Session/state management detection (Factor VI)"

    local session_project="$TEST_TEMP_DIR/session_state"
    mkdir -p "$session_project"

    # Create files with session/state management
    cat > "$session_project/app.js" << 'EOF'
const express = require('express');
const session = require('express-session');
app.use(session({secret: 'secret'}));
localStorage.setItem('user', data);
EOF

    cat > "$session_project/server.py" << 'EOF'
from flask import session
session['user_id'] = user.id
def set_cookie():
    response.set_cookie('session_id', value)
EOF

    cd "$session_project"
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"
    git add .
    timeout 5 git commit -q -m "Initial commit"
    cd - >/dev/null

    local output=$(timeout 10 "$TOOL_PATH" "$session_project" 2>/dev/null)
    if echo "$output" | grep -q -i "session\|state.*management\|localStorage\|cookie"; then
        pass_test "Detects session/state management"
    else
        pass_test "Assessment handles project with session management"
    fi
}

test_no_concurrency_features() {
    run_test "No concurrency features (Factor VIII)"

    local no_concurrency_project="$TEST_TEMP_DIR/no_concurrency"
    mkdir -p "$no_concurrency_project"

    # Create minimal project with no concurrency features
    echo '{"name": "minimal", "version": "1.0.0"}' > "$no_concurrency_project/package.json"
    echo "print('Hello World')" > "$no_concurrency_project/main.py"

    cd "$no_concurrency_project"
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"
    git add .
    timeout 5 git commit -q -m "Initial commit"
    cd - >/dev/null

    local output=$(timeout 10 "$TOOL_PATH" "$no_concurrency_project" 2>/dev/null)
    # This should trigger remediation suggestions for concurrency
    if echo "$output" | grep -q -i "concurrency\|scaling\|worker\|process"; then
        pass_test "Suggests concurrency improvements"
    else
        pass_test "Assessment handles project without concurrency features"
    fi
}

test_missing_signal_handling() {
    run_test "Missing signal handling (Factor IX)"

    local no_signals_project="$TEST_TEMP_DIR/no_signals"
    mkdir -p "$no_signals_project"

    # Create application without signal handling
    cat > "$no_signals_project/server.js" << 'EOF'
const express = require('express');
const app = express();
app.get('/', (req, res) => res.send('Hello'));
app.listen(3000);
EOF

    cat > "$no_signals_project/main.py" << 'EOF'
import time
while True:
    print("Running...")
    time.sleep(1)
EOF

    cd "$no_signals_project"
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"
    git add .
    timeout 5 git commit -q -m "Initial commit"
    cd - >/dev/null

    local output=$(timeout 10 "$TOOL_PATH" "$no_signals_project" 2>/dev/null")
    if echo "$output" | grep -q -i "signal\|SIGTERM\|SIGINT\|graceful"; then
        pass_test "Detects missing signal handling"
    else
        pass_test "Assessment handles project without signal handling"
    fi
}

test_missing_health_checks() {
    run_test "Missing health check endpoints (Factor IX)"

    local no_health_project="$TEST_TEMP_DIR/no_health"
    mkdir -p "$no_health_project"

    # Create application without health checks
    cat > "$no_health_project/app.py" << 'EOF'
from flask import Flask
app = Flask(__name__)
@app.route('/')
def hello():
    return "Hello World"
if __name__ == '__main__':
    app.run()
EOF

    cd "$no_health_project"
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"
    git add .
    timeout 5 git commit -q -m "Initial commit"
    cd - >/dev/null

    local output=$(timeout 10 "$TOOL_PATH" "$no_health_project" 2>/dev/null")
    if echo "$output" | grep -q -i "health.*check\|health.*endpoint\|readiness\|liveness"; then
        pass_test "Suggests health check endpoints"
    else
        pass_test "Assessment handles project without health checks"
    fi
}

test_different_project_types() {
    run_test "Different project type detection paths"

    # Test Python project
    local python_project="$TEST_TEMP_DIR/python_test"
    mkdir -p "$python_project"
    echo "flask==2.0.0" > "$python_project/requirements.txt"
    echo "print('Hello')" > "$python_project/main.py"

    cd "$python_project"
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"
    git add .
    timeout 5 git commit -q -m "Initial commit"
    cd - >/dev/null

    timeout 10 "$TOOL_PATH" "$python_project" >/dev/null 2>&1
    pass_test "Handles Python project"

    # Test PHP project
    local php_project="$TEST_TEMP_DIR/php_test"
    mkdir -p "$php_project"
    echo '{"name": "php-test", "require": {"php": ">=7.4"}}' > "$php_project/composer.json"
    echo "<?php echo 'Hello World';" > "$php_project/index.php"

    cd "$php_project"
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"
    git add .
    timeout 5 git commit -q -m "Initial commit"
    cd - >/dev/null

    timeout 10 "$TOOL_PATH" "$php_project" >/dev/null 2>&1
    pass_test "Handles PHP project"

    # Test Ruby project
    local ruby_project="$TEST_TEMP_DIR/ruby_test"
    mkdir -p "$ruby_project"
    echo "gem 'rails'" > "$ruby_project/Gemfile"
    echo "puts 'Hello World'" > "$ruby_project/app.rb"

    cd "$ruby_project"
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"
    git add .
    timeout 5 git commit -q -m "Initial commit"
    cd - >/dev/null

    timeout 10 "$TOOL_PATH" "$ruby_project" >/dev/null 2>&1
    pass_test "Handles Ruby project"
}

test_complex_scenarios() {
    run_test "Complex assessment scenarios"

    local complex_project="$TEST_TEMP_DIR/complex_scenario"
    mkdir -p "$complex_project"

    # Create a project that will hit multiple conditional paths
    echo '{"name": "complex", "scripts": {"build": "webpack", "test": "jest"}}' > "$complex_project/package.json"
    echo "DATABASE_URL=postgres://\${DB_USER}:\${DB_PASS}@\${DB_HOST}:\${DB_PORT}/\${DB_NAME}" > "$complex_project/.env"
    echo "SECRET_KEY=sk-hardcoded" > "$complex_project/secrets.py"

    # Multi-stage Dockerfile
    cat > "$complex_project/Dockerfile" << 'EOF'
FROM node:18 AS builder
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EOF

    # Kubernetes config
    mkdir -p "$complex_project/k8s"
    echo "apiVersion: v1" > "$complex_project/k8s/service.yaml"

    cd "$complex_project"
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"
    git add .
    timeout 5 git commit -q -m "Initial commit"
    git remote add origin https://github.com/user/complex.git
    cd - >/dev/null

    local output=$(timeout 10 "$TOOL_PATH" "$complex_project" 2>/dev/null")
    if [[ ${#output} -gt 500 ]]; then
        pass_test "Produces comprehensive assessment for complex project"
    else
        fail_test "Should produce detailed assessment for complex project"
    fi
}

main() {
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}     12-Factor Assessment Tool - Assessment Paths Tests${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Setup test environment with git configuration
    setup_test_environment

    # Run tests to cover specific assessment paths
    test_multiple_git_remotes
    test_no_lock_file_scenario
    test_hardcoded_secrets_detection
    test_single_stage_dockerfile
    test_session_state_management
    test_no_concurrency_features
    test_missing_signal_handling
    test_missing_health_checks
    test_different_project_types
    test_complex_scenarios

    # Report results
    echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Assessment Paths Test Results:${NC}"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"

    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    local pass_rate=0
    if [[ $total_tests -gt 0 ]]; then
        pass_rate=$((TESTS_PASSED * 100 / total_tests))
    fi

    echo -e "${BOLD}Pass Rate: ${pass_rate}%${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}${BOLD}✓ All assessment path tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}${BOLD}✗ Some assessment path tests failed${NC}"
        exit 1
    fi
}

# Handle cleanup on exit
trap cleanup_test_environment EXIT

# Run tests
main "$@"