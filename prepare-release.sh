#!/bin/bash
# Prepare Save My Tokens for Open Source Release
# This script automates the essential cleanup steps

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Save My Tokens - Open Source Prep"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Archive old MCP server variants
echo "1. Cleaning up old MCP server files..."
cd mcp-scripts
mkdir -p _archive
ARCHIVED=0
for file in mcp-server-{clean,debug,enhanced,final,fixed,kiro,manual,minimal,production,sdk,working}.js; do
  if [ -f "$file" ]; then
    mv "$file" _archive/
    echo "   Archived: $file"
    ((ARCHIVED++))
  fi
done
echo "   ✓ Archived $ARCHIVED old server files"
cd ..

# 2. Archive old documentation
echo ""
echo "2. Cleaning up old documentation..."
mkdir -p _archive/old-docs
ARCHIVED_DOCS=0
for file in mcp-scripts/STREAMING-*.md mcp-scripts/PROGRESS-*.md mcp-scripts/RESTART-*.md; do
  if [ -f "$file" ]; then
    mv "$file" _archive/old-docs/
    echo "   Archived: $(basename $file)"
    ((ARCHIVED_DOCS++))
  fi
done
echo "   ✓ Archived $ARCHIVED_DOCS old docs"

# 3. Create .env.example if it doesn't exist
echo ""
echo "3. Creating .env.savemytokens.example..."
if [ ! -f ".env.savemytokens.example" ]; then
  cat > .env.savemytokens.example << 'EOF'
# Save My Tokens API Keys
# Copy this file to .env.savemytokens and add your actual keys

# Cerebras (https://cerebras.ai)
CEREBRAS_API_KEY=your_cerebras_key_here
CEREBRAS_MODEL=llama-3.3-70b

# Mistral (https://mistral.ai)
MISTRAL_API_KEY=your_mistral_key_here
MISTRAL_MODEL=mistral-small-latest

# Gemini (https://ai.google.dev)
GEMINI_API_KEY=your_gemini_key_here
GEMINI_MODEL=gemini-2.0-flash-exp

# DeepSeek (https://deepseek.com)
DEEPSEEK_API_KEY=your_deepseek_key_here
DEEPSEEK_MODEL=deepseek-chat

# Optional: Caching
SAVE_MY_TOKENS_CACHE_ENABLED=true
SAVE_MY_TOKENS_CACHE_DIR=./cache

# Optional: Execution mode
SAVE_MY_TOKENS_PARALLEL_MODE=true
EOF
  echo "   ✓ Created .env.savemytokens.example"
else
  echo "   ⊙ .env.savemytokens.example already exists"
fi

# 4. Update .gitignore
echo ""
echo "4. Updating .gitignore..."
touch .gitignore
ADDED=0

for pattern in ".env.savemytokens" ".env.local" ".env*.local" "*.key" "*.pem" "logs/" "*.log" "cache/" ".cache/" ".DS_Store" "_archive/"; do
  if ! grep -q "^${pattern}$" .gitignore 2>/dev/null; then
    echo "$pattern" >> .gitignore
    ((ADDED++))
  fi
done

if [ $ADDED -gt 0 ]; then
  echo "   ✓ Added $ADDED patterns to .gitignore"
else
  echo "   ⊙ .gitignore already up to date"
fi

# 5. Security check
echo ""
echo "5. Running security check..."
if grep -r "API_KEY.*=.*[a-zA-Z0-9]\{20\}" . \
   --exclude-dir=node_modules \
   --exclude-dir=_archive \
   --exclude="*.example" \
   --exclude=".gitignore" \
   --exclude="prepare-release.sh" \
   --exclude="QUICK-START-OSS.md" \
   2>/dev/null | grep -v "your_.*_key_here" > /tmp/secrets.txt; then
  echo "   ⚠️  WARNING: Potential secrets found:"
  cat /tmp/secrets.txt
  echo ""
  echo "   Please review these files before committing!"
  rm /tmp/secrets.txt
else
  echo "   ✓ No exposed secrets detected"
fi

# 6. Check if LICENSE exists
echo ""
echo "6. Checking license..."
if [ ! -f "LICENSE" ]; then
  echo "   ⚠️  No LICENSE file found"
  echo "   Creating MIT License template..."
  cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2025 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
  echo "   ✓ Created LICENSE file (edit to add your name)"
else
  echo "   ✓ LICENSE file exists"
fi

# 7. Check essential files
echo ""
echo "7. Checking essential files..."
MISSING=""
for file in "README.md" "INSTALLATION.md"; do
  if [ ! -f "$file" ]; then
    MISSING="$MISSING $file"
  else
    echo "   ✓ $file exists"
  fi
done

if [ -n "$MISSING" ]; then
  echo "   ⚠️  Missing files:$MISSING"
fi

# 8. Test script
echo ""
echo "8. Testing MCP server..."
if [ -f "mcp-scripts/test-streaming.sh" ]; then
  echo "   Running test script..."
  if bash mcp-scripts/test-streaming.sh > /tmp/test-output.txt 2>&1; then
    echo "   ✓ Tests passed"
  else
    echo "   ⚠️  Tests failed - check /tmp/test-output.txt"
  fi
else
  echo "   ⚠️  Test script not found"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Cleanup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Review and edit LICENSE (add your name)"
echo "  2. Review README.md and INSTALLATION.md"
echo "  3. Check QUICK-START-OSS.md for launch guide"
echo "  4. Commit changes:"
echo "     git add -A"
echo "     git commit -m 'chore: prepare for open source release'"
echo "     git tag -a v1.0.0 -m 'Initial release'"
echo "  5. Push to GitHub and announce!"
echo ""
