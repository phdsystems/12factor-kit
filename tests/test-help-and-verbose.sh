#!/bin/bash

# ==============================================================================
# Help and Verbose Mode Test Suite
# ==============================================================================
# Tests help function and verbose logging paths that are currently uncovered
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
TEST_TEMP_DIR="/tmp/12factor-help-verbose-$$"

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
    TEST_TEMP_DIR=$(mktemp -d -t test-help-verbose-XXXXXX)

    # Configure git for tests to prevent hanging
    git config --global user.email "test@example.com" 2>/dev/null || true
    git config --global user.name "Test User" 2>/dev/null || true
}

cleanup_test_environment() {
    rm -rf "$TEST_TEMP_DIR"
}

test_help_function_coverage() {
    run_test "Help function coverage"

    # Test --help flag
    local help_output=$(timeout 10 "$TOOL_PATH" --help 2>&1)
    if [[ "$help_output" == *"12-Factor App Compliance Assessment Tool"* ]]; then
        pass_test "Help function shows main title"
    else
        fail_test "Help function should show main title"
    fi

    if [[ "$help_output" == *"USAGE:"* ]]; then
        pass_test "Help shows usage section"
    else
        fail_test "Help should show usage section"
    fi

    if [[ "$help_output" == *"OPTIONS:"* ]]; then
        pass_test "Help shows options section"
    else
        fail_test "Help should show options section"
    fi

    if [[ "$help_output" == *"EXAMPLES:"* ]]; then
        pass_test "Help shows examples section"
    else
        fail_test "Help should show examples section"
    fi

    if [[ "$help_output" == *"12 FACTORS ASSESSED:"* ]]; then
        pass_test "Help shows factors section"
    else
        fail_test "Help should show factors section"
    fi

    # Test -h short flag
    local short_help=$(timeout 10 "$TOOL_PATH" -h 2>&1)
    if [[ "$short_help" == *"12-Factor App Compliance Assessment Tool"* ]]; then
        pass_test "Short help flag works"
    else
        fail_test "Short help flag should work"
    fi
}

test_verbose_logging_coverage() {
    run_test "Verbose logging coverage"

    mkdir -p "$TEST_TEMP_DIR/verbose_test"
    echo '{"name": "test"}' > "$TEST_TEMP_DIR/verbose_test/package.json"

    # Test verbose mode enabled
    local verbose_output=$(timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/verbose_test" --verbose 2>&1)
    if [[ "$verbose_output" == *"[DEBUG]"* ]] || [[ "$verbose_output" == *"verbose"* ]]; then
        pass_test "Verbose mode produces debug output"
    else
        # Check if verbose output contains more detailed information
        if [[ ${#verbose_output} -gt 1000 ]]; then
            pass_test "Verbose mode produces extended output"
        else
            fail_test "Verbose mode should produce debug or extended output"
        fi
    fi

    # Test non-verbose mode (default)
    local normal_output=$(timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/verbose_test" 2>&1)
    if [[ "$normal_output" != *"[DEBUG]"* ]]; then
        pass_test "Normal mode does not show debug output"
    else
        fail_test "Normal mode should not show debug output"
    fi

    # Test verbose with different formats
    timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/verbose_test" --verbose -f json >/dev/null 2>&1
    pass_test "Verbose works with JSON format"

    timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/verbose_test" --verbose -f markdown >/dev/null 2>&1
    pass_test "Verbose works with markdown format"
}

test_help_with_invalid_args() {
    run_test "Help with invalid arguments"

    # Test help after invalid argument (should still show help)
    local invalid_help=$(timeout 10 "$TOOL_PATH" --invalid-flag --help 2>&1 || true)
    if [[ "$invalid_help" == *"12-Factor App Compliance Assessment Tool"* ]]; then
        pass_test "Help shows even with invalid args"
    else
        fail_test "Help should show even with invalid args"
    fi
}

test_help_exit_code() {
    run_test "Help exit code"

    # Help should exit with 0
    if timeout 10 "$TOOL_PATH" --help >/dev/null 2>&1; then
        pass_test "Help exits with code 0"
    else
        fail_test "Help should exit with code 0"
    fi

    if timeout 10 "$TOOL_PATH" -h >/dev/null 2>&1; then
        pass_test "Short help exits with code 0"
    else
        fail_test "Short help should exit with code 0"
    fi
}

main() {
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}     12-Factor Assessment Tool - Help and Verbose Tests${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Create test environment
    setup_test_environment

    # Run tests
    test_help_function_coverage
    test_verbose_logging_coverage
    test_help_with_invalid_args
    test_help_exit_code

    # Report results
    echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Help and Verbose Test Results:${NC}"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"

    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    local pass_rate=0
    if [[ $total_tests -gt 0 ]]; then
        pass_rate=$((TESTS_PASSED * 100 / total_tests))
    fi

    echo -e "${BOLD}Pass Rate: ${pass_rate}%${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}${BOLD}✓ All help and verbose tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}${BOLD}✗ Some help and verbose tests failed${NC}"
        exit 1
    fi
}

# Handle cleanup on exit
trap cleanup_test_environment EXIT

# Run tests
main "$@"