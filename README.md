# 🤖 Save My Tokens

**Offload Claude Code tasks to free LLM APIs - Save your tokens for what matters**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![MCP Compatible](https://img.shields.io/badge/MCP-Compatible-purple)](https://modelcontextprotocol.io)
[![Node.js](https://img.shields.io/badge/node-%3E%3D18-green)](https://nodejs.org)

Stop burning Claude tokens on tasks that free LLMs can handle. Inspired by [GSD (Get Shit Done)](https://github.com/PaulJuliusMartinez/get-shit-done), but designed to **conserve your Claude usage** by intelligently offloading work to free API tiers.

---

## 💡 The Problem

You love GSD and Claude Code workflows, but:
- 💸 **Token costs add up fast** - Research, planning, code generation all burn through your limit
- ⚡ **Claude does EVERYTHING** - Even simple tasks that free LLMs can handle
- 📊 **No visibility** - You have no idea how many tokens you're using per task
- 🔥 **Rate limits hit hard** - Intensive workflows exhaust your daily quota

**What if Claude could delegate to free workers?**

---

## ✨ The Solution

Save My Tokens lets Claude **intelligently offload tasks** to free LLM APIs:

- 🎯 **Smart Delegation** - Claude orchestrates, free agents execute
- 💰 **Token Savings** - Use Claude for decisions, free LLMs for heavy lifting
- 🚀 **Free Tier APIs** - Cerebras, Mistral (all have generous free tiers)
- 📊 **Real-Time Progress** - See exactly what's happening (no silent hangs)
- 🔄 **Smart Caching** - Never pay twice for the same query
- ⚡ **Zero Config** - Drop in task files, auto-discovery handles the rest

### How It Works

```
User: "Research AI trends and write a summary"
  ↓
Claude Code: "I'll delegate the research to free agents"
  ↓
Save My Tokens: Research task → Cerebras API (FREE) ✅
              Writing task → Mistral API (FREE) ✅
  ↓
Claude Code: Reviews results, provides final polish
  ↓
Result: Task done. Claude tokens saved! 🎉
```

Instead of Claude burning 10K tokens on research, it uses ~100 tokens to orchestrate and review free agent work.

---

## 🎬 Quick Demo

**Installation:**
```bash
# One command install
npx github:Dan-paull/save-my-tokens install

# Add API keys (all FREE tiers!)
# Cerebras: https://cerebras.ai (fast, generous free tier)
# Mistral: https://mistral.ai (free tier available)
```

**Usage in Claude Code:**
```
You: "Research the latest developments in quantum computing"

Claude: "I'll use the research tool to gather information"

[Behind the scenes: Save My Tokens routes to Cerebras - FREE]

🎯 Processing research request
🧠 Selected: cerebras (free tier)
🚀 Starting: cerebras/llama-3.3-70b
📡 Sending request to Cerebras API (FREE)
⏳ Waiting for response...
📥 Received 15KB, 1234 tokens in 3s
✅ Completed - Claude tokens saved: ~1000 tokens! 💰
```

**Your Claude tokens?** Only used for orchestration (~50 tokens) instead of the full research (~1000 tokens).

---

## 💰 Cost Savings

### Before Save My Tokens (Pure Claude)

```
Research task:        1000 tokens
Code generation:      2000 tokens
Planning:            1500 tokens
Code review:          800 tokens
───────────────────────────────
Total per workflow:  5300 tokens
Daily limit:        ~50,000 tokens (Sonnet)
Workflows/day:       ~9 workflows
```

### After Save My Tokens (Claude + Free APIs)

```
Research task:        50 tokens (orchestration) + FREE API
Code generation:     100 tokens (review) + FREE API
Planning:            75 tokens (coordination) + FREE API
Code review:         50 tokens (oversight) + FREE API
──────────────────────────────────────────────
Total per workflow:  275 tokens
Daily limit:        ~50,000 tokens
Workflows/day:       ~180 workflows
```

**Result: 19x more workflows with the same Claude token budget!** 🚀

---

## 📦 Installation

### Prerequisites

- Node.js 18+
- Claude Code (for MCP integration)
- **FREE API keys** from at least one provider (no credit card needed for free tiers!)

### Quick Install

```bash
# Install
npx github:Dan-paull/save-my-tokens install

# Get FREE API keys (no credit card required)
# Cerebras: https://cerebras.ai - Very fast, generous limits
# Mistral: https://mistral.ai - Good free tier

# Add to .env.savemytokens
nano .env.savemytokens

# Restart Claude Code
pkill -f "claude --"

# Done! Claude can now delegate to free agents! 🎉
```

### Verify Installation

```bash
npx github:Dan-paull/save-my-tokens status
npx github:Dan-paull/save-my-tokens test
```

---

## 🎯 When to Use Save My Tokens

**Offload to Save My Tokens:**
- ✅ Research and information gathering
- ✅ Code generation (first draft)
- ✅ Architecture planning (multiple perspectives)
- ✅ Code review (initial analysis)
- ✅ Documentation writing
- ✅ Brainstorming and ideation

**Keep in Claude:**
- ⭐ Final decision making
- ⭐ Complex reasoning requiring context
- ⭐ Critical code changes
- ⭐ Sensitive information processing
- ⭐ Tasks requiring your project's full context

**The Strategy:** Let free agents do the heavy lifting, Claude does the final polish.

---

## 🎯 Available Tasks

| Task | What It Does | Token Savings | Free Agent Used |
|------|--------------|---------------|-----------------|
| **research** | Information gathering, web research | ~1000 tokens/task | Cerebras (fast) or Mistral |
| **coding** | Code generation, first drafts | ~2000 tokens/task | Cerebras or Mistral |
| **planning** | Architecture design, multiple strategies | ~1500 tokens/task | Mistral or Cerebras |
| **code-review** | Initial code analysis | ~800 tokens/task | Mistral or Cerebras |

**All tasks can run in:**
- **Parallel mode** - Multiple free agents for diverse perspectives (research, planning)
- **Cascade mode** - Try free agents sequentially until success (coding, review)

---

## 🚀 Free API Providers

All providers below offer **generous free tiers** - no credit card required:

### Cerebras (Recommended for Speed)
- **Model:** llama-3.3-70b
- **Speed:** 1,800+ tokens/sec (blazing fast!)
- **Free Tier:** Very generous
- **Best For:** Research, quick coding tasks
- **Get Key:** https://cerebras.ai

### Mistral AI
- **Model:** mistral-small-latest
- **Speed:** Fast
- **Free Tier:** Available
- **Best For:** Balanced tasks, planning, review
- **Get Key:** https://mistral.ai

**Setup:** Get free API keys from Cerebras and/or Mistral, add to `.env.savemytokens`, and you're ready to go!

> 💡 **Coming Soon:** More free tier providers will be added in future releases!

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      CLAUDE CODE                            │
│  (Orchestration, decision making, final review)             │
│  Token usage: ~50-100 per task                              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ MCP Protocol
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                  FREE AGENTS MCP SERVER                     │
│  - Task routing & model selection                           │
│  - Real-time progress streaming                             │
│  - Smart caching (don't repeat work)                        │
│  - Automatic failover                                       │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
   ┌─────────┐              ┌─────────┐
   │Cerebras │              │ Mistral │
   │  FREE   │              │  FREE   │
   └─────────┘              └─────────┘
        │                         │
        └────────────┬────────────┘
                     │
            Heavy lifting done here
            Claude tokens: SAVED! 💰
```

---

## 💡 Usage Examples

### Research Task

**Before Save My Tokens:**
```
You: "Research the top 10 AI coding assistants in 2025"

Claude: [Uses 1200 tokens doing all the research itself]
```

**With Save My Tokens:**
```
You: "Research the top 10 AI coding assistants in 2025"

Claude: "I'll use the research tool" [Uses 50 tokens]
  ↓
Free Agent (Cerebras): [Does research using FREE API]
  ↓
Claude: [Reviews and formats - 50 tokens]

Token savings: 1100 tokens! (92% reduction)
```

### Code Generation

**Before:**
```
You: "Write a Python function to parse JSON with error handling"

Claude: [Uses 2000 tokens generating code]
```

**With Save My Tokens:**
```
You: "Write a Python function to parse JSON with error handling"

Claude: "I'll use the coding tool" [Uses 80 tokens]
  ↓
Free Agent (Cerebras or Mistral): [Generates code using FREE API]
  ↓
Claude: [Reviews and refines - 100 tokens]

Token savings: 1820 tokens! (91% reduction)
```

---

## 📊 Real-Time Progress

See exactly what's happening (no more wondering if it's stuck):

```
🎯 Processing research request
🧠 Analyzing available models
🧠 Selected: cerebras (FREE tier - fast!)
🚀 Starting: cerebras/llama-3.3-70b
🔄 Checking cache... (save even more!)
📡 Sending request to Cerebras API
⏳ Waiting for response...
📥 Received 15KB, 1234 tokens in 3s
✅ Completed: cerebras/llama-3.3-70b (3s)
💰 Claude tokens saved: ~1000 tokens
🎉 Success - Result ready for Claude to review!
```

**With caching:**
```
🔄 Checking cache for: cerebras/llama-3.3-70b
⚡ Cache hit! Using cached result (instant)
💰 API call saved! Claude tokens saved!
🎉 Success (0s)
```

---

## 🔧 Configuration

### Basic Setup (.env.savemytokens)

```bash
# Get these keys FREE (no credit card):

# Cerebras (Recommended - very fast!)
CEREBRAS_API_KEY=your_free_key_here
CEREBRAS_MODEL=llama-3.3-70b

# Mistral
MISTRAL_API_KEY=your_free_key_here
MISTRAL_MODEL=mistral-small-latest

# Caching (save even more!)
SAVE_MY_TOKENS_CACHE_ENABLED=true
SAVE_MY_TOKENS_CACHE_DIR=./cache
```

### Task Configuration (tasks/*.json)

Customize which free agents handle which tasks:

```json
{
  "task": "research",
  "task_type": "information",
  "run_multiple": true,  // Use multiple agents for diverse perspectives
  "models": [
    {
      "name": "cerebras-research",
      "platform": "cerebras",
      "model": "llama-3.3-70b"
    },
    {
      "name": "mistral-research",
      "platform": "mistral",
      "model": "mistral-small-latest"
    }
  ]
}
```

---

## 🤝 Inspired By GSD

This project was inspired by Paul Julius Martinez's [Get Shit Done (GSD)](https://github.com/PaulJuliusMartinez/get-shit-done) workflow.

**The GSD Problem:**
- 🔥 GSD is AMAZING for productivity
- 💸 But it burns through Claude tokens FAST
- 📊 Complex projects can exhaust daily limits quickly

**The Save My Tokens Solution:**
- ✅ Keep the GSD workflow you love
- ✅ Offload heavy tasks to free APIs
- ✅ Save your Claude tokens for orchestration and critical thinking
- ✅ 10-20x more workflows per day with the same token budget

**Use them together:**
1. Use GSD for project orchestration
2. Let GSD delegate to Save My Tokens for execution
3. Enjoy massively extended Claude Code usage!

---

## 🎓 How It Works

### The Smart Delegation Model

1. **Claude Decides:** Should this task be delegated?
2. **Save My Tokens Execute:** Route to appropriate free API
3. **Real-Time Progress:** See what's happening
4. **Claude Reviews:** Final polish and integration
5. **Result:** Task done, tokens saved!

### Execution Modes

**Parallel Mode** (Research, Planning)
```
Claude delegates → Multiple free agents work simultaneously
                → Diverse perspectives returned
                → Claude synthesizes final answer

Token cost: 100 (orchestration) vs 2000 (doing it all)
```

**Cascade Mode** (Coding, Review)
```
Claude delegates → Try Agent 1 (Cerebras)
                   ↓ (if fails)
                → Try Agent 2 (Mistral)
                   ↓
                ✅ Success!

Token cost: 80 (orchestration) vs 2500 (doing it all)
```

---

## 📝 Documentation

- **[Installation Guide](INSTALLATION.md)** - Detailed setup instructions
- **[Contributing](CONTRIBUTING.md)** - How to add new providers and tasks
- **[Changelog](CHANGELOG.md)** - Version history

---

## 🙏 Acknowledgments

- **[GSD (Get Shit Done)](https://github.com/PaulJuliusMartinez/get-shit-done)** - The inspiration! Use GSD + Save My Tokens together for maximum productivity
- **[Anthropic](https://anthropic.com)** - For Claude and the Model Context Protocol
- **Free LLM Providers** - Cerebras and Mistral for generous free tiers

---

## 🤝 Contributing

We welcome contributions! Especially:

- **New free provider integrations** - Found another free API? Add it!
- **Task templates** - New use cases for token savings
- **Optimization strategies** - Better ways to save tokens
- **Usage statistics** - Share your token savings!

See [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 📄 License

MIT License - see [LICENSE](LICENSE)

---

## 💬 Support

**Getting Started:**
1. [Installation Guide](INSTALLATION.md)
2. Run: `npx github:Dan-paull/save-my-tokens test`
3. Check: `npx github:Dan-paull/save-my-tokens status`

**Having Issues?**
- Check logs: `tail -f logs/mcp-server.log`
- [Open an issue](https://github.com/Dan-paull/save-my-tokens/issues)

---

## 🌟 Star This Repo!

If Save My Tokens saves your Claude tokens, give us a star! ⭐

Every star motivates us to add more free providers and save even more tokens!

---

**Stop burning Claude tokens on tasks free LLMs can handle. Save your quota for what matters.** 💰

[Get Started →](INSTALLATION.md) | [View on GitHub →](https://github.com/Dan-paull/save-my-tokens)
