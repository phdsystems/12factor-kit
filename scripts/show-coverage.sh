#!/bin/bash

if [[ ! -f coverage/.resultset.json ]]; then
    echo "No coverage data found. Run coverage analysis first."
    exit 1
fi

echo "12-Factor Reviewer - Coverage Report"
echo "===================================="
echo

# Extract coverage data
total_lines=0
covered_lines=0

while IFS= read -r file; do
    coverage_data=$(jq -r ".[\"/bin/bash tests/test_12factor_assessment.sh\"].coverage[\"$file\"]" coverage/.resultset.json)
    
    # Count non-null entries (covered lines) and total entries
    file_total=$(echo "$coverage_data" | jq 'length')
    file_covered=$(echo "$coverage_data" | jq '[.[] | select(. != null)] | length')
    
    total_lines=$((total_lines + file_total))
    covered_lines=$((covered_lines + file_covered))
    
    if [[ $file_total -gt 0 ]]; then
        file_percent=$((file_covered * 100 / file_total))
    else
        file_percent=0
    fi
    
    # Extract just the filename
    basename_file=$(basename "$file")
    printf "%-30s %4d/%4d lines (%3d%%)\n" "$basename_file:" "$file_covered" "$file_total" "$file_percent"
done < <(jq -r '."/bin/bash tests/test_12factor_assessment.sh".coverage | keys[]' coverage/.resultset.json)

echo "----------------------------------------"
if [[ $total_lines -gt 0 ]]; then
    overall_percent=$((covered_lines * 100 / total_lines))
else
    overall_percent=0
fi

printf "%-30s %4d/%4d lines (%3d%%)\n" "TOTAL:" "$covered_lines" "$total_lines" "$overall_percent"
echo
echo "HTML Report: file://$(pwd)/coverage/index.html"
