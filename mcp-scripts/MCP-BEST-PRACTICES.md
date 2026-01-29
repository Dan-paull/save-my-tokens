# MCP Best Practices for Save My Tokens

## Current Implementation

### ✅ Already Implemented

1. **Official MCP SDK Usage**
   - Using `@modelcontextprotocol/sdk` instead of manual protocol implementation
   - Proper request handler registration
   - Standard stdio transport

2. **Error Handling**
   - Try-catch blocks in tool execution
   - Graceful fallbacks when router.sh is unavailable
   - Proper error responses with `isError: true`

3. **Tool Metadata**
   - Clear tool names and descriptions
   - Detailed input schemas with type validation
   - Required vs optional parameters clearly defined

4. **Process Management**
   - Proper child process spawning
   - Output buffering and parsing
   - Cleanup on process completion

## Recommended Improvements

### 1. Installation Scope (✅ Added)

**Enhancement:** Support both user-level and project-level installation

```bash
# User-level (global)
./install-mcp-claude-enhanced.sh --user

# Project-level (directory-specific)
./install-mcp-claude-enhanced.sh --project
```

**Benefits:**
- User-level: Available in all projects, single configuration
- Project-level: Team can share MCP config via `.mcp.json` in git

### 2. Environment Variables

**Current:** Environment variables are loaded from `.env.savemytokens`

**Enhancement:** Pass environment variables through MCP configuration

```json
{
  "mcpServers": {
    "save-my-tokens": {
      "type": "stdio",
      "command": "node",
      "args": ["/path/to/mcp-server.js"],
      "env": {
        "CEREBRAS_API_KEY": "${CEREBRAS_API_KEY}",
        "MISTRAL_API_KEY": "${MISTRAL_API_KEY}"
      }
    }
  }
}
```

**Benefits:**
- Centralized environment management
- Claude Code can resolve environment variables
- Easier debugging (can see what env vars are passed)

### 3. Logging and Debugging

**Recommended Addition:**

```javascript
// Add to mcp-server.js
const LOG_FILE = process.env.SAVE_MY_TOKENS_LOG ||
                 join(dirname(__dirname), 'logs', 'mcp-server.log');

function log(level, message, data = {}) {
  const timestamp = new Date().toISOString();
  const logEntry = JSON.stringify({ timestamp, level, message, ...data });
  fs.appendFileSync(LOG_FILE, logEntry + '\n');
}
```

**Benefits:**
- Debug tool execution issues
- Monitor performance
- Track usage patterns

### 4. Health Check Tool

**Recommended Addition:**

```javascript
{
  name: 'health',
  description: 'Check Save My Tokens system health and configuration',
  inputSchema: {
    type: 'object',
    properties: {},
    required: []
  }
}
```

**Returns:**
- Router availability
- API key configuration status
- Enabled platforms
- Recent error rate

### 5. Tool Response Metadata

**Enhancement:** Include metadata in tool responses

```javascript
return {
  content: [
    {
      type: 'text',
      text: result
    }
  ],
  _meta: {
    model: 'llama-3.3-70b',
    provider: 'cerebras',
    cached: false,
    duration_ms: 1234,
    tokens: { prompt: 150, completion: 450 }
  }
};
```

**Benefits:**
- Transparency about which model was used
- Cost tracking
- Performance monitoring

### 6. Rate Limiting and Throttling

**Recommended Addition:**

```javascript
class RateLimiter {
  constructor(maxRequestsPerMinute = 60) {
    this.requests = [];
    this.maxRequests = maxRequestsPerMinute;
  }

  async checkLimit() {
    const now = Date.now();
    const oneMinuteAgo = now - 60000;
    this.requests = this.requests.filter(t => t > oneMinuteAgo);

    if (this.requests.length >= this.maxRequests) {
      throw new Error('Rate limit exceeded');
    }

    this.requests.push(now);
  }
}
```

**Benefits:**
- Prevent API quota exhaustion
- Protect against runaway requests
- Better error messages when limits hit

### 7. Caching Support

**Enhancement:** Expose cache control to MCP clients

```javascript
{
  name: 'research',
  description: 'Multi-model research with diverse perspectives',
  inputSchema: {
    type: 'object',
    properties: {
      prompt: { type: 'string' },
      context: { type: 'string' },
      run_multiple: { type: 'boolean' },
      use_cache: {
        type: 'boolean',
        description: 'Use cached results if available',
        default: true
      },
      cache_ttl: {
        type: 'number',
        description: 'Cache TTL in seconds',
        default: 3600
      }
    }
  }
}
```

**Benefits:**
- User control over caching behavior
- Faster responses for repeated queries
- Reduced API costs

### 8. Progress Streaming

**Recommended for Long Operations:**

