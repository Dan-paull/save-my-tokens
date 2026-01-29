#!/bin/bash
# YAML to JSON converter for task files

# Convert YAML file to JSON
yaml_to_json() {
    local yaml_file=$1
    local json_file=$2
    
    if [ ! -f "$yaml_file" ]; then
        echo "ERROR: YAML file not found: $yaml_file" >&2
        return 1
    fi
    
    # Convert using yq
    if command -v yq >/dev/null 2>&1; then
        yq eval -o=json "$yaml_file" > "$json_file"
        return $?
    else
        echo "ERROR: yq not found. Install with: brew install yq" >&2
        return 1
    fi
}

# Get JSON file path for a task, converting from YAML if needed
get_task_json() {
    local task_name=$1
    local tasks_dir=$2
    
    local yaml_file="$tasks_dir/${task_name}.yaml"
    local json_file="$tasks_dir/${task_name}.json"
    
    # If YAML exists and JSON doesn't exist or is older, convert
    if [ -f "$yaml_file" ]; then
        if [ ! -f "$json_file" ] || [ "$yaml_file" -nt "$json_file" ]; then
            yaml_to_json "$yaml_file" "$json_file"
            if [ $? -eq 0 ]; then
                echo "$json_file"
                return 0
            else
                return 1
            fi
        else
            echo "$json_file"
            return 0
        fi
    elif [ -f "$json_file" ]; then
        echo "$json_file"
        return 0
    else
        echo "ERROR: No task file found for: $task_name" >&2
        return 1
    fi
}
