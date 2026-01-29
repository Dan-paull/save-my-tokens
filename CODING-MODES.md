# Coding Agent Modes

The coding agent supports multiple execution modes to handle different scenarios and avoid context/output limitations.

## Available Modes

### 1. Default Mode (default)
**Best for:** Small to medium code generation tasks

```
Use mcp__save_my_tokens__coding to "create a Python calculator"
```

Returns all code in a single response. Works well for:
- Single files under ~2000 lines
- Simple scripts
- Small utilities

**Limitations:** May truncate on very large outputs

---

### 2. Direct Mode (direct)
**Best for:** Multi-file projects where agent should write files directly

```
Use mcp__save_my_tokens__coding with mode="direct" to "create a Flask REST API with authentication"
```

Agent generates code and writes files using special tags:
```xml
<write_file path="app.py">
from flask import Flask
app = Flask(__name__)
</write_file>
```

**Benefits:**
- Agent handles file writing
- No truncation issues (files written incrementally)
- Returns file paths + summary
- Claude can review written files

**Use when:**
- Generating multiple files
- Large codebases
- Want agent to manage file structure

---

### 3. Streaming Mode (streaming)
**Best for:** Large single files that need chunking

```
Use mcp__save_my_tokens__coding with mode="streaming" to "create a 5000-line data processing pipeline"
```

Agent breaks output into manageable chunks:
```
=== CHUNK 1/3: Data Loading ===
[code for data loading]
=== END CHUNK ===

=== CHUNK 2/3: Processing ===
[code for processing]
=== END CHUNK ===
```

**Benefits:**
- Handles very large files
- Each chunk is complete (full functions/classes)
- No mid-function truncation

**Use when:**
- Single file > 2000 lines
- Complex implementations
- Need to see progress as code generates

---

### 4. Incremental Mode (incremental)
**Best for:** Multi-file projects with conversation continuity

```
Use mcp__save_my_tokens__coding with mode="incremental" to "create a Django blog application"
```

Agent creates a plan, then generates one file at a time:
```
=== PLAN ===
Files to create:
1. models.py - Database models
2. views.py - View functions
3. urls.py - URL routing
=== END PLAN ===

=== FILE 1/3: models.py ===
[complete models.py code]
=== END FILE ===

File 1 of 3 complete. Request 'next file' to continue.
```

Then you can request:
```
Use mcp__save_my_tokens__coding with mode="incremental" to "generate next file"
```

**Benefits:**
- Context-aware (remembers plan)
- One file at a time (no truncation)
- Can review/modify between files
- Agent explains each file

**Use when:**
- Large multi-file projects
- Want to review incrementally
- Need flexibility to adjust between files

---

## Mode Selection Guide

| Scenario | Recommended Mode | Why |
|----------|-----------------|-----|
| Single file < 2000 lines | `default` | Fast, simple |
| Single file > 2000 lines | `streaming` | Chunks prevent truncation |
| 2-5 files | `direct` | Agent writes all files |
| 5+ files | `incremental` | Review between files |
| Need file system control | `direct` | Agent manages structure |
| Uncertain file count | `incremental` | Flexible, can adjust |

---

## Examples

### Example 1: Quick Script (Default)
```
Use mcp__save_my_tokens__coding to "create a Python script to parse CSV files"
```
Output: Complete script returned as text

---

### Example 2: Multi-file Project (Direct)
```
Use mcp__save_my_tokens__coding with mode="direct" and project_dir="/path/to/project" to "create a REST API with user authentication, including models, routes, and tests"
```

Agent output:
```xml
<write_file path="src/models/user.py">
class User:
    ...
</write_file>
<write_file path="src/routes/auth.py">
from flask import Blueprint
...
</write_file>
<write_file path="tests/test_auth.py">
import pytest
...
</write_file>

Created 3 files:
- src/models/user.py: User model with authentication
- src/routes/auth.py: Authentication routes
- tests/test_auth.py: Authentication tests
```

Claude receives: "Created 3 files: ..." and can review them

---

### Example 3: Large File (Streaming)
```
Use mcp__save_my_tokens__coding with mode="streaming" to "create a comprehensive data pipeline with ETL, validation, and reporting"
```

Agent output:
```
=== CHUNK 1/4: Imports and Configuration ===
import pandas as pd
import numpy as np
...
=== END CHUNK ===

=== CHUNK 2/4: Data Loading ===
def load_data(source):
    ...
=== END CHUNK ===
```

---

### Example 4: Large Project (Incremental)
```
Use mcp__save_my_tokens__coding with mode="incremental" to "create a full e-commerce application"
```

First response:
```
=== PLAN ===
Files to create:
1. models.py - Product, Order, User models
2. views.py - Product listing, cart, checkout
3. forms.py - User registration, login, checkout forms
4. tests.py - Unit tests
=== END PLAN ===

=== FILE 1/4: models.py ===
[models.py code]
=== END FILE ===

File 1 of 4 complete. Request 'next file' for views.py
```

Then:
```
Use mcp__save_my_tokens__coding with mode="incremental" to "next file"
```

Agent generates file 2/4, and so on.

---

## Implementation Status

✅ **Complete:**
- Mode parameter support in MCP server
- Mode-specific system prompts
- Router argument passing

🚧 **In Progress:**
- Direct mode file writing logic
- Streaming chunk parser
- Incremental state management

📋 **Planned:**
- Auto-detect optimal mode based on task
- Progress tracking for multi-file generation
- File diff support for modifications

---

## How It Works

1. **Claude decides mode** based on task complexity
2. **MCP server** passes mode to router
3. **Router** loads mode-specific system prompt
4. **Agent** generates code following mode instructions
5. **Response handler** processes mode-specific output
6. **Claude receives** structured result

---

## Troubleshooting

**Issue:** Code still truncated
- **Solution:** Try `mode="streaming"` or `mode="incremental"`

**Issue:** Files not being written in direct mode
- **Solution:** Ensure `project_dir` parameter is set

**Issue:** Incremental mode lost context
- **Solution:** Include previous file names in follow-up prompts

---

Ready to use the new modes! Restart Claude Code to load the updates:
```bash
pkill -f "claude --"
```
