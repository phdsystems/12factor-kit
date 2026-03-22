# 12-Factor Reviewer

A comprehensive, language-agnostic tool for reviewing and assessing 12-Factor App compliance in any software project.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash 5.0+](https://img.shields.io/badge/bash-5.0%2B-blue)](https://www.gnu.org/software/bash/)
[![Tests Passing](https://img.shields.io/badge/tests-9%20suites%20passing-brightgreen)](./tests)
[![Coverage](https://img.shields.io/badge/coverage-71%25-yellow)](docs/5-testing/testing.md)

## 🎯 Overview

The 12-Factor Reviewer evaluates your project against the [12-Factor App](https://12factor.net/) methodology, providing:

- **Detailed scoring** (0-10 per factor, 120 total)
- **Multiple output formats** (Terminal, JSON, Markdown)
- **Language-agnostic analysis** (Works with any tech stack)
- **CI/CD ready** (Exit codes and strict mode)
- **Fast assessment** (<5 seconds)

## 🚀 Quick Start

```bash
# Clone and run
git clone https://github.com/phdsystems/12-factor-reviewer.git
cd 12-factor-reviewer
./bin/twelve-factor-reviewer /path/to/project
```

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [Quick Start](docs/quick_start.md) | Commands cheat sheet — start here |
| [Installation Guide](docs/4-development/installation.md) | Multiple installation methods |
| [Usage Guide](docs/4-development/usage.md) | Commands, options, and examples |
| [FAQ](docs/faq.md) | Frequently asked questions |
| [CI/CD Integration](docs/4-development/ci_cd_integration.md) | GitHub Actions, GitLab, Jenkins setup |
| [Tech Stack](docs/3-design/tech_stack.md) | Technologies and requirements |
| [API Reference](docs/3-design/api.md) | Detailed API documentation |
| [Architecture](docs/3-design/architecture.md) | System design and internals |
| [Contributing](docs/4-development/contributing.md) | How to contribute |
| [Testing](docs/5-testing/testing.md) | Test suite and coverage |

## ✨ Key Features

- ✅ Assesses all 12 factors with actionable feedback
- ✅ Detects 8+ languages and frameworks automatically
- ✅ Provides remediation suggestions
- ✅ Integrates with CI/CD pipelines
- ✅ Docker support included
- ✅ Comprehensive test suite (9 test suites, 71% coverage)
- ✅ Code coverage analysis with bashcov

## 📊 The 12 Factors

1. **Codebase** - One codebase tracked in revision control
2. **Dependencies** - Explicitly declare and isolate
3. **Config** - Store config in the environment
4. **Backing Services** - Treat as attached resources
5. **Build, Release, Run** - Strictly separate stages
6. **Processes** - Execute as stateless processes
7. **Port Binding** - Export services via port binding
8. **Concurrency** - Scale out via the process model
9. **Disposability** - Fast startup and graceful shutdown
10. **Dev/Prod Parity** - Keep environments similar
11. **Logs** - Treat logs as event streams
12. **Admin Processes** - Run admin tasks as one-off processes

## 💻 Basic Usage

```bash
# Assess current directory
twelve-factor-reviewer

# Generate JSON report
twelve-factor-reviewer . -f json > report.json

# Generate Markdown report
twelve-factor-reviewer . -f markdown > report.md

# CI/CD mode (fail if <80% compliance)
twelve-factor-reviewer . --strict

# Verbose output with remediation
twelve-factor-reviewer . --verbose --remediate
```

See [Usage Guide](docs/4-development/usage.md) for more examples.

## 🔧 Requirements

- Bash 4.0+ (5.0+ recommended)
- Git 2.0+
- 50MB disk space

See [Tech Stack](docs/3-design/tech_stack.md) for details.

## 🤝 Contributing

Contributions welcome! Please see our [Contributing Guide](docs/4-development/contributing.md).

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

## 📁 Examples

Check out the [examples](examples/) directory for:
- Sample terminal output
- JSON report structure
- Markdown report format
- GitHub Actions workflow
- CI/CD integration examples

## 🙏 Acknowledgments

- Based on the [12-Factor App](https://12factor.net/) methodology by Heroku
- Originally developed as part of the PHD-ADE project
- Test coverage powered by [bashcov](https://github.com/infertux/bashcov)

## 📞 Support

- 🐛 [Report Issues](https://github.com/phdsystems/12-factor-reviewer/issues)
- 💬 [Discussions](https://github.com/phdsystems/12-factor-reviewer/discussions)
- 📧 Contact: phdsystemz@gmail.com
- 📖 [FAQ](docs/faq.md) - Frequently Asked Questions