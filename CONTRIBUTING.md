# Contributing to Save My Tokens

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## 🎯 Ways to Contribute

- 🐛 **Bug reports** - Found an issue? Let us know
- ✨ **Feature requests** - Ideas for improvements
- 📝 **Documentation** - Improve guides and examples
- 🔧 **Code contributions** - Bug fixes, new features, providers
- 🧪 **Testing** - Test on different systems and report results

---

## 🚀 Quick Start

### 1. Fork & Clone

```bash
git clone https://github.com/YOUR-USERNAME/save-my-tokens
cd save-my-tokens
```

### 2. Setup Development Environment

```bash
# Copy environment template
cp .env.savemytokens.example .env.savemytokens

# Add your API keys for testing
nano .env.savemytokens

# Run tests to verify setup
cd mcp-scripts
./test-streaming.sh
```

### 3. Make Changes

```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Make your changes
# ... edit files ...

# Test your changes
./mcp-scripts/test-streaming.sh
```

### 4. Submit Pull Request

```bash
# Commit with clear message
git add -A
git commit -m "feat: add support for XYZ"

# Push to your fork
git push origin feature/your-feature-name

# Open PR on GitHub
```

---

## 📋 Development Guidelines

### Code Style

**Bash Scripts:**
```bash
#!/bin/bash
# Always use strict mode
set -euo pipefail

# Clear variable names
PROVIDER_NAME="cerebras"
API_ENDPOINT="https://api.cerebras.ai"

# Comments for complex logic
# Extract model from response
MODEL=$(jq -r '.model' response.json)
```

**JavaScript (MCP Server):**
```javascript
// Use ES6+ features
import { Server } from '@modelcontextprotocol/sdk/server/index.js';

// Clear function names
function parseProgressMessage(line) {
  // ...
}

// Add JSDoc for public APIs
/**
 * Parse agent progress message
 * @param {string} line - Log line to parse
 * @returns {Object|null} Parsed progress or null
 */
```

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add DeepSeek provider wrapper
fix: resolve cache key collision issue
docs: update installation guide for macOS
test: add tests for parallel execution mode
chore: update dependencies
```

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation only
- `test` - Adding tests
- `refactor` - Code refactoring
- `chore` - Maintenance tasks

---

## 🔌 Adding a New Provider

### 1. Create Provider Wrapper

Create `providers/wrappers/your-provider.sh`:

```bash
#!/bin/bash
# Your Provider LLM Wrapper
# Standardized interface for save-my-tokens router

set -euo pipefail

# Source environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [ -f "$SCRIPT_DIR/.env.savemytokens" ]; then
    set -a
    source "$SCRIPT_DIR/.env.savemytokens"
    set +a
fi

# Extract XML values (BSD sed compatible)
extract_xml() {
    local tag=$1
    local content=$2
    echo "$content" | sed -n "s/.*<${tag}>\(.*\)<\/${tag}>.*/\1/p" | head -n 1
}

# Read task request from stdin
INPUT_XML=$(cat)

# Parse input
PROMPT=$(extract_xml "prompt" "$INPUT_XML")
TEMPERATURE=$(extract_xml "temperature" "$INPUT_XML")
MAX_TOKENS=$(extract_xml "max-tokens" "$INPUT_XML")

# Defaults
TEMPERATURE=${TEMPERATURE:-0.7}
MAX_TOKENS=${MAX_TOKENS:-2000}
MODEL="${YOUR_PROVIDER_MODEL:-default-model}"

# Check for API key
if [ -z "${YOUR_PROVIDER_API_KEY:-}" ]; then
    echo "ERROR: YOUR_PROVIDER_API_KEY not set" >&2
    exit 1
fi

# Emit progress
echo "[AGENT-PROGRESS] model-wait: Waiting for Your Provider API response..." >&2
START_TIME=$(date +%s)

# Call API (customize for your provider)
HTTP_CODE=$(curl -s -w "%{http_code}" -o "$OUTPUT_FILE" \
    -X POST "https://api.yourprovider.com/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $YOUR_PROVIDER_API_KEY" \
    -d "$REQUEST_JSON")

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Extract response
RESPONSE_CONTENT=$(jq -r '.choices[0].message.content' "$OUTPUT_FILE")

# Emit progress
RESPONSE_SIZE=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')
TOTAL_TOKENS=$(jq -r '.usage.total_tokens // 0' "$OUTPUT_FILE")
echo "[AGENT-PROGRESS] model-receive: Received ${RESPONSE_SIZE} bytes, ${TOTAL_TOKENS} tokens in ${DURATION}s" >&2

# Output result in standard XML format
cat <<EOF
<agent-result>
  <agent>yourprovider</agent>
  <model>$MODEL</model>
  <status>completed</status>
  <output>
