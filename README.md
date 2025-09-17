# 12-Factor Reviewer

A comprehensive, language-agnostic tool for reviewing and assessing 12-Factor App compliance in any software project.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash 5.0+](https://img.shields.io/badge/bash-5.0%2B-blue)](https://www.gnu.org/software/bash/)
[![Tests Passing](https://img.shields.io/badge/tests-46%20passing-brightgreen)](./tests)

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
./bin/12factor-assess /path/to/project
```

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [Installation Guide](docs/INSTALLATION.md) | Multiple installation methods |
| [Usage Guide](docs/USAGE.md) | Commands, options, and examples |
| [CI/CD Integration](docs/CI-CD-INTEGRATION.md) | GitHub Actions, GitLab, Jenkins setup |
| [Tech Stack](docs/TECH-STACK.md) | Technologies and requirements |
| [API Reference](docs/API.md) | Detailed API documentation |
| [Architecture](docs/ARCHITECTURE.md) | System design and internals |
| [Contributing](docs/CONTRIBUTING.md) | How to contribute |

## ✨ Key Features

- ✅ Assesses all 12 factors with actionable feedback
- ✅ Detects 8+ languages and frameworks automatically
- ✅ Provides remediation suggestions
- ✅ Integrates with CI/CD pipelines
- ✅ Docker support included
- ✅ 100% test coverage (46 tests passing)

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
12factor-assess

# Generate JSON report
12factor-assess . -f json > report.json

# CI/CD mode (fail if <80% compliance)
12factor-assess . --strict
```

See [Usage Guide](docs/USAGE.md) for more examples.

## 🔧 Requirements

- Bash 4.0+ (5.0+ recommended)
- Git 2.0+
- 50MB disk space

See [Tech Stack](docs/TECH-STACK.md) for details.

## 🤝 Contributing

Contributions welcome! Please see our [Contributing Guide](docs/CONTRIBUTING.md).

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Based on the [12-Factor App](https://12factor.net/) methodology by Heroku
- Originally developed as part of the PHD-ADE project

## 📞 Support

- 🐛 [Report Issues](https://github.com/phdsystems/12-factor-reviewer/issues)
- 💬 [Discussions](https://github.com/phdsystems/12-factor-reviewer/discussions)
- 📧 Contact: phdsystemz@gmail.com