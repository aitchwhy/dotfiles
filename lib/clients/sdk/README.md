# Dotfiles SDK

A TypeScript SDK for interacting with dotfiles functionality, justfile commands, and AI capabilities.

## Features

- Execute justfile commands programmatically
- Access AI capabilities like code generation, commit message suggestions, and more
- Unified interface for different AI providers (Claude, OpenAI, local models)
- TypeScript 5.5.0 with strong typing

## Installation

```bash
npm install @dotfiles/sdk
```

## Usage

```typescript
import { DotfilesSDK } from '@dotfiles/sdk';

// Create SDK instance
const sdk = new DotfilesSDK({
  rootDir: '/path/to/dotfiles', // Optional, defaults to env var or cwd
});

// Get all available commands
const commands = sdk.getCommands();
console.log(commands);

// Execute a command
const result = await sdk.execute('sync', ['--dry-run']);
console.log(result.stdout);

// Use AI capabilities
const response = await sdk.ai('claude', {
  messages: [
    { role: 'system', content: 'You are a helpful assistant.' },
    { role: 'user', content: 'Help me write a git commit message for these changes.' }
  ],
  capability: 'commit-message',
});
console.log(response.content);
```

## Development

```bash
# Install dependencies
npm install

# Build the package
npm run build

# Run tests
npm test

# Lint code
npm run lint
```

## License

MIT