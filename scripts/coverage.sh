#!/bin/bash

# ==============================================================================
# Code Coverage Script for 12-Factor Reviewer
# ==============================================================================
# Uses kcov to generate code coverage reports for bash scripts
# ==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COVERAGE_DIR="$PROJECT_ROOT/coverage"
TOOL_PATH="$PROJECT_ROOT/bin/12factor-assess"
TEST_SCRIPT="$PROJECT_ROOT/tests/test_12factor_assessment.sh"

# Cleanup previous coverage
rm -rf "$COVERAGE_DIR"
mkdir -p "$COVERAGE_DIR"

echo -e "${BOLD}${CYAN}12-Factor Reviewer - Code Coverage Analysis${NC}"
echo -e "${BOLD}============================================${NC}"
echo

# Check if kcov is installed
if ! command -v kcov &> /dev/null; then
    echo -e "${RED}Error: kcov is not installed${NC}"
    echo "Install with: sudo apt-get install -y kcov"
    exit 1
fi

echo -e "${BLUE}Running tests with coverage...${NC}"
echo

# Run tests with coverage
kcov \
    --include-path="$PROJECT_ROOT/src,$PROJECT_ROOT/bin" \
    --exclude-pattern="/tests/,/examples/" \
    "$COVERAGE_DIR" \
    "$TEST_SCRIPT"

# Check if coverage was generated
if [[ -f "$COVERAGE_DIR/index.html" ]]; then
    echo
    echo -e "${GREEN}✅ Coverage report generated successfully!${NC}"
    echo

    # Extract coverage percentage from kcov output
    if [[ -f "$COVERAGE_DIR/index.json" ]]; then
        coverage_percent=$(python3 -c "import json; data=json.load(open('$COVERAGE_DIR/index.json')); print(data.get('percent_covered', 'N/A'))" 2>/dev/null || echo "N/A")
        echo -e "${BOLD}Coverage Summary:${NC}"
        echo -e "  Overall Coverage: ${GREEN}${coverage_percent}%${NC}"
    fi

    echo
    echo -e "${BOLD}Coverage Reports:${NC}"
    echo -e "  HTML Report: ${CYAN}file://$COVERAGE_DIR/index.html${NC}"
    echo -e "  JSON Report: ${CYAN}$COVERAGE_DIR/index.json${NC}"

    # Show file-by-file coverage if available
    if command -v jq &> /dev/null && [[ -f "$COVERAGE_DIR/index.json" ]]; then
        echo
        echo -e "${BOLD}File Coverage:${NC}"
        python3 << EOF
import json
import os

try:
    with open('$COVERAGE_DIR/index.json') as f:
        data = json.load(f)

    files = data.get('files', [])
    for file_data in files:
        name = os.path.basename(file_data.get('file', 'unknown'))
        covered = file_data.get('percent_covered', 0)

        # Color based on coverage
        if covered >= 80:
            color = '\033[0;32m'  # Green
        elif covered >= 60:
            color = '\033[1;33m'  # Yellow
        else:
            color = '\033[0;31m'  # Red

        print(f"  {name:30} {color}{covered:5.1f}%\033[0m")
except Exception as e:
    print(f"Could not parse coverage data: {e}")
EOF
    fi
else
    echo -e "${RED}Error: Coverage report was not generated${NC}"
    exit 1
fi

echo
echo -e "${BOLD}${GREEN}Coverage analysis complete!${NC}"
echo

# Open in browser if available (optional)
if command -v xdg-open &> /dev/null; then
    echo -e "${YELLOW}Opening coverage report in browser...${NC}"
    xdg-open "$COVERAGE_DIR/index.html" 2>/dev/null || true
elif command -v open &> /dev/null; then
    echo -e "${YELLOW}Opening coverage report in browser...${NC}"
    open "$COVERAGE_DIR/index.html" 2>/dev/null || true
fi