#!/bin/bash

# ==============================================================================
# 12-Factor Assessment Tool - Test Runner Script
# ==============================================================================
# Runs the complete test suite with options
# ==============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."
TEST_SCRIPT="${PROJECT_ROOT}/tests/test-core-assessment.sh"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# Parse arguments
VERBOSE="${1:-false}"

echo -e "${BOLD}12-Factor Assessment Tool - Test Runner${NC}"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check test script exists
if [[ ! -f "$TEST_SCRIPT" ]]; then
    echo -e "${RED}Error: Test script not found at $TEST_SCRIPT${NC}"
    exit 1
fi

# Make sure it's executable
chmod +x "$TEST_SCRIPT"

# Run tests
if [[ "$VERBOSE" == "verbose" ]] || [[ "$VERBOSE" == "true" ]]; then
    echo -e "${YELLOW}Running tests in verbose mode...${NC}"
    VERBOSE=true "$TEST_SCRIPT"
else
    echo -e "${YELLOW}Running tests...${NC}"
    "$TEST_SCRIPT"
fi

# Check exit code
if [[ $? -eq 0 ]]; then
    echo -e "\n${GREEN}${BOLD}✓ All tests passed successfully!${NC}"
else
    echo -e "\n${RED}${BOLD}✗ Some tests failed${NC}"
    exit 1
fi