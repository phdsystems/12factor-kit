#!/bin/bash

# ==============================================================================
# 12-Factor Assessment Tool - Installation Script
# ==============================================================================
# Installs the 12-factor assessment tool system-wide or locally
# ==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
LOCAL_INSTALL="${LOCAL_INSTALL:-false}"
TOOL_NAME="twelve-factor-reviewer"

# ==============================================================================
# Functions
# ==============================================================================

show_help() {
    cat << EOF
${BOLD}12-Factor Assessment Tool - Installation Script${NC}

${BOLD}USAGE:${NC}
    $0 [OPTIONS]

${BOLD}OPTIONS:${NC}
    -h, --help              Show this help message
    -l, --local             Install to ~/.local/bin instead of system-wide
    -d, --dir DIR           Custom installation directory
    -u, --uninstall        Uninstall the tool
    --symlink              Create symlink instead of copying

${BOLD}EXAMPLES:${NC}
    # System-wide installation (requires sudo)
    sudo $0

    # Local user installation
    $0 --local

    # Custom directory
    $0 --dir /opt/tools

    # Uninstall
    sudo $0 --uninstall

EOF
}

check_dependencies() {
    local missing_deps=()
    
    # Check for required commands
    for cmd in bash grep find; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Missing required dependencies: ${missing_deps[*]}${NC}"
        exit 1
    fi
}

install_tool() {
    local source_file="${SCRIPT_DIR}/bin/twelve-factor-reviewer"
    local target_file="${INSTALL_DIR}/${TOOL_NAME}"
    
    # Check if source file exists
    if [[ ! -f "$source_file" ]]; then
        echo -e "${RED}Error: Source file not found: $source_file${NC}"
        exit 1
    fi
    
    # Create install directory if it doesn't exist
    if [[ ! -d "$INSTALL_DIR" ]]; then
        echo -e "${YELLOW}Creating directory: $INSTALL_DIR${NC}"
        if [[ "$LOCAL_INSTALL" == "true" ]] || [[ "$INSTALL_DIR" == "$HOME"* ]]; then
            mkdir -p "$INSTALL_DIR"
        else
            sudo mkdir -p "$INSTALL_DIR"
        fi
    fi
    
    # Check write permissions
    if [[ ! -w "$INSTALL_DIR" ]] && [[ "$LOCAL_INSTALL" == "false" ]]; then
        echo -e "${YELLOW}Note: Installation to $INSTALL_DIR requires sudo privileges${NC}"
        if [[ "$SYMLINK" == "true" ]]; then
            sudo ln -sf "$source_file" "$target_file"
        else
            sudo cp "$source_file" "$target_file"
            sudo chmod +x "$target_file"
        fi
    else
        if [[ "$SYMLINK" == "true" ]]; then
            ln -sf "$source_file" "$target_file"
        else
            cp "$source_file" "$target_file"
            chmod +x "$target_file"
        fi
    fi
    
    # Verify installation
    if [[ -f "$target_file" ]]; then
        echo -e "${GREEN}✓ Successfully installed to: $target_file${NC}"
        
        # Check if directory is in PATH
        if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
            echo -e "${YELLOW}Note: $INSTALL_DIR is not in your PATH${NC}"
            echo -e "${YELLOW}Add the following to your shell configuration:${NC}"
            echo -e "${CYAN}export PATH=\"\$PATH:$INSTALL_DIR\"${NC}"
        fi
        
        # Test the installation
        if command -v "$TOOL_NAME" &> /dev/null; then
            echo -e "${GREEN}✓ Tool is accessible via: $TOOL_NAME${NC}"
        else
            echo -e "${YELLOW}Tool installed but not in PATH yet${NC}"
        fi
    else
        echo -e "${RED}Error: Installation failed${NC}"
        exit 1
    fi
}

uninstall_tool() {
    local target_file="${INSTALL_DIR}/${TOOL_NAME}"
    
    if [[ -f "$target_file" ]] || [[ -L "$target_file" ]]; then
        if [[ -w "$INSTALL_DIR" ]]; then
            rm -f "$target_file"
        else
            sudo rm -f "$target_file"
        fi
        echo -e "${GREEN}✓ Successfully uninstalled from: $target_file${NC}"
    else
        echo -e "${YELLOW}Tool not found at: $target_file${NC}"
    fi
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    local action="install"
    SYMLINK="false"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -l|--local)
                LOCAL_INSTALL=true
                INSTALL_DIR="$HOME/.local/bin"
                shift
                ;;
            -d|--dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            -u|--uninstall)
                action="uninstall"
                shift
                ;;
            --symlink)
                SYMLINK=true
                shift
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Set local install directory if requested
    if [[ "$LOCAL_INSTALL" == "true" ]]; then
        INSTALL_DIR="$HOME/.local/bin"
    fi
    
    echo -e "${BOLD}12-Factor Assessment Tool Installer${NC}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check dependencies
    check_dependencies
    
    # Perform action
    case $action in
        install)
            echo -e "Installing to: ${CYAN}$INSTALL_DIR${NC}"
            install_tool
            ;;
        uninstall)
            echo -e "Uninstalling from: ${CYAN}$INSTALL_DIR${NC}"
            uninstall_tool
            ;;
    esac
    
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}Done!${NC}"
}

# Run main function
main "$@"