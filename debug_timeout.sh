#!/bin/bash

# Quick debug test to find timeout issue
set -euo pipefail

# Test minimal execution
echo "Testing basic execution..."
timeout 3 ./bin/twelve-factor-reviewer --help >/dev/null && echo "Help works" || echo "Help timeout"

# Test with minimal project
echo "Creating test project..."
TESTDIR=$(mktemp -d)
echo "# Test" > "$TESTDIR/README.md"

echo "Testing basic assessment..."
timeout 5 ./bin/twelve-factor-reviewer "$TESTDIR" >/dev/null && echo "Basic works" || echo "Basic timeout"

echo "Testing JSON format..."
timeout 5 ./bin/twelve-factor-reviewer "$TESTDIR" -f json >/dev/null && echo "JSON works" || echo "JSON timeout"

echo "Testing strict mode..."
timeout 5 ./bin/twelve-factor-reviewer "$TESTDIR" --strict >/dev/null
exit_code=$?
if [[ $exit_code -eq 124 ]]; then
    echo "Strict timeout"
elif [[ $exit_code -eq 1 ]]; then
    echo "Strict works (failed compliance as expected)"
else
    echo "Strict works (passed compliance)"
fi

rm -rf "$TESTDIR"
echo "Debug complete"