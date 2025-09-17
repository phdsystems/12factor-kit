# Usage Guide

## Basic Usage

```bash
# Assess current directory
12factor-assess

# Assess specific project
12factor-assess /path/to/project
```

## Output Formats

### Terminal Output (Default)
```bash
12factor-assess /path/to/project
```
Provides colored, human-readable output with scores and recommendations.

### JSON Output
```bash
12factor-assess /path/to/project -f json > report.json
```
Machine-readable format for automation and further processing.

### Markdown Output
```bash
12factor-assess /path/to/project -f markdown > report.md
```
Documentation-friendly format for reports and wikis.

## Command-Line Options

| Option | Description | Example |
|--------|------------|---------|
| `-h, --help` | Show help message | `12factor-assess --help` |
| `-v, --verbose` | Enable verbose output | `12factor-assess . -v` |
| `-f, --format` | Output format (terminal/json/markdown) | `12factor-assess . -f json` |
| `-s, --strict` | Exit with error if compliance < 80% | `12factor-assess . --strict` |
| `-d, --depth` | Search depth for file scanning | `12factor-assess . -d 5` |
| `-r, --remediate` | Generate remediation suggestions | `12factor-assess . --remediate` |

## Examples

### Basic Assessment
```bash
12factor-assess ~/my-project
```

### CI/CD Pipeline Integration
```bash
# Fail build if compliance is below 80%
12factor-assess . --strict

# Generate JSON report for further processing
12factor-assess . -f json > compliance.json
```

### Detailed Analysis
```bash
# Verbose output with deep scanning
12factor-assess . --verbose --depth 5

# Generate full report with remediation
12factor-assess . -f markdown --remediate > assessment.md
```

### Batch Assessment
```bash
# Assess multiple projects
for dir in ~/projects/*; do
  echo "Assessing $dir"
  12factor-assess "$dir" -f json > "reports/$(basename $dir).json"
done
```

## Understanding the Output

### Score Interpretation
- **0-4**: Poor - Significant improvements needed
- **5-6**: Fair - Some compliance but gaps exist
- **7-8**: Good - Mostly compliant with minor issues
- **9-10**: Excellent - Fully compliant with best practices

### Overall Grades
- **A+ (90-100%)**: Excellent 12-Factor Compliance
- **A (80-89%)**: Very Good Compliance
- **B (70-79%)**: Good Compliance
- **C (60-69%)**: Fair Compliance
- **D (50-59%)**: Poor Compliance
- **F (<50%)**: Needs Significant Improvement

### Status Indicators
- ✅ **Green**: Factor is well-implemented
- ⚠️ **Yellow**: Factor partially implemented or has minor issues
- ❌ **Red**: Factor is missing or poorly implemented

## Advanced Usage

### Custom Configuration
Create a `.12factor` file in your project root:
```yaml
exclude:
  - node_modules
  - vendor
  - .git
depth: 3
strict: true
```

### Integration with CI/CD

#### GitHub Actions
```yaml
- name: Check 12-Factor Compliance
  run: |
    12factor-assess . --strict -f json > compliance.json
    score=$(jq '.percentage' compliance.json)
    echo "Compliance: $score%"
```

#### Pre-commit Hook
```bash
#!/bin/bash
12factor-assess . --strict || {
  echo "Project does not meet 12-Factor compliance standards"
  exit 1
}
```

## Tips and Best Practices

1. **Regular Assessment**: Run assessments regularly during development
2. **CI Integration**: Add to CI pipeline for continuous compliance checking
3. **Track Progress**: Save reports over time to track improvement
4. **Team Reviews**: Use markdown reports for team discussions
5. **Incremental Improvement**: Focus on one factor at a time