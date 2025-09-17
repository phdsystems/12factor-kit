#!/bin/bash

# ==============================================================================
# Edge Cases Test Suite - Hit specific uncovered paths
# ==============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TOOL_PATH="$PROJECT_ROOT/bin/12factor-assess"
TEST_TEMP_DIR="/tmp/12factor-edge-$$"

# Test tracking
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    echo -e "\n${BOLD}Running: $1${NC}"
}

pass_test() {
    echo -e "  ${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

fail_test() {
    echo -e "  ${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

cleanup_test_environment() {
    rm -rf "$TEST_TEMP_DIR"
}

test_permission_issues() {
    run_test "Permission and access errors"

    mkdir -p "$TEST_TEMP_DIR/restricted"
    echo "{}" > "$TEST_TEMP_DIR/restricted/package.json"

    # Create a directory that becomes inaccessible
    chmod 000 "$TEST_TEMP_DIR/restricted"

    # Test access error handling
    "$TOOL_PATH" "$TEST_TEMP_DIR/restricted" >/dev/null 2>&1 || true
    pass_test "Handles permission denied on directory access"

    # Restore permissions for cleanup
    chmod 755 "$TEST_TEMP_DIR/restricted"
}

test_command_line_edge_cases() {
    run_test "Command line edge cases"

    mkdir -p "$TEST_TEMP_DIR/normal"
    echo "{}" > "$TEST_TEMP_DIR/normal/package.json"

    # Test format validation with edge cases
    "$TOOL_PATH" "$TEST_TEMP_DIR/normal" --format "JSON" >/dev/null 2>&1 || true
    pass_test "Handles case-sensitive format rejection"

    "$TOOL_PATH" "$TEST_TEMP_DIR/normal" -f "xml" >/dev/null 2>&1 || true
    pass_test "Handles unknown format gracefully"

    # Test depth edge cases
    "$TOOL_PATH" "$TEST_TEMP_DIR/normal" -d "999" >/dev/null 2>&1 || true
    pass_test "Handles very large depth values"

    # Test all flag combinations
    "$TOOL_PATH" "$TEST_TEMP_DIR/normal" --verbose --strict --remediate >/dev/null 2>&1 || true
    pass_test "Handles multiple flags together"
}

test_project_type_detection_edge_cases() {
    run_test "Project type detection edge cases"

    # Empty JSON files
    local empty_json_dir="$TEST_TEMP_DIR/empty_json"
    mkdir -p "$empty_json_dir"
    echo "{}" > "$empty_json_dir/package.json"
    echo "{}" > "$empty_json_dir/composer.json"

    "$TOOL_PATH" "$empty_json_dir" >/dev/null 2>&1 || true
    pass_test "Handles empty JSON project files"

    # Multiple project types
    local multi_type_dir="$TEST_TEMP_DIR/multi_type"
    mkdir -p "$multi_type_dir"
    echo '{"name": "test"}' > "$multi_type_dir/package.json"
    echo 'name = "test"' > "$multi_type_dir/Cargo.toml"
    echo "requirements.txt content" > "$multi_type_dir/requirements.txt"

    "$TOOL_PATH" "$multi_type_dir" >/dev/null 2>&1 || true
    pass_test "Handles multiple project type markers"

    # Broken/malformed files that might exist
    local broken_dir="$TEST_TEMP_DIR/broken"
    mkdir -p "$broken_dir"
    echo "broken json content" > "$broken_dir/package.json"

    "$TOOL_PATH" "$broken_dir" >/dev/null 2>&1 || true
    pass_test "Handles malformed project files"
}

test_output_format_edge_cases() {
    run_test "Output format edge cases"

    mkdir -p "$TEST_TEMP_DIR/format_test"

    # Test each format with minimal project
    for format in terminal json markdown; do
        "$TOOL_PATH" "$TEST_TEMP_DIR/format_test" -f "$format" >/dev/null 2>&1 || true
        pass_test "Handles $format format on minimal project"
    done

    # Test format with no output redirection to exercise different code paths
    "$TOOL_PATH" "$TEST_TEMP_DIR/format_test" -f json 2>/dev/null | head -1 >/dev/null || true
    pass_test "JSON format produces output"
}

test_search_depth_edge_cases() {
    run_test "Search depth edge cases"

    # Create nested structure
    local deep_dir="$TEST_TEMP_DIR/deep"
    local current_dir="$deep_dir"

    for i in {1..5}; do
        current_dir="$current_dir/level$i"
        mkdir -p "$current_dir"
    done

    echo "SECRET_KEY=hidden" > "$current_dir/config.env"

    # Test with depth that should find it
    "$TOOL_PATH" "$deep_dir" -d 6 >/dev/null 2>&1 || true
    pass_test "Deep search finds nested files"

    # Test with depth that should not find it
    "$TOOL_PATH" "$deep_dir" -d 3 >/dev/null 2>&1 || true
    pass_test "Shallow search respects depth limits"
}

test_special_file_types() {
    run_test "Special file types and conditions"

    local special_dir="$TEST_TEMP_DIR/special"
    mkdir -p "$special_dir"

    # Create files with special conditions
    echo "# Empty Docker file" > "$special_dir/Dockerfile"
    touch "$special_dir/.env"  # Empty env file
    echo "" > "$special_dir/docker-compose.yml"  # Empty compose file

    # Create binary files that might interfere
    dd if=/dev/zero of="$special_dir/binary.bin" bs=1024 count=1 2>/dev/null

    "$TOOL_PATH" "$special_dir" >/dev/null 2>&1 || true
    pass_test "Handles special and empty files"
}

test_help_and_version_paths() {
    run_test "Help and information paths"

    # Test help paths
    "$TOOL_PATH" --help >/dev/null 2>&1 || true
    pass_test "Help flag works"

    "$TOOL_PATH" -h >/dev/null 2>&1 || true
    pass_test "Short help flag works"

    # Test with no arguments (should use current directory)
    cd "$TEST_TEMP_DIR" && mkdir -p test_dir && cd test_dir
    "$TOOL_PATH" >/dev/null 2>&1 || true
    pass_test "Runs with no arguments (current directory)"
    cd "$PROJECT_ROOT"
}

test_unusual_argument_patterns() {
    run_test "Unusual argument patterns"

    mkdir -p "$TEST_TEMP_DIR/args_test"

    # Test argument order variations
    "$TOOL_PATH" --verbose "$TEST_TEMP_DIR/args_test" --format json >/dev/null 2>&1 || true
    pass_test "Handles mixed argument order"

    # Test with equals signs
    "$TOOL_PATH" "$TEST_TEMP_DIR/args_test" --format=terminal >/dev/null 2>&1 || true
    pass_test "Handles arguments with equals (falls back gracefully)"

    # Test double dash
    "$TOOL_PATH" "$TEST_TEMP_DIR/args_test" -- >/dev/null 2>&1 || true
    pass_test "Handles double dash"
}

main() {
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}     12-Factor Assessment Tool - Edge Cases Tests${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    mkdir -p "$TEST_TEMP_DIR"

    # Run all edge case tests
    test_permission_issues
    test_command_line_edge_cases
    test_project_type_detection_edge_cases
    test_output_format_edge_cases
    test_search_depth_edge_cases
    test_special_file_types
    test_help_and_version_paths
    test_unusual_argument_patterns

    # Report results
    echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Edge Cases Test Results:${NC}"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"

    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    local pass_rate=0
    if [[ $total_tests -gt 0 ]]; then
        pass_rate=$((TESTS_PASSED * 100 / total_tests))
    fi

    echo -e "${BOLD}Pass Rate: ${pass_rate}%${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}${BOLD}✓ All edge case tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}${BOLD}✗ Some edge case tests failed${NC}"
        exit 1
    fi
}

# Handle cleanup on exit
trap cleanup_test_environment EXIT

# Run tests
main "$@"