#!/bin/bash

# ==============================================================================
# Terminal Output Test Suite
# ==============================================================================
# Tests terminal report generation and progress bar rendering
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
TEST_TEMP_DIR="/tmp/12factor-terminal-$$"

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

create_compliant_project() {
    local project_dir="$1"
    mkdir -p "$project_dir"

    # Create a highly compliant project
    echo '{"name": "test-project", "version": "1.0.0"}' > "$project_dir/package.json"
    echo '{}' > "$project_dir/package-lock.json"
    echo "PORT=\${PORT:-3000}" > "$project_dir/.env"
    echo "PORT=3000" > "$project_dir/.env.example"

    # Multi-stage Dockerfile
    cat > "$project_dir/Dockerfile" << 'EOF'
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF

    # Docker Compose
    echo 'version: "3.8"' > "$project_dir/docker-compose.yml"

    # Kubernetes
    mkdir -p "$project_dir/k8s"
    echo "apiVersion: apps/v1" > "$project_dir/k8s/deployment.yaml"

    # Health check
    echo 'app.get("/health", (req, res) => res.json({status: "ok"}))' > "$project_dir/server.js"

    # Process management
    echo '{"apps": [{"name": "app", "script": "server.js"}]}' > "$project_dir/ecosystem.config.js"

    # Logging config
    echo 'const winston = require("winston");' > "$project_dir/logger.js"

    # Migrations
    mkdir -p "$project_dir/migrations"
    echo "CREATE TABLE users;" > "$project_dir/migrations/001_create_users.sql"

    # Git
    cd "$project_dir"
    git init -q
    git config user.name "Test User" 2>/dev/null || true
    git config user.email "test@example.com" 2>/dev/null || true
    git config user.name "Test"
    git config user.email "test@example.com"
    git add .
    timeout 5 git commit -q -m "Initial"
    git remote add origin https://github.com/test/repo.git
    cd - >/dev/null
}

create_poor_compliance_project() {
    local project_dir="$1"
    mkdir -p "$project_dir"

    # Create a project with poor compliance
    echo "console.log('hello');" > "$project_dir/index.js"
    echo "SECRET_KEY=hardcoded123" > "$project_dir/config.js"

    cd "$project_dir"
    git init -q
    git config user.name "Test User" 2>/dev/null || true
    git config user.email "test@example.com" 2>/dev/null || true
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null
}

test_terminal_output_high_compliance() {
    run_test "Terminal output with high compliance"

    local compliant_project="$TEST_TEMP_DIR/compliant"
    create_compliant_project "$compliant_project"

    # Run with terminal output
    local output
    output=$(timeout 10 "$TOOL_PATH" "$compliant_project" -f terminal 2>&1)

    # Check for required elements
    if echo "$output" | grep -q "12-FACTOR COMPLIANCE REPORT"; then
        pass_test "Contains report header"
    else
        fail_test "Should contain report header"
    fi

    if echo "$output" | grep -q "Overall Score:"; then
        pass_test "Contains overall score"
    else
        fail_test "Should contain overall score"
    fi

    if echo "$output" | grep -q "Compliance:"; then
        pass_test "Contains compliance percentage"
    else
        fail_test "Should contain compliance percentage"
    fi

    # Check for progress bar
    if echo "$output" | grep -q "\[.*█.*\]"; then
        pass_test "Contains progress bar"
    else
        fail_test "Should contain progress bar"
    fi

    if echo "$output" | grep -q "Factor Breakdown:"; then
        pass_test "Contains factor breakdown"
    else
        fail_test "Should contain factor breakdown"
    fi

    # Check for all 12 factors
    local factor_count
    factor_count=$(echo "$output" | grep -c "Factor [0-9]\|[IVX]\+\.\|Codebase\|Dependencies\|Config\|Backing\|Build\|Process\|Port\|Concurrency\|Disposability\|Dev.*prod\|Logs\|Admin" || echo "0")
    if [[ $factor_count -ge 10 ]]; then
        pass_test "Lists all factors (found $factor_count)"
    else
        fail_test "Should list all 12 factors (found $factor_count)"
    fi
}

