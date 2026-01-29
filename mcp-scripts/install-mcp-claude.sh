#!/bin/bash
# Save My Tokens Installation Script for Claude Code CLI

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_CONFIG_FILE="$HOME/.claude.json"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Save My Tokens Installation for Claude Code"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Claude Code is installed
if ! command -v claude &> /dev/null; then
    echo "⚠️  Warning: claude command not found in PATH"
    echo "   This script will update the config file, but Claude Code may not be installed."
    echo ""
fi

# Check if .claude.json exists
if [ ! -f "$CLAUDE_CONFIG_FILE" ]; then
    echo "Creating new .claude.json file..."
    cat > "$CLAUDE_CONFIG_FILE" << 'EOF'
{
  "mcpServers": {}
}
EOF
fi

echo "Adding save-my-tokens MCP server to Claude Code..."

# Use Node.js to safely update the JSON configuration
CLAUDE_CONFIG_FILE="$CLAUDE_CONFIG_FILE" SCRIPT_DIR="$SCRIPT_DIR" node << 'NODEJS_SCRIPT'
const fs = require('fs');
const path = require('path');

const configFile = process.env.CLAUDE_CONFIG_FILE;
const scriptDir = process.env.SCRIPT_DIR;
const mcpServerPath = path.join(scriptDir, 'mcp-server.js');

try {
  // Read existing config
  let config = {};
  if (fs.existsSync(configFile)) {
    const content = fs.readFileSync(configFile, 'utf8');
    config = JSON.parse(content);
  }

  // Ensure mcpServers object exists
  if (!config.mcpServers) {
    config.mcpServers = {};
  }

  // Add or update save-my-tokens server
  config.mcpServers['save-my-tokens'] = {
    type: 'stdio',
    command: 'node',
    args: [mcpServerPath]
  };

  // Write updated config
  fs.writeFileSync(configFile, JSON.stringify(config, null, 2) + '\n');

  console.log('✓ Save My Tokens server added to Claude Code configuration');
} catch (error) {
  console.error('✗ Error updating configuration:', error.message);
  process.exit(1);
}
NODEJS_SCRIPT

echo ""
echo "Configuration file: $CLAUDE_CONFIG_FILE"
echo "MCP server path: $SCRIPT_DIR/mcp-server.js"
echo ""
echo "Available tools in Claude Code:"
echo "  • mcp__save_my_tokens__research     - Multi-model research"
echo "  • mcp__save_my_tokens__coding       - Code generation"
echo "  • mcp__save_my_tokens__planning     - Architecture planning"
echo "  • mcp__save_my_tokens__code_review  - Code review and analysis"
echo ""
echo "Restart Claude Code to load the new MCP server."
echo ""
echo "To verify installation:"
echo "  claude mcp list"
echo ""
