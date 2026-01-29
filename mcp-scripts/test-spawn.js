#!/usr/bin/env node

import { spawn } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const routerPath = path.join(__dirname, 'router.sh');

console.error(`Testing spawn with: ${routerPath}`);

const child = spawn(routerPath, ['--task', 'research', '--prompt', 'test', '--run-multiple', 'false'], {
  cwd: __dirname,
  stdio: ['pipe', 'pipe', 'pipe']
});

let stdout = '';
let stderr = '';

child.stdout.on('data', (data) => {
  const chunk = data.toString();
  console.error(`stdout: ${JSON.stringify(chunk)}`);
  stdout += chunk;
});

child.stderr.on('data', (data) => {
  const chunk = data.toString();
  console.error(`stderr: ${JSON.stringify(chunk)}`);
  stderr += chunk;
});

child.on('close', (code) => {
  console.error(`Process exited with code: ${code}`);
  console.error(`Final stdout: ${JSON.stringify(stdout)}`);
  console.error(`Final stderr: ${JSON.stringify(stderr)}`);
  process.exit(0);
});

child.on('error', (error) => {
  console.error(`Spawn error: ${error.message}`);
  process.exit(1);
});
