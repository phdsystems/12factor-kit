#!/bin/bash

# ==============================================================================
# 12-Factor App Compliance Assessment Tool
# ==============================================================================
# Language-agnostic tool to assess 12-factor app compliance for any project
# ==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
PROJECT_PATH="${1:-.}"
REPORT_FORMAT="${REPORT_FORMAT:-terminal}"  # terminal, json, markdown
VERBOSE="${VERBOSE:-false}"
CHECK_DEPTH="${CHECK_DEPTH:-3}"  # How deep to search in directories
STRICT_MODE="${STRICT_MODE:-false}"
GENERATE_REMEDIATION="${GENERATE_REMEDIATION:-false}"

# Scoring
TOTAL_SCORE=0
MAX_SCORE=120  # 10 points per factor
FACTOR_SCORES=()
FACTOR_DETAILS=()
REMEDIATION_SUGGESTIONS=()

# ==============================================================================
# Helper Functions
# ==============================================================================

show_help() {
    cat << EOF
${BOLD}12-Factor App Compliance Assessment Tool${NC}

${BOLD}USAGE:${NC}
    $0 [PROJECT_PATH] [OPTIONS]

${BOLD}OPTIONS:${NC}
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -f, --format FORMAT     Output format: terminal, json, markdown (default: terminal)
    -d, --depth DEPTH       Directory search depth (default: 3)
    --remediate            Generate remediation scripts
    --strict               Strict mode - fail on any non-compliance

${BOLD}EXAMPLES:${NC}
    # Assess current directory
    $0

    # Assess specific project with JSON output
    $0 /path/to/project -f json

    # Generate markdown report with remediation
    $0 . -f markdown --remediate

${BOLD}12 FACTORS ASSESSED:${NC}
    I.    Codebase         - One codebase tracked in revision control
    II.   Dependencies     - Explicitly declare and isolate dependencies
    III.  Config           - Store config in the environment
    IV.   Backing services - Treat backing services as attached resources
    V.    Build/Release    - Strictly separate build and run stages
    VI.   Processes        - Execute app as stateless processes
    VII.  Port binding     - Export services via port binding
    VIII. Concurrency      - Scale out via the process model
    IX.   Disposability    - Fast startup and graceful shutdown
    X.    Dev/prod parity  - Keep dev, staging, production similar
    XI.   Logs             - Treat logs as event streams
    XII.  Admin processes  - Run admin tasks as one-off processes

EOF
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${DIM}[DEBUG] $1${NC}" >&2
    fi
}

detect_project_type() {
    local path="$1"
    local project_types=()
    
    # Check for various project indicators
    [[ -f "$path/package.json" ]] && project_types+=("node")
    [[ -f "$path/requirements.txt" || -f "$path/setup.py" || -f "$path/Pipfile" ]] && project_types+=("python")
    [[ -f "$path/go.mod" || -f "$path/go.sum" ]] && project_types+=("go")
    [[ -f "$path/Gemfile" ]] && project_types+=("ruby")
    [[ -f "$path/pom.xml" || -f "$path/build.gradle" ]] && project_types+=("java")
    [[ -f "$path/Cargo.toml" ]] && project_types+=("rust")
    [[ -f "$path/composer.json" ]] && project_types+=("php")
    [[ -f "$path/.csproj" || -f "$path/.sln" ]] && project_types+=("dotnet")
    [[ -f "$path/Dockerfile" || -f "$path/docker-compose.yml" ]] && project_types+=("docker")
    [[ -d "$path/.git" ]] && project_types+=("git")
    
    echo "${project_types[@]}"
}

calculate_score() {
    local score=$1
    local max_score=$2
    local percentage=$((score * 100 / max_score))
    
    if [[ $percentage -ge 80 ]]; then
        echo -e "${GREEN}✅ Excellent ($score/$max_score)${NC}"
    elif [[ $percentage -ge 60 ]]; then
        echo -e "${YELLOW}⚠️  Good ($score/$max_score)${NC}"
    elif [[ $percentage -ge 40 ]]; then
        echo -e "${YELLOW}⚠️  Fair ($score/$max_score)${NC}"
    else
        echo -e "${RED}❌ Poor ($score/$max_score)${NC}"
    fi
}

# ==============================================================================
# Factor Assessment Functions
# ==============================================================================

