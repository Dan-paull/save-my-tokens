# MCP Scripts Changelog

## 2026-01-29 - Major Reorganization

### Changes

1. **Reorganized MCP files into dedicated directory**
   - Created `/mcp-scripts/` directory
   - Moved all MCP-related files from root to `mcp-scripts/`
   - Cleaner project structure with better separation of concerns

2. **Switched to SDK-based MCP server**
   - Replaced manual protocol implementation with `@modelcontextprotocol/sdk`
   - Cleaner, more maintainable code
   - Better error handling
   - Uses official MCP SDK v1.25.3

3. **Added Claude Code support**
   - Created `install-mcp-claude.sh` installation script
   - Automatically updates `~/.claude/settings.json`
   - Compatible with Claude Code CLI
   - Same tool interface as Kiro CLI

4. **Updated existing files**
   - Fixed `install-mcp.sh` for Kiro CLI
   - Updated `test-mcp.sh` to work with SDK-based server
   - Fixed path references in `mcp-server.js` to find `router.sh`
   - Updated `package.json` with new paths and npm scripts

5. **Documentation improvements**
   - Created `INSTALLATION.md` - comprehensive installation guide
   - Created `mcp-scripts/README.md` - directory documentation
   - Updated main `README.md` with MCP integration section
   - Updated `MCP-README.md` with Claude Code instructions

### File Structure

```
save-my-tokens/
├── mcp-scripts/                    # NEW: All MCP files
│   ├── mcp-server.js               # Production server (SDK-based)
│   ├── install-mcp-claude.sh       # NEW: Claude Code installer
│   ├── install-mcp.sh              # Kiro CLI installer
│   ├── test-mcp.sh                 # Updated tests
│   ├── README.md                   # NEW: Directory docs
│   ├── MCP-README.md               # Updated with Claude Code
│   └── [reference implementations] # Old versions kept for reference
├── INSTALLATION.md                 # NEW: Installation guide
├── package.json                    # Updated paths
└── README.md                       # Updated with MCP section
```

### Breaking Changes

- MCP server moved from root to `mcp-scripts/`
- Package.json `main` field updated to `mcp-scripts/mcp-server.js`
- Installation scripts must be run from `mcp-scripts/` directory

### Migration Guide

**For existing Kiro CLI users:**
```bash
# Remove old configuration
# Edit ~/.kiro/mcp_servers.json and remove save-my-tokens entry

# Reinstall
cd mcp-scripts
./install-mcp.sh
```

**For Claude Code users:**
```bash
cd mcp-scripts
./install-mcp-claude.sh
```

### Testing

All tests pass:
```bash
cd mcp-scripts
./test-mcp.sh
```

### npm Scripts

New npm scripts added:
- `npm start` - Start MCP server
- `npm test` - Run MCP tests
- `npm run validate` - Validate router configuration
- `npm run install:claude` - Install for Claude Code
- `npm run install:kiro` - Install for Kiro CLI

### Compatibility

- **Node.js:** >= 16.0.0
- **Claude Code:** All versions with MCP support
- **Kiro CLI:** All versions with MCP support
- **MCP Protocol:** 2024-11-05

### Known Issues

None currently.

### Contributors

- Claude Sonnet 4.5 (Architecture & Implementation)
