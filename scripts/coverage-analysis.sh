#!/bin/bash

# ==============================================================================
# Code Coverage Script using Bashcov (Ruby-based)
# ==============================================================================
# Uses bashcov to generate detailed code coverage reports for bash scripts
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
# Run coverage on multiple test suites
TEST_SCRIPTS=(
    "tests/test-core-assessment.sh"
    "tests/test-input-validation.sh"
    "tests/test-help-and-verbose.sh"
    "tests/test-output-formats.sh"
    "tests/test-strict-mode.sh"
    "tests/test-assessment-paths.sh"
    "tests/test-terminal-output.sh"
    "tests/test-remediation.sh"
    "tests/test-edge-cases.sh"
    "tests/test-verbose-and-flags.sh"
    "tests/test-language-detection.sh"
    "tests/test-all-languages-formats.sh"
    "tests/test-remediation-all-factors.sh"
    "tests/test-verbose-edge-cases.sh"
    "tests/test-maximum-project-scenarios.sh"
    "tests/test-exhaustive-combinations.sh"
)

# Cleanup previous coverage
rm -rf "$COVERAGE_DIR"

echo -e "${BOLD}${CYAN}12-Factor Reviewer - Code Coverage Analysis (Bashcov)${NC}"
echo -e "${BOLD}======================================================${NC}"
echo

# Check if bashcov is installed
if ! command -v bashcov &> /dev/null; then
    echo -e "${RED}Error: bashcov is not installed${NC}"
    echo "Install with: gem install bashcov"
    exit 1
fi

echo -e "${BLUE}Running tests with bashcov coverage...${NC}"
echo

# Change to project root for proper paths
cd "$PROJECT_ROOT"

# Run tests with bashcov
# --root specifies the root directory for coverage
if bashcov --root . "${TEST_SCRIPTS[@]}" 2>&1 | tail -20; then
    echo
    echo -e "${GREEN}✅ Coverage analysis completed!${NC}"
else
    echo -e "${YELLOW}⚠️  Tests may have hung (known issue with strict mode test)${NC}"
    echo -e "${YELLOW}   Coverage data may still be generated${NC}"
fi

# Check if coverage was generated
if [[ -d "$COVERAGE_DIR" ]]; then
    echo
    echo -e "${BOLD}Coverage Reports Generated:${NC}"
    
    # Check for HTML report
    if [[ -f "$COVERAGE_DIR/index.html" ]]; then
        echo -e "  ${CYAN}HTML Report: file://$COVERAGE_DIR/index.html${NC}"
        
        # Try to extract coverage percentage from HTML
        if command -v grep &> /dev/null; then
            coverage_line=$(grep -oP 'class="covered_percent">.*?<' "$COVERAGE_DIR/index.html" 2>/dev/null | head -1 || true)
            if [[ -n "$coverage_line" ]]; then
                coverage_percent=$(echo "$coverage_line" | sed 's/.*>\(.*\)<.*/\1/')
                echo
                echo -e "${BOLD}Overall Coverage: ${GREEN}${coverage_percent}${NC}"
            fi
        fi
    fi
    
    # Check for JSON report
    if [[ -f "$COVERAGE_DIR/.resultset.json" ]]; then
        echo -e "  ${CYAN}JSON Report: $COVERAGE_DIR/.resultset.json${NC}"
    fi
    
    # List covered files
    echo
    echo -e "${BOLD}Coverage by File:${NC}"
    if [[ -d "$COVERAGE_DIR" ]]; then
        # Look for individual file coverage in HTML files
        for html_file in "$COVERAGE_DIR"/*.html; do
            if [[ -f "$html_file" ]] && [[ "$(basename "$html_file")" != "index.html" ]]; then
                filename=$(basename "$html_file" .html | sed 's/_/\//g')
                if [[ "$filename" == *"12factor"* ]] || [[ "$filename" == *".sh" ]]; then
                    echo "  - $filename"
                fi
            fi
        done
    fi
    
    echo
    echo -e "${BOLD}${GREEN}✨ Coverage analysis complete!${NC}"
    echo
    
    # Open in browser if available (optional)
    if command -v xdg-open &> /dev/null; then
        echo -e "${YELLOW}Opening coverage report in browser...${NC}"
        xdg-open "$COVERAGE_DIR/index.html" 2>/dev/null || true
    elif command -v open &> /dev/null; then
        echo -e "${YELLOW}Opening coverage report in browser...${NC}"
        open "$COVERAGE_DIR/index.html" 2>/dev/null || true
    fi
else
    echo -e "${RED}Error: Coverage directory was not created${NC}"
    echo -e "${YELLOW}This might be due to the test hanging. Try running individual tests:${NC}"
    echo -e "  ${CYAN}bashcov --root . tests/test-quick-validation.sh${NC}"
    exit 1
fi