assess_factor_1_codebase() {
    local score=0
    local details=""
    local remediation=""

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "\n${BOLD}Factor I: Codebase${NC}"
        echo "Checking for single codebase with version control..."
    fi
    
    # Check for version control
    if [[ -d "$PROJECT_PATH/.git" ]]; then
        score=$((score + 5))
        details+="✅ Git repository found\n"
        
        # Check for single remote
        local remote_count=$(cd "$PROJECT_PATH" && git remote | wc -l 2>/dev/null || echo 0)
        if [[ $remote_count -eq 1 ]]; then
            score=$((score + 3))
            details+="✅ Single remote repository\n"
        elif [[ $remote_count -gt 1 ]]; then
            score=$((score + 1))
            details+="⚠️  Multiple remotes detected\n"
            remediation+="- Consider consolidating to single remote\n"
        fi
        
        # Check for monorepo indicators
        if [[ -f "$PROJECT_PATH/lerna.json" ]] || [[ -f "$PROJECT_PATH/nx.json" ]] || [[ -d "$PROJECT_PATH/packages" ]]; then
            score=$((score + 2))
            details+="✅ Monorepo structure detected\n"
        fi
    else
        details+="❌ No version control found\n"
        remediation+="- Initialize git: git init\n"
        remediation+="- Add remote: git remote add origin <url>\n"
    fi
    
    FACTOR_SCORES[1]=$score
    FACTOR_DETAILS[1]="$details"
    REMEDIATION_SUGGESTIONS[1]="$remediation"
    TOTAL_SCORE=$((TOTAL_SCORE + score))

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "$details"
        echo -e "Score: $(calculate_score $score 10)"
    fi
}

assess_factor_2_dependencies() {
    local score=0
    local details=""
    local remediation=""

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "\n${BOLD}Factor II: Dependencies${NC}"
        echo "Checking for explicit dependency declaration..."
    fi
    
    # Check for dependency files
    local dep_files_found=0
    
    # Node.js
    if [[ -f "$PROJECT_PATH/package.json" ]]; then
        score=$((score + 3))
        details+="✅ package.json found (Node.js)\n"
        dep_files_found=$((dep_files_found + 1))
        
        if [[ -f "$PROJECT_PATH/package-lock.json" ]] || [[ -f "$PROJECT_PATH/yarn.lock" ]]; then
            score=$((score + 2))
            details+="✅ Lock file found\n"
        else
            details+="⚠️  No lock file\n"
            remediation+="- Run: npm install or yarn install\n"
        fi
    fi
    
    # Python
    if [[ -f "$PROJECT_PATH/requirements.txt" ]] || [[ -f "$PROJECT_PATH/Pipfile" ]] || [[ -f "$PROJECT_PATH/pyproject.toml" ]]; then
        score=$((score + 3))
        details+="✅ Python dependencies found\n"
        dep_files_found=$((dep_files_found + 1))
    fi
    
    # Go
    if [[ -f "$PROJECT_PATH/go.mod" ]]; then
        score=$((score + 3))
        details+="✅ go.mod found (Go)\n"
        dep_files_found=$((dep_files_found + 1))
    fi
    
    # Docker
    if [[ -f "$PROJECT_PATH/Dockerfile" ]]; then
        score=$((score + 2))
        details+="✅ Dockerfile found\n"
    fi
    
    # Check for vendoring
    if [[ -d "$PROJECT_PATH/vendor" ]] || [[ -d "$PROJECT_PATH/node_modules" ]]; then
        details+="⚠️  Vendored dependencies detected\n"
        remediation+="- Consider using Docker for isolation\n"
    fi
    
    if [[ $dep_files_found -eq 0 ]]; then
        details+="❌ No dependency declarations found\n"
        remediation+="- Add appropriate dependency file for your language\n"
    fi
    
    # Cap at 10
    [[ $score -gt 10 ]] && score=10
    
    FACTOR_SCORES[2]=$score
    FACTOR_DETAILS[2]="$details"
    REMEDIATION_SUGGESTIONS[2]="$remediation"
    TOTAL_SCORE=$((TOTAL_SCORE + score))

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "$details"
        echo -e "Score: $(calculate_score $score 10)"
    fi
}

