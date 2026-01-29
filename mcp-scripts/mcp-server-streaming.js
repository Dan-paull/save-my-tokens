#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';
import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { existsSync, readFileSync, appendFileSync, mkdirSync, readdirSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const TOOL_VERSION = '1.1.0';  // Streaming version
const DEFAULT_TIMEOUT_MS = parseInt(process.env.SAVE_MY_TOKENS_TIMEOUT || '300000');

/**
 * Parse agent progress messages
 */
function parseProgressMessage(line) {
  const match = line.match(/\[AGENT-PROGRESS\]\s+([^:]+):\s*(.+)/);
  if (!match) return null;

  const [, category, message] = match;
  return {
    category: category.trim(),
    message: message.trim(),
    timestamp: new Date().toISOString()
  };
}

/**
 * Format progress for display
 */
function formatProgress(progress) {
  const icons = {
    'task-start': '🎯',
    'allocation': '🧠',
    'model-start': '🚀',
    'model-call': '📡',
    'model-wait': '⏳',
    'model-receive': '📥',
    'model-complete': '✅',
    'model-fail': '❌',
    'cache-hit': '⚡',
    'cache-miss': '🔄',
    'results': '📊',
    'task-complete': '🎉',
    'task-error': '💥'
  };

  const icon = icons[progress.category] || '🤖';
  return `${icon} ${progress.message}`;
}

/**
 * Structured Logger
 */
class Logger {
  constructor(logDir) {
    this.logDir = logDir;
    this.logFile = join(logDir, 'mcp-server.log');

    if (!existsSync(logDir)) {
      mkdirSync(logDir, { recursive: true });
    }
  }

  log(level, message, metadata = {}) {
    const entry = {
      timestamp: new Date().toISOString(),
      level,
      message,
      ...metadata
    };

    try {
      appendFileSync(this.logFile, JSON.stringify(entry) + '\n');
    } catch (error) {
      console.error('Logging failed:', error.message);
    }

    if (level === 'error' || level === 'warn') {
      console.error(`[${level.toUpperCase()}] ${message}`, metadata);
    }
  }

  info(message, metadata) { this.log('info', message, metadata); }
  warn(message, metadata) { this.log('warn', message, metadata); }
  error(message, metadata) { this.log('error', message, metadata); }
  debug(message, metadata) { this.log('debug', message, metadata); }
}

/**
 * Save My Tokens Server with Agent Progress Streaming
 */
class FreeAgentsServer {
  constructor() {
    this.freeAgentsPath = dirname(__dirname);
    this.routerPath = join(this.freeAgentsPath, 'router.sh');
    this.tasksPath = join(this.freeAgentsPath, 'tasks');
    this.logsPath = join(this.freeAgentsPath, 'logs');

    this.logger = new Logger(this.logsPath);
    this.logger.info('MCP Server starting (streaming version)', {
      version: TOOL_VERSION,
      nodeVersion: process.version
    });

    this.server = new Server(
      {
        name: 'save-my-tokens',
        version: TOOL_VERSION,
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.runningTasks = new Map();
    this.setupToolHandlers();
    this.setupShutdownHandlers();
  }

  discoverTasks() {
    const tasks = [];

    if (!existsSync(this.tasksPath)) {
      this.logger.warn('Tasks directory not found', { path: this.tasksPath });
      return tasks;
    }

    try {
      const files = readdirSync(this.tasksPath);

      for (const file of files) {
        if (!file.endsWith('.json')) continue;

        try {
          const taskPath = join(this.tasksPath, file);
          const taskConfig = JSON.parse(readFileSync(taskPath, 'utf8'));

          tasks.push({
            name: taskConfig.name || file.replace('.json', ''),
            description: taskConfig.description || `Execute ${taskConfig.name} task`,
            multiModel: taskConfig.multi_model !== false,
            config: taskConfig
          });
        } catch (error) {
          this.logger.error(`Failed to load task: ${file}`, { error: error.message });
        }
      }

      this.logger.info('Tasks discovered', { count: tasks.length, tasks: tasks.map(t => t.name) });
    } catch (error) {
      this.logger.error('Failed to discover tasks', { error: error.message });
    }

    return tasks;
  }

  async checkHealth() {
    const health = {
      status: 'healthy',
      version: TOOL_VERSION,
      features: ['streaming', 'agent-progress', 'real-time-updates'],
      checks: {},
      timestamp: new Date().toISOString()
    };

    // Check router
    health.checks.router = {
      available: existsSync(this.routerPath),
      path: this.routerPath,
      executable: false
    };

    if (health.checks.router.available) {
      try {
        const { mode } = await import('fs').then(fs => fs.promises.stat(this.routerPath));
        health.checks.router.executable = (mode & 0o111) !== 0;
      } catch (error) {
        this.logger.error('Failed to check router', { error: error.message });
      }
    }

    // Check environment
    const envPath = join(this.freeAgentsPath, '.env.savemytokens');
    health.checks.environment = {
      configured: existsSync(envPath),
      hasApiKeys: false
    };

    if (health.checks.environment.configured) {
      try {
        const envContent = readFileSync(envPath, 'utf8');
        const hasKeys = /^[A-Z_]+_API_KEY=.+$/m.test(envContent);
        health.checks.environment.hasApiKeys = hasKeys;
      } catch (error) {
        this.logger.error('Failed to check environment', { error: error.message });
      }
    }

    // Check tasks
    const discoveredTasks = this.discoverTasks();
    health.checks.tasks = {
      directory: existsSync(this.tasksPath),
      count: discoveredTasks.length,
      available: discoveredTasks.map(t => t.name)
    };

    // Check logs
    health.checks.logs = {
      directory: existsSync(this.logsPath),
      logFile: this.logger.logFile,
      writable: true
    };

    try {
      appendFileSync(this.logger.logFile, '');
    } catch (error) {
      health.checks.logs.writable = false;
      health.status = 'warning';
    }

    // Overall status
    if (!health.checks.router.available || !health.checks.router.executable) {
      health.status = 'degraded';
      health.message = 'Router not available or not executable';
    } else if (!health.checks.environment.configured || !health.checks.environment.hasApiKeys) {
      health.status = 'warning';
      health.message = 'API keys not configured';
    } else if (health.checks.tasks.count === 0) {
      health.status = 'warning';
      health.message = 'No tasks available';
    }

    return health;
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      const tools = [
        {
          name: 'health',
          description: 'Check Save My Tokens system health and configuration status',
          version: TOOL_VERSION,
          inputSchema: {
            type: 'object',
            properties: {},
            required: []
          }
        }
      ];

      const discoveredTasks = this.discoverTasks();
      for (const task of discoveredTasks) {
        tools.push({
          name: task.name,
          description: task.description,
          version: TOOL_VERSION,
          inputSchema: {
            type: 'object',
            properties: {
              prompt: {
                type: 'string',
                description: `${task.name.charAt(0).toUpperCase() + task.name.slice(1)} query or request`
              },
              context: {
                type: 'string',
                description: 'Additional context or constraints'
              },
              run_multiple: {
                type: 'boolean',
                description: 'Use multiple models for diverse perspectives',
                default: task.multiModel
              },
              timeout_seconds: {
                type: 'number',
                description: 'Maximum execution time in seconds (default: 300)',
                default: 300
              }
            },
            required: ['prompt']
          }
        });
      }

      this.logger.debug('Tools listed', { count: tools.length });
      return { tools };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;
      const taskId = `${name}-${Date.now()}`;

      this.logger.info('Tool called', { tool: name, taskId, args });

      try {
        if (name === 'health') {
          const health = await this.checkHealth();
          return {
            content: [{
              type: 'text',
              text: JSON.stringify(health, null, 2)
            }]
          };
        }

        const startTime = Date.now();
        const timeoutMs = (args.timeout_seconds || 300) * 1000;

        // Execute with real-time agent progress streaming
        const result = await this.executeTaskWithStreaming(
          taskId,
          name,
          args.prompt,
          {
            context: args.context,
            run_multiple: args.run_multiple,
            mode: args.mode,
            project_dir: args.project_dir,
            timeout: timeoutMs
          }
        );

        const duration = Date.now() - startTime;

        this.logger.info('Tool completed', {
          tool: name,
          taskId,
          duration_ms: duration,
          success: true
        });

        return {
          content: [{
            type: 'text',
            text: result
          }],
          _meta: {
            task: name,
            taskId,
            version: TOOL_VERSION,
            duration_ms: duration,
            timestamp: new Date().toISOString()
          }
        };
      } catch (error) {
        this.logger.error('Tool failed', {
          tool: name,
          taskId,
          error: error.message,
          stack: error.stack
        });

        return {
          content: [{
            type: 'text',
            text: `Error: ${error.message}\n\nCheck logs: ${this.logger.logFile}`
          }],
          isError: true
        };
      }
    });
  }

  /**
   * Execute task with real-time agent progress streaming
   */
  async executeTaskWithStreaming(taskId, task, prompt, options = {}) {
    const timeoutMs = options.timeout || DEFAULT_TIMEOUT_MS;

    return new Promise((resolve, reject) => {
      // Validate
      if (!prompt || typeof prompt !== 'string') {
        reject(new Error('Invalid prompt'));
        return;
      }

      if (prompt.length > 50000) {
        reject(new Error('Prompt too long (max 50000 characters)'));
        return;
      }

      if (!existsSync(this.routerPath)) {
        this.logger.error('Router not found', { path: this.routerPath });
        reject(new Error(`Router not available at: ${this.routerPath}\n\nRun health check for details.`));
        return;
      }

      // Build args
      const args = ['--task', task, '--prompt', prompt];
      if (options.context) args.push('--context', options.context);
      if (options.mode) args.push('--mode', options.mode);
      if (options.project_dir) args.push('--project-dir', options.project_dir);
      if (options.run_multiple !== undefined) {
        args.push('--run-multiple', options.run_multiple.toString());
      }

      this.logger.info('Spawning router with streaming', { taskId, task });

      // Spawn (use 'ignore' for stdin to prevent blocking)
      const child = spawn(this.routerPath, args, {
        cwd: this.freeAgentsPath,
        stdio: ['ignore', 'pipe', 'pipe']  // stdin: ignore, stdout: pipe, stderr: pipe
      });

      this.runningTasks.set(taskId, child);

      let stdout = '';
      let stderr = '';
      let lastProgressTime = Date.now();
      const progressMessages = []; // Collect all progress for final response

      // Timeout
      const timeoutTimer = setTimeout(() => {
        this.logger.error('Task timeout', { taskId, task, timeout_ms: timeoutMs });

        if (!child.killed) {
          child.kill('SIGTERM');
          setTimeout(() => {
            if (!child.killed) {
              this.logger.warn('Force killing task', { taskId });
              child.kill('SIGKILL');
            }
          }, 5000);
        }

        reject(new Error(`Task timeout after ${timeoutMs / 1000}s.\n\nCheck logs: ${this.logger.logFile}`));
      }, timeoutMs);

      // Capture stdout (normal output)
      child.stdout.on('data', (data) => {
        stdout += data.toString();
        lastProgressTime = Date.now();
      });

      // Capture stderr (AGENT PROGRESS MESSAGES!)
      child.stderr.on('data', (data) => {
        const chunk = data.toString();
        stderr += chunk;
        lastProgressTime = Date.now();

        // Parse and stream agent progress in real-time
        const lines = chunk.split('\n');
        for (const line of lines) {
          if (line.includes('[AGENT-PROGRESS]')) {
            const progress = parseProgressMessage(line);
            if (progress) {
              // Log to file
              this.logger.info('Agent progress', {
                taskId,
                category: progress.category,
                message: progress.message
              });

              // Format and collect
              const formatted = formatProgress(progress);
              progressMessages.push(formatted);

              // Stream to user (Claude Code UI) via MCP notification
              try {
                // Send as MCP notification
                this.server.sendLoggingMessage({
                  level: 'info',
                  data: formatted
                });
              } catch (error) {
                // Fallback to stderr if notification fails
                console.error(formatted);
              }
            }
          } else if (line.trim()) {
            // Log other stderr output
            this.logger.debug('Router stderr', { taskId, line: line.trim() });
          }
        }
      });

      // Handle completion
      child.on('close', (code) => {
        clearTimeout(timeoutTimer);
        this.runningTasks.delete(taskId);

        this.logger.info('Task completed', {
          taskId,
          task,
          exitCode: code,
          stdout_length: stdout.length,
          stderr_length: stderr.length
        });

        if (code === 0) {
          // Success
          const xmlMatch = stdout.match(/<agent-result>[\s\S]*?<\/agent-result>/);
          let result;
          if (xmlMatch) {
            const outputMatch = xmlMatch[0].match(/<output>([\s\S]*?)<\/output>/);
            result = outputMatch ? outputMatch[1].trim() : stdout;
          } else if (stdout.trim()) {
            result = stdout.trim();
          } else {
            result = 'Task completed successfully';
          }

          // Prepend progress log if we have messages
          if (progressMessages.length > 0) {
            const progressLog = progressMessages.join('\n');
            result = `Agent Execution Progress:\n${progressLog}\n\n---\n\n${result}`;
          }

          resolve(result);
        } else {
          // Failure - include progress log
          const error = stderr || stdout || 'Unknown error';
          this.logger.error('Task failed', { taskId, code, error });

          let errorMessage = `Router failed (exit ${code}): ${error}`;
          if (progressMessages.length > 0) {
            const progressLog = progressMessages.join('\n');
            errorMessage = `Agent Execution Progress:\n${progressLog}\n\n---\n\n${errorMessage}`;
          }
          errorMessage += `\n\nCheck logs: ${this.logger.logFile}`;

          reject(new Error(errorMessage));
        }
      });

      // Handle spawn errors
      child.on('error', (error) => {
        clearTimeout(timeoutTimer);
        this.runningTasks.delete(taskId);

        this.logger.error('Spawn failed', { taskId, error: error.message });
        reject(new Error(`Failed to spawn router: ${error.message}\n\nCheck logs: ${this.logger.logFile}`));
      });
    });
  }

  setupShutdownHandlers() {
    const shutdown = async (signal) => {
      this.logger.info('Shutdown requested', { signal });

      if (this.runningTasks.size > 0) {
        console.error(`[SHUTDOWN] Canceling ${this.runningTasks.size} running tasks...`);

        for (const [taskId, child] of this.runningTasks) {
          this.logger.info('Killing task', { taskId });
          child.kill('SIGTERM');
        }

        await new Promise(resolve => setTimeout(resolve, 2000));

        for (const [taskId, child] of this.runningTasks) {
          if (!child.killed) {
            this.logger.warn('Force killing task', { taskId });
            child.kill('SIGKILL');
          }
        }
      }

      this.logger.info('Shutdown complete');
      process.exit(0);
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));
  }

  async run() {
    try {
      const transport = new StdioServerTransport();
      await this.server.connect(transport);
      this.logger.info('MCP Server running (streaming enabled)');
    } catch (error) {
      this.logger.error('Failed to start server', { error: error.message, stack: error.stack });
      throw error;
    }
  }
}

const server = new FreeAgentsServer();
server.run().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
