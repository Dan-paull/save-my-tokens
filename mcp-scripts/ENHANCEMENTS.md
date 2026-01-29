# Save My Tokens Enhancements

## New Features Added

### 1. User/Project-Level Installation ✅

**File:** `install-mcp-claude-enhanced.sh`

#### Usage

```bash
# Interactive mode (prompts for choice)
./install-mcp-claude-enhanced.sh

# User-level installation (global)
./install-mcp-claude-enhanced.sh --user

# Project-level installation (directory-specific)
./install-mcp-claude-enhanced.sh --project

# Show help
./install-mcp-claude-enhanced.sh --help
```

#### Benefits

**User-Level (`~/.claude.json`):**
- ✅ Available in all projects
- ✅ Single configuration to manage
- ✅ Personal tool setup
- ✅ API keys in one place

**Project-Level (`.mcp.json`):**
- ✅ Team can share via git
- ✅ Project-specific configuration
- ✅ Different settings per project
- ✅ Isolated from personal config

#### Environment Variable Support

The enhanced installer automatically:
- Checks for `.env.savemytokens` file
- Validates API key configuration
- Warns if API keys are missing
- Passes environment variables through MCP config (optional)

### 2. Health Check Tool ✅

**File:** `mcp-server-enhanced.js`

A new `health` tool that checks system status:

```javascript
Use the health tool to check system status
```

#### Returns

```json
{
  "status": "healthy",
  "checks": {
    "router": {
      "available": true,
      "path": "/path/to/router.sh",
      "executable": true
    },
    "environment": {
      "configured": true,
      "hasApiKeys": true
    },
    "tasks": {
      "directory": true
    }
  },
  "timestamp": "2026-01-29T..."
}
```

#### Status Levels

- `healthy` - Everything working
- `warning` - API keys not configured
- `degraded` - Router not available

### 3. Response Metadata

**File:** `mcp-server-enhanced.js`

Tool responses now include metadata:

```json
{
  "content": [...],
  "_meta": {
    "task": "research",
    "duration_ms": 1234,
    "timestamp": "2026-01-29T..."
  }
}
```

**Benefits:**
- Track performance
- Debug slow responses
- Monitor usage patterns

### 4. Input Validation

**File:** `mcp-server-enhanced.js`

Added security best practices:
- ✅ Prompt length validation (max 50KB)
- ✅ Path traversal prevention
- ✅ Command injection prevention (already had via spawn)

### 5. Better Error Messages

Enhanced error messages include:
- Specific error details
- Suggestions for resolution
- Link to health check tool

## MCP Best Practices Document

**File:** `MCP-BEST-PRACTICES.md`

Comprehensive guide covering:

### ✅ Implemented
1. Official SDK usage
2. User/project installation scope
3. Environment variable support
4. Health check tool
5. Response metadata
6. Input validation

### 🟡 Recommended (Future)
1. Logging system
2. Rate limiting
3. Progress streaming for long tasks
4. Dynamic tool discovery
5. Caching controls

### 🔵 Nice to Have (Optional)
1. Performance monitoring
2. Usage analytics
3. Advanced rate limiting
4. Tool versioning

## Migration Guide

### From Basic to Enhanced Installer

**Old way:**
```bash
./install-mcp-claude.sh
```

**New way:**
```bash
# Interactive - choose user or project
./install-mcp-claude-enhanced.sh

# Or specify directly
./install-mcp-claude-enhanced.sh --user
./install-mcp-claude-enhanced.sh --project
```

### From Basic to Enhanced Server

**To use the enhanced server:**

1. Update your configuration to use the enhanced server:

```bash
cd mcp-scripts
./install-mcp-claude-enhanced.sh --user
```

2. When prompted, choose user or project level

3. Restart Claude Code

4. Test the health check:
```
Use the health tool to check status
```

## Comparison: Basic vs Enhanced

| Feature | Basic | Enhanced |
|---------|-------|----------|
| Installation scope | User only | User or Project |
| Health check | ❌ | ✅ |
| Response metadata | ❌ | ✅ |
| Input validation | Basic | Enhanced |
| Environment check | ❌ | ✅ |
| Error messages | Basic | Detailed |
| Configuration validation | ❌ | ✅ |

## Testing

### Test Enhanced Installer

```bash
# Test help
./install-mcp-claude-enhanced.sh --help

# Test user installation
./install-mcp-claude-enhanced.sh --user

# Test project installation
cd /path/to/project
./install-mcp-claude-enhanced.sh --project

# Verify config
cat ~/.claude.json | jq .mcpServers
cat .mcp.json | jq .mcpServers
```

### Test Enhanced Server

```bash
# Make executable
chmod +x mcp-server-enhanced.js

# Test health check
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}
{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' | node mcp-server-enhanced.js | tail -1 | jq '.result.tools[] | select(.name=="health")'

# Test manual health check
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}
{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"health","arguments":{}}}' | node mcp-server-enhanced.js | tail -1 | jq '.result.content[0].text | fromjson'
```

## Deployment Options

### Option 1: Keep Both (Recommended for now)

Keep both basic and enhanced versions:
- `mcp-server.js` - Current working version
- `mcp-server-enhanced.js` - New features to test

Users can choose which to use.

### Option 2: Gradual Migration

1. Test enhanced version thoroughly
2. Rename current to `mcp-server-basic.js`
3. Promote enhanced to `mcp-server.js`
4. Update documentation

### Option 3: Feature Flag

Add environment variable to enable/disable features:
```javascript
const ENABLE_HEALTH_CHECK = process.env.SAVE_MY_TOKENS_HEALTH_CHECK !== 'false';
const ENABLE_METADATA = process.env.SAVE_MY_TOKENS_METADATA !== 'false';
```

## Next Steps

1. **Test the enhanced installer:**
   ```bash
   ./install-mcp-claude-enhanced.sh --project
   ```

2. **Test the health check:**
   ```
   Use the health tool
   ```

3. **Review the best practices document:**
   - Read `MCP-BEST-PRACTICES.md`
   - Prioritize which features to implement next

4. **Get feedback:**
   - Does user/project installation work as expected?
   - Is the health check useful?
   - What other features would be valuable?

## Documentation Updates Needed

If we promote the enhanced versions:
- [ ] Update README.md to mention user/project installation
- [ ] Update MCP-README.md with health tool documentation
- [ ] Update INSTALLATION.md with new installation options
- [ ] Add examples of health check usage
- [ ] Document the metadata format

## Questions to Consider

1. **Should we make enhanced the default?**
   - Pro: Better features for everyone
   - Con: Need more testing first

2. **Should health check be a separate tool or built-in?**
   - Current: Separate tool (good for explicit checks)
   - Alternative: Automatic health logging (less visible)

3. **Should we implement logging next?**
   - Pro: Helps with debugging
   - Con: Adds complexity, file I/O concerns

4. **What's the priority for other best practices?**
   - Rate limiting?
   - Progress streaming?
   - Cache controls?
   - Dynamic tool discovery?
