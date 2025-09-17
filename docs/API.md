# 12-Factor Assessment Tool - API Documentation

## Command Line Interface

### Synopsis

```bash
12factor-assess [PROJECT_PATH] [OPTIONS]
```

### Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| PROJECT_PATH | Path to the project to assess | Current directory (.) |

### Options

| Option | Short | Description | Values |
|--------|-------|-------------|--------|
| --help | -h | Display help message | - |
| --verbose | -v | Enable verbose output | - |
| --format | -f | Output format | terminal, json, markdown |
| --depth | -d | Directory search depth | 1-10 (default: 3) |
| --strict | - | Fail if compliance < 80% | - |
| --remediate | - | Generate remediation suggestions | - |

### Exit Codes

| Code | Description |
|------|-------------|
| 0 | Success |
| 1 | General error or strict mode failure |
| 2 | Invalid arguments |
| 3 | Project directory not found |

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| VERBOSE | Enable verbose output | false |
| REPORT_FORMAT | Default output format | terminal |
| CHECK_DEPTH | Default search depth | 3 |
| STRICT_MODE | Enable strict mode | false |

## Output Formats

### Terminal Output

Default human-readable format with colors and formatting.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        12-FACTOR COMPLIANCE REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Overall Score: ✅ Excellent (95/120)
Compliance: 79%
[███████████████░░░░░]

Factor Breakdown:
  1. Codebase         ✅ Excellent (10/10)
  2. Dependencies     ✅ Excellent (9/10)
  ...
```

### JSON Output

Machine-readable JSON format for automation.

```json
{
  "timestamp": "2024-01-01T00:00:00Z",
  "project_path": "/path/to/project",
  "total_score": 95,
  "max_score": 120,
  "percentage": 79,
  "factors": [
    {
      "number": 1,
      "name": "codebase",
      "score": 10,
      "max_score": 10,
      "details": "Git repository found...",
      "remediation": ""
    }
  ]
}
```

### Markdown Output

Documentation-friendly Markdown format.

```markdown
# 12-Factor App Compliance Report

**Date:** 2024-01-01 00:00:00 UTC
**Project:** /path/to/project
**Overall Score:** 95/120 (79%)

## Executive Summary
...
```

## Core Functions

### Main Assessment Functions

#### `assess_factor_1_codebase()`
Evaluates Factor I: Codebase
- Checks for version control (Git)
- Validates single codebase
- Detects monorepo structures

**Scoring:**
- Git repository: +5 points
- Single remote: +3 points
- Monorepo setup: +2 points

#### `assess_factor_2_dependencies()`
Evaluates Factor II: Dependencies
- Detects dependency declaration files
- Checks for lock files
- Identifies vendoring

**Supported Files:**
- Node.js: package.json, package-lock.json
- Python: requirements.txt, Pipfile, pyproject.toml
- Go: go.mod, go.sum
- Ruby: Gemfile, Gemfile.lock
- Java: pom.xml, build.gradle
- Rust: Cargo.toml, Cargo.lock
- PHP: composer.json, composer.lock
- .NET: *.csproj, packages.config

#### `assess_factor_3_config()`
Evaluates Factor III: Configuration
- Checks for environment templates
- Detects hardcoded values
- Validates secret management

#### `assess_factor_4_backing_services()`
Evaluates Factor IV: Backing Services
- Checks service configuration
- Validates environment-based URLs
- Detects service dependencies

#### `assess_factor_5_build_release_run()`
Evaluates Factor V: Build, Release, Run
- Checks CI/CD configurations
- Validates build scripts
- Detects multi-stage Docker builds

#### `assess_factor_6_processes()`
Evaluates Factor VI: Processes
- Checks for stateless design
- Detects local state storage
- Validates process management

#### `assess_factor_7_port_binding()`
Evaluates Factor VII: Port Binding
- Checks port configuration
- Detects web frameworks
- Validates Docker EXPOSE

#### `assess_factor_8_concurrency()`
Evaluates Factor VIII: Concurrency
- Checks orchestration configs
- Validates scaling settings
- Detects worker processes

#### `assess_factor_9_disposability()`
Evaluates Factor IX: Disposability
- Checks signal handling
- Validates health checks
- Detects connection pooling

#### `assess_factor_10_dev_prod_parity()`
Evaluates Factor X: Dev/Prod Parity
- Checks containerization
- Validates environment configs
- Detects environment-specific files

#### `assess_factor_11_logs()`
Evaluates Factor XI: Logs
- Checks logging implementation
- Validates stream-based logging
- Detects structured logging

#### `assess_factor_12_admin_processes()`
Evaluates Factor XII: Admin Processes
- Checks for migrations
- Validates script directories
- Detects task runners

### Utility Functions

#### `detect_project_type()`
Identifies the project's technology stack.

**Parameters:**
- `path`: Project directory path

**Returns:**
Array of detected project types

#### `calculate_score()`
Calculates and formats score display.

**Parameters:**
- `score`: Current score
- `max_score`: Maximum possible score

**Returns:**
Formatted score string with color

#### `generate_terminal_report()`
Generates human-readable terminal output.

#### `generate_json_report()`
Generates JSON-formatted output.

#### `generate_markdown_report()`
Generates Markdown-formatted documentation.

## Library Functions

### colors.sh

#### `print_success(message)`
Print success message with green color and ✅ symbol

#### `print_warning(message)`
Print warning message with yellow color and ⚠️ symbol

#### `print_error(message)`
Print error message with red color and ❌ symbol

#### `print_info(message)`
Print info message with cyan color and ℹ️ symbol

#### `print_bold(message)`
Print message in bold

#### `print_section(title)`
Print section header with separator

### utils.sh

#### `command_exists(command)`
Check if a command is available

#### `file_readable(file)`
Check if file exists and is readable

#### `dir_accessible(directory)`
Check if directory exists and is accessible

#### `safe_grep(pattern, file)`
Safely grep with error handling

#### `find_files(path, pattern, depth)`
Find files matching pattern

#### `count_files(path, pattern)`
Count files matching pattern

#### `calculate_percentage(score, max)`
Calculate percentage value

#### `detect_primary_language(path)`
Detect primary programming language

#### `has_cicd(path)`
Check for CI/CD configuration

#### `json_escape(string)`
Escape string for JSON output

#### `get_timestamp()`
Get current ISO 8601 timestamp

## Integration Examples

### GitHub Actions

```yaml
- name: 12-Factor Assessment
  run: |
    packages/12factor-assess/bin/12factor-assess . --strict
```

### GitLab CI

```yaml
12factor-check:
  script:
    - ./12factor-assess . -f json > compliance.json
  artifacts:
    paths:
      - compliance.json
```

### Pre-commit Hook

```bash
#!/bin/bash
12factor-assess . --strict || {
    echo "Project does not meet 12-factor compliance"
    exit 1
}
```

### Docker

```bash
docker run -v $(pwd):/project 12factor-assess /project
```

## Extending the Tool

### Adding Custom Factors

1. Add assessment function:
```bash
assess_factor_custom() {
    local score=0
    # Assessment logic
    FACTOR_SCORES[13]=$score
}
```

2. Call from main:
```bash
assess_factor_custom
```

3. Update report generation

### Custom Output Formats

1. Create generator function:
```bash
generate_custom_report() {
    # Format output
}
```

2. Add to format switch:
```bash
case $REPORT_FORMAT in
    custom)
        generate_custom_report
        ;;
esac
```