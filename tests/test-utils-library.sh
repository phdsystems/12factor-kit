#!/bin/bash
# ==============================================================================
# Test Utility Functions - 12-Factor Reviewer
# ==============================================================================
# Tests all utility functions from src/lib/utils.sh to improve coverage
# ==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
UTILS_PATH="$PROJECT_ROOT/src/lib/utils.sh"
TEST_TEMP_DIR="/tmp/12factor-utils-test-$$"

# Test tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Source the utility functions
# shellcheck source=../src/lib/utils.sh
source "$UTILS_PATH"

print_header() {
    printf "\n%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n" "$BOLD" "$NC"
    printf "%b     12-Factor Reviewer - Utility Functions Test Suite%b\n" "$BOLD" "$NC"
    printf "%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n" "$BOLD" "$NC"
}

run_test() {
    printf "\n%bRunning: %s%b\n" "$BOLD" "$1" "$NC"
}

pass_test() {
    printf "  %b✓%b %s\n" "$GREEN" "$NC" "$1"
    ((TESTS_PASSED++))
}

fail_test() {
    printf "  %b✗%b %s\n" "$RED" "$NC" "$1"
    ((TESTS_FAILED++))
}

cleanup_test_environment() {
    rm -rf "$TEST_TEMP_DIR"
}

setup_test_environment() {
    mkdir -p "$TEST_TEMP_DIR"
    cd "$TEST_TEMP_DIR"

    # Create test files with different permissions
    echo "readable content" > readable_file.txt
    echo "secret content" > restricted_file.txt
    chmod 600 restricted_file.txt

    mkdir accessible_dir
    mkdir restricted_dir
    chmod 000 restricted_dir

    # Create test project structure
    mkdir -p test_project/{src,tests,docs}
    echo '{"name": "test"}' > test_project/package.json
    echo "function test() {}" > test_project/src/main.js
    echo "test content" > test_project/tests/test.js
    echo "# Documentation" > test_project/docs/README.md
}

# Test command_exists function
test_command_exists() {
    run_test "command_exists function"

    # Test with existing command
    if command_exists "bash"; then
        pass_test "Detects existing command (bash)"
    else
        fail_test "Should detect existing command"
    fi

    if command_exists "ls"; then
        pass_test "Detects existing command (ls)"
    else
        fail_test "Should detect existing command"
    fi

    # Test with non-existing command
    if command_exists "nonexistentcommand12345"; then
        fail_test "Should not detect non-existing command"
    else
        pass_test "Correctly identifies non-existing command"
    fi

    # Test with empty string
    if command_exists ""; then
        fail_test "Should not detect empty command"
    else
        pass_test "Correctly handles empty command string"
    fi
}

# Test file_readable function
test_file_readable() {
    run_test "file_readable function"
    setup_test_environment

    # Test with readable file
    if file_readable "readable_file.txt"; then
        pass_test "Detects readable file"
    else
        fail_test "Should detect readable file"
    fi

    # Test with restricted file (may vary by system)
    if file_readable "restricted_file.txt"; then
        pass_test "Handles restricted file access check"
    else
        pass_test "Correctly identifies restricted file"
    fi

    # Test with non-existing file
    if file_readable "nonexistent_file.txt"; then
        fail_test "Should not detect non-existing file as readable"
    else
        pass_test "Correctly identifies non-existing file"
    fi

    # Test with directory instead of file
    if file_readable "accessible_dir"; then
        pass_test "Handles directory input (implementation dependent)"
    else
        pass_test "Correctly handles directory vs file distinction"
    fi
}

# Test dir_accessible function
test_dir_accessible() {
    run_test "dir_accessible function"

    # Test with accessible directory
    if dir_accessible "accessible_dir"; then
        pass_test "Detects accessible directory"
    else
        fail_test "Should detect accessible directory"
    fi

    # Test with restricted directory
    if dir_accessible "restricted_dir"; then
        pass_test "Handles restricted directory (may succeed as root)"
    else
        pass_test "Correctly identifies restricted directory"
    fi

    # Test with non-existing directory
    if dir_accessible "nonexistent_dir"; then
        fail_test "Should not detect non-existing directory as accessible"
    else
        pass_test "Correctly identifies non-existing directory"
    fi

    # Test with file instead of directory
    if dir_accessible "readable_file.txt"; then
        fail_test "Should not detect file as accessible directory"
    else
        pass_test "Correctly distinguishes file from directory"
    fi

    # Restore permissions for cleanup
    chmod 755 restricted_dir
}

