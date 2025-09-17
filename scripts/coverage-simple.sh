#!/bin/bash

# Simple coverage analysis using bash tracing
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COVERAGE_DIR="$PROJECT_ROOT/coverage"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}12-Factor Reviewer - Coverage Analysis${NC}"
echo -e "${BOLD}======================================${NC}"
echo

# Create coverage directory
rm -rf "$COVERAGE_DIR"
mkdir -p "$COVERAGE_DIR"

# Run tests and capture which lines are executed
echo -e "${CYAN}Running tests with trace...${NC}"
BASH_XTRACEFD=3 PS4='+ ${BASH_SOURCE}:${LINENO}: ' \
  bash -x tests/test_12factor_assessment.sh 3> "$COVERAGE_DIR/trace.log" 2>&1 | tail -5

# Analyze coverage
echo
echo -e "${BOLD}Coverage Summary:${NC}"

# Count lines in source files
total_lines=0
covered_lines=0

for file in bin/12factor-assess src/*.sh; do
  if [[ -f "$file" ]]; then
    file_lines=$(wc -l < "$file")
    total_lines=$((total_lines + file_lines))
    
    # Count covered lines (approximation based on trace)
    file_covered=$(grep -c "$(basename "$file")" "$COVERAGE_DIR/trace.log" 2>/dev/null || echo 0)
    covered_lines=$((covered_lines + file_covered))
    
    echo -e "  $(basename "$file"): ${file_covered}/${file_lines} lines traced"
  fi
done

# Calculate percentage
if [[ $total_lines -gt 0 ]]; then
  percentage=$((covered_lines * 100 / total_lines))
  echo
  echo -e "${BOLD}Overall Coverage: ${GREEN}~${percentage}%${NC} (approximation)"
fi

echo
echo -e "Trace log: ${CYAN}$COVERAGE_DIR/trace.log${NC}"
echo -e "${BOLD}${GREEN}Coverage analysis complete!${NC}"
