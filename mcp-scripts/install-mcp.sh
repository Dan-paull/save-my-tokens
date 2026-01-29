#!/bin/bash
# Save My Tokens Installation Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIRO_CONFIG_DIR="$HOME/.kiro"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Save My Tokens Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create Kiro config directory if it doesn't exist
mkdir -p "$KIRO_CONFIG_DIR"

echo "Adding save-my-tokens MCP server to Kiro CLI..."

# Use kiro-cli command to add MCP server
if command -v kiro-cli &> /dev/null; then
    echo "Using kiro-cli to add MCP server..."
    kiro-cli mcp add --name save-my-tokens --command node --args "$SCRIPT_DIR/mcp-server.js" --scope global
    echo "✓ Save My Tokens server added via kiro-cli"
else
    echo "kiro-cli not found in PATH. Adding manually to configuration..."
    
    # Create the configuration manually
    cat > "$KIRO_CONFIG_DIR/mcp_servers.json" << EOF
{
  "save-my-tokens": {
    "command": "node",
    "args": ["$SCRIPT_DIR/mcp-server.js"],
    "env": {}
  }
}
EOF
    echo "✓ Save My Tokens server added to manual configuration"
fi

echo ""
echo "Configuration directory: $KIRO_CONFIG_DIR"
echo "MCP server path: $SCRIPT_DIR/mcp-server.js"
echo ""
echo "Available tools:"
echo "  • mcp__save_my_tokens__research     - Multi-model research"
echo "  • mcp__save_my_tokens__coding       - Code generation"
echo "  • mcp__save_my_tokens__planning     - Architecture planning"
echo "  • mcp__save_my_tokens__code_review  - Code review and analysis"
echo ""
echo "Restart Kiro CLI to load the new MCP server."
