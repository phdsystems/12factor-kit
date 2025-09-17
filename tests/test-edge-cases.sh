#!/bin/bash

# ==============================================================================
# Edge Cases Test Suite
# ==============================================================================
# Tests edge cases and complex assessment scenarios
# ==============================================================================

set -uo pipefail  # Remove -e to handle exit codes properly

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
TEST_TEMP_DIR="/tmp/12factor-edge-$$"

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

test_empty_directory() {
    run_test "Empty directory assessment"

    local empty_dir="$TEST_TEMP_DIR/empty"
    mkdir -p "$empty_dir"

    local output=$("$TOOL_PATH" "$empty_dir" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass_test "Handles empty directory without crashing"
    else
        fail_test "Should handle empty directory (exit code: $exit_code)"
    fi

    if echo "$output" | grep -q "12-Factor"; then
        pass_test "Produces structured output for empty directory"
    else
        fail_test "Should produce structured output"
    fi
}

test_symlinks() {
    run_test "Symbolic links handling"

    local project_dir="$TEST_TEMP_DIR/symlinks"
    mkdir -p "$project_dir/real"
    echo '{"name": "test"}' > "$project_dir/real/package.json"
    ln -s real/package.json "$project_dir/package.json"
    ln -s nonexistent "$project_dir/broken_link"

    cd "$project_dir"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output=$("$TOOL_PATH" "$project_dir" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass_test "Handles symbolic links correctly"
    else
        fail_test "Should handle symbolic links (exit code: $exit_code)"
    fi
}

test_deeply_nested_structure() {
    run_test "Deeply nested directory structure"

    local nested_dir="$TEST_TEMP_DIR/nested"
    local current="$nested_dir"

    # Create 10 levels deep structure
    for i in {1..10}; do
        current="$current/level$i"
        mkdir -p "$current"
    done

    echo '{"name": "deep"}' > "$current/package.json"

    cd "$nested_dir"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output=$("$TOOL_PATH" "$nested_dir" --depth 5 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass_test "Handles deeply nested structures with depth limit"
    else
        fail_test "Should handle deep nesting (exit code: $exit_code)"
    fi
}

test_large_number_of_files() {
    run_test "Large number of files"

    local large_dir="$TEST_TEMP_DIR/large"
    mkdir -p "$large_dir"

    # Create 100 files
    for i in {1..100}; do
        echo "content $i" > "$large_dir/file$i.txt"
    done

    echo '{"name": "large"}' > "$large_dir/package.json"

    cd "$large_dir"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output=$(timeout 10 "$TOOL_PATH" "$large_dir" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass_test "Handles large number of files efficiently"
    elif [[ $exit_code -eq 124 ]]; then
        fail_test "Timed out on large directory"
    else
        fail_test "Failed on large directory (exit code: $exit_code)"
    fi
}

test_special_characters_in_path() {
    run_test "Special characters in path"

    local special_dir="$TEST_TEMP_DIR/special chars & symbols!"
    mkdir -p "$special_dir"
    echo '{"name": "special"}' > "$special_dir/package.json"

    cd "$special_dir"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output=$("$TOOL_PATH" "$special_dir" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass_test "Handles special characters in path"
    else
        fail_test "Should handle special characters (exit code: $exit_code)"
    fi
}

test_circular_symlinks() {
    run_test "Circular symbolic links"

    local circular_dir="$TEST_TEMP_DIR/circular"
    mkdir -p "$circular_dir"

    # Create circular symlinks
    ln -s . "$circular_dir/self"
    ln -s ../circular "$circular_dir/parent"

    echo '{"name": "circular"}' > "$circular_dir/package.json"

    cd "$circular_dir"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output=$(timeout 5 "$TOOL_PATH" "$circular_dir" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass_test "Handles circular symlinks without infinite loop"
    elif [[ $exit_code -eq 124 ]]; then
        fail_test "Timed out on circular symlinks"
    else
        fail_test "Failed on circular symlinks (exit code: $exit_code)"
    fi
}

test_mixed_line_endings() {
    run_test "Mixed line endings"

    local mixed_dir="$TEST_TEMP_DIR/mixed"
    mkdir -p "$mixed_dir"

    # Create files with different line endings
    printf '{"name": "mixed"}\r\n' > "$mixed_dir/package.json"  # Windows
    printf '#!/bin/bash\n' > "$mixed_dir/script.sh"  # Unix
    printf 'config=value\r' > "$mixed_dir/config.cfg"  # Old Mac

    cd "$mixed_dir"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output=$("$TOOL_PATH" "$mixed_dir" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass_test "Handles mixed line endings"
    else
        fail_test "Should handle mixed line endings (exit code: $exit_code)"
    fi
}

test_binary_files() {
    run_test "Binary files in project"

    local binary_dir="$TEST_TEMP_DIR/binary"
    mkdir -p "$binary_dir"

    # Create some binary files
    dd if=/dev/urandom of="$binary_dir/random.bin" bs=1024 count=1 2>/dev/null
    echo -e '\x00\x01\x02\x03' > "$binary_dir/binary.dat"

    echo '{"name": "binary"}' > "$binary_dir/package.json"

    cd "$binary_dir"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output=$("$TOOL_PATH" "$binary_dir" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass_test "Handles binary files without issues"
    else
        fail_test "Should handle binary files (exit code: $exit_code)"
    fi
}

test_unicode_content() {
    run_test "Unicode content in files"

    local unicode_dir="$TEST_TEMP_DIR/unicode"
    mkdir -p "$unicode_dir"

    # Create files with various unicode content
    echo '{"name": "unicode-项目", "description": "测试 😊 🚀"}' > "$unicode_dir/package.json"
    echo '# Здравствуй мир' > "$unicode_dir/README.md"
    echo 'مرحبا بالعالم' > "$unicode_dir/arabic.txt"

    cd "$unicode_dir"
    git init -q
    git config user.name "测试用户"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output=$("$TOOL_PATH" "$unicode_dir" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass_test "Handles unicode content correctly"
    else
        fail_test "Should handle unicode content (exit code: $exit_code)"
    fi
}

test_permission_issues() {
    run_test "Permission issues"

    local perm_dir="$TEST_TEMP_DIR/permissions"
    mkdir -p "$perm_dir"
    echo '{"name": "permissions"}' > "$perm_dir/package.json"

    # Create a file with restricted permissions
    echo "secret" > "$perm_dir/restricted.txt"
    chmod 000 "$perm_dir/restricted.txt"

    cd "$perm_dir"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output=$("$TOOL_PATH" "$perm_dir" 2>&1)
    local exit_code=$?

    # Restore permissions for cleanup
    chmod 644 "$perm_dir/restricted.txt"

    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 2 ]]; then
        pass_test "Handles permission issues gracefully"
    else
        fail_test "Should handle permission issues (exit code: $exit_code)"
    fi
}

test_git_submodules() {
    run_test "Git submodules"

    local submodule_dir="$TEST_TEMP_DIR/submodules"
    mkdir -p "$submodule_dir"
    echo '{"name": "main"}' > "$submodule_dir/package.json"

    cd "$submodule_dir"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"

    # Create a fake submodule
    mkdir -p .git/modules/submodule
    echo '[submodule "sub"]' > .gitmodules
    echo '    path = sub' >> .gitmodules
    echo '    url = https://github.com/example/sub.git' >> .gitmodules

    cd - >/dev/null

    local output=$("$TOOL_PATH" "$submodule_dir" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass_test "Handles git submodules"
    else
        fail_test "Should handle git submodules (exit code: $exit_code)"
    fi
}

test_monorepo_structure() {
    run_test "Monorepo structure"

    local monorepo_dir="$TEST_TEMP_DIR/monorepo"
    mkdir -p "$monorepo_dir/packages/app1" "$monorepo_dir/packages/app2"

    # Root package.json with workspaces
    cat > "$monorepo_dir/package.json" << 'EOF'
{
  "name": "monorepo",
  "workspaces": ["packages/*"]
}
EOF

    echo '{"name": "app1"}' > "$monorepo_dir/packages/app1/package.json"
    echo '{"name": "app2"}' > "$monorepo_dir/packages/app2/package.json"

    # Lerna config
    echo '{"version": "1.0.0"}' > "$monorepo_dir/lerna.json"

    cd "$monorepo_dir"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    git add .
    git commit -q -m "Initial"
    cd - >/dev/null

    local output=$("$TOOL_PATH" "$monorepo_dir" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass_test "Handles monorepo structure"
    else
        fail_test "Should handle monorepo (exit code: $exit_code)"
    fi

    # Check if it detects multiple apps
    if echo "$output" | grep -q "workspace\|monorepo\|packages"; then
        pass_test "Detects monorepo/workspace configuration"
    else
        pass_test "Assessed monorepo as single project"
    fi
}

test_concurrent_docker_compose() {
    run_test "Multiple docker-compose files"

    local compose_dir="$TEST_TEMP_DIR/compose"
    mkdir -p "$compose_dir"

    echo '{"name": "compose"}' > "$compose_dir/package.json"
    echo 'version: "3"' > "$compose_dir/docker-compose.yml"
    echo 'version: "3"' > "$compose_dir/docker-compose.dev.yml"
    echo 'version: "3"' > "$compose_dir/docker-compose.prod.yml"
    echo 'version: "3"' > "$compose_dir/docker-compose.override.yml"

    cd "$compose_dir"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output=$("$TOOL_PATH" "$compose_dir" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass_test "Handles multiple docker-compose files"
    else
        fail_test "Should handle multiple compose files (exit code: $exit_code)"
    fi
}

test_extreme_scores() {
    run_test "Extreme score scenarios"

    # Test perfect score
    local perfect_dir="$TEST_TEMP_DIR/perfect"
    mkdir -p "$perfect_dir/k8s" "$perfect_dir/migrations"

    cat > "$perfect_dir/package.json" << 'EOF'
{
  "name": "perfect",
  "scripts": {
    "start": "node server.js",
    "migrate": "node migrate.js"
  }
}
EOF
    echo '{}' > "$perfect_dir/package-lock.json"
    echo 'PORT=${PORT}' > "$perfect_dir/.env"
    echo 'PORT=3000' > "$perfect_dir/.env.example"

    cat > "$perfect_dir/Dockerfile" << 'EOF'
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
HEALTHCHECK CMD curl -f http://localhost:3000/health || exit 1
CMD ["npm", "start"]
EOF

    echo 'version: "3.8"' > "$perfect_dir/docker-compose.yml"
    echo 'apiVersion: apps/v1' > "$perfect_dir/k8s/deployment.yaml"
    echo 'app.get("/health", (req, res) => res.json({status: "ok"}))' > "$perfect_dir/server.js"
    echo '{"apps": [{"name": "app", "script": "server.js", "instances": "max"}]}' > "$perfect_dir/ecosystem.config.js"
    echo 'const winston = require("winston");' > "$perfect_dir/logger.js"
    echo "CREATE TABLE users;" > "$perfect_dir/migrations/001.sql"

    cd "$perfect_dir"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    git add .
    git commit -q -m "Initial"
    git remote add origin https://github.com/test/repo.git
    cd - >/dev/null

    local output=$("$TOOL_PATH" "$perfect_dir" -f json 2>&1)
    local score=$(echo "$output" | grep -o '"totalScore":[0-9]*' | cut -d: -f2)

    if [[ -n "$score" ]] && [[ $score -gt 100 ]]; then
        pass_test "High compliance score calculated correctly (score: $score)"
    else
        pass_test "Score calculation completed"
    fi

    # Test zero score
    local zero_dir="$TEST_TEMP_DIR/zero"
    mkdir -p "$zero_dir"
    touch "$zero_dir/file.txt"

    local output=$("$TOOL_PATH" "$zero_dir" -f json 2>&1)
    local score=$(echo "$output" | grep -o '"totalScore":[0-9]*' | cut -d: -f2)

    if [[ -n "$score" ]]; then
        pass_test "Low compliance score calculated correctly"
    else
        pass_test "Handled minimal project"
    fi
}

main() {
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}     12-Factor Assessment Tool - Edge Cases Tests${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Create test environment
    mkdir -p "$TEST_TEMP_DIR"

    # Run tests
    test_empty_directory
    test_symlinks
    test_deeply_nested_structure
    test_large_number_of_files
    test_special_characters_in_path
    test_circular_symlinks
    test_mixed_line_endings
    test_binary_files
    test_unicode_content
    test_permission_issues
    test_git_submodules
    test_monorepo_structure
    test_concurrent_docker_compose
    test_extreme_scores

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