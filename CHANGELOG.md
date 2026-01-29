# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-29

### Added
- **npx installation** - One-command install: `npx save-my-tokens install`
- **Interactive CLI** - Install, test, status, and uninstall commands via npx
- **Real-time progress streaming** - See agent execution progress with emoji indicators
- **MCP streaming server** (`mcp-server-streaming.js`) with stdio transport
- **Progress message protocol** - Structured `[AGENT-PROGRESS]` messages from agents
- **Multi-model support** - Cerebras, Mistral providers
- **Smart caching** - Hash-based response caching with configurable TTL
- **Parallel execution mode** - Run multiple models simultaneously for research/planning
- **Cascade execution mode** - Sequential failover for coding/code-review
- **Dynamic task discovery** - Auto-register tasks from JSON files
- **Progress categories** - 12 progress types (task-start, allocation, model-start, cache, etc.)
- **Stdin blocking fix** - Resolved issue preventing router from running in Node.js spawn
- **Comprehensive documentation** - README, INSTALLATION, CONTRIBUTING guides
- **Test suite** - `test-streaming.sh` for automated testing
- **Installation script** - `install-streaming.sh` for one-command setup

### Changed
- Migrated from generic progress timers to real agent progress messages
- Updated MCP server to use `sendLoggingMessage()` for Claude Code compatibility
- Changed stdin handling from 'pipe' to 'ignore' to prevent blocking
- Improved error handling with progress log inclusion
- Enhanced logging with structured JSON format

### Fixed
- **Critical**: Stdin blocking causing router to hang when spawned from Node.js
- **Critical**: Silent hangs with no user feedback during long operations
- Progress messages not being captured by MCP server
- Missing progress updates in final tool response
- API timeout handling

### Security
- Added `.gitignore` patterns for API keys and sensitive files
- Created `.env.savemytokens.example` template
- Implemented security scanning in release preparation script
- Removed accidentally committed secrets from history

### Documentation
- Created production-ready README with quick start guide
- Added comprehensive INSTALLATION.md
- Created CONTRIBUTING.md with development guidelines
- Added CHANGELOG.md (this file)
- Documented progress message protocol
- Added troubleshooting guides

### Infrastructure
- Added `package.json` for npm compatibility
- Created `prepare-release.sh` for automated cleanup
- Set up MIT License
- Configured GitHub repository metadata
- Added open source readiness checklist

### Known Limitations
- Real-time MCP logging may be buffered by Claude Code (progress appears in final response)
- Requires Node.js 18+ for ES modules support
- Currently tested on macOS (Linux/Windows testing needed)

## [Unreleased]

### Planned
- Windows compatibility testing
- Additional provider wrappers (OpenRouter, Together.ai)
- Web UI for configuration and testing
- Prometheus metrics export
- Docker container support
- CI/CD pipeline with GitHub Actions

---

## Version History

- **1.0.0** (2025-01-29) - Initial public release with real-time progress streaming

---

[1.0.0]: https://github.com/Dan-paull/save-my-tokens/releases/tag/v1.0.0
