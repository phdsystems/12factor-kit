# 12-Factor Assessment Tool - Architecture

## Overview

The 12-Factor Assessment Tool is designed as a modular, extensible system for evaluating software projects against the 12-Factor App methodology principles.

## Directory Structure

```
12factor-assess/
├── src/                           # Source code
│   ├── twelve-factor-assessment.sh  # Main assessment engine
│   └── lib/                      # Shared libraries
│       ├── colors.sh            # Color definitions and output formatting
│       └── utils.sh             # Utility functions
├── bin/                          # Executable wrappers
│   └── 12factor-assess          # CLI entry point
├── tests/                        # Test suite
│   ├── test-core-assessment.sh  # Main test suite
│   ├── test-input-validation.sh # Input validation tests
│   ├── test-edge-cases.sh       # Edge case tests
│   ├── test-error-handling.sh   # Error handling tests
│   ├── test-quick-validation.sh # Quick validation tests
│   └── run-comprehensive-tests.sh # Complete test runner
├── docs/                  # Documentation
│   ├── ARCHITECTURE.md    # This file
│   ├── CONTRIBUTING.md    # Contribution guidelines
│   └── API.md            # API documentation
├── config/               # Configuration files
├── scripts/                     # Helper scripts
│   ├── batch-assessment.sh      # Batch processing
│   ├── coverage-analysis.sh     # Coverage analysis (kcov)
│   ├── coverage-analysis-bashcov.sh  # Coverage analysis (bashcov)
│   ├── coverage-analysis-simple.sh   # Simple coverage analysis
│   ├── coverage-summary.sh      # Coverage report display
│   └── test-runner.sh           # Test execution
├── examples/             # Usage examples
└── lib/                  # External libraries

```

## Components

### 1. Core Assessment Engine (`src/twelve-factor-assessment.sh`)

The main assessment logic that:
- Analyzes project structure
- Evaluates each of the 12 factors
- Calculates scores
- Generates reports

#### Key Functions:
- `assess_factor_*()` - Individual factor assessment functions
- `generate_*_report()` - Report generation in various formats
- `calculate_score()` - Scoring logic

### 2. Libraries (`src/lib/`)

#### colors.sh
- Color code definitions
- Output formatting functions
- Status symbols

#### utils.sh
- File system operations
- Project detection utilities
- Common helper functions

### 3. CLI Wrapper (`bin/12factor-assess`)

A lightweight wrapper that:
- Validates environment
- Locates the main script
- Passes arguments through

### 4. Test Suite (`tests/`)

Comprehensive testing including:
- Unit tests for each factor
- Integration tests
- Performance benchmarks
- Mock project generators

## Data Flow

```
User Input → CLI Wrapper → Assessment Engine → Factor Evaluators
                                              ↓
                                          Scoring System
                                              ↓
                                         Report Generator
                                              ↓
                                         Output (Terminal/JSON/MD)
```

## Assessment Process

1. **Initialization**
   - Parse command-line arguments
   - Validate project directory
   - Set configuration options

2. **Project Analysis**
   - Detect project type
   - Identify technology stack
   - Scan for configuration files

3. **Factor Assessment**
   - Execute 12 individual factor assessments
   - Each factor scores 0-10 points
   - Collect detailed findings

4. **Score Calculation**
   - Sum individual scores
   - Calculate percentage
   - Determine compliance grade

5. **Report Generation**
   - Format findings based on output type
   - Include remediation suggestions
   - Generate final report

## Scoring System

### Score Ranges
- 0-3: Poor compliance
- 4-6: Fair compliance
- 7-8: Good compliance
- 9-10: Excellent compliance

### Grade Calculation
- A+ (90-100%): Excellent 12-Factor Compliance
- A (80-89%): Very Good Compliance
- B (70-79%): Good Compliance
- C (60-69%): Fair Compliance
- D (50-59%): Poor Compliance
- F (<50%): Needs Significant Improvement

## Extensibility

### Adding New Factors

To add a new assessment factor:

1. Create assessment function in main script:
```bash
assess_factor_new() {
    local score=0
    local details=""
    local remediation=""
    
    # Assessment logic here
    
    FACTOR_SCORES[13]=$score
    FACTOR_DETAILS[13]="$details"
    REMEDIATION_SUGGESTIONS[13]="$remediation"
}
```

2. Update the assessment loop
3. Add to report generation

### Adding Language Support

To support a new programming language:

1. Add detection logic in `detect_project_type()`
2. Add dependency file checks in Factor II
3. Add language-specific patterns throughout

## Performance Considerations

- Uses `find` with `-maxdepth` to limit directory traversal
- Employs early exit strategies for efficiency
- Caches detection results when possible
- Targets < 5 second execution time

## Security Considerations

- No external network calls
- Read-only operations on project files
- Safe string handling for JSON output
- Proper input validation

## Future Enhancements

1. **Plugin System**
   - Allow custom factor definitions
   - Support for organization-specific rules

2. **Caching**
   - Cache assessment results
   - Track improvements over time

3. **Reporting**
   - HTML report generation
   - Trend analysis
   - Comparative assessments

4. **Integration**
   - IDE plugins
   - Git hooks
   - CI/CD templates