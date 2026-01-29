#!/bin/bash
# Task executor for save-my-tokens
# Handles both cascade (sequential) and parallel execution

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/xml-utils.sh"
source "$SCRIPT_DIR/lib/yaml-parser.sh"
source "$SCRIPT_DIR/lib/cache.sh"

# Execute single model
execute_model() {
    local config_file=$1
    local task_file=$2
    local model_index=$3
    local input_xml=$4
    local cache_enabled=$5
    local cache_ttl=$6
    local task_name=$7

    # Get model details
    local platform=$(yaml_get_model_details "$task_file" "$model_index" "platform")
    local model=$(yaml_get_model_details "$task_file" "$model_index" "model")
    local name=$(yaml_get_model_details "$task_file" "$model_index" "name")
    local provider=$(yaml_get_model_details "$task_file" "$model_index" "provider")

    # Use platform as provider if not specified
    [ -z "$provider" ] || [ "$provider" = "null" ] && provider="$platform"

    log_info "executor" "Trying $name ($platform/$model)..."
    echo "[AGENT-PROGRESS] model-start: ${platform}/${model}" >&2

    # Check cache if enabled
    if [ "$cache_enabled" = "true" ]; then
        echo "[AGENT-PROGRESS] cache: Checking cache for ${platform}/${model}" >&2
        local prompt=$(extract_xml "prompt" "$input_xml")
        
        # Test cache_get return code first
        cache_get "$task_name" "$prompt" "$platform/$model" "$cache_ttl" >/dev/null 2>&1
        local cache_result=$?
        
        if [ $cache_result -eq 0 ]; then
            # Now get the actual response
            local cached_response=$(cache_get "$task_name" "$prompt" "$platform/$model" "$cache_ttl")
            echo "[AGENT-PROGRESS] cache-hit: Using cached result for ${platform}/${model}" >&2
            log_success "executor" "$name succeeded (cached)"
            local cached_output=$(echo "$cached_response" | jq -r '.response')
            echo "$cached_output"
            return 0
        else
            echo "[AGENT-PROGRESS] cache-miss: No cached result" >&2
        fi
    fi

    # Determine provider wrapper
    local wrapper="$SCRIPT_DIR/providers/wrappers/${provider}.sh"

    if [ ! -f "$wrapper" ]; then
        log_error "executor" "Provider wrapper not found: $wrapper"
        return 1
    fi

    # Execute provider
    echo "[AGENT-PROGRESS] model-call: Sending request to ${platform} API" >&2
    local start_time=$(date +%s)
    local output=$(echo "$input_xml" | "$wrapper" 2>&1)
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Check if successful
    if [ $exit_code -eq 0 ] && echo "$output" | grep -q "<status>completed</status>"; then
        echo "[AGENT-PROGRESS] model-complete: ${platform}/${model} (${duration}s)" >&2
        log_success "executor" "$name succeeded"

        # Cache response if enabled
        if [ "$cache_enabled" = "true" ]; then
            local prompt=$(extract_xml "prompt" "$input_xml")
            local usage=$(extract_xml "usage" "$output")
            local tokens=$(echo "$usage" | grep -oE '[0-9]+' | tail -1)
            cache_put "$task_name" "$prompt" "$platform/$model" "$output" "${tokens:-0}" "$cache_ttl"
        fi

        echo "$output"
        return 0
    else
        # Extract error
        local error=$(echo "$output" | grep -i "error" | head -n 1 || echo "Unknown error")
        echo "[AGENT-PROGRESS] model-fail: ${platform}/${model}: ${error}" >&2
        log_failure "executor" "$name failed: $error"
        return 1
    fi
}

# Execute cascade (sequential failover)
execute_cascade() {
    local config_file=$1
    local task_file=$2
    local available_models=$3
    local input_xml=$4
    local cache_enabled=$5
    local cache_ttl=$6
    local task_name=$7

    local attempt=1
    local total_models=$(echo "$available_models" | wc -w | tr -d ' ')

    log_info "executor" "Cascade mode: trying $total_models models sequentially"

    for model_index in $available_models; do
        log_info "executor" "Attempt $attempt of $total_models"

        local output
        if output=$(execute_model "$config_file" "$task_file" "$model_index" "$input_xml" "$cache_enabled" "$cache_ttl" "$task_name"); then
            echo "$output"
            return 0
        fi

        attempt=$((attempt + 1))
    done

    log_error "executor" "All models failed in cascade"
    return 1
}

# Execute parallel (multiple models)
execute_parallel() {
    local config_file=$1
    local task_file=$2
    local available_models=$3
    local input_xml=$4
    local cache_enabled=$5
    local cache_ttl=$6
    local task_name=$7
    local max_parallel=$8

    local tmp_dir=$(mktemp -d)
    local pids=()
    local model_names=()
    local results=()

    log_info "executor" "Parallel mode: running up to $max_parallel models simultaneously"

    # Start models in parallel
    local count=0
    for model_index in $available_models; do
        if [ "$count" -ge "$max_parallel" ]; then
            break
        fi

        local name=$(yaml_get_model_details "$task_file" "$model_index" "name")
        local output_file="$tmp_dir/$model_index.out"

        # Execute in background
        (execute_model "$config_file" "$task_file" "$model_index" "$input_xml" "$cache_enabled" "$cache_ttl" "$task_name" > "$output_file" 2>&1) &
        pids+=($!)
        model_names+=("$name")
        results+=("$output_file")

        count=$((count + 1))
    done

    log_info "executor" "Started $count models in parallel, waiting for completion..."

    # Wait for all to complete
    for pid in "${pids[@]}"; do
        wait "$pid"
    done

    # Collect successful results
    local successful_results=()
    local successful_models=()
    local failed_models=()

    for i in "${!results[@]}"; do
        local output_file="${results[$i]}"
        local name="${model_names[$i]}"

        if [ -f "$output_file" ] && [ -s "$output_file" ]; then
            local output=$(cat "$output_file")
            if echo "$output" | grep -q "<status>completed</status>"; then
                successful_results+=("$output")
                successful_models+=("$name")
                log_success "executor" "$name completed"
            else
                failed_models+=("$name")
                log_failure "executor" "$name failed"
            fi
        else
            failed_models+=("$name")
            log_failure "executor" "$name produced no output"
        fi
    done

    # Clean up
    rm -rf "$tmp_dir"

    # Check if we have any successful results
    if [ ${#successful_results[@]} -eq 0 ]; then
        log_error "executor" "All parallel models failed"
        return 1
    fi

    log_info "executor" "Collected ${#successful_results[@]} successful responses"

    # Combine results
    local combined_output=""
    combined_output+="=== Multiple Model Perspectives ===\n\n"

    for i in "${!successful_results[@]}"; do
        local model_name="${successful_models[$i]}"
        local output="${successful_results[$i]}"

        # Extract agent and model info
        local agent=$(extract_xml "agent" "$output")
        local model=$(extract_xml "model" "$output")
        local response=$(extract_xml_multiline "output" "$output")

        combined_output+="Model $((i+1)) ($agent/$model) Response:\n"
        combined_output+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        combined_output+="$response\n"
        combined_output+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
    done

    combined_output+="=== Summary: ${#successful_results[@]} models provided perspectives ===\n"

    if [ ${#failed_models[@]} -gt 0 ]; then
        combined_output+="\nFailed Models: ${failed_models[*]}\n"
    fi

    echo "$combined_output"
    return 0
}
