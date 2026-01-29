#!/bin/bash
# Final MCP Server Validation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCP_SERVER="$SCRIPT_DIR/mcp-server-kiro.js"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Final MCP Server Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: Server responds to initialize
echo "Test 1: Initialize response..."
RESPONSE=$(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | timeout 3 node "$MCP_SERVER" 2>/dev/null || echo "timeout")
if echo "$RESPONSE" | grep -q '"protocolVersion":"2024-11-05"'; then
    echo "✓ PASS: Initialize works"
else
    echo "✗ FAIL: Initialize failed"
    echo "Response: $RESPONSE"
    exit 1
fi

# Test 2: Server stays alive when started
echo ""
echo "Test 2: Server persistence..."
{
    node "$MCP_SERVER" &
    SERVER_PID=$!
    sleep 1
    if kill -0 $SERVER_PID 2>/dev/null; then
        echo "✓ PASS: Server stays alive"
        kill $SERVER_PID 2>/dev/null
        wait $SERVER_PID 2>/dev/null || true
    else
        echo "✗ FAIL: Server exits immediately"
        exit 1
    fi
}

# Test 3: Kiro CLI config is correct
echo ""
echo "Test 3: Kiro CLI configuration..."
KIRO_CONFIG="/Users/danpaull/.kiro/settings/mcp.json"
if [ -f "$KIRO_CONFIG" ]; then
    if grep -q "mcp-server-kiro.js" "$KIRO_CONFIG"; then
        echo "✓ PASS: Kiro CLI config points to correct server"
    else
        echo "✗ FAIL: Kiro CLI config incorrect"
        cat "$KIRO_CONFIG"
        exit 1
    fi
else
    echo "✗ FAIL: Kiro CLI config not found"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ ALL VALIDATION TESTS PASSED!"
echo ""
echo "  The MCP server is now ready for Kiro CLI."
echo "  Restart Kiro CLI and run /mcp to verify."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
