#!/bin/bash
# Complete Kiro CLI MCP Server Simulation Test

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCP_SERVER="$SCRIPT_DIR/mcp-server-kiro.js"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Complete Kiro CLI MCP Simulation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: Simulate exactly how Kiro CLI starts the server
echo "Test 1: Kiro CLI startup simulation..."
{
    # Start the server in background
    node "$MCP_SERVER" &
    SERVER_PID=$!
    
    # Give it time to start
    sleep 0.5
    
    # Check if process is still running
    if kill -0 $SERVER_PID 2>/dev/null; then
        echo "✓ PASS: Server starts and stays running"
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
    else
        echo "✗ FAIL: Server exits immediately"
        exit 1
    fi
}

# Test 2: Test with pipe that stays open (like Kiro CLI does)
echo ""
echo "Test 2: Persistent connection simulation..."
{
    # Create a named pipe
    PIPE=$(mktemp -u)
    mkfifo "$PIPE"
    
    # Start server with pipe
    node "$MCP_SERVER" < "$PIPE" &
    SERVER_PID=$!
    
    # Open pipe for writing
    exec 3>"$PIPE"
    
    # Send initialize
    echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' >&3
    sleep 0.5
    
    # Check if server is still running
    if kill -0 $SERVER_PID 2>/dev/null; then
        echo "✓ PASS: Server handles persistent connection"
        
        # Send tools/list
        echo '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' >&3
        sleep 0.5
        
        if kill -0 $SERVER_PID 2>/dev/null; then
            echo "✓ PASS: Server handles multiple requests"
        else
            echo "✗ FAIL: Server dies after second request"
            exit 1
        fi
    else
        echo "✗ FAIL: Server dies on persistent connection"
        exit 1
    fi
    
    # Cleanup
    exec 3>&-
    kill $SERVER_PID 2>/dev/null || true
    wait $SERVER_PID 2>/dev/null || true
    rm -f "$PIPE"
}

# Test 3: Test exact Kiro CLI command
echo ""
echo "Test 3: Exact Kiro CLI command simulation..."
KIRO_CONFIG="/Users/danpaull/.kiro/settings/mcp.json"
if [ -f "$KIRO_CONFIG" ]; then
    # Extract the exact command Kiro CLI would run
    COMMAND=$(cat "$KIRO_CONFIG" | grep -A 10 '"save-my-tokens"' | grep '"command"' | cut -d'"' -f4)
    ARGS=$(cat "$KIRO_CONFIG" | grep -A 10 '"save-my-tokens"' | grep -A 5 '"args"' | grep '"/Users' | cut -d'"' -f2)
    
    if [ "$COMMAND" = "node" ] && [ -n "$ARGS" ]; then
        echo "Testing exact command: $COMMAND $ARGS"
        
        # Test the exact command
        echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | timeout 5 $COMMAND "$ARGS" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "✓ PASS: Exact Kiro CLI command works"
        else
            echo "✗ FAIL: Exact Kiro CLI command fails"
            exit 1
        fi
    else
        echo "✗ FAIL: Could not parse Kiro CLI config"
        exit 1
    fi
else
    echo "✗ FAIL: Kiro CLI config not found"
    exit 1
fi

# Test 4: Test with stderr/stdout handling like Kiro CLI
echo ""
echo "Test 4: Kiro CLI I/O handling simulation..."
{
    # Test with proper I/O redirection
    OUTPUT=$(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | timeout 5 node "$MCP_SERVER" 2>/dev/null)
    
    if echo "$OUTPUT" | grep -q '"protocolVersion"'; then
        echo "✓ PASS: I/O handling works correctly"
    else
        echo "✗ FAIL: I/O handling broken"
        echo "Output: $OUTPUT"
        exit 1
    fi
}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ ALL KIRO CLI SIMULATION TESTS PASSED!"
echo "  MCP Server is ready for Kiro CLI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
