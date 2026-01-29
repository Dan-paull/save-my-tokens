#!/bin/bash
# Shows tokens used in the LAST Claude message (any project)

# Get the most recent project activity
latest=$(cat ~/.claude.json | jq -r '[.projects | to_entries[] |
  select(.value.lastTotalInputTokens != null) |
  {
    tokens: ((.value.lastTotalInputTokens // 0) + (.value.lastTotalOutputTokens // 0)),
    path: .key
  }] | sort_by(.tokens) | reverse | .[0]')

tokens=$(echo "$latest" | jq -r '.tokens')
project=$(echo "$latest" | jq -r '.path' | sed 's|.*/||')

echo "Last message: $tokens tokens ($project)"
