# Save My Tokens Server

A Model Context Protocol (MCP) server that provides access to the Save My Tokens multi-model AI system.

## Quick Install

### For Claude Code CLI

```bash
cd /path/to/save-my-tokens/mcp-scripts
./install-mcp-claude.sh
```

This will:
1. Add the MCP server to your Claude Code configuration (~/.claude/settings.json)
2. Make the save-my-tokens tools available as MCP tools
3. Restart Claude Code to load the new server

### For Kiro CLI

```bash
cd /path/to/save-my-tokens/mcp-scripts
./install-mcp.sh
```

This will:
1. Add the MCP server to your Kiro CLI configuration
2. Make the save-my-tokens tools available as MCP tools
3. Restart Kiro CLI to load the new server

## Available Tools

Once installed, you can use these tools in Claude Code or Kiro CLI:

- `mcp__save_my_tokens__research` - Multi-model research with diverse perspectives
- `mcp__save_my_tokens__coding` - Code generation and modifications  
- `mcp__save_my_tokens__planning` - Architecture and implementation planning
- `mcp__save_my_tokens__code_review` - Code review and analysis

## Manual Installation

### Claude Code

Add this to your `~/.claude.json`:

```json
{
  "mcpServers": {
    "save-my-tokens": {
      "type": "stdio",
      "command": "node",
      "args": ["/path/to/save-my-tokens/mcp-scripts/mcp-server.js"]
    }
  }
}
```

### Kiro CLI

Add this to your `~/.kiro/mcp_servers.json`:

```json
{
  "save-my-tokens": {
    "command": "node",
    "args": ["/path/to/save-my-tokens/mcp-scripts/mcp-server.js"],
    "env": {}
  }
}
```

### 2. Ensure Dependencies

Make sure your save-my-tokens system is properly configured:

```bash
# Validate configuration
./router.sh --validate

# Check platform status  
./router.sh --status
```

## Usage Examples

### Research Task
```
Use mcp__save_my_tokens__research to research "latest trends in AI agents" with context "focus on enterprise applications"
```

### Code Generation
```
Use mcp__save_my_tokens__coding to "create a REST API endpoint for user authentication in Node.js"
```

### Architecture Planning
```
Use mcp__save_my_tokens__planning to "design a microservices architecture for an e-commerce platform"
```

### Code Review
```
Use mcp__save_my_tokens__code_review to review this code: [paste code here]
```

## Configuration

The MCP server uses your existing save-my-tokens configuration:
- `config.json` - Main configuration
- `.env.savemytokens` - API keys and environment variables
- `tasks/*.json` - Task definitions

## Directory Structure

```
save-my-tokens/
├── mcp-scripts/          # MCP server and installation scripts
│   ├── mcp-server.js     # Main MCP server (SDK-based)
│   ├── install-mcp-claude.sh  # Claude Code installer
│   ├── install-mcp.sh    # Kiro CLI installer
│   ├── test-mcp.sh       # MCP server tests
│   └── validate-mcp.sh   # MCP validation
├── router.sh             # Main router for agent tasks
├── lib/                  # Core libraries
├── tasks/                # Task definitions
└── providers/            # Model provider wrappers
```

## Troubleshooting

### MCP Server Not Loading (Claude Code)
1. Check Claude Code logs: `tail -f ~/.claude/debug/*.log`
2. Verify Node.js is available in PATH
3. Ensure save-my-tokens router.sh is executable
4. Test the MCP server manually: `cd mcp-scripts && ./test-mcp.sh`

### MCP Server Not Loading (Kiro CLI)
1. Check Kiro CLI logs for MCP server errors
2. Verify Node.js is available in PATH
3. Ensure save-my-tokens router.sh is executable

### Tools Not Working
1. Run `./router.sh --validate` to check configuration
2. Run `./router.sh --status` to verify API keys
3. Check that required platforms are enabled

### Permission Issues
```bash
chmod +x router.sh
chmod +x mcp-server.js
chmod +x install-mcp.sh
```

## Development

Test the MCP server directly:

```bash
# Start MCP server
node mcp-server.js

# Send test request (in another terminal)
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | node mcp-server.js
```
