#!/bin/bash
# Save My Tokens Installation Script for Claude Code CLI
# Supports both user-level and project-level installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCP_SERVER_PATH="$SCRIPT_DIR/mcp-server.js"

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

# Parse command line arguments
INSTALL_SCOPE=""
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
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --user       Install for all projects (global, in ~/.claude.json)"
            echo "  --project    Install for current project only (in .mcp.json)"
            echo "  --help       Show this help message"
            echo ""
            echo "If no option is specified, you'll be prompted to choose."
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
        1)
            INSTALL_SCOPE="user"
            ;;
        2)
            INSTALL_SCOPE="project"
            ;;
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
    echo ""
    echo "Installing at user level (global)..."
    echo "Config file: $CONFIG_FILE"
else
    CONFIG_FILE="$(pwd)/.mcp.json"
    CONFIG_TYPE="Project-level"
    echo ""
    echo "Installing at project level..."
    echo "Config file: $CONFIG_FILE"
    echo "Note: This will only be available in the current directory."
fi

# Check for environment variables
echo ""
echo "Checking environment setup..."
ENV_FILE="$SCRIPT_DIR/../.env.savemytokens"
if [ -f "$ENV_FILE" ]; then
    echo "✓ Found .env.savemytokens"

    # Check for required API keys
    if grep -q "CEREBRAS_API_KEY=" "$ENV_FILE" && grep -q "MISTRAL_API_KEY=" "$ENV_FILE"; then
        echo "✓ API keys configured"
    else
        echo "⚠️  Warning: API keys may not be configured in .env.savemytokens"
        echo "   Edit $ENV_FILE to add your API keys"
    fi
else
    echo "⚠️  Warning: .env.savemytokens not found"
    echo "   Copy .env.savemytokens.example and add your API keys"
fi

# Create or update configuration file
echo ""
echo "Updating MCP configuration..."

# Ensure config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating new configuration file..."
    cat > "$CONFIG_FILE" << 'EOF'
{
  "mcpServers": {}
}
EOF
fi

# Use Node.js to safely update the JSON configuration
CONFIG_FILE="$CONFIG_FILE" MCP_SERVER_PATH="$MCP_SERVER_PATH" INSTALL_SCOPE="$INSTALL_SCOPE" node << 'NODEJS_SCRIPT'
const fs = require('fs');
const path = require('path');

const configFile = process.env.CONFIG_FILE;
const mcpServerPath = process.env.MCP_SERVER_PATH;
const installScope = process.env.INSTALL_SCOPE;

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

  // Build server configuration
  const serverConfig = {
    type: 'stdio',
    command: 'node',
    args: [mcpServerPath]
  };

  // Add environment variables if .env.savemytokens exists
  const envPath = path.join(path.dirname(mcpServerPath), '..', '.env.savemytokens');
  if (fs.existsSync(envPath)) {
    // Parse .env file for API keys
    const envContent = fs.readFileSync(envPath, 'utf8');
    const env = {};

    envContent.split('\n').forEach(line => {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith('#') && trimmed.includes('=')) {
        const [key, ...valueParts] = trimmed.split('=');
        const value = valueParts.join('=').trim();
        if (value && !value.startsWith('your-') && !value.startsWith('sk-')) {
          // Only include non-placeholder values
          env[key.trim()] = value;
        }
      }
    });

    if (Object.keys(env).length > 0) {
      serverConfig.env = env;
    }
  }

  // Add or update save-my-tokens server
  config.mcpServers['save-my-tokens'] = serverConfig;

  // Add metadata comment for project-level installs
  if (installScope === 'project' && !config._comment) {
    config._comment = 'MCP configuration for this project. See https://modelcontextprotocol.io/';
  }

  // Write updated config
  fs.writeFileSync(configFile, JSON.stringify(config, null, 2) + '\n');

  console.log('✓ Save My Tokens server added to configuration');
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
echo "Installation type: $CONFIG_TYPE"
echo "Configuration file: $CONFIG_FILE"
echo "MCP server path: $MCP_SERVER_PATH"
echo ""
echo "Available tools in Claude Code:"
echo "  • research     - Multi-model research with diverse perspectives"
echo "  • coding       - Code generation and modifications"
echo "  • planning     - Architecture and implementation planning"
echo "  • code_review  - Code review and analysis"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code (Cmd+Q or pkill -f 'claude --')"
echo "  2. Verify installation: /mcp"
echo "  3. Test a tool: Use the research tool to research \"test query\""
echo ""
echo "To verify installation:"
echo "  claude mcp list"
echo ""
if [ "$INSTALL_SCOPE" = "project" ]; then
    echo "Note: Project-level installation is only available in this directory."
    echo "To use in other projects, run this script again in those directories."
fi
echo ""
