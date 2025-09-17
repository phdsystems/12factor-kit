# Contributing to 12-Factor Assessment Tool

Thank you for your interest in contributing to the 12-Factor Assessment Tool! This document provides guidelines and instructions for contributing.

## Code of Conduct

Please be respectful and constructive in all interactions. We aim to maintain a welcoming and inclusive environment for all contributors.

## How to Contribute

### Reporting Issues

1. Check if the issue already exists
2. Create a new issue with:
   - Clear title and description
   - Steps to reproduce (if applicable)
   - Expected vs actual behavior
   - Environment details (OS, shell version)

### Suggesting Enhancements

1. Open an issue with the "enhancement" label
2. Describe the feature and its benefits
3. Provide use cases and examples

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Add/update tests as needed
5. Update documentation
6. Commit with clear messages
7. Push to your fork
8. Open a pull request

## Development Setup

### Prerequisites

- Bash 4.0+
- Git
- Standard Unix tools (grep, find, sed, awk)

### Setting Up Development Environment

```bash
# Clone the repository
git clone <repository-url>
cd packages/12factor-assess

# Make scripts executable
chmod +x bin/12factor-assess
chmod +x src/12factor-assess.sh
chmod +x tests/*.sh

# Run tests to verify setup
./tests/test_12factor_assessment.sh
```

## Development Guidelines

### Code Style

#### Shell Script Standards

- Use `#!/bin/bash` shebang
- Set `set -euo pipefail` for error handling
- Use meaningful variable names
- Add comments for complex logic
- Follow existing indentation (2 spaces)

#### Variable Naming

- Use UPPERCASE for constants
- Use lowercase for local variables
- Use descriptive names

Example:
```bash
# Good
PROJECT_PATH="/path/to/project"
local file_count=0

# Avoid
P="/path/to/project"
local fc=0
```

#### Function Naming

- Use lowercase with underscores
- Start with verb for actions
- Be descriptive

Example:
```bash
# Good
assess_factor_codebase()
calculate_total_score()

# Avoid
factor1()
calc()
```

### Testing

#### Running Tests

```bash
# Run all tests
./tests/test_12factor_assessment.sh

# Run with verbose output
VERBOSE=true ./tests/test_12factor_assessment.sh
```

#### Writing Tests

All new features should include tests:

```bash
test_new_feature() {
    run_test "New feature description"
    
    # Setup
    local test_dir="$TEST_TEMP_DIR/new_feature"
    create_test_project "$test_dir"
    
    # Execute
    local output
    output=$("$TOOL_PATH" "$test_dir" 2>&1)
    
    # Assert
    assert_contains "$output" "expected text" "Feature works correctly"
}
```

### Documentation

#### Update Documentation For:

1. New features
2. Changed behavior
3. New dependencies
4. Configuration changes

#### Documentation Locations:

- `README.md` - User-facing documentation
- `docs/ARCHITECTURE.md` - Technical design
- `docs/API.md` - Function/API reference
- `docs/CONTRIBUTING.md` - This file
- Inline comments - Code explanations

### Commit Messages

Follow conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Test additions/changes
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `chore`: Maintenance tasks

Example:
```
feat(assessment): add support for Rust projects

- Add Rust dependency detection (Cargo.toml)
- Update Factor II assessment
- Add Rust-specific patterns

Closes #123
```

## Testing Checklist

Before submitting a PR, ensure:

- [ ] All existing tests pass
- [ ] New tests added for new features
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Commit messages are clear
- [ ] PR description explains changes

## Release Process

1. Update version in `package.json`
2. Update CHANGELOG.md
3. Run full test suite
4. Tag release: `git tag -a v1.x.x -m "Release version 1.x.x"`
5. Push tags: `git push origin --tags`

## Project Structure

```
src/
├── 12factor-assess.sh     # Main assessment logic
└── lib/
    ├── colors.sh          # Output formatting
    └── utils.sh           # Utility functions

tests/
└── test_12factor_assessment.sh  # Test suite

docs/
├── ARCHITECTURE.md        # Technical design
├── CONTRIBUTING.md        # Contribution guide
└── API.md                # API documentation
```

## Getting Help

- Open an issue for questions
- Review existing documentation
- Check closed issues for solutions

## Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- Release notes
- Project documentation

Thank you for contributing to make 12-Factor Assessment Tool better!