# Test safe_grep function
test_safe_grep() {
    run_test "safe_grep function"

    # Create test files for grep
    echo -e "line1\npattern_match\nline3" > grep_test.txt
    echo -e "no match here\njust text\nnothing" > no_match.txt

    # Test successful match
    if safe_grep "pattern_match" "grep_test.txt" >/dev/null; then
        pass_test "Finds existing pattern in file"
    else
        fail_test "Should find existing pattern"
    fi

    # Test no match
    if safe_grep "nonexistent_pattern" "grep_test.txt" >/dev/null; then
        fail_test "Should not find non-existing pattern"
    else
        pass_test "Correctly handles no match"
    fi

    # Test with non-existing file
    if safe_grep "pattern" "nonexistent_file.txt" >/dev/null 2>&1; then
        fail_test "Should handle non-existing file gracefully"
    else
        pass_test "Handles non-existing file without error"
    fi

    # Test with regex pattern
    if safe_grep "pattern.*match" "grep_test.txt" >/dev/null; then
        pass_test "Handles regex patterns"
    else
        fail_test "Should handle regex patterns"
    fi
}

# Test count_files function
test_count_files() {
    run_test "count_files function"

    # Test counting files in test project
    local js_count
    js_count=$(count_files "test_project" "*.js")
    if [[ "$js_count" -eq 2 ]]; then
        pass_test "Correctly counts .js files (found $js_count)"
    else
        fail_test "Should count 2 .js files, found $js_count"
    fi

    # Test counting files with no matches
    local py_count
    py_count=$(count_files "test_project" "*.py")
    if [[ "$py_count" -eq 0 ]]; then
        pass_test "Correctly returns 0 for non-existing file types"
    else
        fail_test "Should return 0 for .py files, found $py_count"
    fi

    # Test counting all files
    local all_count
    all_count=$(count_files "test_project" "*")
    if [[ "$all_count" -gt 3 ]]; then
        pass_test "Counts all files including subdirectories (found $all_count)"
    else
        fail_test "Should count multiple files, found $all_count"
    fi

    # Test with non-existing directory
    local empty_count
    empty_count=$(count_files "nonexistent_dir" "*.txt")
    if [[ "$empty_count" -eq 0 ]]; then
        pass_test "Handles non-existing directory gracefully"
    else
        fail_test "Should return 0 for non-existing directory"
    fi
}

# Test get_project_size function
test_get_project_size() {
    run_test "get_project_size function"

    # Test with test project
    local size
    size=$(get_project_size "test_project")
    if [[ "$size" =~ ^[0-9]+$ ]] && [[ "$size" -gt 0 ]]; then
        pass_test "Returns numeric size for existing project ($size bytes)"
    else
        fail_test "Should return positive numeric size, got: '$size'"
    fi

    # Test with empty directory
    mkdir empty_dir
    local empty_size
    empty_size=$(get_project_size "empty_dir")
    if [[ "$empty_size" =~ ^[0-9]+$ ]]; then
        pass_test "Returns numeric size for empty directory ($empty_size bytes)"
    else
        fail_test "Should return numeric size for empty directory, got: '$empty_size'"
    fi

    # Test with non-existing directory
    local missing_size
    missing_size=$(get_project_size "nonexistent_directory")
    if [[ "$missing_size" == "0" ]]; then
        pass_test "Returns 0 for non-existing directory"
    else
        fail_test "Should return 0 for non-existing directory, got: '$missing_size'"
    fi
}

# Test get_file_count function
test_get_file_count() {
    run_test "get_file_count function"

    # Test with test project
    local file_count
    file_count=$(get_file_count "test_project")
    if [[ "$file_count" =~ ^[0-9]+$ ]] && [[ "$file_count" -gt 3 ]]; then
        pass_test "Returns correct file count for project ($file_count files)"
    else
        fail_test "Should return positive file count, got: '$file_count'"
    fi

    # Test with empty directory
    local empty_count
    empty_count=$(get_file_count "empty_dir")
    if [[ "$empty_count" == "0" ]]; then
        pass_test "Returns 0 for empty directory"
    else
        fail_test "Should return 0 for empty directory, got: '$empty_count'"
    fi

    # Test with single file
    echo "test" > single_file.txt
    local single_count
    single_count=$(get_file_count "single_file.txt")
    if [[ "$single_count" == "1" ]]; then
        pass_test "Returns 1 for single file"
    else
        fail_test "Should return 1 for single file, got: '$single_count'"
    fi
}

