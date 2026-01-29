# MCP Scripts Directory

This directory contains all Model Context Protocol (MCP) server files for integrating Save My Tokens with Claude Code and Kiro CLI.

## Main Files

- **mcp-server.js** - Production MCP server (SDK-based, recommended)
- **install-mcp-claude.sh** - Installation script for Claude Code
- **install-mcp.sh** - Installation script for Kiro CLI
- **MCP-README.md** - Full MCP documentation and usage guide

## Testing & Validation

- **test-mcp.sh** - Comprehensive MCP server tests
- **test-sdk.sh** - SDK-specific tests
- **test-kiro-simulation.sh** - Kiro CLI behavior simulation
- **validate-mcp.sh** - MCP configuration validation
- **test-spawn.js** - Process spawning tests

## Reference Implementations

The following files are previous iterations kept for reference:

- **mcp-server-sdk.js** - Original SDK-based implementation (now main)
- **mcp-server-manual.js** - Previous manual protocol implementation
- **mcp-server-kiro.js** - Kiro-specific variant with keep-alive
- **mcp-server-working.js** - Working version from development
- **mcp-server-final.js** - Final version from development
- **mcp-server-clean.js** - Cleaned version
- **mcp-server-fixed.js** - Fixed version
- **mcp-server-minimal.js** - Minimal implementation
- **mcp-server-debug.js** - Debug version with extra logging

## Quick Start

### Install for Claude Code

```bash
cd mcp-scripts
./install-mcp-claude.sh
```

Then restart Claude Code. Verify with:
```bash
claude mcp list
```

### Install for Kiro CLI

```bash
cd mcp-scripts
./install-mcp.sh
```

### Test the Server

```bash
cd mcp-scripts
./test-mcp.sh
```

## How It Works

1. The MCP server (`mcp-server.js`) receives JSON-RPC requests via stdio
2. It translates them into calls to the Save My Tokens router (`../router.sh`)
3. Router executes tasks using configured LLM providers
4. Results are returned to the MCP client (Claude Code/Kiro CLI)

## Development

To modify the MCP server:

1. Edit `mcp-server.js` (uses @modelcontextprotocol/sdk)
2. Test with `./test-mcp.sh`
3. Validate with `./validate-mcp.sh`

See `MCP-README.md` for complete documentation.
