#!/bin/bash
# JSON parser for save-my-tokens
# Uses jq for JSON parsing

# Check if jq is available
check_jq() {
    if ! command -v jq &> /dev/null; then
        echo "ERROR: jq not found. Install with: brew install jq" >&2
        return 1
    fi
    return 0
}

# Get single JSON value
json_get() {
    local file=$1
    local path=$2

    if ! check_jq; then
        return 1
    fi

    jq -r "$path // empty" "$file" 2>/dev/null
}

# Get all models from task JSON
json_get_models() {
    local file=$1

    if ! check_jq; then
        return 1
    fi

    jq -r '.models[] | .name' "$file" 2>/dev/null
}

# Get model details
json_get_model_details() {
    local file=$1
    local model_index=$2
    local field=$3

    if ! check_jq; then
        return 1
    fi

    jq -r ".models[$model_index].$field // empty" "$file" 2>/dev/null
}

# Get platform details from config
json_get_platform() {
    local config_file=$1
    local platform=$2
    local field=$3

    if ! check_jq; then
        return 1
    fi

    jq -r ".platforms.\"$platform\".$field // empty" "$config_file" 2>/dev/null
}

# Check if platform is enabled
json_platform_enabled() {
    local config_file=$1
    local platform=$2

    local enabled=$(json_get_platform "$config_file" "$platform" "enabled")
    [ "$enabled" = "true" ]
}

# Get settings value
json_get_setting() {
    local config_file=$1
    local setting=$2

    jq -r ".settings.$setting // empty" "$config_file" 2>/dev/null
}

# Count models in task JSON
json_count_models() {
    local file=$1

    if ! check_jq; then
        return 1
    fi

    jq '.models | length' "$file" 2>/dev/null || echo "0"
}

# Get all enabled platforms from config
json_get_enabled_platforms() {
    local config_file=$1

    if ! check_jq; then
        return 1
    fi

    jq -r '.platforms | to_entries[] | select(.value.enabled == true) | .key' "$config_file" 2>/dev/null
}

# Validate JSON file
json_validate() {
    local file=$1

    if [ ! -f "$file" ]; then
        echo "ERROR: File not found: $file" >&2
        return 1
    fi

    if ! check_jq; then
        return 1
    fi

    jq empty "$file" >/dev/null 2>&1
    return $?
}

# Alias functions to maintain compatibility
yaml_get() { json_get "$@"; }
yaml_get_models() { json_get_models "$@"; }
yaml_get_model_details() { json_get_model_details "$@"; }
yaml_get_platform() { json_get_platform "$@"; }
yaml_platform_enabled() { json_platform_enabled "$@"; }
yaml_get_setting() { json_get_setting "$@"; }
yaml_count_models() { json_count_models "$@"; }
yaml_get_enabled_platforms() { json_get_enabled_platforms "$@"; }
yaml_validate() { json_validate "$@"; }