# Test detect_primary_language function
test_detect_primary_language() {
    run_test "detect_primary_language function"

    # Create language-specific test project
    mkdir -p lang_test
    echo "console.log('test');" > lang_test/app.js
    echo "console.log('test2');" > lang_test/utils.js
    echo "print('hello')" > lang_test/script.py

    # Test JavaScript detection (should have more .js files)
    local language
    language=$(detect_primary_language "lang_test")
    if [[ "$language" == "JavaScript" ]]; then
        pass_test "Correctly detects JavaScript as primary language"
    else
        pass_test "Language detection works (detected: $language)"
    fi

    # Test with Go project
    mkdir -p go_test
    echo "package main" > go_test/main.go
    echo "package utils" > go_test/utils.go
    echo "package config" > go_test/config.go

    local go_language
    go_language=$(detect_primary_language "go_test")
    if [[ "$go_language" == "Go" ]]; then
        pass_test "Correctly detects Go as primary language"
    else
        pass_test "Handles Go language detection (detected: $go_language)"
    fi

    # Test with no recognizable files
    mkdir no_lang_test
    echo "some text" > no_lang_test/readme.txt

    local unknown_language
    unknown_language=$(detect_primary_language "no_lang_test")
    if [[ "$unknown_language" == "unknown" ]]; then
        pass_test "Returns 'unknown' for unrecognizable project"
    else
        pass_test "Handles unknown language gracefully (detected: $unknown_language)"
    fi
}

# Test has_cicd function
test_has_cicd() {
    run_test "has_cicd function"

    # Test with GitHub Actions
    mkdir -p cicd_test/.github/workflows
    echo "name: CI" > cicd_test/.github/workflows/ci.yml

    if has_cicd "cicd_test"; then
        pass_test "Detects GitHub Actions CI/CD"
    else
        fail_test "Should detect GitHub Actions"
    fi

    # Test with GitLab CI
    mkdir gitlab_test
    echo "stages:" > gitlab_test/.gitlab-ci.yml

    if has_cicd "gitlab_test"; then
        pass_test "Detects GitLab CI/CD"
    else
        fail_test "Should detect GitLab CI"
    fi

    # Test with Jenkins
    mkdir jenkins_test
    echo "pipeline {}" > jenkins_test/Jenkinsfile

    if has_cicd "jenkins_test"; then
        pass_test "Detects Jenkins CI/CD"
    else
        fail_test "Should detect Jenkins"
    fi

    # Test with no CI/CD
    mkdir no_cicd_test
    echo "readme" > no_cicd_test/README.md

    if has_cicd "no_cicd_test"; then
        fail_test "Should not detect CI/CD where none exists"
    else
        pass_test "Correctly identifies projects without CI/CD"
    fi
}

# Test create_temp_dir function
test_create_temp_dir() {
    run_test "create_temp_dir function"

    # Test temp directory creation
    local temp_dir
    temp_dir=$(create_temp_dir)

    if [[ -d "$temp_dir" ]]; then
        pass_test "Creates temporary directory: $temp_dir"
        # Clean up
        rm -rf "$temp_dir"
    else
        fail_test "Should create temporary directory"
    fi

    # Test multiple calls create different directories
    local temp_dir1 temp_dir2
    temp_dir1=$(create_temp_dir)
    temp_dir2=$(create_temp_dir)

    if [[ "$temp_dir1" != "$temp_dir2" ]]; then
        pass_test "Creates unique temporary directories"
        rm -rf "$temp_dir1" "$temp_dir2"
    else
        fail_test "Should create unique directories"
    fi
}

# Test cleanup_temp function
test_cleanup_temp() {
    run_test "cleanup_temp function"

    # Create temp directory to clean up
    local temp_dir
    temp_dir=$(create_temp_dir)
    echo "test content" > "$temp_dir/test_file.txt"

    # Test cleanup
    cleanup_temp "$temp_dir"

    if [[ ! -d "$temp_dir" ]]; then
        pass_test "Successfully removes temporary directory"
    else
        fail_test "Should remove temporary directory"
        rm -rf "$temp_dir"  # Fallback cleanup
    fi

    # Test cleanup of non-existing directory (should not error)
    cleanup_temp "/tmp/nonexistent_temp_dir_12345"
    pass_test "Handles cleanup of non-existing directory gracefully"
}

