#!/bin/bash
# XML utilities for save-my-tokens
# Functions to build and parse XML (macOS compatible)

# Extract XML tag value (works with BSD sed)
extract_xml() {
    local tag=$1
    local content=$2

    # Try to extract content between tags
    echo "$content" | sed -n "s/.*<${tag}>\(.*\)<\/${tag}>.*/\1/p" | head -n 1
}

# Extract XML tag with multiline content
extract_xml_multiline() {
    local tag=$1
    local content=$2

    # Extract content between tags (including newlines)
    echo "$content" | sed -n "/<${tag}>/,/<\/${tag}>/p" | sed "1d;\$d"
}

# Build task request XML
build_task_request_xml() {
    local prompt=$1
    local context=$2
    local run_multiple=$3
    local timeout=$4
    local temperature=$5
    local max_tokens=$6

    cat <<EOF
<task-request>
  <prompt>$prompt</prompt>
EOF

    [ -n "$context" ] && echo "  <context>$context</context>"
    [ -n "$run_multiple" ] && echo "  <run-multiple>$run_multiple</run-multiple>"
    [ -n "$timeout" ] && echo "  <timeout>$timeout</timeout>"

    if [ -n "$temperature" ] || [ -n "$max_tokens" ]; then
        echo "  <parameters>"
        [ -n "$temperature" ] && echo "    <temperature>$temperature</temperature>"
        [ -n "$max_tokens" ] && echo "    <max-tokens>$max_tokens</max-tokens>"
        echo "  </parameters>"
    fi

    echo "</task-request>"
}

# Build agent result XML (success)
build_result_xml() {
    local agent=$1
    local model=$2
    local task=$3
    local task_type=$4
    local run_multiple=$5
    local status=$6
    local output=$7
    local usage=$8

    cat <<EOF
<agent-result>
  <agent>$agent</agent>
  <model>$model</model>
  <task>$task</task>
  <task-type>$task_type</task-type>
  <run-multiple>$run_multiple</run-multiple>
  <status>$status</status>
  <output>
$output
  </output>
  <usage>$usage</usage>
  <timestamp>$(date -u +"%Y-%m-%dT%H:%M:%SZ")</timestamp>
</agent-result>
EOF
}

# Build error result XML
build_error_xml() {
    local task=$1
    local task_type=$2
    local error_msg=$3
    local details=$4

    cat <<EOF
<agent-result>
  <agent>save-my-tokens-router</agent>
  <task>$task</task>
  <task-type>$task_type</task-type>
  <status>error</status>
  <error>$error_msg</error>
  <output>
$details
  </output>
  <timestamp>$(date -u +"%Y-%m-%dT%H:%M:%SZ")</timestamp>
</agent-result>
EOF
}

# Build multi-model result XML
build_multimodel_result_xml() {
    local task=$1
    local task_type=$2
    local run_multiple=$3
    local combined_output=$4
    local models_used=$5

    cat <<EOF
<agent-result>
  <agent>save-my-tokens-router</agent>
  <task>$task</task>
  <task-type>$task_type</task-type>
  <run-multiple>$run_multiple</run-multiple>
  <status>completed</status>
  <output>
$combined_output
  </output>
  <models-used>
$models_used
  </models-used>
  <timestamp>$(date -u +"%Y-%m-%dT%H:%M:%SZ")</timestamp>
</agent-result>
EOF
}

# Parse provider output for key fields
parse_provider_output() {
    local output=$1

    # Extract key fields
    local status=$(extract_xml "status" "$output")
    local agent=$(extract_xml "agent" "$output")
    local model=$(extract_xml "model" "$output")
    local response=$(extract_xml_multiline "output" "$output")
    local usage=$(extract_xml "usage" "$output")

    # Return as pipe-separated values
    echo "$status|$agent|$model|$response|$usage"
}

# Escape XML special characters
xml_escape() {
    local text=$1
    echo "$text" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g' -e "s/'/\&apos;/g"
}