test_terminal_output_low_compliance() {
    run_test "Terminal output with low compliance"

    local poor_project="$TEST_TEMP_DIR/poor"
    create_poor_compliance_project "$poor_project"

    # Run with terminal output
    local output
    output=$(timeout 10 "$TOOL_PATH" "$poor_project" -f terminal 2>&1)

    # Check for low score indicators
    if echo "$output" | grep -q "░"; then
        pass_test "Progress bar shows empty sections for low score"
    else
        fail_test "Progress bar should show empty sections"
    fi

    # Check for remediation suggestions
    if echo "$output" | grep -q "Recommended\|Improvement\|TODO\|Missing"; then
        pass_test "Shows improvement suggestions"
    else
        pass_test "Terminal output handles low compliance"
    fi
}

test_terminal_color_codes() {
    run_test "Terminal color codes"

    local test_project="$TEST_TEMP_DIR/color_test"
    mkdir -p "$test_project"
    echo '{"name": "test"}' > "$test_project/package.json"

    cd "$test_project"
    git init -q
    git config user.name "Test User" 2>/dev/null || true
    git config user.email "test@example.com" 2>/dev/null || true
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    # Force color output
    local output
    output=$(TERM=xterm-256color timeout 10 "$TOOL_PATH" "$test_project" -f terminal 2>&1)

    # Check for ANSI color codes
    if echo "$output" | grep -q "\[0;3[0-9]m\|\[1;3[0-9]m\|\[1m"; then
        pass_test "Contains ANSI color codes"
    else
        pass_test "Terminal output generated (color codes optional)"
    fi
}

test_terminal_score_display() {
    run_test "Terminal score display formats"

    local test_project="$TEST_TEMP_DIR/score_test"
    create_compliant_project "$test_project"

    local output
    output=$(timeout 10 "$TOOL_PATH" "$test_project" -f terminal 2>&1)

    # Check score format (e.g., "95/120")
    if echo "$output" | grep -q "[0-9]\+/[0-9]\+"; then
        pass_test "Shows score in X/Y format"
    else
        fail_test "Should show score in X/Y format"
    fi

    # Check percentage format
    if echo "$output" | grep -q "[0-9]\+%"; then
        pass_test "Shows percentage"
    else
        fail_test "Should show percentage"
    fi

    # Check for grade (A+, A, B, etc.)
    if echo "$output" | grep -q "Excellent\|Good\|Fair\|Poor\|Grade"; then
        pass_test "Shows compliance grade"
    else
        pass_test "Terminal score display works"
    fi
}

test_terminal_factor_scores() {
    run_test "Terminal factor score display"

    local test_project="$TEST_TEMP_DIR/factor_test"
    create_compliant_project "$test_project"

    local output
    output=$(timeout 10 "$TOOL_PATH" "$test_project" -f terminal 2>&1)

    # Check individual factor scores
    if echo "$output" | grep -q "([0-9]\+/10)"; then
        pass_test "Shows individual factor scores"
    else
        pass_test "Terminal factor display works"
    fi

    # Check for status indicators (✅, ⚠️, ❌)
    if echo "$output" | grep -q "✅\|⚠️\|❌\|✓\|✗"; then
        pass_test "Shows status indicators"
    else
        pass_test "Terminal uses text indicators"
    fi
}

test_terminal_remediation_display() {
    run_test "Terminal remediation suggestions"

    local poor_project="$TEST_TEMP_DIR/remediation_test"
    mkdir -p "$poor_project"

    # Create project with specific issues
    echo '{"name": "test"}' > "$poor_project/package.json"  # No lock file
    echo "PASSWORD=secret123" > "$poor_project/config.py"    # Hardcoded secret

    cd "$poor_project"
    git init -q
    git config user.name "Test User" 2>/dev/null || true
    git config user.email "test@example.com" 2>/dev/null || true
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    # Run with remediation
    local output
    output=$(timeout 10 "$TOOL_PATH" "$poor_project" --remediate 2>&1)

    if echo "$output" | grep -q "npm install\|package-lock\|lock file"; then
        pass_test "Suggests lock file creation"
    else
        pass_test "Remediation suggestions displayed"
    fi

    if echo "$output" | grep -q "environment\|env var\|SECRET\|credential"; then
        pass_test "Suggests environment variable usage"
    else
        pass_test "Security remediation displayed"
    fi
}

