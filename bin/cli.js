#!/usr/bin/env node

/**
 * Save My Tokens CLI
 * Install and manage Save My Tokens for Claude Code
 */

import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { execSync } from 'child_process';
import { readFileSync, existsSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const rootDir = join(__dirname, '..');

// ANSI colors
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  blue: '\x1b[34m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
};

function print(msg, color = '') {
  console.log(`${color}${msg}${colors.reset}`);
}

function printBanner() {
  print('╔══════════════════════════════════════════════════════════╗', colors.cyan);
  print('║                                                          ║', colors.cyan);
  print('║         🤖 Save My Tokens - Installation CLI 🤖         ║', colors.cyan);
  print('║                                                          ║', colors.cyan);
  print('╚══════════════════════════════════════════════════════════╝', colors.cyan);
  print('');
}

function printHelp() {
  printBanner();
  print('Multi-model AI agent router with real-time progress streaming\n', colors.bright);

  print('Usage:', colors.bright);
  print('  npx save-my-tokens [command]\n');

  print('Commands:', colors.bright);
  print('  install          Install Save My Tokens for Claude Code');
  print('  test             Run test suite to verify installation');
  print('  uninstall        Remove Save My Tokens from Claude Code');
  print('  status           Check installation status');
  print('  help             Show this help message\n');

  print('Examples:', colors.bright);
  print('  npx save-my-tokens install      # Install to Claude Code');
  print('  npx save-my-tokens test          # Run tests');
  print('  npx save-my-tokens status        # Check status\n');

  print('After installation:', colors.bright);
  print('  1. Restart Claude Code: pkill -f "claude --"');
  print('  2. Use in Claude: "use research tool with prompt=\\"test\\""');
  print('  3. See real-time progress! 🚀\n');

  print('Documentation:', colors.bright);
  print('  README:        https://github.com/Dan-paull/save-my-tokens#readme');
  print('  Installation:  https://github.com/Dan-paull/save-my-tokens/blob/main/INSTALLATION.md');
  print('  Contributing:  https://github.com/Dan-paull/save-my-tokens/blob/main/CONTRIBUTING.md\n');
}

function checkNodeVersion() {
  const version = process.version;
  const major = parseInt(version.slice(1).split('.')[0]);

  if (major < 18) {
    print(`❌ Error: Node.js 18 or higher required (you have ${version})`, colors.red);
    print('Please upgrade Node.js: https://nodejs.org\n', colors.yellow);
    process.exit(1);
  }

  print(`✓ Node.js ${version}`, colors.green);
}

function checkPrerequisites() {
  print('Checking prerequisites...', colors.bright);

  checkNodeVersion();

  // Check if Claude Code config exists
  const claudeConfigPath = join(process.env.HOME, '.claude.json');
  if (!existsSync(claudeConfigPath)) {
    print('⚠️  Claude Code config not found at ~/.claude.json', colors.yellow);
    print('   This is normal if you haven\'t run Claude Code yet.\n', colors.yellow);
  } else {
    print('✓ Claude Code config found', colors.green);
  }

  print('');
}

function runInstall() {
  printBanner();
  print('Installing Save My Tokens for Claude Code...\n', colors.bright);

  checkPrerequisites();

  // Check for API keys
  const envPath = join(rootDir, '.env.savemytokens');
  const envExamplePath = join(rootDir, '.env.savemytokens.example');

  if (!existsSync(envPath)) {
    print('⚠️  No .env.savemytokens file found', colors.yellow);
    print('   Creating from template...\n', colors.yellow);

    try {
      const example = readFileSync(envExamplePath, 'utf8');
      require('fs').writeFileSync(envPath, example);
      print('✓ Created .env.savemytokens', colors.green);
      print('⚠️  Please edit .env.savemytokens and add your API keys:', colors.yellow);
      print(`   ${envPath}\n`, colors.cyan);
      print('Get FREE API keys from:', colors.bright);
      print('  - Cerebras: https://cerebras.ai (fast, generous free tier)');
      print('  - Mistral:  https://mistral.ai (good free tier)\n');
    } catch (error) {
      print(`❌ Error creating .env.savemytokens: ${error.message}`, colors.red);
      process.exit(1);
    }
  } else {
    print('✓ .env.savemytokens exists', colors.green);
  }

  // Run installation script
  print('\nRunning installation script...', colors.bright);
  const installScript = join(rootDir, 'mcp-scripts', 'install-streaming.sh');

  try {
    execSync(`bash "${installScript}"`, {
      stdio: 'inherit',
      cwd: rootDir
    });

    print('\n✅ Installation complete!', colors.green);
    print('\nNext steps:', colors.bright);
    print('  1. Edit API keys (if not done): nano .env.savemytokens');
    print('  2. Restart Claude Code: pkill -f "claude --"');
    print('  3. Test: use research tool with prompt="test"');
    print('  4. See real-time progress! 🚀\n');

  } catch (error) {
    print(`\n❌ Installation failed: ${error.message}`, colors.red);
    process.exit(1);
  }
}