```javascript
// Use Server-Sent Events for progress updates
async executeTask(task, prompt, options) {
  return new Promise((resolve) => {
    const child = spawn(this.routerPath, args);

    let buffer = '';
    child.stdout.on('data', (data) => {
      buffer += data.toString();

      // Check for progress markers
      if (buffer.includes('[PROGRESS]')) {
        // Send progress notification to client
        this.server.notification({
          method: 'tools/progress',
          params: {
            task,
            progress: extractProgress(buffer)
          }
        });
      }
    });
  });
}
```

**Benefits:**
- Better UX for long-running tasks
- User knows something is happening
- Can show which model is currently running

### 9. Tool Discovery and Capabilities

**Enhancement:** Dynamic tool discovery based on configuration

```javascript
async getAvailableTools() {
  const tasksDir = join(this.freeAgentsPath, 'tasks');
  const taskFiles = fs.readdirSync(tasksDir)
    .filter(f => f.endsWith('.json'));

  return taskFiles.map(file => {
    const task = JSON.parse(fs.readFileSync(join(tasksDir, file)));
    return {
      name: task.name,
      description: task.description,
      inputSchema: generateSchema(task)
    };
  });
}
```

**Benefits:**
- Automatic tool registration when new tasks added
- Consistent with Save My Tokens' dynamic task discovery
- Easier to maintain

### 10. Security Considerations

**Recommended:**

1. **Input Validation:**
   ```javascript
   function validateInput(prompt) {
     if (prompt.length > 10000) {
       throw new Error('Prompt too long (max 10000 chars)');
     }
     // Sanitize dangerous characters
     return prompt.replace(/[<>]/g, '');
   }
   ```

2. **Path Traversal Prevention:**
   ```javascript
   const resolvedPath = path.resolve(this.freeAgentsPath, userPath);
   if (!resolvedPath.startsWith(this.freeAgentsPath)) {
     throw new Error('Invalid path');
   }
   ```

3. **Command Injection Prevention:**
   - Already using `spawn()` with array args (good!)
   - Don't use shell: true
   - Don't concatenate user input into commands

### 11. Graceful Shutdown

**Recommended Addition:**

```javascript
async shutdown() {
  // Cancel any running tasks
  if (this.runningTasks.size > 0) {
    console.error('Canceling running tasks...');
    for (const [taskId, child] of this.runningTasks) {
      child.kill('SIGTERM');
    }
  }

  // Close transport
  await this.server.close();
}

process.on('SIGTERM', () => server.shutdown());
process.on('SIGINT', () => server.shutdown());
```

### 12. Version Compatibility

**Recommended:**

```javascript
{
  name: 'save-my-tokens',
  version: '1.0.0',
  protocolVersion: '2024-11-05',
  capabilities: {
    tools: {},
    // Future: resources, prompts
  }
}
```

## Configuration Best Practices

### User-Level vs Project-Level

**User-Level (`~/.claude.json`):**
- Use for personal tools
- Available in all projects
- Single place to manage API keys

**Project-Level (`.mcp.json`):**
- Use for team-shared tools
- Commit to git (without sensitive data)
- Project-specific configuration

### Environment Variables

**Good:**
```json
{
  "mcpServers": {
    "save-my-tokens": {
      "env": {
        "CEREBRAS_API_KEY": "${CEREBRAS_API_KEY}"
      }
    }
  }
}
```

**Bad:**
```json
{
  "mcpServers": {
    "save-my-tokens": {
      "env": {
        "CEREBRAS_API_KEY": "csk-12345..."  // Don't hardcode!
      }
    }
  }
}
```

## Testing Best Practices

1. **Unit Tests:** Test individual functions
2. **Integration Tests:** Test MCP protocol compliance
3. **End-to-End Tests:** Test actual tool execution
4. **Performance Tests:** Measure response times

## Documentation Best Practices

1. **Clear Tool Descriptions:** Explain what each tool does
2. **Input Examples:** Show example inputs
3. **Output Format:** Document response structure
4. **Error Handling:** List possible errors
5. **Rate Limits:** Document any limitations

## Monitoring and Observability

1. **Metrics to Track:**
   - Request count per tool
   - Average response time
   - Error rate
   - API costs
   - Cache hit rate

2. **Logging:**
   - Request/response pairs
   - Errors with stack traces
   - Performance metrics
   - Model selection decisions

## Implementation Priority

1. ✅ **High Priority (Implemented):**
   - User/project installation scope
   - Environment variable support
   - Error handling

2. 🟡 **Medium Priority (Recommended):**
   - Health check tool
   - Response metadata
   - Logging system

3. 🔵 **Low Priority (Nice to Have):**
   - Progress streaming
   - Rate limiting
   - Dynamic tool discovery

## Summary

The Save My Tokens implementation already follows many best practices. The enhanced installation script adds crucial user/project-level support. Additional improvements can be added incrementally based on user needs.
