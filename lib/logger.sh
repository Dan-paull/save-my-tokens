#!/bin/bash
# Logger utility for save-my-tokens
# Provides consistent logging to stderr and optional file logging

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/router.log"

# Log levels
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3

# Default log level (can be overridden by config)
CURRENT_LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

# Initialize logging
init_logger() {
    # Create logs directory if it doesn't exist
    mkdir -p "$LOG_DIR"

    # Convert string log level to numeric
    case "${LOG_LEVEL:-info}" in
        debug) CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
        info)  CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO ;;
        warn)  CURRENT_LOG_LEVEL=$LOG_LEVEL_WARN ;;
        error) CURRENT_LOG_LEVEL=$LOG_LEVEL_ERROR ;;
    esac
}

# Format timestamp
timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Log to stderr
log_stderr() {
    local level=$1
    local component=$2
    local message=$3

    echo "[$component] $message" >&2
}

# Log to file
log_file() {
    local level=$1
    local component=$2
    local message=$3

    if [ "${LOG_TO_FILE:-true}" = "true" ]; then
        echo "$(timestamp) [$level] [$component] $message" >> "$LOG_FILE"
    fi
}

# Main log function
log() {
    local level=$1
    local level_num=$2
    local component=$3
    shift 3
    local message="$*"

    # Check if we should log this level
    if [ "$level_num" -ge "$CURRENT_LOG_LEVEL" ]; then
        log_stderr "$level" "$component" "$message"
    fi

    # Always log to file regardless of level
    log_file "$level" "$component" "$message"
}

# Convenience functions
log_debug() {
    log "DEBUG" $LOG_LEVEL_DEBUG "$@"
}

log_info() {
    log "INFO" $LOG_LEVEL_INFO "$@"
}

log_warn() {
    log "WARN" $LOG_LEVEL_WARN "$@"
}

log_error() {
    log "ERROR" $LOG_LEVEL_ERROR "$@"
}

# Success/failure indicators
log_success() {
    local component=$1
    shift
    log_info "$component" "✓ $*"
}

log_failure() {
    local component=$1
    shift
    log_error "$component" "✗ $*"
}

# Initialize on source
init_logger
