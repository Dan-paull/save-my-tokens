# Save My Tokens - Quick Reference

## Installation

```bash
cd mcp-scripts

# User-level (all projects)
./install-production.sh --user

# Project-level (current directory)
./install-production.sh --project

# Custom timeout (10 minutes)
./install-production.sh --user --timeout 600000

# Restart Claude Code
pkill -f "claude --"
```

---

## Common Commands

### Health Check
```
Use the health tool
```

### View Logs
```bash
# Real-time
tail -f logs/mcp-server.log | jq .

# Errors only
grep '"level":"error"' logs/mcp-server.log | jq .

# Specific task
grep '"taskId":"research-' logs/mcp-server.log | jq .
```

### Test Connection
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}
{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' | \
node mcp-server-production.js 2>&1 | tail -1 | jq '.result.tools | length'
```

---

## Troubleshooting

### Task Hanging?

**1. Check for progress:**
```
[PROGRESS] research: Running for 5s...
```
If you see this, it's working. Wait for timeout.

**2. Check logs:**
```bash
tail -f logs/mcp-server.log | jq .
```

**3. Check timeout:**
```bash
cat ~/.claude.json | jq '.mcpServers["save-my-tokens"].env.SAVE_MY_TOKENS_TIMEOUT'
```

**4. Kill if needed:**
```bash
pkill -f "mcp-server-production"
```

### Not Showing in /mcp?

**1. Check config:**
```bash
cat ~/.claude.json | jq '.mcpServers["save-my-tokens"]'
```

**2. Restart Claude Code:**
```bash
pkill -f "claude --"
# Then start Claude Code
```

**3. Run troubleshoot:**
```bash
./troubleshoot-claude.sh
```

### Errors in Logs?

**View errors:**
```bash
grep '"level":"error"' logs/mcp-server.log | jq .
```

**Common fixes:**
- Router not found → `chmod +x ../router.sh`
- No API keys → Edit `.env.savemytokens`
- Timeout → Increase `SAVE_MY_TOKENS_TIMEOUT`

---

## Configuration

### Config File Locations

- User-level: `~/.claude.json`
- Project-level: `./.mcp.json`
- Logs: `logs/mcp-server.log`
- Environment: `.env.savemytokens`

### Environment Variables

```bash
SAVE_MY_TOKENS_TIMEOUT=300000         # 5 minutes
SAVE_MY_TOKENS_PROGRESS_INTERVAL=5000 # 5 seconds
SAVE_MY_TOKENS_DEBUG=false
```

### Timeout Values

- 1 minute: `60000`
- 5 minutes: `300000` (default)
- 10 minutes: `600000`
- 30 minutes: `1800000`

---

## Tool Usage

### Research
```
Use research with prompt="query" and timeout_seconds=300
```

### Coding
```
Use coding with prompt="task" and run_multiple=false
```

### Planning
```
Use planning with prompt="system" and context="constraints"
```

### Code Review
```
Use code_review with prompt="code to review"
```

### Health Check
```
Use health
```

---

## Monitoring

### Task Performance
```bash
# Average duration
grep '"duration_ms"' logs/mcp-server.log | \
  jq -r '[.task, .duration_ms/1000] | @tsv' | \
  awk '{sum[$1]+=$2; count[$1]++} END {
    for(t in sum) printf "%s: %.1fs\n", t, sum[t]/count[t]
  }'
```

### Error Rate
```bash
errors=$(grep -c '"level":"error"' logs/mcp-server.log)
success=$(grep -c '"success":true' logs/mcp-server.log)
echo "Errors: $errors, Success: $success"
```

### Recent Activity
```bash
# Last 10 tasks
tail -100 logs/mcp-server.log | grep '"task":"' | jq -r '[.timestamp, .task, .duration_ms/1000] | @tsv' | tail -10
```

---

## Quick Fixes

### Silent Hang
✅ **Fixed in production server**
- Auto-timeout after 5 minutes
- Progress updates every 5 seconds
- Logs all activity

### Increase Timeout
```bash
# Edit config
nano ~/.claude.json

# Change:
"SAVE_MY_TOKENS_TIMEOUT": "600000"  # 10 minutes

# Restart Claude Code
```

### Clear Logs
```bash
# Archive old logs
mv logs/mcp-server.log logs/mcp-server-$(date +%Y%m%d).log

# Or just truncate
> logs/mcp-server.log
```

### Reinstall
```bash
# Backup config
cp ~/.claude.json ~/.claude.json.backup

# Reinstall
./install-production.sh --user

# Restart
pkill -f "claude --"
```

---

## Features at a Glance

| Feature | Benefit |
|---------|---------|
| ⏱️ Timeout | Never hang forever |
| 📊 Progress | See what's happening |
| 📝 Logging | Debug any issue |
| 🏷️ Versioning | Handle changes |
| 🔍 Discovery | Auto-register tasks |
| ❤️ Health Check | System diagnostics |
| 🛡️ Errors | No silent failures |
| 🎯 User/Project | Choose scope |

---

## Support

### Log File
```bash
logs/mcp-server.log
```

### Documentation
- `SUMMARY.md` - Complete overview
- `PRODUCTION-FEATURES.md` - Feature details
- `MCP-BEST-PRACTICES.md` - Best practices
- `ENHANCEMENTS.md` - All enhancements

### Health Check
```
Use the health tool to check status
```

Should show:
- ✅ Router available and executable
- ✅ Environment configured with API keys
- ✅ Tasks discovered (4 tasks)
- ✅ Logs writable

---

## Cheat Sheet

```bash
# Install
./install-production.sh --user

# Test
echo '{...}' | node mcp-server-production.js

# Logs
tail -f logs/mcp-server.log | jq .

# Errors
grep error logs/mcp-server.log | jq .

# Restart
pkill -f "claude --"

# Health
# Use health tool in Claude Code
```

---

## Emergency Procedures

### Complete Reset

```bash
# 1. Backup
cp ~/.claude.json ~/.claude.json.emergency

# 2. Remove save-my-tokens
node -e "
const fs = require('fs');
const cfg = JSON.parse(fs.readFileSync('$HOME/.claude.json', 'utf8'));
delete cfg.mcpServers['save-my-tokens'];
fs.writeFileSync('$HOME/.claude.json', JSON.stringify(cfg, null, 2));
"

# 3. Restart Claude Code
pkill -f "claude --"

# 4. Reinstall
./install-production.sh --user

# 5. Restart again
pkill -f "claude --"
```

### Force Kill All

```bash
# Kill all Node processes (careful!)
pkill -f "mcp-server"

# Or specific
pkill -f "mcp-server-production"
```

---

## Key Improvements Over Basic

1. **No more silent hangs** - 5 minute timeout
2. **Progress visibility** - Updates every 5s
3. **Full logging** - Everything recorded
4. **Clear errors** - No silent failures
5. **Auto-discovery** - New tasks work automatically
6. **Versioning** - Handle breaking changes
7. **Health check** - System diagnostics
8. **Graceful shutdown** - Clean cleanup

**Your issue is fixed!** 🎉
