# Open Source Release Checklist

## 🎯 Goal
Prepare save-my-tokens MCP for public release to open source communities

---

## 📋 Pre-Release Checklist

### 1. Code Cleanup (REQUIRED)

- [ ] **Remove 11 old MCP server variants** - Keep only `mcp-server-streaming.js`
  ```bash
  cd mcp-scripts
  # Keep only these files:
  # - mcp-server-streaming.js (production)
  # - install-streaming.sh
  # - test-streaming.sh

  # Archive or delete:
  # - mcp-server-clean.js
  # - mcp-server-debug.js
  # - mcp-server-enhanced.js
  # - mcp-server-final.js
  # - mcp-server-fixed.js
  # - mcp-server-kiro.js
  # - mcp-server-manual.js
  # - mcp-server-minimal.js
  # - mcp-server-production.js
  # - mcp-server-sdk.js
  # - mcp-server-working.js
  ```

- [ ] **Clean up root directory**
  - Remove test scripts from root
  - Keep only: router.sh, setup.sh, README.md, LICENSE, CONTRIBUTING.md

- [ ] **Review and clean git status** (55 uncommitted changes)
  - Commit or remove deleted files
  - Clean working tree

### 2. Documentation (REQUIRED)

- [ ] **README.md** - Update with:
  - Clear project description
  - Key features (multi-model, caching, real-time progress)
  - Quick start guide
  - Screenshots/demos if possible
  - Links to detailed docs
  - Badge for license, npm version (if applicable)

- [ ] **INSTALLATION.md** - Ensure it covers:
  - Prerequisites (Node.js version, API keys needed)
  - Step-by-step installation
  - Configuration
  - Verification steps
  - Troubleshooting common issues

- [ ] **USAGE.md** - Create comprehensive usage guide:
  - All available tools (research, coding, code-review, planning)
  - Examples for each tool
  - Advanced configuration
  - Model selection
  - Cache management

- [ ] **ARCHITECTURE.md** - Document the system:
  - How it works (router → task-executor → providers)
  - MCP integration
  - Progress streaming
  - Caching system
  - Model allocation strategies

- [ ] **API.md** - Document the MCP tools:
  - Each tool's parameters
  - Expected responses
  - Error handling

### 3. Licensing (REQUIRED)

- [ ] **Choose a license**
  - MIT (most permissive, popular)
  - Apache 2.0 (includes patent grant)
  - GPL v3 (copyleft)

  Recommendation: **MIT License** for maximum adoption

- [ ] **Add LICENSE file**
  ```bash
  # Example MIT License template
  ```

- [ ] **Add copyright notices to source files**
  ```javascript
  /**
   * Copyright (c) 2025 [Your Name/Organization]
   * Licensed under the MIT License
   */
  ```

### 4. Security (CRITICAL)

- [ ] **Verify .gitignore**
  ```gitignore
  # API Keys and Secrets
  .env.savemytokens
  .env.local
  .env*.local
  *.key
  *.pem

  # Logs
  logs/
  *.log

  # Dependencies
  node_modules/

  # Cache
  cache/
  .cache/

  # OS
  .DS_Store
  Thumbs.db

  # IDE
  .vscode/
  .idea/
  ```

- [ ] **Scan for accidentally committed secrets**
  ```bash
  grep -r "API_KEY.*=.*[a-zA-Z0-9]" . --exclude-dir=node_modules
  ```

- [ ] **Add security documentation**
  - How to store API keys securely
  - .env.savemytokens.example template
  - Security best practices

### 5. Project Structure

- [ ] **Clean directory structure**
  ```
  save-my-tokens/
  ├── README.md
  ├── LICENSE
  ├── INSTALLATION.md
  ├── USAGE.md
  ├── CONTRIBUTING.md
  ├── CHANGELOG.md
  ├── .gitignore
  ├── package.json (if publishing to npm)
  ├── router.sh
  ├── setup.sh
  ├── lib/
  │   ├── task-executor.sh
  │   ├── model-filter.sh
  │   └── yaml-to-json.sh
  ├── providers/
  │   └── wrappers/
  │       ├── cerebras.sh
  │       ├── mistral.sh
  │       ├── deepseek.sh
  │       └── gemini.sh
  ├── tasks/
  │   ├── research.json
  │   ├── coding.json
  │   ├── code-review.json
  │   └── planning.json
  ├── mcp-scripts/
  │   ├── mcp-server-streaming.js
  │   ├── install-streaming.sh
  │   └── test-streaming.sh
  ├── examples/
  │   └── example-workflows.md
  └── .env.savemytokens.example
  ```

### 6. Testing & Validation

