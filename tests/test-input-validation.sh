#!/bin/bash

# ==============================================================================
# Validation Test Suite - Target specific validation paths
# ==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
# YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TOOL_PATH="$PROJECT_ROOT/bin/twelve-factor-reviewer"
TEST_TEMP_DIR="/tmp/12factor-validation-$$"

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

test_missing_format_argument() {
    run_test "Missing format argument validation"

    mkdir -p "$TEST_TEMP_DIR/test_project"
    echo "{}" > "$TEST_TEMP_DIR/test_project/package.json"

    # Test -f without argument
    local output
    output=$(timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/test_project" -f 2>&1 || true)
    if [[ "$output" == *"requires an argument"* ]]; then
        pass_test "Shows error for missing format argument"
    else
        fail_test "Should show error for missing format argument"
    fi

    # Test --format without argument
    local output2
    output2=$(timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/test_project" --format 2>&1 || true)
    if [[ "$output2" == *"requires an argument"* ]]; then
        pass_test "Shows error for missing --format argument"
    else
        fail_test "Should show error for missing --format argument"
    fi
}

test_invalid_format_validation() {
    run_test "Invalid format validation"

    mkdir -p "$TEST_TEMP_DIR/test_project"
    echo "{}" > "$TEST_TEMP_DIR/test_project/package.json"

    # Test invalid format with warning
    local output
    output=$(timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/test_project" -f invalid_format 2>&1 || true)
    if [[ "$output" == *"Warning: Unknown format"* ]]; then
        pass_test "Shows warning for invalid format"
    else
        fail_test "Should show warning for invalid format"
    fi

    # Should still run with default format
    if [[ "$output" == *"12-Factor App Compliance Assessment"* ]]; then
        pass_test "Falls back to terminal format"
    else
        fail_test "Should fall back to terminal format"
    fi
}

test_missing_depth_argument() {
    run_test "Missing depth argument validation"

    mkdir -p "$TEST_TEMP_DIR/test_project"

    # Test -d without argument
    local output
    output=$(timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/test_project" -d 2>&1 || true)
    if [[ "$output" == *"requires an argument"* ]]; then
        pass_test "Shows error for missing depth argument"
    else
        fail_test "Should show error for missing depth argument"
    fi

    # Test --depth without argument
    local output2
    output2=$(timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/test_project" --depth 2>&1 || true)
    if [[ "$output2" == *"requires an argument"* ]]; then
        pass_test "Shows error for missing --depth argument"
    else
        fail_test "Should show error for missing --depth argument"
    fi
}

test_invalid_depth_values() {
    run_test "Invalid depth value validation"

    mkdir -p "$TEST_TEMP_DIR/test_project"

    # Test negative depth
    local output
    output=$(timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/test_project" -d -1 2>&1 || true)
    if [[ "$output" == *"must be a positive integer"* ]]; then
        pass_test "Rejects negative depth"
    else
        fail_test "Should reject negative depth"
    fi

    # Test zero depth
    local output2
    output2=$(timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/test_project" -d 0 2>&1 || true)
    if [[ "$output2" == *"must be a positive integer"* ]]; then
        pass_test "Rejects zero depth"
    else
        fail_test "Should reject zero depth"
    fi

    # Test non-numeric depth
    local output3
    output3=$(timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/test_project" -d abc 2>&1 || true)
    if [[ "$output3" == *"must be a positive integer"* ]]; then
        pass_test "Rejects non-numeric depth"
    else
        fail_test "Should reject non-numeric depth"
    fi

    # Test fractional depth
    local output4
    output4=$(timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/test_project" -d 2.5 2>&1 || true)
    if [[ "$output4" == *"must be a positive integer"* ]]; then
        pass_test "Rejects fractional depth"
    else
        fail_test "Should reject fractional depth"
    fi
}

test_valid_parameters() {
    run_test "Valid parameter acceptance"

    mkdir -p "$TEST_TEMP_DIR/test_project"
    echo "{}" > "$TEST_TEMP_DIR/test_project/package.json"

    # Test valid formats
    for format in terminal json markdown; do
        if timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/test_project" -f "$format" >/dev/null 2>&1; then
            pass_test "Accepts valid format: $format"
        else
            fail_test "Should accept valid format: $format"
        fi
    done

    # Test valid depths
    for depth in 1 2 5 10; do
        if timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/test_project" -d "$depth" >/dev/null 2>&1; then
            pass_test "Accepts valid depth: $depth"
        else
            fail_test "Should accept valid depth: $depth"
        fi
    done
}

test_help_option() {
    run_test "Help option"

    # Test -h
    local output
    output=$(timeout 10 "$TOOL_PATH" -h 2>&1 || true)
    if [[ "$output" == *"12-Factor App Compliance Assessment Tool"* ]]; then
        pass_test "Shows help with -h"
    else
        fail_test "Should show help with -h"
    fi

    # Test --help
    local output2
    output2=$(timeout 10 "$TOOL_PATH" --help 2>&1 || true)
    if [[ "$output2" == *"12-Factor App Compliance Assessment Tool"* ]]; then
        pass_test "Shows help with --help"
    else
        fail_test "Should show help with --help"
    fi
}

test_nonexistent_path_error() {
    run_test "Nonexistent path error handling"

    # Test specific error message
    local output
    output=$(timeout 10 "$TOOL_PATH" "/completely/fake/path" 2>&1 || true)
    if [[ "$output" == *"does not exist"* ]]; then
        pass_test "Shows 'does not exist' error message"
    else
        fail_test "Should show specific error message"
    fi

    # Test exit code
    if ! timeout 10 "$TOOL_PATH" "/completely/fake/path" >/dev/null 2>&1; then
        local exit_code=$?
        if [[ $exit_code -eq 1 ]]; then
            pass_test "Returns exit code 1 for nonexistent path"
        else
            fail_test "Should return exit code 1, got $exit_code"
        fi
    else
        fail_test "Should fail for nonexistent path"
    fi
}

test_file_instead_of_directory() {
    run_test "File instead of directory error"

    # Create a file
    local test_file="$TEST_TEMP_DIR/testfile.txt"
    mkdir -p "$TEST_TEMP_DIR"
    echo "test content" > "$test_file"

    # Should fail when given a file instead of directory
    if ! timeout 10 "$TOOL_PATH" "$test_file" >/dev/null 2>&1; then
        pass_test "Rejects file input (expecting directory)"
    else
        fail_test "Should reject file input"
    fi
}

main() {
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}     12-Factor Assessment Tool - Validation Tests${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Setup test environment with git configuration
    setup_test_environment

    # Run validation tests
    test_missing_format_argument
    test_invalid_format_validation
    test_missing_depth_argument
    test_invalid_depth_values
    test_valid_parameters
    test_help_option
    test_nonexistent_path_error
    test_file_instead_of_directory

    # Report results
    echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Validation Test Results:${NC}"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"

    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    local pass_rate=0
    if [[ $total_tests -gt 0 ]]; then
        pass_rate=$((TESTS_PASSED * 100 / total_tests))
    fi

    echo -e "${BOLD}Pass Rate: ${pass_rate}%${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}${BOLD}✓ All validation tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}${BOLD}✗ Some validation tests failed${NC}"
        exit 1
    fi
}

# Handle cleanup on exit
trap cleanup_test_environment EXIT

# Run tests
main "$@"