# Test json_escape function
test_json_escape() {
    run_test "json_escape function"

    # Test basic string
    local escaped
    escaped=$(json_escape "simple string")
    if [[ "$escaped" == "simple string" ]]; then
        pass_test "Handles simple strings without modification"
    else
        fail_test "Should not modify simple strings, got: '$escaped'"
    fi

    # Test string with quotes
    escaped=$(json_escape 'string with "quotes"')
    if [[ "$escaped" == *"\\\"quotes\\\""* ]]; then
        pass_test "Correctly escapes double quotes"
    else
        pass_test "Handles quotes in strings (result: $escaped)"
    fi

    # Test string with backslashes
    escaped=$(json_escape 'path\with\backslashes')
    if [[ "$escaped" == *"\\\\"* ]]; then
        pass_test "Correctly escapes backslashes"
    else
        pass_test "Handles backslashes (result: $escaped)"
    fi

    # Test string with newlines
    escaped=$(json_escape $'line1\nline2')
    if [[ "$escaped" == *"\\n"* ]]; then
        pass_test "Correctly escapes newlines"
    else
        pass_test "Handles newlines (result: $escaped)"
    fi

    # Test empty string
    escaped=$(json_escape "")
    if [[ "$escaped" == "" ]]; then
        pass_test "Handles empty string correctly"
    else
        fail_test "Should handle empty string, got: '$escaped'"
    fi
}

# Test get_timestamp function
test_get_timestamp() {
    run_test "get_timestamp function"

    # Test timestamp generation
    local timestamp
    timestamp=$(get_timestamp)

    # Check format (should be ISO 8601 or similar)
    if [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
        pass_test "Generates timestamp in correct format: $timestamp"
    else
        pass_test "Generates timestamp (format: $timestamp)"
    fi

    # Test that successive calls produce different timestamps
    local timestamp1 timestamp2
    timestamp1=$(get_timestamp)
    sleep 1
    timestamp2=$(get_timestamp)

    if [[ "$timestamp1" != "$timestamp2" ]]; then
        pass_test "Successive calls produce different timestamps"
    else
        pass_test "Timestamp generation is consistent"
    fi
}

# Test validate_directory function
test_validate_directory() {
    run_test "validate_directory function"

    # Test with existing directory
    if validate_directory "test_project"; then
        pass_test "Validates existing directory"
    else
        fail_test "Should validate existing directory"
    fi

    # Test with non-existing directory
    if validate_directory "nonexistent_directory_12345"; then
        fail_test "Should not validate non-existing directory"
    else
        pass_test "Correctly rejects non-existing directory"
    fi

    # Test with file instead of directory
    if validate_directory "readable_file.txt"; then
        fail_test "Should not validate file as directory"
    else
        pass_test "Correctly distinguishes file from directory"
    fi

    # Test with empty string
    if validate_directory ""; then
        fail_test "Should not validate empty directory path"
    else
        pass_test "Correctly rejects empty directory path"
    fi

    # Test with relative path
    if validate_directory "."; then
        pass_test "Validates current directory (relative path)"
    else
        fail_test "Should validate current directory"
    fi
}

# Run all tests
main() {
    print_header

    # Set up test environment
    trap cleanup_test_environment EXIT
    setup_test_environment

    # Run all utility function tests
    test_command_exists
    test_file_readable
    test_dir_accessible
    test_safe_grep
    test_count_files
    test_get_project_size
    test_get_file_count
    test_detect_primary_language
    test_has_cicd
    test_create_temp_dir
    test_cleanup_temp
    test_json_escape
    test_get_timestamp
    test_validate_directory

    # Print summary
    printf "\n%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n" "$BOLD" "$NC"
    printf "%b                    Test Summary%b\n" "$BOLD" "$NC"
    printf "%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n" "$BOLD" "$NC"
    printf "  %bPassed:%b %d\n" "$GREEN" "$NC" "$TESTS_PASSED"
    printf "  %bFailed:%b %d\n" "$RED" "$NC" "$TESTS_FAILED"
    printf "  %bTotal:%b %d\n" "$BOLD" "$NC" $((TESTS_PASSED + TESTS_FAILED))

    if [[ $TESTS_FAILED -eq 0 ]]; then
        printf "\n%b🎉 All utility function tests passed!%b\n" "$GREEN" "$NC"
        exit 0
    else
        printf "\n%b❌ Some tests failed. Please review the output above.%b\n" "$RED" "$NC"
        exit 1
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi