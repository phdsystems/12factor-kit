#!/bin/bash

# ==============================================================================
# 12-Factor Assessment Tool - Utility Functions
# ==============================================================================
# Common utility functions used throughout the assessment tool
# ==============================================================================

set -euo pipefail

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if a file exists and is readable
file_readable() {
    [[ -f "$1" ]] && [[ -r "$1" ]]
}

# Check if a directory exists and is accessible
dir_accessible() {
    [[ -d "$1" ]] && [[ -x "$1" ]]
}

# Safe grep with fallback
safe_grep() {
    local pattern="$1"
    local file="$2"
    
    if file_readable "$file"; then
        grep -q "$pattern" "$file" 2>/dev/null
        return $?
    else
        return 1
    fi
}

# Find files with pattern
find_files() {
    local path="$1"
    local pattern="$2"
    local max_depth="${3:-3}"
    
    find "$path" -maxdepth "$max_depth" -type f -name "$pattern" 2>/dev/null
}

# Count matching files
count_files() {
    local path="$1"
    local pattern="$2"
    
    find_files "$path" "$pattern" | wc -l
}

# Calculate percentage
calculate_percentage() {
    local score="$1"
    local max="$2"
    
    if [[ "$max" -eq 0 ]]; then
        echo "0"
    else
        echo "$((score * 100 / max))"
    fi
}

# Get project size
get_project_size() {
    local path="$1"
    
    if dir_accessible "$path"; then
        du -sh "$path" 2>/dev/null | cut -f1
    else
        echo "unknown"
    fi
}

# Get file count
get_file_count() {
    local path="$1"
    
    if dir_accessible "$path"; then
        find "$path" -type f 2>/dev/null | wc -l
    else
        echo "0"
    fi
}

# Detect primary language
detect_primary_language() {
    local path="$1"
    local languages=()
    
    # Count files by extension
    local js_count=$(count_files "$path" "*.js")
    local py_count=$(count_files "$path" "*.py")
    local go_count=$(count_files "$path" "*.go")
    local rb_count=$(count_files "$path" "*.rb")
    local java_count=$(count_files "$path" "*.java")
    local rs_count=$(count_files "$path" "*.rs")
    local php_count=$(count_files "$path" "*.php")
    local cs_count=$(count_files "$path" "*.cs")
    
    # Determine primary language
    local max_count=0
    local primary_lang="unknown"
    
    [[ $js_count -gt $max_count ]] && max_count=$js_count && primary_lang="JavaScript"
    [[ $py_count -gt $max_count ]] && max_count=$py_count && primary_lang="Python"
    [[ $go_count -gt $max_count ]] && max_count=$go_count && primary_lang="Go"
    [[ $rb_count -gt $max_count ]] && max_count=$rb_count && primary_lang="Ruby"
    [[ $java_count -gt $max_count ]] && max_count=$java_count && primary_lang="Java"
    [[ $rs_count -gt $max_count ]] && max_count=$rs_count && primary_lang="Rust"
    [[ $php_count -gt $max_count ]] && max_count=$php_count && primary_lang="PHP"
    [[ $cs_count -gt $max_count ]] && max_count=$cs_count && primary_lang="C#"
    
    echo "$primary_lang"
}

# Check for CI/CD
has_cicd() {
    local path="$1"
    
    # Check for various CI/CD configurations
    [[ -d "$path/.github/workflows" ]] || \
    [[ -f "$path/.gitlab-ci.yml" ]] || \
    [[ -f "$path/Jenkinsfile" ]] || \
    [[ -f "$path/.travis.yml" ]] || \
    [[ -f "$path/bitbucket-pipelines.yml" ]] || \
    [[ -f "$path/.circleci/config.yml" ]]
}

# Create temporary directory
create_temp_dir() {
    mktemp -d -t 12factor-assess-XXXXXX
}

# Clean up temporary files
cleanup_temp() {
    local temp_dir="$1"
    
    if [[ -n "$temp_dir" ]] && [[ -d "$temp_dir" ]]; then
        rm -rf "$temp_dir"
    fi
}

# JSON escape string
json_escape() {
    local string="$1"
    
    # Escape special characters for JSON
    string="${string//\\/\\\\}"
    string="${string//\"/\\\"}"
    string="${string//$'\n'/\\n}"
    string="${string//$'\r'/\\r}"
    string="${string//$'\t'/\\t}"
    
    echo "$string"
}

# Get current timestamp
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Validate directory path
validate_directory() {
    local path="$1"
    
    if [[ ! -d "$path" ]]; then
        echo "Error: Directory does not exist: $path" >&2
        return 1
    fi
    
    if [[ ! -r "$path" ]]; then
        echo "Error: Directory is not readable: $path" >&2
        return 1
    fi
    
    return 0
}