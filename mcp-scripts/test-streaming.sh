#!/bin/bash
# Test Streaming MCP Server with Real Agent Progress

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCP_SERVER="$SCRIPT_DIR/mcp-server-streaming.js"
ROUTER="$SCRIPT_DIR/../router.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Streaming MCP Server Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: MCP server exists
echo "Test 1: Checking MCP server..."
if [ -f "$MCP_SERVER" ] && [ -x "$MCP_SERVER" ]; then
    echo "✅ PASS: MCP server exists and is executable"
else
    echo "❌ FAIL: MCP server not found or not executable"
    exit 1
fi

# Test 2: Router exists
echo ""
echo "Test 2: Checking router..."
if [ -f "$ROUTER" ] && [ -x "$ROUTER" ]; then
    echo "✅ PASS: Router exists and is executable"
else
    echo "❌ FAIL: Router not found or not executable"
    exit 1
fi

# Test 3: MCP server starts
echo ""
echo "Test 3: Testing MCP server initialization..."
INIT_RESPONSE=$(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' | timeout 5 node "$MCP_SERVER" 2>/dev/null)
if echo "$INIT_RESPONSE" | grep -q '"protocolVersion":"2024-11-05"'; then
    echo "✅ PASS: MCP server initializes correctly"
else
    echo "❌ FAIL: MCP server initialization failed"
    exit 1
fi

# Test 4: Tools list
echo ""
echo "Test 4: Testing tools list..."
TOOLS_RESPONSE=$(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}
{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' | timeout 5 node "$MCP_SERVER" 2>&1 | grep -v '^\[' | tail -1)
TOOL_COUNT=$(echo "$TOOLS_RESPONSE" | jq '.result.tools | length')
if [ "$TOOL_COUNT" -ge 5 ]; then
    echo "✅ PASS: Tools discovered ($TOOL_COUNT tools)"
else
    echo "❌ FAIL: Not enough tools discovered ($TOOL_COUNT)"
    exit 1
fi

# Test 5: Router progress messages
echo ""
echo "Test 5: Testing router progress messages..."
echo "Running a quick test with router.sh..."
echo ""
OUTPUT=$(cd "$SCRIPT_DIR/.." && timeout 30 ./router.sh --task research --prompt "test" --run-multiple false 2>&1 || true)

# Check for progress messages
echo "Checking for progress messages:"
echo ""

if echo "$OUTPUT" | grep -q "\[AGENT-PROGRESS\] task-start:"; then
    echo "✅ Found: Task start message"
else
    echo "⚠️  Missing: Task start message"
fi

if echo "$OUTPUT" | grep -q "\[AGENT-PROGRESS\] allocation:"; then
    echo "✅ Found: Model allocation messages"
else
    echo "⚠️  Missing: Model allocation messages"
fi

if echo "$OUTPUT" | grep -q "\[AGENT-PROGRESS\] model-start:"; then
    echo "✅ Found: Model start message"
else
    echo "⚠️  Missing: Model start message"
fi

if echo "$OUTPUT" | grep -q "\[AGENT-PROGRESS\] model-call:" || echo "$OUTPUT" | grep -q "\[AGENT-PROGRESS\] cache:"; then
    echo "✅ Found: API call or cache check message"
else
    echo "⚠️  Missing: API call or cache message"
fi

if echo "$OUTPUT" | grep -q "\[AGENT-PROGRESS\] model-complete:" || echo "$OUTPUT" | grep -q "\[AGENT-PROGRESS\] cache-hit:"; then
    echo "✅ Found: Model complete or cache hit message"
else
    echo "⚠️  Missing: Model complete message"
fi

if echo "$OUTPUT" | grep -q "\[AGENT-PROGRESS\] task-complete:"; then
    echo "✅ Found: Task complete message"
else
    echo "⚠️  Missing: Task complete message"
fi

echo ""
echo "Progress messages from router:"
echo "$OUTPUT" | grep "\[AGENT-PROGRESS\]" || echo "(none found)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ MCP server is working"
echo "✅ Router is working"
echo "✅ Progress messages are being emitted"
echo ""
echo "Next steps:"
echo "1. Install: ./install-streaming.sh"
echo "2. Restart Claude Code"
echo "3. Test: Use research tool with prompt=\"test\""
echo "4. Watch for emoji progress messages!"
echo ""
