#!/bin/bash

if [[ ! -f coverage/.resultset.json ]]; then
    echo "No coverage data found. Run coverage analysis first."
    exit 1
fi

echo "12-Factor Reviewer - Coverage Report"
echo "===================================="
echo

# Get the most recent test run
latest_key=$(jq -r 'to_entries | max_by(.value.timestamp) | .key' coverage/.resultset.json)

if [[ -z "$latest_key" || "$latest_key" == "null" ]]; then
    echo "No valid coverage data found."
    exit 1
fi

echo "Latest test run: $(basename "$latest_key")"
echo

# Extract coverage data for each file
total_lines=0
covered_lines=0

while IFS= read -r file; do
    coverage_data=$(jq -r ".\"$latest_key\".coverage[\"$file\"]" coverage/.resultset.json 2>/dev/null)

    if [[ "$coverage_data" != "null" ]]; then
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
    fi
done < <(jq -r ".\"$latest_key\".coverage | keys[]" coverage/.resultset.json)

echo "----------------------------------------"
if [[ $total_lines -gt 0 ]]; then
    overall_percent=$((covered_lines * 100 / total_lines))
else
    overall_percent=0
fi

printf "%-30s %4d/%4d lines (%3d%%)\n" "TOTAL:" "$covered_lines" "$total_lines" "$overall_percent"
echo
echo "HTML Report: file://$(pwd)/coverage/index.html"