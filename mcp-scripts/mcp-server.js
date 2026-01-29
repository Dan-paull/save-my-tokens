#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';
import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { existsSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

class FreeAgentsServer {
  constructor() {
    this.server = new Server(
      {
        name: 'save-my-tokens',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    // MCP server is in mcp-scripts/, router.sh is in parent directory
    this.freeAgentsPath = dirname(__dirname);
    this.routerPath = join(this.freeAgentsPath, 'router.sh');
    
    this.setupToolHandlers();
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'research',
            description: 'Multi-model research with diverse perspectives',
            inputSchema: {
              type: 'object',
              properties: {
                prompt: {
                  type: 'string',
                  description: 'Research query or topic'
                },
                context: {
                  type: 'string',
                  description: 'Additional context for the research'
                },
                run_multiple: {
                  type: 'boolean',
                  description: 'Use multiple models for diverse perspectives',
                  default: true
                }
              },
              required: ['prompt']
            }
          },
          {
            name: 'coding',
            description: 'Code generation and modifications',
            inputSchema: {
              type: 'object',
              properties: {
                prompt: {
                  type: 'string',
                  description: 'Coding task or requirement'
                },
                context: {
                  type: 'string',
                  description: 'Additional context or existing code'
                },
                run_multiple: {
                  type: 'boolean',
                  description: 'Use multiple models for code generation',
                  default: false
                }
              },
              required: ['prompt']
            }
          },
          {
            name: 'planning',
            description: 'Architecture and implementation planning',
            inputSchema: {
              type: 'object',
              properties: {
                prompt: {
                  type: 'string',
                  description: 'Planning task or system to design'
                },
                context: {
                  type: 'string',
                  description: 'Additional context or constraints'
                },
                run_multiple: {
                  type: 'boolean',
                  description: 'Use multiple models for diverse planning approaches',
                  default: true
                }
              },
              required: ['prompt']
            }
          },
          {
            name: 'code_review',
            description: 'Code review and analysis',
            inputSchema: {
              type: 'object',
              properties: {
                prompt: {
                  type: 'string',
                  description: 'Code to review or specific review request'
                },
                context: {
                  type: 'string',
                  description: 'Additional context about the code or project'
                },
                run_multiple: {
                  type: 'boolean',
                  description: 'Use multiple models for comprehensive review',
                  default: true
                }
              },
              required: ['prompt']
            }
          }
        ]
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;
      
      try {
        const result = await this.executeTask(name, args.prompt, {
          context: args.context,
          run_multiple: args.run_multiple
        });

        return {
          content: [
            {
              type: 'text',
              text: result
            }
          ]
        };
      } catch (error) {
        return {
          content: [
            {
              type: 'text',
              text: `Error: ${error.message}`
            }
          ],
          isError: true
        };
      }
    });
  }

  async executeTask(task, prompt, options = {}) {
    return new Promise((resolve) => {
      // Check if router.sh exists and is executable
      if (!existsSync(this.routerPath)) {
        resolve(`Save My Tokens ${task} (router not available): ${prompt}`);
        return;
      }

      const args = [
        '--task', task,
        '--prompt', prompt
      ];

      if (options.context) {
        args.push('--context', options.context);
      }
      
      if (options.run_multiple !== undefined) {
        args.push('--run-multiple', options.run_multiple.toString());
      }

      const child = spawn(this.routerPath, args, {
        cwd: this.freeAgentsPath,
        stdio: ['pipe', 'pipe', 'pipe']
      });

      let stdout = '';
      let stderr = '';

      child.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      child.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      child.on('close', (code) => {
        if (code === 0) {
          // Extract XML result from stdout
          const xmlMatch = stdout.match(/<agent-result>[\s\S]*?<\/agent-result>/);
          if (xmlMatch) {
            const outputMatch = xmlMatch[0].match(/<output>([\s\S]*?)<\/output>/);
            const result = outputMatch ? outputMatch[1].trim() : stdout;
            resolve(result);
          } else {
            resolve(stdout || 'Task completed successfully');
          }
        } else {
          // Fallback to simple response if router fails
          resolve(`Save My Tokens ${task} (fallback): ${prompt}\n\nNote: Router execution failed, using fallback response.`);
        }
      });

      child.on('error', () => {
        // Fallback to simple response if spawn fails
        resolve(`Save My Tokens ${task} (fallback): ${prompt}\n\nNote: Router spawn failed, using fallback response.`);
      });
    });
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
  }
}

const server = new FreeAgentsServer();
server.run().catch(console.error);
