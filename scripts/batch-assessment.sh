#!/bin/bash

# ==============================================================================
# 12-Factor Assessment Tool - Batch Assessment Script
# ==============================================================================
# Assess multiple projects and generate comparative reports
# ==============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_PATH="${SCRIPT_DIR}/../bin/twelve-factor-reviewer"
OUTPUT_DIR="${OUTPUT_DIR:-./assessment-reports}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ==============================================================================
# Functions
# ==============================================================================

show_help() {
    cat << EOF
${BOLD}12-Factor Batch Assessment Tool${NC}

${BOLD}USAGE:${NC}
    $0 [OPTIONS] PROJECT1 [PROJECT2 ...]

${BOLD}OPTIONS:${NC}
    -h, --help              Show this help message
    -o, --output DIR        Output directory for reports (default: ./assessment-reports)
    -f, --format FORMAT     Report format: terminal, json, markdown, all (default: all)
    --compare              Generate comparative analysis
    --threshold SCORE      Minimum compliance threshold (0-100)

${BOLD}EXAMPLES:${NC}
    # Assess multiple projects
    $0 /path/to/project1 /path/to/project2

    # Generate only JSON reports
    $0 -f json /path/to/projects/*

    # Set output directory and compare
    $0 -o reports --compare project1/ project2/ project3/

EOF
}

assess_project() {
    local project_path="$1"
    local project_name=$(basename "$project_path")
    
    echo -e "${CYAN}Assessing: $project_name${NC}"
    
    # Create project output directory
    local project_output="${OUTPUT_DIR}/${project_name}_${TIMESTAMP}"
    mkdir -p "$project_output"
    
    # Generate reports based on format
    case "$FORMAT" in
        all)
            "$TOOL_PATH" "$project_path" > "$project_output/terminal.txt" 2>&1
            "$TOOL_PATH" "$project_path" -f json > "$project_output/report.json" 2>&1
            "$TOOL_PATH" "$project_path" -f markdown > "$project_output/report.md" 2>&1
            ;;
        json)
            "$TOOL_PATH" "$project_path" -f json > "$project_output/report.json" 2>&1
            ;;
        markdown)
            "$TOOL_PATH" "$project_path" -f markdown > "$project_output/report.md" 2>&1
            ;;
        terminal)
            "$TOOL_PATH" "$project_path" > "$project_output/terminal.txt" 2>&1
            ;;
    esac
    
    # Extract score for summary
    if [[ -f "$project_output/report.json" ]]; then
        local score=$(grep '"total_score"' "$project_output/report.json" | grep -o '[0-9]*' | head -1)
        local percentage=$(grep '"percentage"' "$project_output/report.json" | grep -o '[0-9]*' | head -1)
        
        echo "$project_name,$score,120,$percentage" >> "${OUTPUT_DIR}/summary_${TIMESTAMP}.csv"
        
        # Check threshold
        if [[ -n "$THRESHOLD" ]] && [[ "$percentage" -lt "$THRESHOLD" ]]; then
            echo -e "  ${YELLOW}⚠️  Below threshold: $percentage% < $THRESHOLD%${NC}"
            BELOW_THRESHOLD+=("$project_name")
        else
            echo -e "  ${GREEN}✅ Compliance: $percentage%${NC}"
        fi
    fi
}

generate_comparative_report() {
    echo -e "\n${BOLD}Generating Comparative Analysis${NC}"
    
    local summary_file="${OUTPUT_DIR}/comparative_analysis_${TIMESTAMP}.md"
    
    cat > "$summary_file" << EOF
# 12-Factor Compliance - Comparative Analysis

**Date:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Projects Assessed:** ${#PROJECTS[@]}

## Summary Table

| Project | Score | Max | Percentage | Grade |
|---------|-------|-----|------------|-------|
EOF
    
    # Read from CSV and generate table
    while IFS=',' read -r name score max percentage; do
        local grade="F"
        [[ $percentage -ge 90 ]] && grade="A+"
        [[ $percentage -ge 80 ]] && [[ $percentage -lt 90 ]] && grade="A"
        [[ $percentage -ge 70 ]] && [[ $percentage -lt 80 ]] && grade="B"
        [[ $percentage -ge 60 ]] && [[ $percentage -lt 70 ]] && grade="C"
        [[ $percentage -ge 50 ]] && [[ $percentage -lt 60 ]] && grade="D"
        
        echo "| $name | $score | $max | $percentage% | $grade |" >> "$summary_file"
    done < "${OUTPUT_DIR}/summary_${TIMESTAMP}.csv"
    
    # Add statistics
    cat >> "$summary_file" << EOF

## Statistics

- **Average Compliance:** $(awk -F',' '{sum+=$4; count++} END {print sum/count "%"}' "${OUTPUT_DIR}/summary_${TIMESTAMP}.csv")
- **Highest Score:** $(awk -F',' 'BEGIN {max=0} {if($4>max) {max=$4; project=$1}} END {print project " (" max "%)"}' "${OUTPUT_DIR}/summary_${TIMESTAMP}.csv")
- **Lowest Score:** $(awk -F',' 'BEGIN {min=100} {if($4<min) {min=$4; project=$1}} END {print project " (" min "%)"}' "${OUTPUT_DIR}/summary_${TIMESTAMP}.csv")

EOF
    
    if [[ ${#BELOW_THRESHOLD[@]} -gt 0 ]]; then
        cat >> "$summary_file" << EOF
## Projects Below Threshold ($THRESHOLD%)

EOF
        for project in "${BELOW_THRESHOLD[@]}"; do
            echo "- $project" >> "$summary_file"
        done
    fi
    
    echo -e "${GREEN}Comparative report saved to: $summary_file${NC}"
}

# ==============================================================================
# Main
# ==============================================================================

# Default values
FORMAT="all"
COMPARE="false"
THRESHOLD=""
PROJECTS=()
BELOW_THRESHOLD=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        --compare)
            COMPARE="true"
            shift
            ;;
        --threshold)
            THRESHOLD="$2"
            shift 2
            ;;
        *)
            PROJECTS+=("$1")
            shift
            ;;
    esac
done

# Validate projects
if [[ ${#PROJECTS[@]} -eq 0 ]]; then
    echo -e "${RED}Error: No projects specified${NC}"
    show_help
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${BOLD}12-Factor Batch Assessment${NC}"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Projects to assess: ${#PROJECTS[@]}"
echo -e "Output directory: $OUTPUT_DIR"
echo -e "Report format: $FORMAT"
[[ -n "$THRESHOLD" ]] && echo -e "Compliance threshold: $THRESHOLD%"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Initialize summary
echo "Project,Score,Max,Percentage" > "${OUTPUT_DIR}/summary_${TIMESTAMP}.csv"

# Assess each project
for project in "${PROJECTS[@]}"; do
    if [[ -d "$project" ]]; then
        assess_project "$project"
    else
        echo -e "${YELLOW}Warning: Skipping $project (not a directory)${NC}"
    fi
done

# Generate comparative report if requested
if [[ "$COMPARE" == "true" ]]; then
    generate_comparative_report
fi

# Final summary
echo -e "\n${BOLD}Assessment Complete${NC}"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Reports saved to: ${CYAN}$OUTPUT_DIR${NC}"

if [[ ${#BELOW_THRESHOLD[@]} -gt 0 ]]; then
    echo -e "\n${YELLOW}Projects below threshold ($THRESHOLD%):${NC}"
    for project in "${BELOW_THRESHOLD[@]}"; do
        echo -e "  - $project"
    done
    exit 1
fi

exit 0