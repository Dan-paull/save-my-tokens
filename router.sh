#!/bin/bash
# Save My Tokens Router
# Main entry point for all agent tasks

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/xml-utils.sh"
source "$SCRIPT_DIR/lib/yaml-parser.sh"
source "$SCRIPT_DIR/lib/override.sh"
source "$SCRIPT_DIR/lib/model-filter.sh"
source "$SCRIPT_DIR/lib/cache.sh"
source "$SCRIPT_DIR/lib/task-executor.sh"
source "$SCRIPT_DIR/lib/yaml-to-json.sh"

# Load environment variables
if [ -f "$SCRIPT_DIR/.env.savemytokens" ]; then
    set -a
    source "$SCRIPT_DIR/.env.savemytokens"
    set +a
fi

# Configuration
CONFIG_FILE="$SCRIPT_DIR/config.json"
TASKS_DIR="$SCRIPT_DIR/tasks"

# Parse CLI arguments
parse_args() {
    TASK_NAME=""
    PROMPT=""
    CONTEXT=""
    RUN_MULTIPLE_CLI=""
    TIMEOUT_CLI=""
    MAX_TOKENS_CLI=""
    TEMPERATURE_CLI=""
    CACHE_BUST=false
    DEBUG=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --task)
                TASK_NAME="$2"
                shift 2
                ;;
            --prompt)
                PROMPT="$2"
                shift 2
                ;;
            --context)
                CONTEXT="$2"
                shift 2
                ;;
            --run-multiple)
                RUN_MULTIPLE_CLI="$2"
                shift 2
                ;;
            --timeout)
                TIMEOUT_CLI="$2"
                shift 2
                ;;
            --max-tokens)
                MAX_TOKENS_CLI="$2"
                shift 2
                ;;
            --temperature)
                TEMPERATURE_CLI="$2"
                shift 2
                ;;
            --cache-bust)
                CACHE_BUST=true
                shift
                ;;
            --debug)
                DEBUG=true
                LOG_LEVEL="debug"
                shift
                ;;
            --list-tasks)
                list_tasks
                exit 0
                ;;
            --validate)
                validate_config
                exit $?
                ;;
            --status)
                show_status
                exit 0
                ;;
            --clear-cache)
                cache_clear_all
                exit 0
                ;;
            --version)
                echo "Save My Tokens Router v1.0.0"
                exit 0
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help
show_help() {
    cat <<EOF
Save My Tokens Router - Unified entry point for LLM agent tasks

Usage:
  ./router.sh --task <task-name> --prompt <prompt> [options]
  echo '<task-request>...</task-request>' | ./router.sh --task <task-name>

Required:
  --task <name>         Task to execute (research, coding, code-review, etc.)
  --prompt <text>       Task prompt (or provide via XML stdin)

Optional:
  --context <text>      Additional context
  --run-multiple <bool> Override run_multiple setting (true/false)
  --timeout <seconds>   Override timeout
  --max-tokens <n>      Override max_tokens
  --temperature <n>     Override temperature
  --cache-bust          Bypass cache
  --debug               Enable debug logging

Utility Commands:
  --list-tasks          List all available tasks
  --validate            Validate configuration
  --status              Show platform status
  --clear-cache         Clear all cached responses
  --version             Show version
  --help                Show this help

Examples:
  # Run research task
  ./router.sh --task research --prompt "Find info about AI"

  # Override run_multiple
  ./router.sh --task research --prompt "Quick question" --run-multiple false

  # Via XML stdin
  cat <<'XML' | ./router.sh --task research
  <task-request>
    <prompt>Research topic</prompt>
    <context>Additional context</context>
  </task-request>
  XML

  # List available tasks
  ./router.sh --list-tasks

Documentation: See README.md in save-my-tokens/ directory
EOF
}

