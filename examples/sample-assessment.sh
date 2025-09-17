#!/bin/bash

# ==============================================================================
# Sample Assessment Script
# ==============================================================================
# Example of how to use the 12-Factor Assessment Tool in automation
# ==============================================================================

set -euo pipefail

# Configuration
TOOL_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../bin" && pwd)/twelve-factor-reviewer"
PROJECTS_DIR="${1:-/path/to/projects}"
OUTPUT_DIR="${2:-./reports}"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to assess a project
assess_project() {
    local project_path="$1"
    local project_name
    project_name=$(basename "$project_path")
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    echo "Assessing project: $project_name"
    
    # Generate reports in multiple formats
    "$TOOL_PATH" "$project_path" -f json > "$OUTPUT_DIR/${project_name}_${timestamp}.json"
    "$TOOL_PATH" "$project_path" -f markdown > "$OUTPUT_DIR/${project_name}_${timestamp}.md"
    
    # Check compliance level
    if "$TOOL_PATH" "$project_path" --strict > /dev/null 2>&1; then
        echo "  ✅ Project meets compliance threshold (≥80%)"
    else
        echo "  ⚠️  Project below compliance threshold (<80%)"
    fi
}

# Main execution
echo "12-Factor Compliance Assessment - Batch Processing"
echo "=================================================="

# Check if projects directory exists
if [[ ! -d "$PROJECTS_DIR" ]]; then
    echo "Error: Projects directory not found: $PROJECTS_DIR"
    exit 1
fi

# Find and assess all projects
for project in "$PROJECTS_DIR"/*; do
    if [[ -d "$project" ]]; then
        assess_project "$project"
    fi
done

echo ""
echo "Assessment complete. Reports saved to: $OUTPUT_DIR"

# Generate summary report
echo ""
echo "Summary Report"
echo "=============="
for report in "$OUTPUT_DIR"/*.json; do
    if [[ -f "$report" ]]; then
        project=$(basename "$report" | cut -d'_' -f1)
        score=$(grep '"total_score"' "$report" | grep -o '[0-9]*' | head -1)
        percentage=$(grep '"percentage"' "$report" | grep -o '[0-9]*' | head -1)
        echo "  $project: $score/120 ($percentage%)"
    fi
done