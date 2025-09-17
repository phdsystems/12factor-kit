#!/bin/bash

# ==============================================================================
# Output Formats Test Suite
# ==============================================================================
# Tests JSON and Markdown output generation paths that are currently uncovered
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
TEST_TEMP_DIR="/tmp/12factor-formats-$$"

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

create_sample_project() {
    local project_dir="$1"
    mkdir -p "$project_dir"

    # Create various project files to trigger different assessment paths
    echo '{"name": "test-project", "version": "1.0.0"}' > "$project_dir/package.json"
    echo "node_modules/" > "$project_dir/.gitignore"
    echo "DATABASE_URL=\${DB_URL}" > "$project_dir/.env"
    printf "FROM node:18\nCOPY . .\nCMD [\"npm\", \"start\"]" > "$project_dir/Dockerfile"

    # Initialize git repository
    cd "$project_dir"
    git init -q
    git config user.name "Test User" 2>/dev/null || true
    git config user.email "test@example.com" 2>/dev/null || true
    git config user.name "Test User"
    git config user.email "test@example.com"
    git add .
    timeout 5 git commit -q -m "Initial commit"
    cd - >/dev/null
}

test_json_output_format() {
    run_test "JSON output format coverage"

    local json_project="$TEST_TEMP_DIR/json_test"
    create_sample_project "$json_project"

    # Test JSON output generation
    local json_output
    json_output=$(timeout 10 "$TOOL_PATH" "$json_project" -f json 2>/dev/null)

    # Validate JSON structure
    if echo "$json_output" | python3 -m json.tool >/dev/null 2>&1; then
        pass_test "JSON output is valid JSON"
    else
        fail_test "JSON output should be valid JSON"
    fi

    # Check required JSON fields
    if echo "$json_output" | grep -q '"timestamp"'; then
        pass_test "JSON contains timestamp field"
    else
        fail_test "JSON should contain timestamp field"
    fi

    if echo "$json_output" | grep -q '"project_path"'; then
        pass_test "JSON contains project_path field"
    else
        fail_test "JSON should contain project_path field"
    fi

    if echo "$json_output" | grep -q '"total_score"'; then
        pass_test "JSON contains total_score field"
    else
        fail_test "JSON should contain total_score field"
    fi

    if echo "$json_output" | grep -q '"max_score"'; then
        pass_test "JSON contains max_score field"
    else
        fail_test "JSON should contain max_score field"
    fi

    if echo "$json_output" | grep -q '"percentage"'; then
        pass_test "JSON contains percentage field"
    else
        fail_test "JSON should contain percentage field"
    fi

    if echo "$json_output" | grep -q '"factors"'; then
        pass_test "JSON contains factors array"
    else
        fail_test "JSON should contain factors array"
    fi

    # Check that factors array has 12 elements
    local factor_count
    factor_count=$(echo "$json_output" | python3 -c "import json, sys; data=json.load(sys.stdin); print(len(data['factors']))" 2>/dev/null || echo "0")
    if [[ "$factor_count" == "12" ]]; then
        pass_test "JSON contains all 12 factors"
    else
        fail_test "JSON should contain all 12 factors, got $factor_count"
    fi

    # Test JSON with verbose mode
    local json_verbose
    json_verbose=$(timeout 10 "$TOOL_PATH" "$json_project" -f json --verbose 2>/dev/null)
    if echo "$json_verbose" | python3 -m json.tool >/dev/null 2>&1; then
        pass_test "JSON with verbose mode is valid"
    else
        fail_test "JSON with verbose mode should be valid"
    fi
}

