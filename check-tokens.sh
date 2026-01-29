#!/bin/bash

# Simple token counter for Claude Code
# Shows current total token usage

PROJECT_PATH="${1:-/Users/danpaull/Documents/code_tests/free-offload-cli}"
CLAUDE_CONFIG="$HOME/.claude.json"

if [ ! -f "$CLAUDE_CONFIG" ]; then
    echo "Error: Claude config not found"
    exit 1
fi

# Get cumulative stats for the project
stats=$(cat "$CLAUDE_CONFIG" | jq -r ".projects[\"$PROJECT_PATH\"]")

if [ "$stats" = "null" ]; then
    echo "No stats found for: $PROJECT_PATH"
    echo "Try: $0 /path/to/your/project"
    exit 1
fi

# Extract cumulative totals
input=$(echo "$stats" | jq -r '.lastTotalInputTokens // 0')
output=$(echo "$stats" | jq -r '.lastTotalOutputTokens // 0')
cache_read=$(echo "$stats" | jq -r '.lastTotalCacheReadInputTokens // 0')
cache_create=$(echo "$stats" | jq -r '.lastTotalCacheCreationInputTokens // 0')
cost=$(echo "$stats" | jq -r '.lastCost // 0')

# Calculate total tokens (what actually matters for usage)
total=$((input + output + cache_create))

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Claude Token Usage (Last Operation)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Input tokens:      $input"
echo "Output tokens:     $output"
echo "Cache read:        $cache_read"
echo "Cache create:      $cache_create"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total tokens:      $total"
echo "Cost (USD):        \$$cost"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Project: $PROJECT_PATH"