- [ ] **Create test suite**
  - Add to `test-streaming.sh` or create separate tests
  - Test each provider
  - Test caching
  - Test error handling

- [ ] **Add CI/CD** (optional but recommended)
  - GitHub Actions workflow
  - Run tests on PRs
  - Lint code

### 7. Community Files

- [ ] **CONTRIBUTING.md**
  - How to contribute
  - Code style guide
  - PR process
  - Development setup

- [ ] **CODE_OF_CONDUCT.md**
  - Use Contributor Covenant or similar

- [ ] **Issue Templates** (.github/ISSUE_TEMPLATE/)
  - Bug report
  - Feature request
  - Question

- [ ] **PR Template** (.github/pull_request_template.md)

### 8. Release Preparation

- [ ] **CHANGELOG.md**
  - Version 1.0.0 - Initial release
  - List all features
  - Known limitations

- [ ] **Version tagging**
  - Use semantic versioning (1.0.0)
  - Tag in git: `git tag -a v1.0.0 -m "Initial release"`

- [ ] **Package.json** (if distributing via npm)
  ```json
  {
    "name": "save-my-tokens",
    "version": "1.0.0",
    "description": "Multi-model AI agent router with MCP integration",
    "main": "mcp-scripts/mcp-server-streaming.js",
    "scripts": {
      "test": "bash mcp-scripts/test-streaming.sh",
      "install": "bash mcp-scripts/install-streaming.sh"
    },
    "keywords": ["mcp", "ai", "agents", "llm", "multi-model"],
    "author": "Your Name",
    "license": "MIT",
    "dependencies": {
      "@modelcontextprotocol/sdk": "^1.25.3"
    }
  }
  ```

### 9. Marketing & Distribution

- [ ] **Publish to GitHub**
  - Create public repository
  - Add description and tags
  - Add website/documentation link

- [ ] **Announce on**:
  - [ ] Reddit: r/ClaudeAI, r/LocalLLaMA, r/opensource
  - [ ] Twitter/X: Tag @AnthropicAI, use #MCP #AI hashtags
  - [ ] Hacker News (Show HN:)
  - [ ] Dev.to / Medium blog post
  - [ ] Discord communities (Claude, AI)

- [ ] **Create demo video/GIF**
  - Show installation
  - Show real-time progress
  - Show multi-model results

### 10. Optional Enhancements

- [ ] **Badge in README**
  ```markdown
  ![License](https://img.shields.io/badge/license-MIT-blue.svg)
  ![Node](https://img.shields.io/badge/node-%3E%3D18-green)
  ![MCP](https://img.shields.io/badge/MCP-compatible-purple)
  ```

- [ ] **GitHub Pages documentation**
  - Deploy docs to GitHub Pages
  - Use MkDocs or Docusaurus

- [ ] **Example workflows**
  - Research assistant workflow
  - Code review automation
  - Multi-model comparison

---

## 🚀 Quick Start Commands

### Clean up old files
```bash
cd mcp-scripts
mkdir -p archive
mv mcp-server-{clean,debug,enhanced,final,fixed,kiro,manual,minimal,production,sdk,working}.js archive/
```

### Create essential files
```bash
# License
curl https://raw.githubusercontent.com/licenses/license-templates/master/templates/mit.txt > LICENSE
# Edit LICENSE file to add your name/year

# Contributing guide
cat > CONTRIBUTING.md << 'EOF'
# Contributing to Save My Tokens
...
EOF

# Code of conduct
curl https://www.contributor-covenant.org/version/2/1/code_of_conduct/code_of_conduct.md > CODE_OF_CONDUCT.md
```

### Git cleanup
```bash
git add -A
git commit -m "chore: prepare for open source release"
git tag -a v1.0.0 -m "Initial public release"
```

---

## 📦 Recommended Release Order

1. **Week 1**: Code cleanup + Documentation
2. **Week 2**: Testing + Security audit
3. **Week 3**: Community files + Examples
4. **Week 4**: Soft launch (Discord/Reddit)
5. **Week 5**: Official launch (HN, Twitter, blog post)

---

## 🎯 Success Metrics

After release, track:
- GitHub stars
- Installation attempts
- Issues opened
- PRs submitted
- Community engagement

---

## ⚠️ Critical Before Release

1. ✅ No API keys in git history
2. ✅ All files have proper licensing
3. ✅ README is clear and accurate
4. ✅ Installation works from scratch
5. ✅ All test scripts pass

---

## 📞 Need Help?

Consider getting feedback from:
- Anthropic Discord MCP channel
- r/ClaudeAI community
- Early beta testers

---

**Next Steps**:
1. Review this checklist
2. Decide on must-haves vs nice-to-haves
3. Create issues/tasks for each item
4. Set a target release date
