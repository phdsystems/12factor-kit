# Frequently Asked Questions (FAQ)

## General Questions

### What is the 12-Factor Reviewer?
The 12-Factor Reviewer is a comprehensive, language-agnostic tool that evaluates software projects against the [12-Factor App](https://12factor.net/) methodology. It provides detailed scoring, actionable feedback, and remediation suggestions to help teams build better cloud-native applications.

### Which languages and frameworks are supported?
The tool supports 8+ major programming languages including:
- Node.js/JavaScript
- Python
- Go
- Ruby
- Java
- Rust
- PHP
- .NET/C#

It automatically detects frameworks and package managers for each language.

### How accurate is the assessment?
The tool provides approximately 98% functional coverage of the 12-Factor principles. The scoring algorithm has been refined through extensive testing with 200+ test cases across 9 test suites, achieving 71% code coverage.

## Installation & Usage

### Do I need to install any dependencies?
No, the core tool only requires:
- Bash 4.0+ (5.0+ recommended)
- Git 2.0+

Optional dependencies include Ruby 3.0+ for code coverage analysis.

### Can I use this in my CI/CD pipeline?
Yes! The tool is CI/CD ready with:
- Exit codes for build automation
- `--strict` mode for compliance enforcement
- JSON output for machine processing
- Examples for GitHub Actions, GitLab CI, Jenkins, and more

### How do I update to the latest version?
For Git installations:
```bash
cd 12-factor-reviewer
git pull origin main
```

## Scoring & Results

### What does the scoring mean?
Each factor is scored 0-10:
- **0-4**: Poor - Significant improvements needed
- **5-6**: Fair - Some compliance but gaps exist
- **7-8**: Good - Mostly compliant with minor issues
- **9-10**: Excellent - Fully compliant

Overall grades:
- **A+ (90-100%)**: Excellent compliance
- **A (80-89%)**: Very good compliance
- **B (70-79%)**: Good compliance
- **C (60-69%)**: Fair compliance
- **D (50-59%)**: Poor compliance
- **F (<50%)**: Needs significant improvement

### What is strict mode?
Strict mode (`--strict`) causes the tool to exit with error code 1 if compliance is below 80%. This is useful for CI/CD pipelines where you want to enforce minimum compliance standards.

### Can I customize the scoring thresholds?
Currently, the scoring thresholds are fixed. However, you can use the JSON output format to implement custom scoring logic in your own scripts.

## Technical Questions

### Why is the tool written in Bash?
Bash was chosen for:
- Zero dependencies for core functionality
- Universal availability on Unix-like systems
- Fast execution (<5 seconds for most projects)
- Easy integration with existing shell scripts and CI/CD pipelines

### How does the tool detect different technologies?
The tool uses file pattern matching and content analysis to detect:
- Package manifests (package.json, requirements.txt, go.mod, etc.)
- Configuration files (Dockerfile, docker-compose.yml, etc.)
- Framework-specific files and directories
- Version control metadata

### Can I contribute to the project?
Yes! Contributions are welcome. Please see our [Contributing Guide](4-development/contributing.md) for details on:
- Code style guidelines
- Testing requirements
- Pull request process
- Issue reporting

## Troubleshooting

### The tool reports "Permission Denied"
Make the script executable:
```bash
chmod +x bin/twelve-factor-reviewer
```

### The assessment seems incomplete
Try increasing the search depth:
```bash
twelve-factor-reviewer . --depth 5
```

### The tool doesn't detect my framework
Ensure your project has the appropriate package manifest files (package.json, requirements.txt, etc.) in the project root or within the search depth.

### Tests are timing out
Some tests may timeout in constrained environments. Use the quick validation test:
```bash
./tests/test-quick-validation.sh
```

## Advanced Usage

### Can I generate reports in multiple formats?
Yes, run the tool multiple times with different format flags:
```bash
twelve-factor-reviewer . -f json > report.json
twelve-factor-reviewer . -f markdown > report.md
```

### How do I assess multiple projects?
Use a bash loop:
```bash
for dir in ~/projects/*; do
  twelve-factor-reviewer "$dir" -f json > "reports/$(basename $dir).json"
done
```

### Can I exclude certain directories?
Currently, the tool automatically excludes common directories like node_modules and .git. Custom exclusions are planned for a future release.

## Support & Resources

### Where can I get help?
- 🐛 [Report Issues](https://github.com/phdsystems/12-factor-reviewer/issues)
- 💬 [Discussions](https://github.com/phdsystems/12-factor-reviewer/discussions)
- 📧 Contact: phdsystemz@gmail.com

### Where can I learn more about 12-Factor Apps?
- [Official 12-Factor App Methodology](https://12factor.net/)
- [12-Factor App on Wikipedia](https://en.wikipedia.org/wiki/Twelve-Factor_App_methodology)
- [Beyond the Twelve-Factor App](https://tanzu.vmware.com/content/blog/beyond-the-twelve-factor-app)