#!/bin/bash

# ==============================================================================
# 12-Factor Assessment Tool - Color Definitions
# ==============================================================================
# Shared color definitions for consistent output formatting
# ==============================================================================

set -euo pipefail

# Color codes
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export MAGENTA='\033[0;35m'
export BOLD='\033[1m'
export DIM='\033[2m'
export CLEAR='\033[2J'
export HOME='\033[H'
export NC='\033[0m' # No Color

# Status symbols
export SYMBOL_SUCCESS="✅"
export SYMBOL_WARNING="⚠️"
export SYMBOL_ERROR="❌"
export SYMBOL_INFO="ℹ️"
export SYMBOL_CHECK="✓"
export SYMBOL_CROSS="✗"

# Functions for colored output
print_success() {
    echo -e "${GREEN}${SYMBOL_SUCCESS} $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${SYMBOL_WARNING} $1${NC}"
}

print_error() {
    echo -e "${RED}${SYMBOL_ERROR} $1${NC}"
}

print_info() {
    echo -e "${CYAN}${SYMBOL_INFO} $1${NC}"
}

print_bold() {
    echo -e "${BOLD}$1${NC}"
}

print_section() {
    echo -e "\n${BOLD}$1${NC}"
    echo -e "${BOLD}$(printf '=%.0s' {1..60})${NC}"
}