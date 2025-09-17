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
  - 46 comprehensive test cases
  - Unit and integration testing
  - Performance benchmarking
  - 100% test passing rate

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
- Docker (for containerized usage)
- Node.js 14+ (for npm package usage)
- Python 3.6+ (for Python project detection)
- Make (for Makefile usage)