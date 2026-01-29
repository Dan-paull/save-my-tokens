#!/bin/bash
# Cerebras LLM Provider Wrapper
# Standardized interface for save-my-tokens router

set -euo pipefail

# Source environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [ -f "$SCRIPT_DIR/.env.savemytokens" ]; then
    set -a
    source "$SCRIPT_DIR/.env.savemytokens"
    set +a
fi

# Extract XML values (BSD sed compatible)
extract_xml() {
    local tag=$1
    local content=$2
    echo "$content" | sed -n "s/.*<${tag}>\(.*\)<\/${tag}>.*/\1/p" | head -n 1
}

extract_xml_multiline() {
    local tag=$1
    local content=$2
    echo "$content" | sed -n "/<${tag}>/,/<\/${tag}>/p" | sed "1d;\$d"
}

# Read task request from stdin
INPUT_XML=$(cat)

# Parse input
PROMPT=$(extract_xml "prompt" "$INPUT_XML")
if [ -z "$PROMPT" ]; then
    PROMPT=$(extract_xml_multiline "prompt" "$INPUT_XML")
fi
CONTEXT=$(extract_xml "context" "$INPUT_XML")
TEMPERATURE=$(extract_xml "temperature" "$INPUT_XML")
MAX_TOKENS=$(extract_xml "max-tokens" "$INPUT_XML")

# Defaults
TEMPERATURE=${TEMPERATURE:-0.7}
MAX_TOKENS=${MAX_TOKENS:-2000}
MODEL="${CEREBRAS_MODEL:-llama-3.3-70b}"

# Check for API key
if [ -z "${CEREBRAS_API_KEY:-}" ]; then
    echo "ERROR: CEREBRAS_API_KEY not set" >&2
    exit 1
fi

# Build full prompt
FULL_PROMPT="$PROMPT"
[ -n "$CONTEXT" ] && FULL_PROMPT="Context: $CONTEXT\n\n$FULL_PROMPT"

# Log
echo "[cerebras] Processing task with model: $MODEL" >&2

# Create temporary file for output
OUTPUT_FILE=$(mktemp)
trap "rm -f $OUTPUT_FILE" EXIT

# Build JSON request
REQUEST_JSON=$(jq -n \
    --arg model "$MODEL" \
    --arg prompt "$FULL_PROMPT" \
    --argjson temp "$TEMPERATURE" \
    --argjson max_tokens "$MAX_TOKENS" \
    '{
        model: $model,
        messages: [
            {
                role: "user",
                content: $prompt
            }
        ],
        temperature: $temp,
        max_tokens: $max_tokens
    }')

# Call Cerebras API
echo "[AGENT-PROGRESS] model-wait: Waiting for Cerebras API response..." >&2
START_TIME=$(date +%s)
HTTP_CODE=$(curl -s -w "%{http_code}" -o "$OUTPUT_FILE" \
    -X POST "https://api.cerebras.ai/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $CEREBRAS_API_KEY" \
    -d "$REQUEST_JSON")
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Check HTTP status
if [ "$HTTP_CODE" != "200" ]; then
    echo "ERROR: Cerebras API request failed with HTTP $HTTP_CODE" >&2
    cat "$OUTPUT_FILE" >&2
    exit 1
fi

# Extract response
RESPONSE_CONTENT=$(jq -r '.choices[0].message.content // empty' "$OUTPUT_FILE")

if [ -z "$RESPONSE_CONTENT" ]; then
    echo "ERROR: No valid response from Cerebras API" >&2
    cat "$OUTPUT_FILE" >&2
    exit 1
fi

# Get usage info
PROMPT_TOKENS=$(jq -r '.usage.prompt_tokens // 0' "$OUTPUT_FILE")
COMPLETION_TOKENS=$(jq -r '.usage.completion_tokens // 0' "$OUTPUT_FILE")
TOTAL_TOKENS=$(jq -r '.usage.total_tokens // 0' "$OUTPUT_FILE")
RESPONSE_SIZE=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')
echo "[AGENT-PROGRESS] model-receive: Received ${RESPONSE_SIZE} bytes, ${TOTAL_TOKENS} tokens in ${DURATION}s" >&2
USAGE="Prompt: $PROMPT_TOKENS | Completion: $COMPLETION_TOKENS | Total: $TOTAL_TOKENS"

# Output result in standard XML format
cat <<EOF
<agent-result>
  <agent>cerebras</agent>
  <model>$MODEL</model>
  <status>completed</status>
  <output>
$RESPONSE_CONTENT
  </output>
  <usage>$USAGE</usage>
  <timestamp>$(date -u +"%Y-%m-%dT%H:%M:%SZ")</timestamp>
</agent-result>
EOF

echo "[cerebras] Task completed successfully" >&2