assess_factor_3_config() {
    local score=0
    local details=""
    local remediation=""

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "\n${BOLD}Factor III: Config${NC}"
        echo "Checking for environment-based configuration..."
    fi
    
    # Check for .env files
    if [[ -f "$PROJECT_PATH/.env.example" ]] || [[ -f "$PROJECT_PATH/.env.sample" ]]; then
        score=$((score + 4))
        details+="✅ Environment template found\n"
    fi
    
    # Check for hardcoded configs
    local config_files=$(find "$PROJECT_PATH" -maxdepth "$CHECK_DEPTH" -type f \
        \( -name "*.config.js" -o -name "*.config.json" -o -name "config.yml" -o -name "config.yaml" \) 2>/dev/null | head -5)
    
    if [[ -n "$config_files" ]]; then
        details+="⚠️  Config files found - check for hardcoded values\n"
        score=$((score + 2))
        
        # Check if configs use env vars
        if grep -r "process.env\|ENV\|getenv\|os.environ" "$PROJECT_PATH" --include="*.js" --include="*.py" --include="*.go" -q 2>/dev/null; then
            score=$((score + 3))
            details+="✅ Environment variable usage detected\n"
        fi
    fi
    
    # Check for secrets in code
    if grep -r "password\|api_key\|secret" "$PROJECT_PATH" --include="*.js" --include="*.py" --include="*.go" -i -q 2>/dev/null; then
        details+="⚠️  Potential hardcoded secrets detected\n"
        remediation+="- Move secrets to environment variables\n"
        remediation+="- Use secret management service\n"
    else
        score=$((score + 1))
        details+="✅ No obvious hardcoded secrets\n"
    fi
    
    FACTOR_SCORES[3]=$score
    FACTOR_DETAILS[3]="$details"
    REMEDIATION_SUGGESTIONS[3]="$remediation"
    TOTAL_SCORE=$((TOTAL_SCORE + score))

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "$details"
        echo -e "Score: $(calculate_score $score 10)"
    fi
}

assess_factor_4_backing_services() {
    local score=0
    local details=""
    local remediation=""

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "\n${BOLD}Factor IV: Backing Services${NC}"
        echo "Checking for attached resource handling..."
    fi

    # Check for database configs
    if grep -r "DATABASE_URL\|DB_HOST\|MONGO_URI\|REDIS_URL" "$PROJECT_PATH" -q 2>/dev/null; then
        score=$((score + 4))
        details+="✅ Database configuration via environment detected\n"
    fi
    
    # Check docker-compose for services
    if [[ -f "$PROJECT_PATH/docker-compose.yml" ]] || [[ -f "$PROJECT_PATH/docker-compose.yaml" ]]; then
        score=$((score + 3))
        details+="✅ Docker Compose services found\n"
        
        # Check for service dependencies
        if grep -q "depends_on:" "$PROJECT_PATH/docker-compose.yml" 2>/dev/null; then
            score=$((score + 2))
            details+="✅ Service dependencies defined\n"
        fi
    fi
    
    # Check for service discovery patterns
    if grep -r "SERVICE_\|_HOST\|_PORT" "$PROJECT_PATH" -q 2>/dev/null; then
        score=$((score + 1))
        details+="✅ Service discovery patterns found\n"
    fi
    
    FACTOR_SCORES[4]=$score
    FACTOR_DETAILS[4]="$details"
    REMEDIATION_SUGGESTIONS[4]="$remediation"
    TOTAL_SCORE=$((TOTAL_SCORE + score))

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "$details"
        echo -e "Score: $(calculate_score $score 10)"
    fi
}

