#!/bin/bash
# Cache system for save-my-tokens
# Caches responses to reduce API calls

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="$SCRIPT_DIR/.cache"

# Source dependencies
source "$SCRIPT_DIR/lib/logger.sh"

# Generate cache key from task + prompt + model
generate_cache_key() {
    local task=$1
    local prompt=$2
    local model=$3

    # Create hash of task:prompt:model
    echo -n "${task}:${prompt}:${model}" | md5
}

# Get cache file path
get_cache_file() {
    local task=$1
    local cache_key=$2

    local task_cache_dir="$CACHE_DIR/$task"
    mkdir -p "$task_cache_dir"

    echo "$task_cache_dir/${cache_key}.json"
}

# Check if cache entry exists and is valid
cache_get() {
    local task=$1
    local prompt=$2
    local model=$3
    local cache_ttl=$4

    # Generate cache key
    local cache_key=$(generate_cache_key "$task" "$prompt" "$model")
    local cache_file=$(get_cache_file "$task" "$cache_key")

    # Check if cache file exists
    if [ ! -f "$cache_file" ]; then
        log_debug "cache" "Cache miss: $cache_key"
        return 1
    fi

    # Check if cache is expired
    local created_at=$(jq -r '.created_at' "$cache_file" 2>/dev/null)
    if [ -z "$created_at" ] || [ "$created_at" = "null" ]; then
        log_debug "cache" "Invalid cache entry: $cache_key"
        rm -f "$cache_file"
        return 1
    fi

    # Convert ISO timestamp to Unix epoch
    local created_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_at" "+%s" 2>/dev/null)
    local now_epoch=$(date +%s)
    local age=$((now_epoch - created_epoch))

    if [ "$age" -gt "$cache_ttl" ]; then
        log_debug "cache" "Cache expired: $cache_key (age: ${age}s, ttl: ${cache_ttl}s)"
        rm -f "$cache_file"
        return 1
    fi

    log_info "cache" "Cache hit: $cache_key (age: ${age}s)"
    cat "$cache_file"
    return 0
}

# Store response in cache
cache_put() {
    local task=$1
    local prompt=$2
    local model=$3
    local response=$4
    local tokens=$5
    local cache_ttl=$6

    # Generate cache key
    local cache_key=$(generate_cache_key "$task" "$prompt" "$model")
    local cache_file=$(get_cache_file "$task" "$cache_key")

    # Create cache entry
    local created_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local expires_at=$(date -u -v+${cache_ttl}S +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat > "$cache_file" <<EOF
{
  "task": "$task",
  "model": "$model",
  "prompt_hash": "$cache_key",
  "created_at": "$created_at",
  "expires_at": "$expires_at",
  "tokens_used": $tokens,
  "response": $(echo "$response" | jq -Rs .)
}
EOF

    log_debug "cache" "Cached response: $cache_key"
}

# Clear cache for a task
cache_clear_task() {
    local task=$1

    local task_cache_dir="$CACHE_DIR/$task"
    if [ -d "$task_cache_dir" ]; then
        rm -rf "$task_cache_dir"
        log_info "cache" "Cleared cache for task: $task"
    fi
}

# Clear all cache
cache_clear_all() {
    if [ -d "$CACHE_DIR" ]; then
        rm -rf "$CACHE_DIR"/*
        log_info "cache" "Cleared all cache"
    fi
}

# Get cache statistics
cache_stats() {
    local total_entries=0
    local total_size=0

    if [ -d "$CACHE_DIR" ]; then
        total_entries=$(find "$CACHE_DIR" -name "*.json" | wc -l | tr -d ' ')
        total_size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
    fi

    echo "Cache entries: $total_entries"
    echo "Cache size: ${total_size:-0}"
}
