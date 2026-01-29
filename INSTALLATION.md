# Save My Tokens Installation Guide

## Quick Start with npx (Recommended) ⚡

The fastest way to get started:

```bash
# Install with one command
npx save-my-tokens install

# Edit API keys when prompted
nano .env.savemytokens

# Restart Claude Code
pkill -f "claude --"

# Test
npx save-my-tokens status
```

**npx Commands:**
```bash
npx save-my-tokens install      # Install to Claude Code
npx save-my-tokens test          # Run test suite
npx save-my-tokens status        # Check status
npx save-my-tokens uninstall     # Remove installation
npx save-my-tokens help          # Show help
```

---

## Manual Installation Methods

Save My Tokens can be used in three ways:

1. **MCP in Claude Code** (Recommended) - Integrate as tools with real-time progress
2. **Direct CLI** - Run `router.sh` directly from command line
3. **From Source** - Clone and build from GitHub

### 1. MCP Integration for Claude Code (npx)

```bash
# One-command install
npx save-my-tokens install

# Or from source
git clone https://github.com/Dan-paull/save-my-tokens
cd save-my-tokens
npx save-my-tokens install
```

### 2. Direct CLI Usage

```bash
# Clone repository
git clone https://github.com/Dan-paull/save-my-tokens
cd save-my-tokens

# Configure API keys
cp .env.savemytokens.example .env.savemytokens
nano .env.savemytokens

# Test
./router.sh --task research --prompt "Test query"
```

**Usage in Claude Code:**
```
Use mcp__save_my_tokens__research to research "topic" with context "additional context"
Use mcp__save_my_tokens__coding to "implement feature X"
Use mcp__save_my_tokens__planning to "design system architecture"
Use mcp__save_my_tokens__code_review to review this code: [code]
```

**Verify installation:**
```bash
claude mcp list
# Should show "save-my-tokens" server
```

### 3. MCP Integration for Kiro CLI

```bash
# Install MCP server
cd save-my-tokens/mcp-scripts
./install-mcp.sh

# Restart Kiro CLI
```

**Usage in Kiro CLI:**
Same tool names as Claude Code above.

## Configuration

All methods use the same configuration:

- `config.json` or `config.yaml` - Platform settings
- `.env.savemytokens` - API keys
- `tasks/*.yaml` - Task definitions

## API Keys

Get free API keys from:

- **Cerebras** (fast, free): https://inference.cerebras.ai/
- **Mistral** (free tier): https://console.mistral.ai/

Add to `.env.savemytokens`:
```bash
CEREBRAS_API_KEY=your-key-here
MISTRAL_API_KEY=your-key-here
```

## Verification

### Test Direct CLI
```bash
./router.sh --status
./router.sh --validate
./router.sh --task research --prompt "Test"
```

### Test MCP Server
```bash
cd mcp-scripts
./test-mcp.sh
```

## Directory Structure

```
save-my-tokens/
├── router.sh              # Main CLI entry point
├── mcp-scripts/           # MCP server files
│   ├── mcp-server.js      # MCP server
│   └── install-*.sh       # Installation scripts
├── tasks/                 # Task definitions
├── providers/             # LLM provider wrappers
└── lib/                   # Core utilities
```

## Troubleshooting

### Claude Code: MCP Not Loading

1. Check settings: `cat ~/.claude.json | jq .mcpServers`
2. Check logs: `tail -f ~/.claude/debug/*.log`
3. Test manually: `cd mcp-scripts && ./test-mcp.sh`
4. Verify paths in settings.json are absolute

### Router Not Found

The MCP server looks for `router.sh` in the parent directory of `mcp-scripts/`. If you move the directory structure, update the path in `mcp-server.js`.

### No API Keys

Run `./router.sh --status` to check which platforms are configured.

## Next Steps

- See `README.md` for full Save My Tokens documentation
- See `mcp-scripts/MCP-README.md` for detailed MCP usage
- See task files in `tasks/` for available operations
