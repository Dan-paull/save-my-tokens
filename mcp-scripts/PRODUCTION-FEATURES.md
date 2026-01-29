# Production MCP Server Features

## Critical Issue Fixed: Silent Hangs ✅

### The Problem
- Tasks would hang indefinitely with no feedback
- Claude Code would wait forever
- No visibility into what was happening
- No error messages when things went wrong

### The Solution
The production server (`mcp-server-production.js`) implements:

1. **Hard Timeouts** - Tasks auto-kill after 5 minutes (configurable)
2. **Progress Notifications** - Updates every 5 seconds while running
3. **Structured Logging** - All activity logged to file
4. **Better Error Messages** - Clear errors with log file location
5. **Graceful Shutdown** - Clean cleanup on exit

---

## New Features

### 1. ✅ Structured Logging

**All activity is logged to:** `logs/mcp-server.log`

**Log Format:**
```json
{
  "timestamp": "2026-01-29T10:30:00.000Z",
  "level": "info",
  "message": "Task completed",
  "taskId": "research-1234567890",
  "duration_ms": 45000,
  "success": true
}
```

**Log Levels:**
- `info` - Normal operations
- `warn` - Issues that don't stop execution
- `error` - Failures with details
- `debug` - Verbose information

**View Logs:**
```bash
# Tail logs in real-time
tail -f ../logs/mcp-server.log

# Search for errors
grep '"level":"error"' ../logs/mcp-server.log | jq .

# See specific task
grep '"taskId":"research-' ../logs/mcp-server.log | jq .
```

### 2. ✅ Tool Versioning

**Every tool includes version:**
```json
{
  "name": "research",
  "version": "1.0.0",
  "description": "..."
}
```

**Benefits:**
- Track which version was used
- Handle breaking changes
- Backward compatibility
- Clear deprecation path

**Version Format:** Semantic Versioning (MAJOR.MINOR.PATCH)
- `1.0.0` → `2.0.0` = Breaking change
- `1.0.0` → `1.1.0` = New features
- `1.0.0` → `1.0.1` = Bug fixes

### 3. ✅ Progress Notifications

**Real-time progress updates every 5 seconds:**

```
[PROGRESS] research: Running for 5s...
[PROGRESS] research: Running for 10s...
[PROGRESS] research: Received 50KB...
[PROGRESS] research: Running for 15s...
```

**Benefits:**
- Know the task is still running
- See data being received
- Catch hangs early
- Better UX in Claude Code

**Configure Update Interval:**
```bash
# Update every 3 seconds instead of 5
SAVE_MY_TOKENS_PROGRESS_INTERVAL=3000 node mcp-server-production.js
```

### 4. ✅ Dynamic Tool Discovery

**Automatically discovers tasks from `tasks/*.json` files!**

**How it works:**
1. Server starts
2. Scans `tasks/` directory
3. Reads all `.json` files
4. Registers tools automatically
5. No code changes needed!

**Adding a new task:**
```bash
# 1. Create task file
cat > tasks/translate.json << 'EOF'
{
  "name": "translate",
  "description": "Translate text between languages",
  "multi_model": false,
  "providers": ["cerebras", "mistral"]
}
EOF

# 2. Restart MCP server
# 3. New 'translate' tool automatically available!
```

**Benefits:**
- Zero code changes for new tasks
- Consistent with Save My Tokens' dynamic system
- Easy to maintain
- Team can add tasks without touching code

### 5. ✅ Timeout Protection

**Prevents infinite hangs:**

**Default Timeout:** 5 minutes (300 seconds)

**Configure Global Timeout:**
```bash
# Set 10 minute timeout
export SAVE_MY_TOKENS_TIMEOUT=600000
```

**Per-Task Timeout:**
```javascript
Use the research tool with prompt="..." and timeout_seconds=120
```

**What happens on timeout:**
1. Warning logged
2. Process killed (SIGTERM)
3. If doesn't die, force kill (SIGKILL) after 5s
4. Clear error returned to user
5. Task cleaned up

**Error Message:**
```
Error: Task timeout after 300s.

Check logs: /path/to/logs/mcp-server.log
```

### 6. ✅ Enhanced Error Handling

**No more silent failures!**

**Error Categories:**

1. **Validation Errors** (immediate)
   - Invalid prompt
   - Prompt too long
   - Missing required fields

2. **Configuration Errors** (with help)
   - Router not found → "Run health check"
   - No API keys → "Configure .env.savemytokens"

3. **Execution Errors** (with context)
   - Router failed → Exit code + stderr
   - Timeout → Duration + log location
   - Spawn failed → Error message + help

**Every error includes:**
- Clear error message
- Log file location
- Suggested next steps

### 7. ✅ Task Management

**Track running tasks:**
- Each task gets unique ID
- Tracked in server memory
- Cleaned up on completion
- Killed on shutdown

**Graceful Shutdown:**
```bash
# Send SIGTERM (Ctrl+C)
^C

# Server:
# 1. Logs shutdown request
# 2. Kills all running tasks
# 3. Waits 2s for cleanup
# 4. Force kills remaining
# 5. Exits cleanly
```

---

## Configuration

### Environment Variables