# List all available tasks
list_tasks() {
    echo "Available tasks:"
    echo ""

    # Get all task names from both YAML and JSON files
    local tasks=()
    for file in "$TASKS_DIR"/*.yaml "$TASKS_DIR"/*.json; do
        if [ -f "$file" ]; then
            local basename=$(basename "$file")
            local task_name="${basename%.*}"
            # Avoid duplicates
            local found=false
            if [ ${#tasks[@]} -gt 0 ]; then
                for existing in "${tasks[@]}"; do
                    if [ "$existing" = "$task_name" ]; then
                        found=true
                        break
                    fi
                done
            fi
            if [ "$found" = false ]; then
                tasks+=("$task_name")
            fi
        fi
    done

    # Sort and display tasks
    for task_name in $(printf '%s\n' "${tasks[@]}" | sort); do
        local task_json=$(get_task_json "$task_name" "$TASKS_DIR")
        if [ $? -eq 0 ] && [ -f "$task_json" ]; then
            local task=$(yaml_get "$task_json" ".task")
            local description=$(yaml_get "$task_json" ".description")
            local task_type=$(yaml_get "$task_json" ".task_type")
            printf "  %-15s [%-11s] %s\n" "$task" "$task_type" "$description"
        fi
    done
}

# Validate configuration
validate_config() {
    echo "Validating configuration..."

    # Check config.json
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "✗ config.json not found"
        return 1
    fi

    if ! yaml_validate "$CONFIG_FILE"; then
        echo "✗ config.json is invalid"
        return 1
    fi
    echo "✓ config.json is valid"

    # Check task files
    local invalid_count=0
    for task_file in "$TASKS_DIR"/*.json; do
        if [ -f "$task_file" ]; then
            local task=$(basename "$task_file" .json)
            if yaml_validate "$task_file"; then
                echo "✓ $task.json is valid"
            else
                echo "✗ $task.json is invalid"
                invalid_count=$((invalid_count + 1))
            fi
        fi
    done

    if [ $invalid_count -eq 0 ]; then
        echo ""
        echo "All configuration files are valid"
        return 0
    else
        echo ""
        echo "$invalid_count configuration file(s) are invalid"
        return 1
    fi
}

# Show platform status
show_status() {
    echo "Platform Status:"
    echo ""
    generate_platform_report "$CONFIG_FILE"
    echo ""
    cache_stats
}

# Main execution function
main() {
    parse_args "$@"

    # Check if reading from stdin
    if [ -t 0 ]; then
        # Not from pipe, need CLI args
        if [ -z "$TASK_NAME" ] || [ -z "$PROMPT" ]; then
            echo "ERROR: --task and --prompt are required when not using stdin" >&2
            echo "Try: ./router.sh --help" >&2
            exit 1
        fi
    else
        # Reading from stdin
        INPUT_XML=$(cat)

        # Extract prompt and other fields from XML if not provided via CLI
        [ -z "$PROMPT" ] && PROMPT=$(extract_xml "prompt" "$INPUT_XML")
        [ -z "$CONTEXT" ] && CONTEXT=$(extract_xml "context" "$INPUT_XML")

        # Extract override values from XML
        XML_RUN_MULTIPLE=$(extract_xml "run-multiple" "$INPUT_XML")
        XML_TIMEOUT=$(extract_xml "timeout" "$INPUT_XML")
        XML_MAX_TOKENS=$(extract_xml "max-tokens" "$INPUT_XML")
        XML_TEMPERATURE=$(extract_xml "temperature" "$INPUT_XML")
    fi

    # Validate task name
    if [ -z "$TASK_NAME" ]; then
        echo "ERROR: Task name is required" >&2
        exit 1
    fi

    # Find task file (YAML preferred, auto-convert to JSON)
    TASK_FILE=$(get_task_json "$TASK_NAME" "$TASKS_DIR")
    if [ $? -ne 0 ] || [ ! -f "$TASK_FILE" ]; then
        echo "ERROR: Task not found: $TASK_NAME" >&2
        echo "Available tasks:" >&2
        list_tasks >&2
        exit 1
    fi

    log_info "router" "Starting task: $TASK_NAME"

    # Agent progress: Task started
    echo "[AGENT-PROGRESS] task-start: Processing ${TASK_NAME} request" >&2

    # Validate configurations
    if ! yaml_validate "$CONFIG_FILE"; then
        echo "ERROR: Invalid config.json" >&2
        exit 1
    fi

    if ! yaml_validate "$TASK_FILE"; then
        echo "ERROR: Invalid task JSON file: $TASK_FILE" >&2
        exit 1
    fi

    # Load task configuration
    echo "[AGENT-PROGRESS] allocation: Loading task configuration" >&2
    TASK_TYPE=$(yaml_get "$TASK_FILE" ".task_type")
    YAML_RUN_MULTIPLE=$(yaml_get "$TASK_FILE" ".run_multiple")
    YAML_TIMEOUT=$(yaml_get "$TASK_FILE" ".timeout")

    # Load global settings
    CACHE_ENABLED=$(yaml_get_setting "$CONFIG_FILE" "cache_enabled")
    CACHE_TTL=$(yaml_get_setting "$CONFIG_FILE" "cache_ttl")
    MAX_PARALLEL=$(yaml_get_setting "$CONFIG_FILE" "max_parallel_models")
    DEFAULT_TIMEOUT=$(yaml_get_setting "$CONFIG_FILE" "default_timeout")

    # Disable cache if cache-bust flag set
    [ "$CACHE_BUST" = "true" ] && CACHE_ENABLED="false"

    # Disable cache for execute tasks
    [ "$TASK_TYPE" = "execute" ] && CACHE_ENABLED="false"

    # Resolve configuration with priority
    RUN_MULTIPLE=$(resolve_run_multiple "$YAML_RUN_MULTIPLE" "${XML_RUN_MULTIPLE:-}" "$RUN_MULTIPLE_CLI")
    RUN_MULTIPLE=$(normalize_boolean "$RUN_MULTIPLE")
    TIMEOUT=$(resolve_timeout "$YAML_TIMEOUT" "${XML_TIMEOUT:-}" "$TIMEOUT_CLI" "$DEFAULT_TIMEOUT")

    log_info "router" "Task type: $TASK_TYPE"
    log_info "router" "Run multiple: $RUN_MULTIPLE"
    log_info "router" "Cache enabled: $CACHE_ENABLED"

    # Filter available models
    echo "[AGENT-PROGRESS] allocation: Analyzing available models" >&2
    AVAILABLE_MODELS=$(filter_available_models "$CONFIG_FILE" "$TASK_FILE")
    AVAILABLE_COUNT=$(echo "$AVAILABLE_MODELS" | wc -w | tr -d ' ')

    if [ "$AVAILABLE_COUNT" -eq 0 ]; then
        log_error "router" "No models available for this task"

        # Generate error report
        ERROR_DETAILS="ERROR: No models are currently available for this task.\n\n"
        ERROR_DETAILS+="Platform Status:\n"
        ERROR_DETAILS+="$(generate_platform_report "$CONFIG_FILE")\n\n"
        ERROR_DETAILS+="Action Required:\n"
        ERROR_DETAILS+="1. Enable platforms in config.yaml\n"
        ERROR_DETAILS+="2. Set API keys in .env.savemytokens\n"
        ERROR_DETAILS+="3. Check platform status with: ./router.sh --status"

        build_error_xml "$TASK_NAME" "$TASK_TYPE" "No models available" "$ERROR_DETAILS"
        exit 1
    fi

    log_info "router" "Available models: $AVAILABLE_COUNT"

    # Show selected models
    MODEL_NAMES=""
    for model_index in $AVAILABLE_MODELS; do
        MODEL_NAME=$(yaml_get_model_details "$TASK_FILE" "$model_index" "name")
        MODEL_PLATFORM=$(yaml_get_model_details "$TASK_FILE" "$model_index" "platform")
        [ -n "$MODEL_NAMES" ] && MODEL_NAMES+=", "
        MODEL_NAMES+="${MODEL_PLATFORM}"
    done
    echo "[AGENT-PROGRESS] allocation: Selected ${AVAILABLE_COUNT} models: ${MODEL_NAMES}" >&2

    # Build task request XML
    TASK_REQUEST=$(build_task_request_xml "$PROMPT" "$CONTEXT" "$RUN_MULTIPLE" "$TIMEOUT" "${TEMPERATURE_CLI:-}" "${MAX_TOKENS_CLI:-}")

    # Execute based on mode
    if [ "$RUN_MULTIPLE" = "true" ] && [ "$TASK_TYPE" != "execute" ]; then
        # Parallel execution
        log_info "router" "Executing in parallel mode..."
        echo "[AGENT-PROGRESS] allocation: Mode: parallel (multi-model)" >&2

        OUTPUT=$(execute_parallel "$CONFIG_FILE" "$TASK_FILE" "$AVAILABLE_MODELS" "$TASK_REQUEST" "$CACHE_ENABLED" "$CACHE_TTL" "$TASK_NAME" "$MAX_PARALLEL")

        if [ $? -eq 0 ]; then
            # Build multi-model result
            echo "[AGENT-PROGRESS] results: Collecting responses from multiple models" >&2
            echo "[AGENT-PROGRESS] results: Formatting output" >&2
            build_multimodel_result_xml "$TASK_NAME" "$TASK_TYPE" "$RUN_MULTIPLE" "$OUTPUT" ""
            echo "[AGENT-PROGRESS] task-complete: Success" >&2
            exit 0
        else
            # All parallel models failed
            echo "[AGENT-PROGRESS] task-error: All parallel models failed" >&2
            ERROR_DETAILS="ERROR: All models failed in parallel execution.\n\n"
            ERROR_DETAILS+="$(generate_platform_report "$CONFIG_FILE")\n\n"
            ERROR_DETAILS+="Action: Claude Code should handle this task directly."

            build_error_xml "$TASK_NAME" "$TASK_TYPE" "All parallel models failed" "$ERROR_DETAILS"
            exit 1
        fi
    else
        # Cascade execution
        log_info "router" "Executing in cascade mode..."
        echo "[AGENT-PROGRESS] allocation: Mode: cascade (first-success)" >&2

        OUTPUT=$(execute_cascade "$CONFIG_FILE" "$TASK_FILE" "$AVAILABLE_MODELS" "$TASK_REQUEST" "$CACHE_ENABLED" "$CACHE_TTL" "$TASK_NAME")

        if [ $? -eq 0 ]; then
            # Return provider output directly
            echo "[AGENT-PROGRESS] task-complete: Success" >&2
            echo "$OUTPUT"
            exit 0
        else
            # All cascade models failed
            echo "[AGENT-PROGRESS] task-error: All cascade models failed" >&2
            ERROR_DETAILS="ERROR: All models failed in cascade execution.\n\n"
            ERROR_DETAILS+="Attempted models (in order):\n"

            local attempt=1
            for model_index in $AVAILABLE_MODELS; do
                local name=$(yaml_get_model_details "$TASK_FILE" "$model_index" "name")
                local platform=$(yaml_get_model_details "$TASK_FILE" "$model_index" "platform")
                ERROR_DETAILS+="$attempt. $name ($platform) - FAILED\n"
                attempt=$((attempt + 1))
            done

            ERROR_DETAILS+="\nPlatform Status:\n"
            ERROR_DETAILS+="$(generate_platform_report "$CONFIG_FILE")\n\n"
            ERROR_DETAILS+="Action: Claude Code should handle this task directly."

            build_error_xml "$TASK_NAME" "$TASK_TYPE" "All cascade models failed" "$ERROR_DETAILS"
            exit 1
        fi
    fi
}

# Run main
main "$@"