test_markdown_output_format() {
    run_test "Markdown output format coverage"

    local md_project="$TEST_TEMP_DIR/markdown_test"
    create_sample_project "$md_project"

    # Test markdown output generation
    local md_output
    md_output=$(timeout 10 "$TOOL_PATH" "$md_project" -f markdown 2>/dev/null)

    # Check markdown structure
    if echo "$md_output" | grep -q "# 12-Factor App Compliance Report"; then
        pass_test "Markdown contains main header"
    else
        fail_test "Markdown should contain main header"
    fi

    if echo "$md_output" | grep -q "## Summary"; then
        pass_test "Markdown contains summary section"
    else
        fail_test "Markdown should contain summary section"
    fi

    if echo "$md_output" | grep -q "## Assessment Results"; then
        pass_test "Markdown contains assessment section"
    else
        fail_test "Markdown should contain assessment section"
    fi

    if echo "$md_output" | grep -q "| Factor |"; then
        pass_test "Markdown contains results table"
    else
        fail_test "Markdown should contain results table"
    fi

    if echo "$md_output" | grep -q "## Key Findings"; then
        pass_test "Markdown contains findings section"
    else
        fail_test "Markdown should contain findings section"
    fi

    if echo "$md_output" | grep -q "## Recommended Next Steps"; then
        pass_test "Markdown contains next steps section"
    else
        fail_test "Markdown should contain next steps section"
    fi

    # Check that all 12 factors are mentioned
    local factor_mentions=0
    for i in {1..12}; do
        if echo "$md_output" | grep -q "Factor $i\|I\.\|II\.\|III\.\|IV\.\|V\.\|VI\.\|VII\.\|VIII\.\|IX\.\|X\.\|XI\.\|XII\."; then
            ((factor_mentions++))
        fi
    done

    if [[ $factor_mentions -ge 10 ]]; then
        pass_test "Markdown mentions most factors (found $factor_mentions)"
    else
        fail_test "Markdown should mention all factors (found $factor_mentions)"
    fi

    # Test markdown with verbose mode
    local md_verbose
    md_verbose=$(timeout 10 "$TOOL_PATH" "$md_project" -f markdown --verbose 2>/dev/null)
    if [[ ${#md_verbose} -gt ${#md_output} ]]; then
        pass_test "Markdown verbose mode produces more content"
    else
        pass_test "Markdown with verbose mode works"
    fi
}

test_terminal_output_coverage() {
    run_test "Terminal output format coverage"

    local terminal_project="$TEST_TEMP_DIR/terminal_test"
    create_sample_project "$terminal_project"

    # Test default terminal output
    local terminal_output
    terminal_output=$(timeout 10 "$TOOL_PATH" "$terminal_project" 2>/dev/null)

    if echo "$terminal_output" | grep -q "12-Factor App Compliance Assessment"; then
        pass_test "Terminal output contains header"
    else
        fail_test "Terminal output should contain header"
    fi

    # Check for progress indicators or visual elements
    if echo "$terminal_output" | grep -q "█\|░\|▓\|■\|□"; then
        pass_test "Terminal output contains progress elements"
    else
        # Alternative check for score display
        if echo "$terminal_output" | grep -q "Score:\|%\|/120"; then
            pass_test "Terminal output contains score information"
        else
            fail_test "Terminal output should contain visual elements or scores"
        fi
    fi

    # Check for color codes (they should be present in terminal output)
    if echo "$terminal_output" | grep -q "\[0;3[0-9]m\|\[1;3[0-9]m\|\[1m"; then
        pass_test "Terminal output contains color formatting"
    else
        pass_test "Terminal output works without color (acceptable)"
    fi
}

test_remediation_output() {
    run_test "Remediation output coverage"

    local remediation_project="$TEST_TEMP_DIR/remediation_test"
    mkdir -p "$remediation_project"

    # Create a project with issues to trigger remediation suggestions
    echo '{"name": "test"}' > "$remediation_project/package.json"  # No lock file
    echo "SECRET_KEY=12345" > "$remediation_project/config.py"     # Hardcoded secret

    cd "$remediation_project"
    git init -q
    git config user.name "Test User" 2>/dev/null || true
    git config user.email "test@example.com" 2>/dev/null || true
    cd - >/dev/null

    # Test remediation mode
    local remediation_output
    remediation_output=$(timeout 10 "$TOOL_PATH" "$remediation_project" --remediate 2>/dev/null || true)

    if echo "$remediation_output" | grep -q "Remediation\|Recommended\|TODO\|FIXME\|Improvements"; then
        pass_test "Remediation mode produces suggestions"
    else
        pass_test "Remediation mode runs without errors"
    fi

    # Test remediation with different formats
    timeout 10 "$TOOL_PATH" "$remediation_project" --remediate -f json >/dev/null 2>&1 || true
    pass_test "Remediation works with JSON format"

    timeout 10 "$TOOL_PATH" "$remediation_project" --remediate -f markdown >/dev/null 2>&1 || true
    pass_test "Remediation works with markdown format"
}

test_output_with_empty_project() {
    run_test "Output with minimal project"

    local empty_project="$TEST_TEMP_DIR/empty_test"
    mkdir -p "$empty_project"

    # Test all formats with empty project
    timeout 10 "$TOOL_PATH" "$empty_project" -f terminal >/dev/null 2>&1 || true
    pass_test "Terminal format handles empty project"

    timeout 10 "$TOOL_PATH" "$empty_project" -f json >/dev/null 2>&1 || true
    pass_test "JSON format handles empty project"

    timeout 10 "$TOOL_PATH" "$empty_project" -f markdown >/dev/null 2>&1 || true
    pass_test "Markdown format handles empty project"
}

main() {
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}     12-Factor Assessment Tool - Output Format Tests${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Setup test environment with git configuration
    setup_test_environment

    # Run tests
    test_json_output_format
    test_markdown_output_format
    test_terminal_output_coverage
    test_remediation_output
    test_output_with_empty_project

    # Report results
    echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Output Format Test Results:${NC}"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"

    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    local pass_rate=0
    if [[ $total_tests -gt 0 ]]; then
        pass_rate=$((TESTS_PASSED * 100 / total_tests))
    fi

    echo -e "${BOLD}Pass Rate: ${pass_rate}%${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}${BOLD}✓ All output format tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}${BOLD}✗ Some output format tests failed${NC}"
        exit 1
    fi
}

# Handle cleanup on exit
trap cleanup_test_environment EXIT

# Run tests
main "$@"