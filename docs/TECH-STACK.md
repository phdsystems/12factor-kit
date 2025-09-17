# Tech Stack

## Core Technologies

### Language & Runtime
- **Bash 5.0+** - Primary implementation language
  - POSIX-compliant shell scripting
  - Cross-platform compatibility (Linux, macOS)
  - Built-in string manipulation and process management

### Code Quality & Linting
- **ShellCheck v0.8.0** - Static analysis tool for shell scripts
  - Detects common mistakes and potential bugs
  - Enforces best practices
  - Current status: 0 errors, 28 warnings (mostly style)

### Testing Framework
- **Custom Bash Testing Framework**
  - 9 comprehensive test suites with 200+ test cases
  - Unit, integration, and end-to-end testing
  - Performance benchmarking
  - 100% test passing rate

### Code Coverage
- **Bashcov 3.2.0** - Bash code coverage analysis
  - Ruby-based SimpleCov integration
  - 71% line coverage across codebase
  - HTML and JSON coverage reports
  - CI/CD integration support

### Containerization
- **Docker** - For portable deployment
  - Alpine Linux 3.19 base image (minimal footprint)
  - Multi-stage build support
  - Volume mounting for project assessment

### Version Control & CI/CD
- **Git** - Version control
- **GitHub Actions** - CI/CD support (examples provided)
- **GitLab CI** - Alternative CI/CD support

## Detection Capabilities

The tool can detect and analyze projects using:

### Programming Languages
- Node.js/JavaScript
- Python
- Go
- Ruby
- Java
- Rust
- PHP
- .NET/C#

### Package Managers
- npm/yarn (Node.js)
- pip/pipenv/poetry (Python)
- go mod (Go)
- bundler (Ruby)
- maven/gradle (Java)
- cargo (Rust)
- composer (PHP)
- nuget (.NET)

### Container Technologies
- Docker
- Docker Compose
- Kubernetes manifests

### CI/CD Platforms
- GitHub Actions
- GitLab CI
- Jenkins
- CircleCI

## Development Tools

### Build System
- **Make** - Task automation
- **npm scripts** - JavaScript tooling integration

### Documentation
- **Markdown** - All documentation
- **JSDoc** comments - Code documentation

### Error Handling
- `set -euo pipefail` - Strict error handling
- Exit codes for CI/CD integration
- Comprehensive error messages

## System Requirements

### Minimum Requirements
- Bash 4.0+ (5.0+ recommended)
- Git 2.0+
- 50MB disk space
- POSIX-compliant shell environment

### Optional Dependencies
- **Docker** (for containerized usage)
- **Node.js 14+** (for npm package usage)
- **Python 3.6+** (for Python project detection)
- **Ruby 3.0+** (for bashcov coverage analysis)
- **Make** (for Makefile usage)

## Test Suite Architecture

### Core Test Files
- `test-core-assessment.sh` - Main functionality testing (46 tests)
- `test-input-validation.sh` - Input validation and error handling (15+ tests)
- `test-help-and-verbose.sh` - Help function and verbose mode (10+ tests)
- `test-output-formats.sh` - JSON/Markdown/Terminal output (25+ tests)
- `test-strict-mode.sh` - Strict mode and compliance enforcement (14 tests)
- `test-assessment-paths.sh` - Assessment logic paths (30+ tests)
- `test-terminal-output.sh` - Terminal report formatting (25+ tests)
- `test-remediation.sh` - Remediation suggestions (20+ tests)
- `test-edge-cases.sh` - Edge cases and error scenarios (17 tests)

### Coverage Analysis
- **Coverage Scripts**: `coverage-analysis.sh`, `coverage-summary.sh`
- **Report Generation**: HTML and JSON formats
- **CI Integration**: Automated coverage reporting
- **Threshold Monitoring**: Coverage trend tracking

## CLI Interface

### Primary Command
- `twelve-factor-reviewer` - Main CLI entry point (renamed from `12factor-assess`)
- Backward compatibility maintained via package.json bin mappings

### Command Structure
```bash
twelve-factor-reviewer [PROJECT_PATH] [OPTIONS]
```

### Supported Output Formats
- **Terminal** - Colorized interactive output
- **JSON** - Machine-readable structured data
- **Markdown** - Documentation-friendly reports