# Quick Reference Card

## Installation (One-liner)
```bash
git clone https://github.com/phdsystems/12-factor-reviewer.git && cd 12-factor-reviewer && ./bin/twelve-factor-reviewer .
```

## Common Commands

### Basic Assessment
```bash
# Current directory
twelve-factor-reviewer

# Specific project
twelve-factor-reviewer /path/to/project

# With verbose output
twelve-factor-reviewer . --verbose
```

### Output Formats
```bash
# Terminal (default)
twelve-factor-reviewer .

# JSON
twelve-factor-reviewer . -f json > report.json

# Markdown
twelve-factor-reviewer . -f markdown > report.md
```

### CI/CD Integration
```bash
# Strict mode (fail if <80%)
twelve-factor-reviewer . --strict

# With remediation suggestions
twelve-factor-reviewer . --remediate

# Combined for CI
twelve-factor-reviewer . --strict -f json > compliance.json || exit 1
```

## Options Quick Reference

| Short | Long | Description |
|-------|------|-------------|
| `-h` | `--help` | Show help |
| `-v` | `--verbose` | Detailed output |
| `-f` | `--format` | Output format (terminal/json/markdown) |
| `-d` | `--depth` | Search depth (1-10) |
| | `--strict` | Fail if <80% compliance |
| | `--remediate` | Show fix suggestions |

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success / Compliant |
| `1` | Error / Non-compliant (strict mode) |
| `2` | Invalid arguments |
| `3` | Directory not found |

## The 12 Factors (Quick List)

1. **Codebase** - One repo, many deploys
2. **Dependencies** - Explicitly declared
3. **Config** - Environment variables
4. **Backing Services** - Attached resources
5. **Build/Release/Run** - Separate stages
6. **Processes** - Stateless execution
7. **Port Binding** - Self-contained services
8. **Concurrency** - Scale via processes
9. **Disposability** - Fast startup/shutdown
10. **Dev/Prod Parity** - Similar environments
11. **Logs** - Event streams
12. **Admin Processes** - One-off tasks

## Score Interpretation

### Per Factor (0-10)
- `9-10` ✅ Excellent
- `7-8` ✅ Good
- `5-6` ⚠️ Fair
- `0-4` ❌ Poor

### Overall Grade
- `90-100%` = A+ (Excellent)
- `80-89%` = A (Very Good)
- `70-79%` = B (Good)
- `60-69%` = C (Fair)
- `50-59%` = D (Poor)
- `<50%` = F (Needs Work)

## Testing

```bash
# Run all tests
./tests/test-quick-validation.sh

# Run with coverage
./scripts/coverage-analysis.sh

# Individual test suites
./tests/test-core-assessment.sh
./tests/test-strict-mode.sh
./tests/test-edge-cases.sh
```

## Docker Usage

```bash
# Build image
docker build -t 12factor-reviewer .

# Run assessment
docker run -v $(pwd):/project 12factor-reviewer

# With options
docker run -v $(pwd):/project 12factor-reviewer --strict -f json
```

## Environment Variables

```bash
export VERBOSE=true           # Enable verbose by default
export REPORT_FORMAT=json     # Default output format
export CHECK_DEPTH=5          # Default search depth
export STRICT_MODE=true       # Enable strict by default
```

## Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| Permission denied | `chmod +x bin/twelve-factor-reviewer` |
| Command not found | Add to PATH: `export PATH="$PATH:$(pwd)/bin"` |
| Incomplete assessment | Increase depth: `--depth 5` |
| Tests timeout | Use quick test: `./tests/test-quick-validation.sh` |

## Project Structure

```
12-factor-reviewer/
├── bin/
│   └── twelve-factor-reviewer    # Main CLI
├── src/
│   └── twelve-factor-assessment.sh  # Core logic
├── tests/                        # 9 test suites
├── scripts/                       # Utilities
├── docs/                          # Documentation
└── coverage/                      # Coverage reports
```

## Links

- 📖 [Full Documentation](../README.md)
- 🐛 [Report Issues](https://github.com/phdsystems/12-factor-reviewer/issues)
- 💬 [Discussions](https://github.com/phdsystems/12-factor-reviewer/discussions)
- 📧 [Contact](mailto:phdsystemz@gmail.com)