function runTest() {
  printBanner();
  print('Running Save My Tokens test suite...\n', colors.bright);

  checkPrerequisites();

  const testScript = join(rootDir, 'mcp-scripts', 'test-streaming.sh');

  try {
    execSync(`bash "${testScript}"`, {
      stdio: 'inherit',
      cwd: rootDir
    });

    print('\n✅ All tests passed!', colors.green);

  } catch (error) {
    print(`\n❌ Tests failed: ${error.message}`, colors.red);
    print('\nCheck logs:', colors.yellow);
    print(`  tail -f ${join(rootDir, 'logs', 'mcp-server.log')}\n`);
    process.exit(1);
  }
}

function runStatus() {
  printBanner();
  print('Checking Save My Tokens status...\n', colors.bright);

  checkNodeVersion();

  // Check config
  const claudeConfigPath = join(process.env.HOME, '.claude.json');
  if (existsSync(claudeConfigPath)) {
    print('✓ Claude Code config found', colors.green);

    try {
      const config = JSON.parse(readFileSync(claudeConfigPath, 'utf8'));
      if (config.mcpServers && config.mcpServers['save-my-tokens']) {
        print('✓ Save My Tokens configured in Claude Code', colors.green);
        const serverPath = config.mcpServers['save-my-tokens'].args?.[0];
        if (serverPath) {
          print(`  Server: ${serverPath}`, colors.cyan);
        }
      } else {
        print('⚠️  Save My Tokens not configured', colors.yellow);
        print('  Run: npx save-my-tokens install\n', colors.cyan);
      }
    } catch (error) {
      print(`⚠️  Could not read config: ${error.message}`, colors.yellow);
    }
  } else {
    print('⚠️  Claude Code config not found', colors.yellow);
    print('  Expected at: ~/.claude.json\n', colors.cyan);
  }

  // Check API keys
  const envPath = join(rootDir, '.env.savemytokens');
  if (existsSync(envPath)) {
    print('✓ .env.savemytokens exists', colors.green);

    const envContent = readFileSync(envPath, 'utf8');
    const keys = ['CEREBRAS_API_KEY', 'MISTRAL_API_KEY'];
    let configuredCount = 0;

    keys.forEach(key => {
      const regex = new RegExp(`^${key}=.+$`, 'm');
      if (regex.test(envContent) && !envContent.includes(`${key}=your_`)) {
        configuredCount++;
      }
    });

    if (configuredCount > 0) {
      print(`✓ ${configuredCount} API key(s) configured`, colors.green);
    } else {
      print('⚠️  No API keys configured', colors.yellow);
      print(`  Edit: ${envPath}\n`, colors.cyan);
    }
  } else {
    print('⚠️  .env.savemytokens not found', colors.yellow);
    print('  Run: npx save-my-tokens install\n', colors.cyan);
  }

  // Check MCP server
  const serverPath = join(rootDir, 'mcp-scripts', 'mcp-server-streaming.js');
  if (existsSync(serverPath)) {
    print('✓ MCP server found', colors.green);
  } else {
    print('❌ MCP server not found', colors.red);
  }

  print('');
}

function runUninstall() {
  printBanner();
  print('Uninstalling Save My Tokens from Claude Code...\n', colors.bright);

  const claudeConfigPath = join(process.env.HOME, '.claude.json');

  if (!existsSync(claudeConfigPath)) {
    print('⚠️  Claude Code config not found', colors.yellow);
    print('Nothing to uninstall.\n');
    return;
  }

  try {
    const config = JSON.parse(readFileSync(claudeConfigPath, 'utf8'));

    if (config.mcpServers && config.mcpServers['save-my-tokens']) {
      delete config.mcpServers['save-my-tokens'];
      require('fs').writeFileSync(claudeConfigPath, JSON.stringify(config, null, 2) + '\n');

      print('✅ Save My Tokens removed from Claude Code config', colors.green);
      print('\nNext steps:', colors.bright);
      print('  1. Restart Claude Code: pkill -f "claude --"');
      print('  2. Save My Tokens tools will no longer be available\n');

    } else {
      print('⚠️  Save My Tokens not configured', colors.yellow);
      print('Nothing to uninstall.\n');
    }

  } catch (error) {
    print(`❌ Error: ${error.message}`, colors.red);
    process.exit(1);
  }
}

// Main CLI logic
const args = process.argv.slice(2);
const command = args[0] || 'help';

switch (command) {
  case 'install':
    runInstall();
    break;

  case 'test':
    runTest();
    break;

  case 'status':
    runStatus();
    break;

  case 'uninstall':
    runUninstall();
    break;

  case 'help':
  case '--help':
  case '-h':
    printHelp();
    break;

  default:
    print(`❌ Unknown command: ${command}\n`, colors.red);
    printHelp();
    process.exit(1);
}
