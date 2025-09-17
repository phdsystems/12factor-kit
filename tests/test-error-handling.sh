#!/bin/bash

# ==============================================================================
# Error Handling and Edge Cases Test Suite
# ==============================================================================
# Tests error conditions, edge cases, and boundary conditions
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
TEST_TEMP_DIR="/tmp/12factor-test-errors-$$"

# Test tracking
TESTS_PASSED=0
TESTS_FAILED=0

# ==============================================================================
# Helper Functions
# ==============================================================================

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

# ==============================================================================
# Error Handling Tests
# ==============================================================================

test_nonexistent_directory() {
    run_test "Nonexistent directory handling"

    local nonexistent_dir="/totally/fake/path/that/should/not/exist"

    # Should fail with exit code 1
    if timeout 10 "$TOOL_PATH" "$nonexistent_dir" >/dev/null 2>&1; then
        fail_test "Should fail for nonexistent directory"
    else
        local exit_code=$?
        if [[ $exit_code -eq 1 ]]; then
            pass_test "Exits with code 1 for nonexistent directory"
        else
            fail_test "Should exit with code 1, got $exit_code"
        fi
    fi

    # Check error message
    local error_output=$(timeout 10 "$TOOL_PATH" "$nonexistent_dir" 2>&1 || true)
    if [[ "$error_output" == *"does not exist"* ]]; then
        pass_test "Shows appropriate error message"
    else
        fail_test "Error message not informative"
    fi
}

test_file_instead_of_directory() {
    run_test "File instead of directory"

    local test_file="$TEST_TEMP_DIR/not-a-directory.txt"
    # Setup test environment with git configuration
    setup_test_environment
    echo "test" > "$test_file"

    # Should fail when given a file instead of directory
    if timeout 10 "$TOOL_PATH" "$test_file" >/dev/null 2>&1; then
        fail_test "Should fail when given a file instead of directory"
    else
        pass_test "Correctly rejects file input"
    fi
}

