#!/bin/bash
# Model filter for save-my-tokens
# Filters models based on platform availability and API keys

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/yaml-parser.sh"
source "$SCRIPT_DIR/lib/logger.sh"

# Check if platform is available (enabled + has API key)
check_platform_available() {
    local config_file=$1
    local platform=$2

    # Check if platform is enabled in config
    if ! yaml_platform_enabled "$config_file" "$platform"; then
        log_debug "model-filter" "Platform $platform is disabled in config"
        return 1
    fi

    # Check if API key exists
    local api_key_env=$(yaml_get_platform "$config_file" "$platform" "api_key_env")
    if [ -z "$api_key_env" ]; then
        log_debug "model-filter" "No API key env var configured for $platform"
        return 1
    fi

    # Check if API key is set
    local api_key_value="${!api_key_env}"
    if [ -z "$api_key_value" ]; then
        log_debug "model-filter" "API key not set for $platform (${api_key_env})"
        return 1
    fi

    return 0
}

# Filter models from task YAML based on availability
filter_available_models() {
    local config_file=$1
    local task_file=$2

    local available_models=""
    local model_count=$(yaml_count_models "$task_file")

    for ((i=0; i<model_count; i++)); do
        local platform=$(yaml_get_model_details "$task_file" "$i" "platform")
        local name=$(yaml_get_model_details "$task_file" "$i" "name")

        if check_platform_available "$config_file" "$platform"; then
            available_models="$available_models$i "
            log_debug "model-filter" "Model $name ($platform) is available"
        else
            log_debug "model-filter" "Model $name ($platform) is not available"
        fi
    done

    # Return space-separated list of available model indices
    echo "$available_models" | tr -s ' ' | sed 's/^ //;s/ $//'
}

# Count available models
count_available_models() {
    local config_file=$1
    local task_file=$2

    local available=$(filter_available_models "$config_file" "$task_file")
    if [ -z "$available" ]; then
        echo "0"
    else
        echo "$available" | wc -w | tr -d ' '
    fi
}

# Get platform status for error reporting
get_platform_status() {
    local config_file=$1
    local platform=$2

    # Source environment file
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    if [ -f "$script_dir/.env.savemytokens" ]; then
        set -a
        source "$script_dir/.env.savemytokens"
        set +a
    fi

    local enabled=$(jq -r ".platforms.${platform}.enabled // false" "$config_file")
    local api_key_env=$(jq -r ".platforms.${platform}.api_key_env // \"\"" "$config_file")
    local api_key_value="${!api_key_env}"

    if [ "$enabled" != "true" ]; then
        echo "disabled"
    elif [ -z "$api_key_value" ]; then
        echo "no_api_key"
    else
        echo "enabled"
    fi
}

# Generate platform status report
generate_platform_report() {
    local config_file=$1

    # Source environment file
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    if [ -f "$script_dir/.env.savemytokens" ]; then
        set -a
        source "$script_dir/.env.savemytokens"
        set +a
    fi

    local platforms=$(jq -r '.platforms | keys[]' "$config_file")

    while IFS= read -r platform; do
        local status=$(get_platform_status "$config_file" "$platform")
        local api_key_env=$(jq -r ".platforms.${platform}.api_key_env // \"\"" "$config_file")

        case "$status" in
            enabled)
                echo "✓ $platform: enabled, API key present"
                ;;
            disabled)
                echo "✗ $platform: disabled in config"
                ;;
            no_api_key)
                echo "✗ $platform: enabled but no API key ($api_key_env)"
                ;;
        esac
    done <<< "$platforms"
}
