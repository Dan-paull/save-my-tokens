#!/bin/bash
# Override system for save-my-tokens
# Handles priority: CLI > XML > YAML > Default

# Determine run_multiple value with priority
resolve_run_multiple() {
    local yaml_default=$1
    local xml_value=$2
    local cli_arg=$3

    # Priority: CLI > XML > YAML > Default (false)
    if [ -n "$cli_arg" ] && [ "$cli_arg" != "null" ]; then
        echo "$cli_arg"
    elif [ -n "$xml_value" ] && [ "$xml_value" != "null" ] && [ "$xml_value" != "" ]; then
        echo "$xml_value"
    elif [ -n "$yaml_default" ] && [ "$yaml_default" != "null" ]; then
        echo "$yaml_default"
    else
        echo "false"
    fi
}

# Determine timeout value with priority
resolve_timeout() {
    local yaml_default=$1
    local xml_value=$2
    local cli_arg=$3
    local system_default=$4

    if [ -n "$cli_arg" ] && [ "$cli_arg" != "null" ]; then
        echo "$cli_arg"
    elif [ -n "$xml_value" ] && [ "$xml_value" != "null" ] && [ "$xml_value" != "" ]; then
        echo "$xml_value"
    elif [ -n "$yaml_default" ] && [ "$yaml_default" != "null" ]; then
        echo "$yaml_default"
    else
        echo "${system_default:-300}"
    fi
}

# Determine temperature value with priority
resolve_temperature() {
    local yaml_default=$1
    local xml_value=$2
    local cli_arg=$3

    if [ -n "$cli_arg" ] && [ "$cli_arg" != "null" ]; then
        echo "$cli_arg"
    elif [ -n "$xml_value" ] && [ "$xml_value" != "null" ] && [ "$xml_value" != "" ]; then
        echo "$xml_value"
    elif [ -n "$yaml_default" ] && [ "$yaml_default" != "null" ]; then
        echo "$yaml_default"
    else
        echo "0.7"
    fi
}

# Determine max_tokens value with priority
resolve_max_tokens() {
    local yaml_default=$1
    local xml_value=$2
    local cli_arg=$3

    if [ -n "$cli_arg" ] && [ "$cli_arg" != "null" ]; then
        echo "$cli_arg"
    elif [ -n "$xml_value" ] && [ "$xml_value" != "null" ] && [ "$xml_value" != "" ]; then
        echo "$xml_value"
    elif [ -n "$yaml_default" ] && [ "$yaml_default" != "null" ]; then
        echo "$yaml_default"
    else
        echo "2000"
    fi
}

# Generic resolve function
resolve_value() {
    local cli_arg=$1
    local xml_value=$2
    local yaml_default=$3
    local system_default=$4

    # Priority: CLI > XML > YAML > Default
    if [ -n "$cli_arg" ] && [ "$cli_arg" != "null" ]; then
        echo "$cli_arg"
    elif [ -n "$xml_value" ] && [ "$xml_value" != "null" ] && [ "$xml_value" != "" ]; then
        echo "$xml_value"
    elif [ -n "$yaml_default" ] && [ "$yaml_default" != "null" ]; then
        echo "$yaml_default"
    else
        echo "$system_default"
    fi
}

# Convert boolean string to true/false
normalize_boolean() {
    local value=$(echo "$1" | tr '[:upper:]' '[:lower:]')

    case "$value" in
        true|yes|1|y)
            echo "true"
            ;;
        false|no|0|n|"")
            echo "false"
            ;;
        *)
            echo "false"
            ;;
    esac
}
