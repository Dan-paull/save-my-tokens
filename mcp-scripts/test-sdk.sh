#!/bin/bash
# Final SDK MCP Server Test

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCP_SERVER="$SCRIPT_DIR/mcp-server-sdk.js"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Final SDK MCP Server Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: Initialize
echo "Test 1: Initialize..."
RESPONSE=$(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' | timeout 5 node "$MCP_SERVER" 2>/dev/null)
if echo "$RESPONSE" | grep -q '"protocolVersion":"2024-11-05"'; then
    echo "✓ PASS: Initialize works"
else
    echo "✗ FAIL: Initialize failed"
    echo "Response: $RESPONSE"
    exit 1
fi

# Test 2: Tools list
echo ""
echo "Test 2: Tools list..."
RESPONSE=$(echo -e '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}\n{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' | timeout 10 node "$MCP_SERVER" 2>/dev/null | tail -1)
if echo "$RESPONSE" | grep -q '"name":"research"'; then
    echo "✓ PASS: Tools list works"
else
    echo "✗ FAIL: Tools list failed"
    echo "Response: $RESPONSE"
    exit 1
fi

# Test 3: Tool call
echo ""
echo "Test 3: Tool call..."
RESPONSE=$(echo -e '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}\n{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"research","arguments":{"prompt":"test query"}}}' | timeout 15 node "$MCP_SERVER" 2>/dev/null | tail -1)
if echo "$RESPONSE" | grep -q '"content"'; then
    echo "✓ PASS: Tool call works"
else
    echo "✗ FAIL: Tool call failed"
    echo "Response: $RESPONSE"
    exit 1
fi

# Test 4: Server persistence
echo ""
echo "Test 4: Server persistence..."
{
    node "$MCP_SERVER" &
    SERVER_PID=$!
    sleep 2
    if kill -0 $SERVER_PID 2>/dev/null; then
        echo "✓ PASS: Server stays alive"
        kill $SERVER_PID 2>/dev/null
        wait $SERVER_PID 2>/dev/null || true
    else
        echo "✗ FAIL: Server exits immediately"
        exit 1
    fi
}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ ALL SDK TESTS PASSED!"
echo ""
echo "  The MCP server is ready for Kiro CLI."
echo "  Restart Kiro CLI and test /mcp"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