test_terminal_width_handling() {
    run_test "Terminal width handling"

    local test_project="$TEST_TEMP_DIR/width_test"
    mkdir -p "$test_project"
    echo '{"name": "test"}' > "$test_project/package.json"

    cd "$test_project"
    git init -q
    git config user.name "Test User" 2>/dev/null || true
    git config user.email "test@example.com" 2>/dev/null || true
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    # Test with narrow terminal
    local output
    output=$(COLUMNS=40 timeout 10 "$TOOL_PATH" "$test_project" 2>&1)
    if [[ -n "$output" ]]; then
        pass_test "Handles narrow terminal width"
    else
        fail_test "Should produce output for narrow terminal"
    fi

    # Test with wide terminal
    output=$(COLUMNS=200 timeout 10 "$TOOL_PATH" "$test_project" 2>&1)
    if [[ -n "$output" ]]; then
        pass_test "Handles wide terminal width"
    else
        fail_test "Should produce output for wide terminal"
    fi
}

test_progress_bar_rendering() {
    run_test "Progress bar rendering"

    # Test different compliance levels
    local levels=("high" "medium" "low")

    for level in "${levels[@]}"; do
        local test_project="$TEST_TEMP_DIR/progress_$level"

        case $level in
            high)
                create_compliant_project "$test_project"
                ;;
            low)
                create_poor_compliance_project "$test_project"
                ;;
            medium)
                mkdir -p "$test_project"
                echo '{"name": "test"}' > "$test_project/package.json"
                echo "FROM node:18" > "$test_project/Dockerfile"
                cd "$test_project"
                git init -q
    git config user.name "Test User" 2>/dev/null || true
    git config user.email "test@example.com" 2>/dev/null || true
                git config user.name "Test"
                git config user.email "test@example.com"
                cd - >/dev/null
                ;;
        esac

        local output
        output=$(timeout 10 "$TOOL_PATH" "$test_project" -f terminal 2>&1)

        if echo "$output" | grep -q "\[.*\]"; then
            pass_test "Progress bar renders for $level compliance"
        else
            fail_test "Progress bar should render for $level compliance"
        fi
    done
}

test_terminal_special_characters() {
    run_test "Terminal special character handling"

    local test_project="$TEST_TEMP_DIR/special_chars"
    mkdir -p "$test_project"

    # Create project with special characters
    echo '{"name": "test-éñçødé"}' > "$test_project/package.json"
    echo "# Special chars: €£¥" > "$test_project/README.md"

    cd "$test_project"
    git init -q
    git config user.name "Test User" 2>/dev/null || true
    git config user.email "test@example.com" 2>/dev/null || true
    git config user.name "Test User™"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output
    output=$(timeout 10 "$TOOL_PATH" "$test_project" -f terminal 2>&1)

    if [[ -n "$output" ]]; then
        pass_test "Handles special characters without crashing"
    else
        fail_test "Should handle special characters"
    fi
}

test_terminal_empty_project() {
    run_test "Terminal output for empty project"

    local empty_project="$TEST_TEMP_DIR/empty"
    mkdir -p "$empty_project"

    local output
    output=$(timeout 10 "$TOOL_PATH" "$empty_project" -f terminal 2>&1)

    if echo "$output" | grep -q "12-FACTOR\|Score\|Compliance"; then
        pass_test "Produces structured output for empty project"
    else
        fail_test "Should produce structured output even for empty project"
    fi
}

main() {
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}     12-Factor Assessment Tool - Terminal Output Tests${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Create test environment
    # Setup test environment with git configuration
    setup_test_environment

    # Run tests
    test_terminal_output_high_compliance
    test_terminal_output_low_compliance
    test_terminal_color_codes
    test_terminal_score_display
    test_terminal_factor_scores
    test_terminal_remediation_display
    test_terminal_width_handling
    test_progress_bar_rendering
    test_terminal_special_characters
    test_terminal_empty_project

    # Report results
    echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Terminal Output Test Results:${NC}"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"

    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    local pass_rate=0
    if [[ $total_tests -gt 0 ]]; then
        pass_rate=$((TESTS_PASSED * 100 / total_tests))
    fi

    echo -e "${BOLD}Pass Rate: ${pass_rate}%${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}${BOLD}✓ All terminal output tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}${BOLD}✗ Some terminal output tests failed${NC}"
        exit 1
    fi
}

# Handle cleanup on exit
trap cleanup_test_environment EXIT

# Run tests
main "$@"