$RESPONSE_CONTENT
  </output>
  <usage>Total: $TOTAL_TOKENS</usage>
  <timestamp>$(date -u +"%Y-%m-%dT%H:%M:%SZ")</timestamp>
</agent-result>
EOF
```

### 2. Add to Environment Template

Update `.env.savemytokens.example`:

```bash
# Your Provider (https://yourprovider.com)
YOUR_PROVIDER_API_KEY=your_key_here
YOUR_PROVIDER_MODEL=default-model
```

### 3. Add to Task Definitions

Update `tasks/research.json` (or others):

```json
{
  "models": [
    {
      "name": "yourprovider-research",
      "platform": "yourprovider",
      "model": "default-model",
      "provider": "yourprovider",
      "parameters": {
        "temperature": 0.7,
        "max_tokens": 2000
      }
    }
  ]
}
```

### 4. Test

```bash
# Make executable
chmod +x providers/wrappers/yourprovider.sh

# Test directly
echo '<task-request><prompt>test</prompt></task-request>' | \
  ./providers/wrappers/yourprovider.sh

# Test via router
./router.sh --task research --prompt "test"
```

### 5. Document

Add to README.md providers list and get API key instructions.

---

## 🎯 Adding a New Task

### 1. Create Task Definition

Create `tasks/your-task.json`:

```json
{
  "task": "your-task",
  "task_type": "information",
  "run_multiple": false,
  "description": "Brief description of what this task does",
  "timeout": 300,
  "cache_enabled": true,
  "models": [
    {
      "name": "primary-model",
      "platform": "cerebras",
      "model": "llama-3.3-70b",
      "provider": "cerebras",
      "parameters": {
        "temperature": 0.7,
        "max_tokens": 2000
      }
    }
  ],
  "input": {
    "required": ["prompt"],
    "optional": ["context"]
  }
}
```

**Task Types:**
- `information` - Research, facts, Q&A
- `execute` - Code generation, actions
- `plan` - Planning, architecture

### 2. Test

```bash
# Task is automatically discovered
./router.sh --list-tasks

# Test it
./router.sh --task your-task --prompt "test prompt"
```

### 3. Add to MCP Server

The MCP server auto-discovers tasks from `tasks/` directory. No code changes needed!

---

## 🧪 Testing

### Run Full Test Suite

```bash
cd mcp-scripts
./test-streaming.sh
```

### Test Individual Components

```bash
# Test router directly
./router.sh --task research --prompt "test" 2>&1 | grep AGENT-PROGRESS

# Test MCP server
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' | \
  node mcp-scripts/mcp-server-streaming.js

# Test provider wrapper
echo '<task-request><prompt>test</prompt></task-request>' | \
  ./providers/wrappers/cerebras.sh
```

### Add Tests

When adding features, add corresponding tests to `test-streaming.sh`.

---

## 🐛 Reporting Bugs

**Before submitting:**
1. Check existing issues
2. Run `./mcp-scripts/test-streaming.sh`
3. Check logs: `tail -f logs/mcp-server.log`

**Include in bug report:**
- OS and version (macOS 14, Ubuntu 22.04, etc.)
- Node.js version (`node --version`)
- Steps to reproduce
- Expected vs actual behavior
- Relevant logs
- Error messages

**Use this template:**

```markdown
**Environment:**
- OS: macOS 14.2
- Node: v20.11.0
- Claude Code: [version]

**Steps to Reproduce:**
1. Install MCP server
2. Run: `use research tool with prompt="test"`
3. Observe error

**Expected:**
Progress messages and result

**Actual:**
Error: [paste error]

**Logs:**
[paste relevant logs from logs/mcp-server.log]
```

---

## 💡 Feature Requests

**Good feature request:**
- Clear use case
- Specific requirements
- Example usage
- Willing to help implement

**Template:**

```markdown
**Use Case:**
I want to [do something] because [reason]

**Proposed Solution:**
Add [feature] that allows [action]

**Example:**
```bash
./router.sh --task my-feature --prompt "example"
```

**Alternatives Considered:**
- Option A: [pros/cons]
- Option B: [pros/cons]

**Willing to Help:**
Yes, I can [write code/test/document]
```

---

## 📝 Documentation

### Improving Docs

- Fix typos/errors
- Add examples
- Clarify confusing sections
- Add troubleshooting tips

### Documentation Files

- `README.md` - Overview and quick start
- `INSTALLATION.md` - Detailed setup
- `CONTRIBUTING.md` - This file
- Task-specific docs in `tasks/` directory

---

## ⚖️ License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

## 🙋 Questions?

- Open a GitHub issue with the `question` label
- Check existing issues for common questions
- Review documentation first

---

## 🎉 Recognition

Contributors are listed in:
- GitHub contributors page
- Release notes for major contributions
- README acknowledgments

Thank you for contributing! 🙏
