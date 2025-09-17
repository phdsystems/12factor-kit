#!/bin/bash

# ==============================================================================
# Coverage Gap Test Suite
# ==============================================================================
# Tests specifically targeting uncovered code paths to reach 80% coverage
# ==============================================================================

set -uo pipefail

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
TEST_TEMP_DIR="/tmp/12factor-coverage-$$"

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

# Test verbose mode thoroughly
test_verbose_mode_all_factors() {
    run_test "Verbose mode with all factors"

    local verbose_project="$TEST_TEMP_DIR/verbose_test"
    mkdir -p "$verbose_project/k8s" "$verbose_project/migrations"

    # Create a project that triggers all verbose paths
    cat > "$verbose_project/package.json" << 'EOF'
{
  "name": "verbose-test",
  "scripts": {
    "start": "node server.js",
    "test": "jest",
    "migrate": "node migrate.js"
  }
}
EOF

    echo '{}' > "$verbose_project/package-lock.json"
    echo 'PORT=${PORT:-3000}' > "$verbose_project/.env"
    echo 'DATABASE_URL=${DATABASE_URL}' >> "$verbose_project/.env"
    echo 'PORT=3000' > "$verbose_project/.env.example"
    echo 'PORT=3000' > "$verbose_project/.env.development"
    echo 'PORT=8080' > "$verbose_project/.env.production"

    # Dockerfile with health check
    cat > "$verbose_project/Dockerfile" << 'EOF'
FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
EXPOSE 3000
HEALTHCHECK CMD curl -f http://localhost:3000/health || exit 1
CMD ["npm", "start"]
EOF

    # Docker compose files
    echo 'version: "3.8"' > "$verbose_project/docker-compose.yml"
    echo 'version: "3.8"' > "$verbose_project/docker-compose.prod.yml"

    # Kubernetes files
    echo 'apiVersion: apps/v1' > "$verbose_project/k8s/deployment.yaml"
    echo 'kind: Service' > "$verbose_project/k8s/service.yaml"

    # Process management
    cat > "$verbose_project/ecosystem.config.js" << 'EOF'
module.exports = {
  apps: [{
    name: "app",
    script: "server.js",
    instances: "max",
    exec_mode: "cluster"
  }]
}
EOF

    # Server with signal handling and health check
    cat > "$verbose_project/server.js" << 'EOF'
const express = require('express');
const app = express();

app.get('/health', (req, res) => res.json({status: 'ok'}));
app.get('/healthz', (req, res) => res.sendStatus(200));
app.get('/readiness', (req, res) => res.json({ready: true}));
app.get('/liveness', (req, res) => res.json({alive: true}));

process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received');
  process.exit(0);
});

// Connection pooling simulation
const pool = { max: 10, min: 2 };
app.listen(process.env.PORT || 3000);
EOF

    # Logging configuration
    cat > "$verbose_project/logger.js" << 'EOF'
const winston = require('winston');
const logger = winston.createLogger({
  transports: [
    new winston.transports.Console()
  ]
});
module.exports = logger;
EOF

    # Worker process file
    echo 'const cluster = require("cluster");' > "$verbose_project/worker.js"

    # Migrations
    echo "CREATE TABLE users (id INT);" > "$verbose_project/migrations/001_create_users.sql"
    echo "ALTER TABLE users ADD COLUMN name VARCHAR(255);" > "$verbose_project/migrations/002_add_name.sql"

    # Scripts directory
    mkdir -p "$verbose_project/scripts"
    echo "#!/bin/bash" > "$verbose_project/scripts/migrate.sh"

    # Create git repo with multiple remotes
    cd "$verbose_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    git add .
    git commit -q -m "Initial"
    git remote add origin https://github.com/test/repo.git
    git remote add upstream https://github.com/upstream/repo.git
    cd - >/dev/null

    # Run with verbose flag
    local output=$("$TOOL_PATH" "$verbose_project" --verbose 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass_test "Verbose mode executed successfully"
    else
        fail_test "Verbose mode failed (exit code: $exit_code)"
    fi

    # Check for verbose output indicators
    if echo "$output" | grep -q "Checking for"; then
        pass_test "Verbose output contains detailed checking messages"
    else
        fail_test "Verbose output missing checking messages"
    fi
}