```bash
# Timeout for all tasks (milliseconds)
SAVE_MY_TOKENS_TIMEOUT=300000  # 5 minutes

# Progress update interval (milliseconds)
SAVE_MY_TOKENS_PROGRESS_INTERVAL=5000  # 5 seconds

# Enable debug logging
SAVE_MY_TOKENS_DEBUG=true
```

### Per-Task Settings

```javascript
// In tool call
{
  "prompt": "research query",
  "timeout_seconds": 120  // Override global timeout
}
```

---

## Troubleshooting Silent Hangs

### If a Task Hangs:

**1. Check Progress:**
Look for progress messages in stderr:
```
[PROGRESS] research: Running for 5s...
```

If you see these, it's still working.

**2. Check Logs:**
```bash
tail -f logs/mcp-server.log | jq .
```

Look for:
- Last progress update
- Any error messages
- Router stderr output

**3. Force Timeout:**
Send SIGTERM to kill gracefully:
```bash
pkill -f "mcp-server-production"
```

**4. Check Router Logs:**
```bash
cat logs/router.log | tail -50
```

### Common Hang Causes:

1. **Router stuck waiting for input**
   - Fix: Ensure router doesn't prompt for user input
   - Check: stdin handling in router.sh

2. **Model API timeout**
   - Fix: Add timeouts to provider wrappers
   - Check: Network connectivity

3. **Infinite loop in router**
   - Fix: Debug router.sh logic
   - Check: Loop conditions

4. **Process zombie**
   - Fix: Ensure proper process cleanup
   - Check: Child process handling

---

## Performance Monitoring

### View Task Metrics:

```bash
# Average duration by task
grep '"level":"info"' logs/mcp-server.log | \
  grep '"duration_ms"' | \
  jq -r '[.task, .duration_ms] | @tsv' | \
  awk '{sum[$1]+=$2; count[$1]++} END {for(t in sum) print t, sum[t]/count[t]}'

# Error rate
echo "Errors: $(grep '"level":"error"' logs/mcp-server.log | wc -l)"
echo "Total: $(grep '"tool":"' logs/mcp-server.log | wc -l)"

# Slowest tasks
grep '"duration_ms"' logs/mcp-server.log | \
  jq -r '[.taskId, .task, .duration_ms] | @tsv' | \
  sort -k3 -n | tail -10
```

---

## Migration from Basic Server

### Step 1: Test Production Server

```bash
# Make executable
chmod +x mcp-server-production.js

# Test health check
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}
{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"health","arguments":{}}}' | \
node mcp-server-production.js 2>&1 | tail -1 | jq '.result.content[0].text | fromjson'
```

### Step 2: Update Configuration

```bash
# Backup current
cp ~/.claude.json ~/.claude.json.backup

# Update to use production server
./install-mcp-claude-enhanced.sh --user
```

Then edit `~/.claude.json` to use `mcp-server-production.js`:
```json
{
  "mcpServers": {
    "save-my-tokens": {
      "type": "stdio",
      "command": "node",
      "args": ["/path/to/mcp-server-production.js"],
      "env": {
        "SAVE_MY_TOKENS_TIMEOUT": "300000"
      }
    }
  }
}
```

### Step 3: Test

1. Restart Claude Code
2. Run health check: `Use the health tool`
3. Test a quick task: `Use research tool with prompt="test"`
4. Check logs: `tail logs/mcp-server.log`

---

## Comparison: Basic vs Production

| Feature | Basic | Enhanced | **Production** |
|---------|-------|----------|----------------|
| Timeout protection | ❌ | ❌ | ✅ 5min default |
| Progress updates | ❌ | ❌ | ✅ Every 5s |
| Structured logging | ❌ | ❌ | ✅ JSON logs |
| Tool versioning | ❌ | ❌ | ✅ Semantic |
| Dynamic discovery | ❌ | ❌ | ✅ Auto-scan |
| Graceful shutdown | ❌ | ❌ | ✅ Clean exit |
| Error context | Basic | Better | ✅ Full context |
| Health check | ❌ | ✅ | ✅ Enhanced |
| Response metadata | ❌ | ✅ | ✅ More detail |

---

## Best Practices

### 1. Monitor Logs

Set up log rotation:
```bash
# In cron
0 0 * * * gzip logs/mcp-server.log && mv logs/mcp-server.log.gz logs/archive/
```

### 2. Set Reasonable Timeouts

```bash
# Quick tasks: 1-2 minutes
timeout_seconds=120

# Research tasks: 3-5 minutes
timeout_seconds=300

# Complex tasks: 5-10 minutes
timeout_seconds=600
```

### 3. Check Health Regularly

```bash
# Add to monitoring
Use the health tool to check status
```

### 4. Review Error Logs

```bash
# Weekly error review
grep '"level":"error"' logs/mcp-server.log | \
  jq -r '[.timestamp, .message, .error] | @tsv' > errors-weekly.txt
```

---

## Summary

The production server **solves the silent hang problem** with:

1. ✅ **5-minute timeout** - Never hangs indefinitely
2. ✅ **Progress every 5s** - Always know it's working
3. ✅ **Full logging** - Debug any issue
4. ✅ **Clear errors** - No silent failures
5. ✅ **Auto-discovery** - Easy to add tasks
6. ✅ **Versioning** - Handle changes properly

**No more waiting forever for hung tasks!**
