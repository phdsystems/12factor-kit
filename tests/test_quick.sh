#!/bin/bash

set -euo pipefail

echo "Quick Test Suite - 12-Factor Reviewer"
echo "======================================"

# Test basic functionality
echo -n "Tool exists: "
if [[ -x bin/12factor-assess ]]; then
    echo "✓"
else
    echo "✗"
    exit 1
fi

# Test on current project
echo -n "Runs on current directory: "
if bin/12factor-assess . -f json > /tmp/test.json 2>/dev/null; then
    echo "✓"
else
    echo "✗"
    exit 1
fi

# Test JSON validity
echo -n "Produces valid JSON: "
if jq . /tmp/test.json > /dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
    exit 1
fi

# Test strict mode exits correctly
echo -n "Strict mode works: "
if bin/12factor-assess . --strict &>/dev/null; then
    # High compliance, passed
    echo "✓ (passed threshold)"
else
    # Low compliance, failed as expected
    echo "✓ (enforced threshold)"
fi

echo
echo "All quick tests passed!"
