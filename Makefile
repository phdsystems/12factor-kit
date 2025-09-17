# 12-Factor Assessment Tool - Makefile

.PHONY: help install uninstall test assess docker-build docker-run clean

# Default target
help:
	@echo "12-Factor Assessment Tool - Available Commands"
	@echo "=============================================="
	@echo ""
	@echo "Installation:"
	@echo "  make install        Install tool locally (~/.local/bin)"
	@echo "  make install-system Install system-wide (requires sudo)"
	@echo "  make uninstall      Uninstall the tool"
	@echo ""
	@echo "Usage:"
	@echo "  make assess         Run assessment on current directory"
	@echo "  make assess-json    Generate JSON report"
	@echo "  make assess-md      Generate Markdown report"
	@echo ""
	@echo "Testing:"
	@echo "  make test           Run test suite"
	@echo "  make test-verbose   Run tests with verbose output"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-build   Build Docker image"
	@echo "  make docker-run     Run assessment in Docker"
	@echo ""
	@echo "Development:"
	@echo "  make clean          Clean generated files"
	@echo "  make check          Check tool integrity"

# Installation targets
install:
	@echo "Installing 12-Factor Assessment Tool locally..."
	@./install.sh --local

install-system:
	@echo "Installing 12-Factor Assessment Tool system-wide..."
	@sudo ./install.sh

uninstall:
	@echo "Uninstalling 12-Factor Assessment Tool..."
	@./install.sh --uninstall --local

# Assessment targets
assess:
	@./bin/twelve-factor-reviewer .

assess-json:
	@./bin/twelve-factor-reviewer . -f json

assess-md:
	@./bin/twelve-factor-reviewer . -f markdown > assessment-report.md
	@echo "Report saved to assessment-report.md"

# Testing targets
test:
	@echo "Running test suite..."
	@./tests/test-core-assessment.sh

test-verbose:
	@echo "Running test suite with verbose output..."
	@VERBOSE=true ./tests/test-core-assessment.sh

# Docker targets
docker-build:
	@echo "Building Docker image..."
	@docker build -t 12factor-assess .

docker-run:
	@echo "Running assessment in Docker..."
	@docker run -v $(PWD):/project 12factor-assess

# Development targets
clean:
	@echo "Cleaning generated files..."
	@rm -f assessment-report.md
	@rm -f compliance.json
	@rm -rf test-output/

check:
	@echo "Checking tool integrity..."
	@test -f bin/twelve-factor-reviewer || (echo "Error: Main script not found" && exit 1)
	@test -f tests/test-core-assessment.sh || (echo "Error: Test script not found" && exit 1)
	@test -x bin/twelve-factor-reviewer || (echo "Error: Main script not executable" && exit 1)
	@test -x tests/test-core-assessment.sh || (echo "Error: Test script not executable" && exit 1)
	@echo "✓ Tool integrity check passed"

# Project-specific assessments
assess-project:
	@./bin/twelve-factor-reviewer ../..

assess-dockerkit:
	@./bin/twelve-factor-reviewer ../../src

# CI/CD targets
ci: check test
	@echo "CI checks completed successfully"

ci-strict: check
	@./bin/twelve-factor-reviewer . --strict
	@./tests/test-core-assessment.sh