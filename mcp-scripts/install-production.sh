#!/bin/bash
# Install Production MCP Server with all features

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCP_SERVER_PATH="$SCRIPT_DIR/mcp-server-production.js"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Save My Tokens Production MCP Server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This production server includes:"
echo "  ✅ Timeout protection (no more silent hangs)"
echo "  ✅ Progress notifications (every 5 seconds)"
echo "  ✅ Structured logging (logs/mcp-server.log)"
echo "  ✅ Tool versioning (semantic versioning)"
echo "  ✅ Dynamic tool discovery (auto-scan tasks/)"
echo "  ✅ Enhanced error handling (no silent failures)"
echo ""

# Parse command line arguments
INSTALL_SCOPE=""
TIMEOUT="300000"  # 5 minutes default

while [[ $# -gt 0 ]]; do
    case $1 in
        --user)
            INSTALL_SCOPE="user"
            shift
            ;;
        --project)
            INSTALL_SCOPE="project"
            shift
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --user         Install for all projects (global)"
            echo "  --project      Install for current project only"
            echo "  --timeout MS   Set timeout in milliseconds (default: 300000 = 5min)"
            echo "  --help         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --user                    # Install globally"
            echo "  $0 --project --timeout 600000  # 10 minute timeout"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Interactive prompt if no scope specified
if [ -z "$INSTALL_SCOPE" ]; then
    echo "Choose installation scope:"
    echo "  1) User-level (global, available in all projects)"
    echo "  2) Project-level (only in current directory)"
    echo ""
    read -p "Enter choice [1-2]: " choice

    case $choice in
        1) INSTALL_SCOPE="user" ;;
        2) INSTALL_SCOPE="project" ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

# Set configuration file based on scope
if [ "$INSTALL_SCOPE" = "user" ]; then
    CONFIG_FILE="$HOME/.claude.json"
    CONFIG_TYPE="User-level"
else
    CONFIG_FILE="$(pwd)/.mcp.json"
    CONFIG_TYPE="Project-level"
fi

echo ""
echo "Installing production server..."
echo "Config file: $CONFIG_FILE"
echo "Timeout: ${TIMEOUT}ms ($(($TIMEOUT / 1000))s)"
echo ""

# Ensure config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating new configuration file..."
    cat > "$CONFIG_FILE" << 'EOF'
{
  "mcpServers": {}
}
EOF
fi

# Update configuration with Node.js
CONFIG_FILE="$CONFIG_FILE" MCP_SERVER_PATH="$MCP_SERVER_PATH" TIMEOUT="$TIMEOUT" node << 'NODEJS_SCRIPT'
const fs = require('fs');

const configFile = process.env.CONFIG_FILE;
const mcpServerPath = process.env.MCP_SERVER_PATH;
const timeout = process.env.TIMEOUT;

try {
  // Read existing config
  let config = JSON.parse(fs.readFileSync(configFile, 'utf8'));

  // Ensure mcpServers object exists
  if (!config.mcpServers) {
    config.mcpServers = {};
  }

  // Build server configuration
  const serverConfig = {
    type: 'stdio',
    command: 'node',
    args: [mcpServerPath],
    env: {
      SAVE_MY_TOKENS_TIMEOUT: timeout,
      SAVE_MY_TOKENS_PROGRESS_INTERVAL: '5000'
    }
  };

  // Add or update save-my-tokens server
  config.mcpServers['save-my-tokens'] = serverConfig;

  // Write updated config
  fs.writeFileSync(configFile, JSON.stringify(config, null, 2) + '\n');

  console.log('✓ Production MCP server configured');
} catch (error) {
  console.error('✗ Error updating configuration:', error.message);
  process.exit(1);
}
NODEJS_SCRIPT

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Configuration: $CONFIG_TYPE"
echo "Server: $MCP_SERVER_PATH"
echo "Timeout: ${TIMEOUT}ms ($(($TIMEOUT / 1000))s)"
echo ""
echo "Available tools:"
echo "  • health       - System health check"
echo "  • research     - Multi-model research"
echo "  • coding       - Code generation"
echo "  • planning     - Architecture planning"
echo "  • code_review  - Code review"
echo ""
echo "New features:"
echo "  ✅ Timeout protection - Never hangs indefinitely"
echo "  ✅ Progress updates - See what's happening every 5s"
echo "  ✅ Structured logging - Debug any issue"
echo "  ✅ Tool versioning - Track breaking changes"
echo "  ✅ Auto-discovery - New tasks automatically available"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code (Cmd+Q or pkill -f 'claude --')"
echo "  2. Test health check: Use the health tool"
echo "  3. View logs: tail -f logs/mcp-server.log"
echo ""
echo "Troubleshooting:"
echo "  • Logs: tail -f $SCRIPT_DIR/../logs/mcp-server.log"
echo "  • Errors: grep '\"level\":\"error\"' logs/mcp-server.log"
echo "  • Health: Use the health tool to check status"
echo ""