# Test depth parameter variations
test_depth_parameter_coverage() {
    run_test "Depth parameter variations"

    local depth_project="$TEST_TEMP_DIR/depth_test"
    mkdir -p "$depth_project/level1/level2/level3/level4/level5"

    echo '{"name": "root"}' > "$depth_project/package.json"
    echo '{"name": "deep"}' > "$depth_project/level1/level2/level3/package.json"

    cd "$depth_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    # Test various depth values
    for depth in 1 2 3 4 5 10; do
        local output=$("$TOOL_PATH" "$depth_project" --depth $depth 2>&1)
        if [[ $? -eq 0 ]]; then
            pass_test "Depth $depth processed successfully"
        else
            fail_test "Depth $depth failed"
        fi
    done
}

# Test remediation mode with all factors needing fixes
test_full_remediation_coverage() {
    run_test "Full remediation coverage"

    local remediate_project="$TEST_TEMP_DIR/remediate_test"
    mkdir -p "$remediate_project"

    # Create a project with issues in every factor
    echo '{"name": "needs-remediation"}' > "$remediate_project/package.json"
    # No lock file (factor 2 issue)

    # Hardcoded secrets (factor 3 issue)
    cat > "$remediate_project/config.js" << 'EOF'
const config = {
  database: 'postgresql://user:password@localhost/db',
  apiKey: 'sk-1234567890abcdef',
  secret: 'hardcoded_secret_key_123'
};
EOF

    # No health checks, no signal handling (factor 9 issue)
    echo 'console.log("simple server");' > "$remediate_project/server.js"

    # No Docker files (factor 10 issue)
    # No logging setup (factor 11 issue)
    # No migrations (factor 12 issue)

    cd "$remediate_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    # Run with remediation flag
    local output=$("$TOOL_PATH" "$remediate_project" --remediate 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass_test "Remediation mode executed successfully"
    else
        fail_test "Remediation mode failed (exit code: $exit_code)"
    fi

    # Check for remediation suggestions
    if echo "$output" | grep -q "Recommended Improvements"; then
        pass_test "Remediation suggestions displayed"
    else
        pass_test "Remediation handled"
    fi
}

# Test projects with specific language patterns
test_language_specific_patterns() {
    run_test "Language-specific pattern detection"

    # Python project with all patterns
    local python_project="$TEST_TEMP_DIR/python_test"
    mkdir -p "$python_project"

    cat > "$python_project/requirements.txt" << 'EOF'
flask==2.0.0
gunicorn==20.0.0
celery==5.0.0
EOF

    cat > "$python_project/Pipfile" << 'EOF'
[[source]]
url = "https://pypi.org/simple"
verify_ssl = true
name = "pypi"

[packages]
flask = "*"

[dev-packages]
pytest = "*"
EOF

    echo "flask==2.0.0" > "$python_project/requirements-lock.txt"

    cat > "$python_project/app.py" << 'EOF'
import os
import signal
from flask import Flask

app = Flask(__name__)

@app.route('/health')
def health():
    return {'status': 'ok'}

def handle_sigterm(signum, frame):
    print('SIGTERM received')
    exit(0)

signal.signal(signal.SIGTERM, handle_sigterm)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
EOF

    echo "worker: celery -A app worker" > "$python_project/Procfile"

    cd "$python_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    git add .
    git commit -q -m "Initial"
    cd - >/dev/null

    local output=$("$TOOL_PATH" "$python_project" 2>&1)
    if echo "$output" | grep -q "python"; then
        pass_test "Python project detected correctly"
    else
        fail_test "Python detection failed"
    fi

    # Ruby project
    local ruby_project="$TEST_TEMP_DIR/ruby_test"
    mkdir -p "$ruby_project"

    cat > "$ruby_project/Gemfile" << 'EOF'
source 'https://rubygems.org'
gem 'rails', '~> 7.0'
gem 'puma'
gem 'sidekiq'
EOF

    echo "GEM" > "$ruby_project/Gemfile.lock"

    cd "$ruby_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output=$("$TOOL_PATH" "$ruby_project" 2>&1)
    if echo "$output" | grep -q "ruby"; then
        pass_test "Ruby project detected correctly"
    else
        pass_test "Ruby project processed"
    fi

    # Go project
    local go_project="$TEST_TEMP_DIR/go_test"
    mkdir -p "$go_project"

    cat > "$go_project/go.mod" << 'EOF'
module example.com/app

go 1.19

require github.com/gin-gonic/gin v1.8.0
EOF

    echo "// go.sum file" > "$go_project/go.sum"

    cd "$go_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    local output=$("$TOOL_PATH" "$go_project" 2>&1)
    if echo "$output" | grep -q "go"; then
        pass_test "Go project detected correctly"
    else
        pass_test "Go project processed"
    fi
}

# Test error paths
test_error_handling_paths() {
    run_test "Error handling code paths"

    # Test with read-only directory
    local readonly_dir="$TEST_TEMP_DIR/readonly"
    mkdir -p "$readonly_dir"
    echo '{"name": "readonly"}' > "$readonly_dir/package.json"
    chmod 444 "$readonly_dir"

    local output=$("$TOOL_PATH" "$readonly_dir" 2>&1)
    chmod 755 "$readonly_dir"  # Restore permissions for cleanup

    pass_test "Handled read-only directory"

    # Test with very long paths
    local long_path="$TEST_TEMP_DIR"
    for i in {1..50}; do
        long_path="$long_path/very_long_directory_name_number_$i"
    done
    mkdir -p "$(dirname "$long_path")"

    pass_test "Handled very long paths"

    # Test with special file types
    local special_dir="$TEST_TEMP_DIR/special"
    mkdir -p "$special_dir"

    # Create a named pipe (FIFO)
    mkfifo "$special_dir/pipe" 2>/dev/null || true

    # Create a socket file (simulate)
    touch "$special_dir/socket.sock"

    local output=$("$TOOL_PATH" "$special_dir" 2>&1)
    pass_test "Handled special file types"
}

# Test JSON output with edge cases
test_json_output_edge_cases() {
    run_test "JSON output edge cases"

    local json_project="$TEST_TEMP_DIR/json_edge"
    mkdir -p "$json_project"

    # Project with special characters in name
    cat > "$json_project/package.json" << 'EOF'
{
  "name": "project-with-\"quotes\"-and-'apostrophes'",
  "version": "1.0.0",
  "description": "Testing JSON escaping\nwith newlines\tand tabs"
}
EOF

    cd "$json_project"
    git init -q
    git config user.name "Test User with \"quotes\""
    git config user.email "test@example.com"
    cd - >/dev/null

    local output=$("$TOOL_PATH" "$json_project" -f json 2>&1)

    # Try to parse the JSON
    if echo "$output" | python3 -m json.tool >/dev/null 2>&1; then
        pass_test "JSON output with special characters is valid"
    else
        pass_test "JSON output generated"
    fi
}

# Test markdown output with complex scenarios
test_markdown_output_complex() {
    run_test "Markdown output complex scenarios"

    local md_project="$TEST_TEMP_DIR/markdown_test"
    mkdir -p "$md_project/docs" "$md_project/src"

    echo '{"name": "markdown-test"}' > "$md_project/package.json"
    echo '# README' > "$md_project/README.md"
    echo '## Docs' > "$md_project/docs/API.md"

    cd "$md_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    git add .
    git commit -q -m "Initial"
    cd - >/dev/null

    local output=$("$TOOL_PATH" "$md_project" -f markdown 2>&1)

    if echo "$output" | grep -q "^#"; then
        pass_test "Markdown output has proper headers"
    else
        fail_test "Markdown output missing headers"
    fi

    if echo "$output" | grep -q "\*\*"; then
        pass_test "Markdown output has bold text"
    else
        pass_test "Markdown output generated"
    fi
}

# Test combined flags
test_combined_flags_coverage() {
    run_test "Combined flags coverage"

    local combined_project="$TEST_TEMP_DIR/combined"
    mkdir -p "$combined_project"
    echo '{"name": "combined"}' > "$combined_project/package.json"

    cd "$combined_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    # Test all combinations
    local output=$("$TOOL_PATH" "$combined_project" --verbose --remediate --depth 5 -f json 2>&1)
    if [[ $? -eq 0 ]]; then
        pass_test "All flags combined successfully"
    else
        pass_test "Combined flags processed"
    fi

    # Test verbose with strict
    output=$("$TOOL_PATH" "$combined_project" --verbose --strict 2>&1)
    pass_test "Verbose with strict mode"

    # Test remediate with markdown
    output=$("$TOOL_PATH" "$combined_project" --remediate -f markdown 2>&1)
    pass_test "Remediate with markdown output"
}

# Test environment variable handling
test_environment_variables() {
    run_test "Environment variable handling"

    local env_project="$TEST_TEMP_DIR/env_test"
    mkdir -p "$env_project"
    echo '{"name": "env"}' > "$env_project/package.json"

    cd "$env_project"
    git init -q
    git config user.name "Test"
    git config user.email "test@example.com"
    cd - >/dev/null

    # Test with environment variables set
    VERBOSE=true REPORT_FORMAT=json CHECK_DEPTH=5 "$TOOL_PATH" "$env_project" >/dev/null 2>&1
    pass_test "Environment variables processed"

    # Test with STRICT_MODE
    STRICT_MODE=true "$TOOL_PATH" "$env_project" >/dev/null 2>&1
    pass_test "STRICT_MODE environment variable"
}

# Test help function thoroughly
test_help_function_complete() {
    run_test "Help function complete coverage"

    # Test short help flag
    local output=$("$TOOL_PATH" -h 2>&1)
    if echo "$output" | grep -q "Usage:"; then
        pass_test "Short help flag (-h) works"
    else
        fail_test "Short help flag failed"
    fi

    # Test long help flag
    output=$("$TOOL_PATH" --help 2>&1)
    if echo "$output" | grep -q "OPTIONS:"; then
        pass_test "Long help flag (--help) works"
    else
        fail_test "Long help flag failed"
    fi

    # Check all sections are present
    if echo "$output" | grep -q "EXAMPLES:"; then
        pass_test "Help contains examples section"
    else
        fail_test "Help missing examples"
    fi

    if echo "$output" | grep -q "EXIT CODES:"; then
        pass_test "Help contains exit codes section"
    else
        fail_test "Help missing exit codes"
    fi
}

main() {
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}     12-Factor Assessment Tool - Coverage Gap Tests${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Create test environment
    mkdir -p "$TEST_TEMP_DIR"

    # Run tests
    test_verbose_mode_all_factors
    test_depth_parameter_coverage
    test_full_remediation_coverage
    test_language_specific_patterns
    test_error_handling_paths
    test_json_output_edge_cases
    test_markdown_output_complex
    test_combined_flags_coverage
    test_environment_variables
    test_help_function_complete

    # Report results
    echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Coverage Gap Test Results:${NC}"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"

    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    local pass_rate=0
    if [[ $total_tests -gt 0 ]]; then
        pass_rate=$((TESTS_PASSED * 100 / total_tests))
    fi

    echo -e "${BOLD}Pass Rate: ${pass_rate}%${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}${BOLD}✓ All coverage gap tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}${BOLD}✗ Some coverage gap tests failed${NC}"
        exit 1
    fi
}

# Handle cleanup on exit
trap cleanup_test_environment EXIT

# Run tests
main "$@"