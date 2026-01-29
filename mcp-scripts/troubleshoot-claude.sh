#!/bin/bash
# Troubleshooting script for Save My Tokens in Claude Code

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Save My Tokens Troubleshooting"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Check if .claude.json exists and is valid
echo "1. Checking Claude Code configuration..."
if [ -f ~/.claude.json ]; then
    echo "✓ Configuration file exists at ~/.claude.json"
    if jq empty ~/.claude.json 2>/dev/null; then
        echo "✓ Configuration file is valid JSON"
    else
        echo "✗ Configuration file has JSON syntax errors!"
        jq . ~/.claude.json 2>&1 | head -10
        exit 1
    fi
else
    echo "✗ Configuration file not found at ~/.claude.json"
    exit 1
fi

# 2. Check if save-my-tokens is configured
echo ""
echo "2. Checking save-my-tokens MCP configuration..."
if jq -e '.mcpServers["save-my-tokens"]' ~/.claude.json > /dev/null 2>&1; then
    echo "✓ save-my-tokens MCP server is configured"
    jq '.mcpServers["save-my-tokens"]' ~/.claude.json
else
    echo "✗ save-my-tokens MCP server not found in configuration"
    exit 1
fi

# 3. Check if MCP server file exists
echo ""
echo "3. Checking MCP server file..."
MCP_PATH=$(jq -r '.mcpServers["save-my-tokens"].args[0]' ~/.claude.json)
if [ -f "$MCP_PATH" ]; then
    echo "✓ MCP server file exists at: $MCP_PATH"
else
    echo "✗ MCP server file not found at: $MCP_PATH"
    exit 1
fi

# 4. Check if Node.js is available
echo ""
echo "4. Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "✓ Node.js is available: $NODE_VERSION"
else
    echo "✗ Node.js not found in PATH"
    echo "  Install Node.js from https://nodejs.org/"
    exit 1
fi

# 5. Test MCP server manually
echo ""
echo "5. Testing MCP server..."
INIT_RESPONSE=$(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' | timeout 5 node "$MCP_PATH" 2>&1)

if echo "$INIT_RESPONSE" | grep -q '"protocolVersion":"2024-11-05"'; then
    echo "✓ MCP server responds correctly"
else
    echo "✗ MCP server failed to respond"
    echo "Response:"
    echo "$INIT_RESPONSE" | head -20
    exit 1
fi

# 6. Check if router.sh exists
echo ""
echo "6. Checking Save My Tokens router..."
ROUTER_PATH="$(dirname "$MCP_PATH")/../router.sh"
if [ -f "$ROUTER_PATH" ]; then
    echo "✓ router.sh exists at: $ROUTER_PATH"
    if [ -x "$ROUTER_PATH" ]; then
        echo "✓ router.sh is executable"
    else
        echo "⚠ router.sh is not executable"
        echo "  Run: chmod +x $ROUTER_PATH"
    fi
else
    echo "✗ router.sh not found at: $ROUTER_PATH"
    exit 1
fi

# 7. Check if Claude Code is running
echo ""
echo "7. Checking Claude Code process..."
if pgrep -f "claude --" > /dev/null; then
    echo "⚠ Claude Code is currently running"
    echo "  You need to FULLY QUIT and restart Claude Code to load MCP changes"
    echo ""
    echo "  To quit: pkill -f 'claude --'  (or use Cmd+Q)"
else
    echo "✓ Claude Code is not running"
    echo "  Start Claude Code to load the MCP server"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "If all checks passed:"
echo "1. Quit Claude Code completely (Cmd+Q or pkill)"
echo "2. Restart Claude Code"
echo "3. Try: /mcp"
echo ""
echo "If save-my-tokens still doesn't appear, check:"
echo "- Claude Code logs at ~/.claude/debug/"
echo "- Or run the MCP server manually to see errors:"
echo "  node $MCP_PATH"
echo ""
