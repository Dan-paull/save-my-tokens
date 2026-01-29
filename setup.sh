#!/bin/bash
# Save My Tokens Setup Script
# One-time setup for the save-my-tokens system

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Save My Tokens Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check dependencies
echo "Checking dependencies..."
echo ""

check_command() {
    local cmd=$1
    local install_hint=$2

    if command -v "$cmd" &> /dev/null; then
        echo "  ✓ $cmd found"
        return 0
    else
        echo "  ✗ $cmd not found"
        [ -n "$install_hint" ] && echo "    Install: $install_hint"
        return 1
    fi
}

MISSING_DEPS=0

check_command "curl" || MISSING_DEPS=$((MISSING_DEPS + 1))
check_command "jq" "brew install jq" || MISSING_DEPS=$((MISSING_DEPS + 1))
# yq not needed - using JSON with jq

echo ""

if [ $MISSING_DEPS -gt 0 ]; then
    echo "⚠️  $MISSING_DEPS required dependencies missing"
    echo "Please install missing dependencies and run setup again"
    exit 1
fi

echo "✓ All dependencies found"
echo ""

# Create .env.savemytokens if it doesn't exist
if [ ! -f "$SCRIPT_DIR/.env.savemytokens" ]; then
    echo "Creating .env.savemytokens from template..."
    cp "$SCRIPT_DIR/.env.savemytokens.example" "$SCRIPT_DIR/.env.savemytokens"
    echo "✓ Created .env.savemytokens"
    echo ""
    echo "⚠️  Please edit .env.savemytokens and add your API keys:"
    echo "   - CEREBRAS_API_KEY (get from: https://inference.cerebras.ai/)"
    echo "   - MISTRAL_API_KEY (get from: https://console.mistral.ai/)"
    echo ""
else
    echo "✓ .env.savemytokens already exists"
    echo ""
fi

# Load environment
if [ -f "$SCRIPT_DIR/.env.savemytokens" ]; then
    set -a
    source "$SCRIPT_DIR/.env.savemytokens"
    set +a
fi

# Test API keys
echo "Testing API keys..."
echo ""

test_api_key() {
    local name=$1
    local var_name=$2
    local var_value="${!var_name}"

    if [ -n "$var_value" ] && [ "$var_value" != "" ]; then
        echo "  ✓ $name API key is set"
        return 0
    else
        echo "  ✗ $name API key not set ($var_name)"
        return 1
    fi
}

WORKING_KEYS=0

test_api_key "Cerebras" "CEREBRAS_API_KEY" && WORKING_KEYS=$((WORKING_KEYS + 1))
test_api_key "Mistral" "MISTRAL_API_KEY" && WORKING_KEYS=$((WORKING_KEYS + 1))

echo ""

if [ $WORKING_KEYS -eq 0 ]; then
    echo "⚠️  No API keys configured"
    echo "Please edit .env.savemytokens and add at least one API key"
    echo ""
elif [ $WORKING_KEYS -eq 1 ]; then
    echo "✓ 1 API key configured (recommended: at least 2 for failover)"
    echo ""
else
    echo "✓ $WORKING_KEYS API keys configured"
    echo ""
fi

# Validate configuration
echo "Validating configuration..."
echo ""

"$SCRIPT_DIR/router.sh" --validate

echo ""

# Discover tasks
echo "Available tasks:"
echo ""

"$SCRIPT_DIR/router.sh" --list-tasks

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Quick start:"
echo ""
echo "  # Run a research task"
echo "  ./router.sh --task research --prompt \"What are AI coding assistants?\""
echo ""
echo "  # Check platform status"
echo "  ./router.sh --status"
echo ""
echo "  # Get help"
echo "  ./router.sh --help"
echo ""
echo "For full documentation, see README.md"
echo ""
