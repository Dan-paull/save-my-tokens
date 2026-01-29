# MCP Installation Fixed

## Issue Found

The installation script was writing to the wrong configuration file:
- ❌ **Wrong:** `~/.claude/settings.json`
- ✅ **Correct:** `~/.claude.json`

Claude Code reads MCP server configuration from `~/.claude.json`, not from `~/.claude/settings.json`.

## What Was Fixed

1. **install-mcp-claude.sh** - Now writes to `~/.claude.json`
2. **troubleshoot-claude.sh** - Now checks `~/.claude.json`
3. **MCP-README.md** - Updated documentation
4. **INSTALLATION.md** - Updated documentation

## Verification

Run the troubleshooting script to verify everything is configured correctly:

```bash
cd /Users/Dan-paull/Documents/code_tests/free-offload-cli/save-my-tokens/mcp-scripts
./troubleshoot-claude.sh
```

All checks should pass ✓

## Current Status

✅ MCP server installed at: `/Users/Dan-paull/Documents/code_tests/free-offload-cli/save-my-tokens/mcp-scripts/mcp-server.js`
✅ Configuration file updated: `~/.claude.json`
✅ Server entry added under: `mcpServers.save-my-tokens`
✅ All tests passing

## Next Steps

1. **Start Claude Code** (it's currently stopped)
2. Type `/mcp` in Claude Code
3. You should see **save-my-tokens** in the list with 4 tools:
   - `research`
   - `coding`
   - `planning`
   - `code_review`

## Testing the Tools

Once Claude Code loads the MCP server, try:

```
Use the research tool to research "AI agents best practices"
```

Or:

```
mcp__save_my_tokens__research prompt="test query"
```

## If It Still Doesn't Show

1. Check if other MCP servers are loading (you have `mcp-pdb` and `sequential-thinking`)
2. Look at Claude Code startup logs for errors
3. Run the troubleshoot script again to verify configuration

The installation is now correct and should work when you restart Claude Code!