assess_factor_5_build_release_run() {
    local score=0
    local details=""
    local remediation=""

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "\n${BOLD}Factor V: Build, Release, Run${NC}"
        echo "Checking for separated build and run stages..."
    fi

    # Check for CI/CD configs
    if ls "$PROJECT_PATH"/.github/workflows/*.yml 2>/dev/null | head -1 | grep -q . || [[ -f "$PROJECT_PATH/.gitlab-ci.yml" ]] || [[ -f "$PROJECT_PATH/Jenkinsfile" ]]; then
        score=$((score + 4))
        details+="✅ CI/CD configuration found\n"
    fi
    
    # Check for build scripts
    if [[ -f "$PROJECT_PATH/build.sh" ]] || [[ -f "$PROJECT_PATH/Makefile" ]] || [[ -f "$PROJECT_PATH/package.json" ]]; then
        score=$((score + 3))
        details+="✅ Build scripts found\n"
    fi
    
    # Check for Dockerfile multi-stage
    if [[ -f "$PROJECT_PATH/Dockerfile" ]]; then
        if grep -q "FROM.*AS.*build" "$PROJECT_PATH/Dockerfile" 2>/dev/null; then
            score=$((score + 3))
            details+="✅ Multi-stage Docker build detected\n"
        else
            score=$((score + 1))
            details+="⚠️  Single-stage Dockerfile\n"
            remediation+="- Consider multi-stage builds\n"
        fi
    fi
    
    FACTOR_SCORES[5]=$score
    FACTOR_DETAILS[5]="$details"
    REMEDIATION_SUGGESTIONS[5]="$remediation"
    TOTAL_SCORE=$((TOTAL_SCORE + score))

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "$details"
        echo -e "Score: $(calculate_score $score 10)"
    fi
}

assess_factor_6_processes() {
    local score=0
    local details=""
    local remediation=""

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "\n${BOLD}Factor VI: Processes${NC}"
        echo "Checking for stateless process design..."
    fi

    # Check for session/state management
    if grep -r "session\|localStorage\|cookie" "$PROJECT_PATH" --include="*.js" --include="*.py" -q 2>/dev/null; then
        details+="⚠️  Session/state management detected\n"
        remediation+="- Consider external session store (Redis)\n"
        score=$((score + 3))
    else
        score=$((score + 5))
        details+="✅ No obvious local state storage\n"
    fi
    
    # Check for file uploads
    if grep -r "upload\|multer\|FormData" "$PROJECT_PATH" --include="*.js" --include="*.py" -q 2>/dev/null; then
        details+="⚠️  File upload handling detected\n"
        remediation+="- Use external storage (S3, GCS)\n"
        score=$((score + 2))
    fi
    
    # Check for PID files
    if find "$PROJECT_PATH" -name "*.pid" 2>/dev/null | grep -q .; then
        details+="⚠️  PID files found\n"
        remediation+="- Use process manager instead\n"
    else
        score=$((score + 3))
        details+="✅ No PID files found\n"
    fi
    
    FACTOR_SCORES[6]=$score
    FACTOR_DETAILS[6]="$details"
    REMEDIATION_SUGGESTIONS[6]="$remediation"
    TOTAL_SCORE=$((TOTAL_SCORE + score))

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "$details"
        echo -e "Score: $(calculate_score $score 10)"
    fi
}

assess_factor_7_port_binding() {
    local score=0
    local details=""
    local remediation=""

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "\n${BOLD}Factor VII: Port Binding${NC}"
        echo "Checking for port binding..."
    fi

    # Check for port configuration
    if grep -r "PORT\|port:" "$PROJECT_PATH" --include="*.js" --include="*.py" --include="*.go" --include="*.yml" -q 2>/dev/null; then
        score=$((score + 4))
        details+="✅ Port configuration found\n"
    fi
    
    # Check for web server
    if grep -r "express\|fastapi\|gin\|rails\|django" "$PROJECT_PATH" -q 2>/dev/null; then
        score=$((score + 3))
        details+="✅ Web framework detected\n"
    fi
    
    # Check for EXPOSE in Dockerfile
    if [[ -f "$PROJECT_PATH/Dockerfile" ]]; then
        if grep -q "EXPOSE" "$PROJECT_PATH/Dockerfile" 2>/dev/null; then
            score=$((score + 3))
            details+="✅ Docker EXPOSE directive found\n"
        fi
    fi
    
    FACTOR_SCORES[7]=$score
    FACTOR_DETAILS[7]="$details"
    REMEDIATION_SUGGESTIONS[7]="$remediation"
    TOTAL_SCORE=$((TOTAL_SCORE + score))

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "$details"
        echo -e "Score: $(calculate_score $score 10)"
    fi
}

assess_factor_8_concurrency() {
    local score=0
    local details=""
    local remediation=""

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "\n${BOLD}Factor VIII: Concurrency${NC}"
        echo "Checking for process-based scaling..."
    fi

    # Check for container orchestration
    if find "$PROJECT_PATH" -name "*.yaml" -o -name "*.yml" | xargs grep -l "kind: Deployment\|replicas:" 2>/dev/null | grep -q .; then
        score=$((score + 5))
        details+="✅ Kubernetes manifests found\n"
    fi
    
    # Check docker-compose scale
    if [[ -f "$PROJECT_PATH/docker-compose.yml" ]]; then
        if grep -q "replicas:\|scale:" "$PROJECT_PATH/docker-compose.yml" 2>/dev/null; then
            score=$((score + 3))
            details+="✅ Docker Compose scaling configured\n"
        fi
    fi
    
    # Check for worker processes
    if grep -r "worker\|cluster\|pm2" "$PROJECT_PATH" -q 2>/dev/null; then
        score=$((score + 2))
        details+="✅ Worker process patterns found\n"
    fi
    
    if [[ $score -eq 0 ]]; then
        remediation+="- Add Kubernetes manifests\n"
        remediation+="- Configure Docker Compose scaling\n"
        remediation+="- Implement worker processes\n"
    fi
    
    FACTOR_SCORES[8]=$score
    FACTOR_DETAILS[8]="$details"
    REMEDIATION_SUGGESTIONS[8]="$remediation"
    TOTAL_SCORE=$((TOTAL_SCORE + score))

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "$details"
        echo -e "Score: $(calculate_score $score 10)"
    fi
}

assess_factor_9_disposability() {
    local score=0
    local details=""
    local remediation=""

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "\n${BOLD}Factor IX: Disposability${NC}"
        echo "Checking for fast startup and graceful shutdown..."
    fi

    # Check for signal handling
    if grep -r "SIGTERM\|SIGINT\|graceful" "$PROJECT_PATH" --include="*.js" --include="*.py" --include="*.go" -q 2>/dev/null; then
        score=$((score + 5))
        details+="✅ Signal handling found\n"
    else
        remediation+="- Implement SIGTERM/SIGINT handlers\n"
    fi
    
    # Check for health checks
    if grep -r "health\|healthz\|readiness\|liveness" "$PROJECT_PATH" -q 2>/dev/null; then
        score=$((score + 3))
        details+="✅ Health check endpoints found\n"
    else
        remediation+="- Add health check endpoints\n"
    fi
    
    # Check for connection pooling
    if grep -r "pool\|connection.*limit" "$PROJECT_PATH" -q 2>/dev/null; then
        score=$((score + 2))
        details+="✅ Connection pooling detected\n"
    fi
    
    FACTOR_SCORES[9]=$score
    FACTOR_DETAILS[9]="$details"
    REMEDIATION_SUGGESTIONS[9]="$remediation"
    TOTAL_SCORE=$((TOTAL_SCORE + score))

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "$details"
        echo -e "Score: $(calculate_score $score 10)"
    fi
}

assess_factor_10_dev_prod_parity() {
    local score=0
    local details=""
    local remediation=""

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "\n${BOLD}Factor X: Dev/Prod Parity${NC}"
        echo "Checking for environment parity..."
    fi

    # Check for Docker
    if [[ -f "$PROJECT_PATH/Dockerfile" ]]; then
        score=$((score + 4))
        details+="✅ Dockerfile ensures consistency\n"
    fi
    
    # Check for docker-compose variants
    if [[ -f "$PROJECT_PATH/docker-compose.yml" ]] && [[ -f "$PROJECT_PATH/docker-compose.prod.yml" ]]; then
        score=$((score + 3))
        details+="✅ Environment-specific compose files\n"
    fi
    
    # Check for environment configs
    if [[ -f "$PROJECT_PATH/.env.development" ]] && [[ -f "$PROJECT_PATH/.env.production" ]]; then
        score=$((score + 3))
        details+="✅ Environment-specific configs\n"
    elif [[ -f "$PROJECT_PATH/.env.example" ]]; then
        score=$((score + 2))
        details+="⚠️  Single env template\n"
        remediation+="- Create environment-specific templates\n"
    fi
    
    FACTOR_SCORES[10]=$score
    FACTOR_DETAILS[10]="$details"
    REMEDIATION_SUGGESTIONS[10]="$remediation"
    TOTAL_SCORE=$((TOTAL_SCORE + score))

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "$details"
        echo -e "Score: $(calculate_score $score 10)"
    fi
}

assess_factor_11_logs() {
    local score=0
    local details=""
    local remediation=""

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "\n${BOLD}Factor XI: Logs${NC}"
        echo "Checking for log streaming..."
    fi

    # Check for console logging
    if grep -r "console.log\|print\|logger\|log.info" "$PROJECT_PATH" --include="*.js" --include="*.py" --include="*.go" -q 2>/dev/null; then
        score=$((score + 3))
        details+="✅ Logging statements found\n"
    fi
    
    # Check for log files
    if find "$PROJECT_PATH" -name "*.log" 2>/dev/null | grep -q .; then
        details+="⚠️  Log files found - should stream to stdout\n"
        remediation+="- Stream logs to stdout/stderr\n"
        remediation+="- Remove file-based logging\n"
        score=$((score + 2))
    else
        score=$((score + 4))
        details+="✅ No log files found\n"
    fi
    
    # Check for structured logging
    if grep -r "winston\|bunyan\|logrus\|zap" "$PROJECT_PATH" -q 2>/dev/null; then
        score=$((score + 3))
        details+="✅ Structured logging library detected\n"
    fi
    
    FACTOR_SCORES[11]=$score
    FACTOR_DETAILS[11]="$details"
    REMEDIATION_SUGGESTIONS[11]="$remediation"
    TOTAL_SCORE=$((TOTAL_SCORE + score))

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "$details"
        echo -e "Score: $(calculate_score $score 10)"
    fi
}

assess_factor_12_admin_processes() {
    local score=0
    local details=""
    local remediation=""

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "\n${BOLD}Factor XII: Admin Processes${NC}"
        echo "Checking for one-off process handling..."
    fi

    # Check for migration files
    if find "$PROJECT_PATH" -type d -name "migrations" 2>/dev/null | grep -q .; then
        score=$((score + 4))
        details+="✅ Database migrations found\n"
    fi
    
    # Check for scripts directory
    if [[ -d "$PROJECT_PATH/scripts" ]] || [[ -d "$PROJECT_PATH/bin" ]]; then
        score=$((score + 3))
        details+="✅ Scripts directory found\n"
    fi
    
    # Check for task runners
    if [[ -f "$PROJECT_PATH/Makefile" ]] || grep -q "scripts" "$PROJECT_PATH/package.json" 2>/dev/null; then
        score=$((score + 3))
        details+="✅ Task runner configured\n"
    fi
    
    FACTOR_SCORES[12]=$score
    FACTOR_DETAILS[12]="$details"
    REMEDIATION_SUGGESTIONS[12]="$remediation"
    TOTAL_SCORE=$((TOTAL_SCORE + score))

    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "$details"
        echo -e "Score: $(calculate_score $score 10)"
    fi
}

# ==============================================================================
# Report Generation
# ==============================================================================

generate_terminal_report() {
    echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}                    12-FACTOR COMPLIANCE REPORT                    ${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local percentage=$((TOTAL_SCORE * 100 / MAX_SCORE))
    
    echo -e "\n${BOLD}Overall Score:${NC} $(calculate_score $TOTAL_SCORE $MAX_SCORE)"
    echo -e "${BOLD}Compliance:${NC} ${percentage}%"
    
    # Progress bar
    echo -n "["
    local filled=$((percentage / 5))
    for ((i=0; i<20; i++)); do
        if [[ $i -lt $filled ]]; then
            printf "█"
        else
            printf "░"
        fi
    done
    echo "]"
    
    echo -e "\n${BOLD}Factor Breakdown:${NC}"
    local factors=(
        "Codebase"
        "Dependencies"
        "Config"
        "Backing Services"
        "Build/Release/Run"
        "Processes"
        "Port Binding"
        "Concurrency"
        "Disposability"
        "Dev/Prod Parity"
        "Logs"
        "Admin Processes"
    )
    
    for i in {1..12}; do
        printf "  %2d. %-20s %s\n" "$i" "${factors[$i-1]}" "$(calculate_score ${FACTOR_SCORES[$i]:-0} 10)"
    done
    
    # Remediation summary
    local has_remediation=false
    for i in {1..12}; do
        if [[ -n "${REMEDIATION_SUGGESTIONS[$i]}" ]]; then
            has_remediation=true
            break
        fi
    done
    
    if [[ "$has_remediation" == "true" ]]; then
        echo -e "\n${BOLD}Recommended Improvements:${NC}"
        for i in {1..12}; do
            if [[ -n "${REMEDIATION_SUGGESTIONS[$i]}" ]]; then
                echo -e "\n  ${BOLD}Factor $i: ${factors[$i-1]}${NC}"
                echo -e "${REMEDIATION_SUGGESTIONS[$i]}" | sed 's/^/    /'
            fi
        done
    fi
    
    # Grade
    echo -e "\n${BOLD}Final Grade:${NC} "
    if [[ $percentage -ge 90 ]]; then
        echo -e "${GREEN}A+ - Excellent 12-Factor Compliance${NC}"
    elif [[ $percentage -ge 80 ]]; then
        echo -e "${GREEN}A - Very Good Compliance${NC}"
    elif [[ $percentage -ge 70 ]]; then
        echo -e "${YELLOW}B - Good Compliance${NC}"
    elif [[ $percentage -ge 60 ]]; then
        echo -e "${YELLOW}C - Fair Compliance${NC}"
    elif [[ $percentage -ge 50 ]]; then
        echo -e "${YELLOW}D - Poor Compliance${NC}"
    else
        echo -e "${RED}F - Needs Significant Improvement${NC}"
    fi
}

generate_json_report() {
    cat << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "project_path": "$PROJECT_PATH",
  "total_score": $TOTAL_SCORE,
  "max_score": $MAX_SCORE,
  "percentage": $((TOTAL_SCORE * 100 / MAX_SCORE)),
  "factors": [
EOF
    
    local factors=(
        "codebase"
        "dependencies"
        "config"
        "backing_services"
        "build_release_run"
        "processes"
        "port_binding"
        "concurrency"
        "disposability"
        "dev_prod_parity"
        "logs"
        "admin_processes"
    )
    
    for i in {1..12}; do
        cat << EOF
    {
      "number": $i,
      "name": "${factors[$i-1]}",
      "score": ${FACTOR_SCORES[$i]:-0},
      "max_score": 10,
      "details": "$(echo "${FACTOR_DETAILS[$i]}" | tr -d '\n' | sed 's/"/\\"/g')",
      "remediation": "$(echo "${REMEDIATION_SUGGESTIONS[$i]}" | tr -d '\n' | sed 's/"/\\"/g')"
    }$([ $i -lt 12 ] && echo ",")
EOF
    done
    
    echo "  ]"
    echo "}"
}

generate_markdown_report() {
    cat << EOF
# 12-Factor App Compliance Report

**Date:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")  
**Project:** $PROJECT_PATH  
**Overall Score:** $TOTAL_SCORE/$MAX_SCORE ($((TOTAL_SCORE * 100 / MAX_SCORE))%)

## Executive Summary

EOF
    
    local percentage=$((TOTAL_SCORE * 100 / MAX_SCORE))
    if [[ $percentage -ge 80 ]]; then
        echo "✅ **Excellent Compliance** - This project demonstrates strong adherence to 12-Factor principles."
    elif [[ $percentage -ge 60 ]]; then
        echo "⚠️ **Good Compliance** - This project follows many 12-Factor principles but has room for improvement."
    else
        echo "❌ **Needs Improvement** - This project requires significant changes to achieve 12-Factor compliance."
    fi
    
    cat << EOF

## Factor Assessment

| Factor | Name | Score | Status |
|--------|------|-------|--------|
EOF
    
    local factors=(
        "Codebase"
        "Dependencies"
        "Config"
        "Backing Services"
        "Build/Release/Run"
        "Processes"
        "Port Binding"
        "Concurrency"
        "Disposability"
        "Dev/Prod Parity"
        "Logs"
        "Admin Processes"
    )
    
    for i in {1..12}; do
        local score=${FACTOR_SCORES[$i]:-0}
        local status="❌"
        [[ $score -ge 8 ]] && status="✅"
        [[ $score -ge 5 ]] && [[ $score -lt 8 ]] && status="⚠️"
        
        echo "| $i | ${factors[$i-1]} | $score/10 | $status |"
    done
    
    echo ""
    echo "## Detailed Findings"
    
    for i in {1..12}; do
        echo ""
        echo "### Factor $i: ${factors[$i-1]}"
        echo ""
        echo "${FACTOR_DETAILS[$i]}" | sed 's/✅/- ✅/g; s/⚠️/- ⚠️/g; s/❌/- ❌/g'
        
        if [[ -n "${REMEDIATION_SUGGESTIONS[$i]}" ]]; then
            echo ""
            echo "**Recommendations:**"
            echo "${REMEDIATION_SUGGESTIONS[$i]}"
        fi
    done
    
    echo ""
    echo "## Next Steps"
    echo ""
    echo "1. Address critical issues (factors scoring < 5)"
    echo "2. Implement recommended improvements"
    echo "3. Re-run assessment after changes"
    echo "4. Consider automation for continuous compliance"
    
    echo ""
    echo "---"
    echo "*Generated by 12-Factor Assessment Tool*"
}

# ==============================================================================
# Main Execution
# ==============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--format)
                if [[ -z "${2:-}" ]]; then
                    echo -e "${RED}Error: --format requires an argument${NC}"
                    exit 1
                fi
                REPORT_FORMAT="$2"
                # Validate format
                if [[ ! "$REPORT_FORMAT" =~ ^(terminal|json|markdown)$ ]]; then
                    echo -e "${YELLOW}Warning: Unknown format '$REPORT_FORMAT', using terminal${NC}" >&2
                    REPORT_FORMAT="terminal"
                fi
                shift 2
                ;;
            -d|--depth)
                if [[ -z "${2:-}" ]]; then
                    echo -e "${RED}Error: --depth requires an argument${NC}"
                    exit 1
                fi
                if [[ ! "$2" =~ ^[0-9]+$ ]] || [[ "$2" -lt 1 ]]; then
                    echo -e "${RED}Error: --depth must be a positive integer${NC}"
                    exit 1
                fi
                CHECK_DEPTH="$2"
                shift 2
                ;;
            --remediate)
                GENERATE_REMEDIATION=true
                shift
                ;;
            --strict)
                STRICT_MODE=true
                shift
                ;;
            *)
                PROJECT_PATH="$1"
                shift
                ;;
        esac
    done
    
    # Validate project path
    if [[ ! -d "$PROJECT_PATH" ]]; then
        echo -e "${RED}Error: Project path '$PROJECT_PATH' does not exist${NC}"
        exit 1
    fi
    
    # Convert to absolute path
    if ! PROJECT_PATH=$(cd "$PROJECT_PATH" && pwd 2>/dev/null); then
        echo -e "${RED}Error: Cannot access project path '$PROJECT_PATH'${NC}"
        exit 1
    fi
    
    if [[ "$REPORT_FORMAT" == "terminal" ]]; then
        echo -e "${BOLD}12-Factor App Compliance Assessment${NC}"
        echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "Project: ${CYAN}$PROJECT_PATH${NC}"

        # Detect project type
        local project_types=($(detect_project_type "$PROJECT_PATH"))
        if [[ ${#project_types[@]} -gt 0 ]]; then
            echo -e "Detected: ${GREEN}${project_types[*]}${NC}"
        fi

        echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
    
    # Run assessments
    assess_factor_1_codebase
    assess_factor_2_dependencies
    assess_factor_3_config
    assess_factor_4_backing_services
    assess_factor_5_build_release_run
    assess_factor_6_processes
    assess_factor_7_port_binding
    assess_factor_8_concurrency
    assess_factor_9_disposability
    assess_factor_10_dev_prod_parity
    assess_factor_11_logs
    assess_factor_12_admin_processes
    
    # Handle strict mode exit BEFORE report generation to avoid hanging
    if [[ "$STRICT_MODE" == "true" ]]; then
        local percentage=$((TOTAL_SCORE * 100 / MAX_SCORE))
        echo -e "\n${BOLD}Strict Mode Assessment Complete${NC}"
        echo -e "${BOLD}Final Score:${NC} ${percentage}% (threshold: 80%)"
        if [[ $percentage -lt 80 ]]; then
            echo -e "${RED}❌ FAILED - Below compliance threshold${NC}"
            exit 1
        else
            echo -e "${GREEN}✅ PASSED - Meets compliance threshold${NC}"
            exit 0
        fi
    fi

    # Generate report
    case $REPORT_FORMAT in
        json)
            generate_json_report
            ;;
        markdown)
            generate_markdown_report
            ;;
        *)
            generate_terminal_report
            ;;
    esac

    exit 0
}

# Run main function
main "$@"