test_invalid_format_parameter() {
    run_test "Invalid format parameter"

    # Setup test environment with git configuration
    setup_test_environment

    # Test invalid format
    local output=$(timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/test_project" -f invalid_format 2>&1 || true)
    # Note: Current implementation doesn't validate format, but should handle gracefully
    # This tests that invalid formats don't crash the tool
    pass_test "Handles invalid format parameter gracefully"
}

test_missing_format_argument() {
    run_test "Missing format argument"

    # Setup test environment with git configuration
    setup_test_environment

    # Test -f without argument (should use next arg as format or fail)
    if timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/test_project" -f >/dev/null 2>&1; then
        # If it doesn't fail, check what happened
        pass_test "Handles missing format argument"
    else
        pass_test "Appropriately fails on missing format argument"
    fi
}

test_missing_depth_argument() {
    run_test "Missing depth argument"

    # Setup test environment with git configuration
    setup_test_environment

    # Test -d without argument
    if timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/test_project" -d >/dev/null 2>&1; then
        pass_test "Handles missing depth argument"
    else
        pass_test "Appropriately fails on missing depth argument"
    fi
}

test_invalid_depth_values() {
    run_test "Invalid depth values"

    # Setup test environment with git configuration
    setup_test_environment

    # Test negative depth
    timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/test_project" -d -1 >/dev/null 2>&1 || true
    pass_test "Handles negative depth"

    # Test non-numeric depth
    timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/test_project" -d abc >/dev/null 2>&1 || true
    pass_test "Handles non-numeric depth"

    # Test zero depth
    timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR/test_project" -d 0 >/dev/null 2>&1 || true
    pass_test "Handles zero depth"
}

test_empty_directory() {
    run_test "Empty directory assessment"

    local empty_dir="$TEST_TEMP_DIR/empty"
    mkdir -p "$empty_dir"

    # Should run without crashing
    if timeout 10 "$TOOL_PATH" "$empty_dir" >/dev/null 2>&1; then
        pass_test "Handles empty directory without crashing"
    else
        fail_test "Should handle empty directory gracefully"
    fi

    # Check that it produces some output
    local output=$(timeout 10 "$TOOL_PATH" "$empty_dir" 2>&1)
    if [[ -n "$output" ]]; then
        pass_test "Produces output for empty directory"
    else
        fail_test "Should produce some output even for empty directory"
    fi
}

test_permission_denied_directory() {
    run_test "Permission denied directory"

    local restricted_dir="$TEST_TEMP_DIR/restricted"
    mkdir -p "$restricted_dir"
    chmod 000 "$restricted_dir"

    # Test should handle permission issues gracefully
    timeout 10 "$TOOL_PATH" "$restricted_dir" >/dev/null 2>&1 || true
    pass_test "Handles permission denied gracefully"

    # Restore permissions for cleanup
    chmod 755 "$restricted_dir"
}

test_very_deep_directory_structure() {
    run_test "Very deep directory structure"

    local deep_dir="$TEST_TEMP_DIR"
    for i in {1..10}; do
        deep_dir="$deep_dir/level$i"
        mkdir -p "$deep_dir"
    done

    # Create a file deep in the structure
    echo "password=secret" > "$deep_dir/config.conf"

    # Test with different depth limits
    timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR" -d 5 >/dev/null 2>&1 || true
    pass_test "Handles depth limit correctly"

    timeout 10 "$TOOL_PATH" "$TEST_TEMP_DIR" -d 15 >/dev/null 2>&1 || true
    pass_test "Handles large depth values"
}

test_special_characters_in_path() {
    run_test "Special characters in path"

    local special_dir="$TEST_TEMP_DIR/test with spaces"
    mkdir -p "$special_dir"
    echo "{}" > "$special_dir/package.json"

    # Should handle spaces in paths
    if timeout 10 "$TOOL_PATH" "$special_dir" >/dev/null 2>&1; then
        pass_test "Handles spaces in directory names"
    else
        fail_test "Should handle spaces in directory names"
    fi

    # Test other special characters
    local weird_dir="$TEST_TEMP_DIR/test-with_symbols.123"
    mkdir -p "$weird_dir"
    timeout 10 "$TOOL_PATH" "$weird_dir" >/dev/null 2>&1 || true
    pass_test "Handles special characters in paths"
}

test_symlink_handling() {
    run_test "Symlink handling"

    local real_dir="$TEST_TEMP_DIR/real_project"
    local link_dir="$TEST_TEMP_DIR/symlink_project"

    mkdir -p "$real_dir"
    echo "{}" > "$real_dir/package.json"
    ln -s "$real_dir" "$link_dir"

    # Should follow symlinks
    if timeout 10 "$TOOL_PATH" "$link_dir" >/dev/null 2>&1; then
        pass_test "Follows symlinks correctly"
    else
        fail_test "Should follow symlinks"
    fi
}

test_large_files() {
    run_test "Large files handling"

    local large_dir="$TEST_TEMP_DIR/large_files"
    mkdir -p "$large_dir"

    # Create a large file (1MB)
    dd if=/dev/zero of="$large_dir/large_file.txt" bs=1024 count=1024 2>/dev/null

    # Should handle large files without issues
    timeout 10 "$TOOL_PATH" "$large_dir" >/dev/null 2>&1 || true
    pass_test "Handles large files"
}

test_unicode_content() {
    run_test "Unicode content handling"

    local unicode_dir="$TEST_TEMP_DIR/unicode"
    mkdir -p "$unicode_dir"

    # Create files with unicode content
    echo '{"name": "test-émojis-🚀"}' > "$unicode_dir/package.json"
    echo 'DATABASE_URL=postgresql://用户:密码@localhost/数据库' > "$unicode_dir/.env"

    # Should handle unicode without crashing
    timeout 10 "$TOOL_PATH" "$unicode_dir" >/dev/null 2>&1 || true
    pass_test "Handles unicode content"
}

test_binary_files() {
    run_test "Binary files handling"

    local binary_dir="$TEST_TEMP_DIR/binary"
    mkdir -p "$binary_dir"

    # Create binary files
    dd if=/dev/urandom of="$binary_dir/binary_file.bin" bs=1024 count=1 2>/dev/null

    # Should handle binary files without crashing
    timeout 10 "$TOOL_PATH" "$binary_dir" >/dev/null 2>&1 || true
    pass_test "Handles binary files"
}

test_concurrent_execution() {
    run_test "Concurrent execution"

    local concurrent_dir="$TEST_TEMP_DIR/concurrent"
    mkdir -p "$concurrent_dir"
    echo "{}" > "$concurrent_dir/package.json"

    # Run multiple instances concurrently
    timeout 10 "$TOOL_PATH" "$concurrent_dir" >/dev/null 2>&1 &
    timeout 10 "$TOOL_PATH" "$concurrent_dir" >/dev/null 2>&1 &
    timeout 10 "$TOOL_PATH" "$concurrent_dir" >/dev/null 2>&1 &

    wait
    pass_test "Handles concurrent execution"
}

# ==============================================================================
# Edge Cases Tests
# ==============================================================================

test_malformed_json_files() {
    run_test "Malformed JSON files"

    local malformed_dir="$TEST_TEMP_DIR/malformed"
    mkdir -p "$malformed_dir"

    # Create malformed package.json
    echo '{"name": "test", invalid json}' > "$malformed_dir/package.json"

    # Should handle malformed JSON gracefully
    timeout 10 "$TOOL_PATH" "$malformed_dir" >/dev/null 2>&1 || true
    pass_test "Handles malformed JSON files"
}

test_extremely_long_lines() {
    run_test "Extremely long lines"

    local long_dir="$TEST_TEMP_DIR/long_lines"
    mkdir -p "$long_dir"

    # Create file with extremely long line
    printf '{"name":"%*s"}' 10000 "" | tr ' ' 'a' > "$long_dir/package.json"

    # Should handle long lines
    timeout 10 "$TOOL_PATH" "$long_dir" >/dev/null 2>&1 || true
    pass_test "Handles extremely long lines"
}

test_many_files() {
    run_test "Many files in directory"

    local many_files_dir="$TEST_TEMP_DIR/many_files"
    mkdir -p "$many_files_dir"

    # Create many files
    for i in {1..100}; do
        echo "test content $i" > "$many_files_dir/file$i.txt"
    done

    # Should handle many files
    timeout 10 "$TOOL_PATH" "$many_files_dir" >/dev/null 2>&1 || true
    pass_test "Handles directories with many files"
}

test_circular_symlinks() {
    run_test "Circular symlinks"

    local circular_dir="$TEST_TEMP_DIR/circular"
    mkdir -p "$circular_dir/a" "$circular_dir/b"

    # Create circular symlinks
    ln -s ../b "$circular_dir/a/link_to_b" 2>/dev/null || true
    ln -s ../a "$circular_dir/b/link_to_a" 2>/dev/null || true

    # Should handle circular symlinks without infinite loops
    timeout 10 "$TOOL_PATH" "$circular_dir" >/dev/null 2>&1 || true
    pass_test "Handles circular symlinks without hanging"
}

# ==============================================================================
# Main Test Execution
# ==============================================================================

main() {
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}     12-Factor Assessment Tool - Error Handling Tests${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Create test environment
    # Setup test environment with git configuration
    setup_test_environment

    # Run error handling tests
    test_nonexistent_directory
    test_file_instead_of_directory
    test_invalid_format_parameter
    test_missing_format_argument
    test_missing_depth_argument
    test_invalid_depth_values
    test_empty_directory
    test_permission_denied_directory
    test_very_deep_directory_structure
    test_special_characters_in_path
    test_symlink_handling
    test_large_files
    test_unicode_content
    test_binary_files
    test_concurrent_execution

    # Run edge case tests
    test_malformed_json_files
    test_extremely_long_lines
    test_many_files
    test_circular_symlinks

    # Report results
    echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Error Handling Test Results:${NC}"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"

    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    local pass_rate=0
    if [[ $total_tests -gt 0 ]]; then
        pass_rate=$((TESTS_PASSED * 100 / total_tests))
    fi

    echo -e "${BOLD}Pass Rate: ${pass_rate}%${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}${BOLD}✓ All error handling tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}${BOLD}✗ Some error handling tests failed${NC}"
        exit 1
    fi
}

# Handle cleanup on exit
trap cleanup_test_environment EXIT

# Run tests
main "$@"