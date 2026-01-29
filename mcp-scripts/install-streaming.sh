#!/bin/bash
# Install Streaming MCP Server with Real Agent Progress

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCP_SERVER_PATH="$SCRIPT_DIR/mcp-server-streaming.js"
CONFIG_FILE="$HOME/.claude.json"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Save My Tokens Streaming MCP Server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This installs the streaming version with REAL agent progress:"
echo "  🎯 Task start/complete messages"
echo "  🧠 Model allocation updates"
echo "  🚀 Individual model start/complete"
echo "  📡 API call progress"
echo "  ⏳ Waiting indicators"
echo "  📥 Response received with size/tokens"
echo "  ⚡ Cache hit/miss notifications"
echo "  ✅ Success with timing"
echo "  ❌ Failures with details"
echo ""

# Check if server exists
if [ ! -f "$MCP_SERVER_PATH" ]; then
    echo "❌ Error: mcp-server-streaming.js not found"
    exit 1
fi

# Make executable
chmod +x "$MCP_SERVER_PATH"

# Update config
echo "Updating Claude Code configuration..."

CONFIG_FILE="$CONFIG_FILE" MCP_SERVER_PATH="$MCP_SERVER_PATH" node << 'NODEJS_SCRIPT'
const fs = require('fs');

const configFile = process.env.CONFIG_FILE;
const mcpServerPath = process.env.MCP_SERVER_PATH;

try {
  let config = JSON.parse(fs.readFileSync(configFile, 'utf8'));

  if (!config.mcpServers) {
    config.mcpServers = {};
  }

  config.mcpServers['save-my-tokens'] = {
    type: 'stdio',
    command: 'node',
    args: [mcpServerPath],
    env: {
      SAVE_MY_TOKENS_TIMEOUT: '300000',
      SAVE_MY_TOKENS_PROGRESS_INTERVAL: '5000'
    }
  };

  fs.writeFileSync(configFile, JSON.stringify(config, null, 2) + '\n');
  console.log('✅ Configuration updated');
} catch (error) {
  console.error('❌ Error:', error.message);
  process.exit(1);
}
NODEJS_SCRIPT

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Server: $MCP_SERVER_PATH"
echo "Config: $CONFIG_FILE"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code:"
echo "     pkill -f 'claude --'"
echo ""
echo "  2. Test with a research task:"
echo "     Use research tool with prompt=\"test\""
echo ""
echo "  3. Watch for real-time progress:"
echo "     🎯 Processing research request"
echo "     🧠 Selected 2 models: cerebras, mistral"
echo "     🚀 Starting: cerebras/llama-3.3-70b"
echo "     📡 Sending request to cerebras API"
echo "     ⏳ Waiting for response..."
echo "     📥 Received 15KB, 1234 tokens in 3s"
echo "     ✅ Completed: cerebras/llama-3.3-70b (3s)"
echo ""
echo "  4. Check logs:"
echo "     tail -f $SCRIPT_DIR/../logs/mcp-server.log | jq ."
echo ""
