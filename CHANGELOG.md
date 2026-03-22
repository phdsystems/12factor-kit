# Changelog

All notable changes to the 12-Factor Reviewer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive test suite expansion from 6 to 9 test suites
- New test files for edge cases, terminal output, and remediation
- Code coverage analysis using bashcov 3.2.0
- Detailed remediation suggestions for all 12 factors
- Terminal progress bar visualization
- Support for monorepo and workspace detection
- Enhanced error handling for edge cases

### Changed
- Test coverage increased from 66% to 71%
- Main script coverage improved from 57% to 79%
- CLI wrapper coverage improved from 31% to 71%
- Fixed strict mode test hanging issue
- Updated all documentation for consistency

### Fixed
- Strict mode tests now properly handle timeouts
- Edge case handling for circular symlinks
- Permission error graceful handling
- Unicode content processing

## [2.0.0] - 2024-01-17

### Added
- Complete rewrite of assessment engine
- Support for 8+ programming languages
- JSON and Markdown output formats
- CI/CD integration with strict mode
- Docker containerization support
- Comprehensive test suite (200+ tests)

### Changed
- Renamed CLI from `12factor-assess` to `twelve-factor-reviewer`
- Improved scoring algorithm accuracy
- Enhanced remediation suggestions
- Better framework detection

### Removed
- Legacy Python implementation
- Deprecated configuration options

## [1.0.0] - 2023-12-01

### Added
- Initial release
- Basic 12-factor assessment
- Terminal output only
- Support for Node.js and Python projects
- Basic scoring system

## Notes

### Version 2.1.0 (Upcoming)
- Planning GraphQL API support
- Web dashboard for reports
- Historical trend analysis
- Team collaboration features

### Version 2.0.1 (Next Patch)
- Performance optimizations
- Additional language support
- Enhanced CI/CD templates

---

For detailed commit history, see the [Git log](https://github.com/phdsystems/12factor-kit/commits/main).