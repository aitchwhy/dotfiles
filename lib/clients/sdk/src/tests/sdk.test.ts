import { describe, it, expect, vi, beforeEach } from 'vitest';
import { DotfilesSDK } from '../sdk';
import * as childProcess from 'child_process';

// Mock child_process
vi.mock('child_process', () => {
  return {
    execSync: vi.fn(),
    spawn: vi.fn(),
  };
});

// Mock fs
vi.mock('fs', () => {
  return {
    existsSync: vi.fn().mockReturnValue(true),
    readFileSync: vi.fn(),
  };
});

describe('DotfilesSDK', () => {
  let sdk: DotfilesSDK;
  
  beforeEach(() => {
    vi.resetAllMocks();
    
    // Mock execSync to return a sample command list
    (childProcess.execSync as any).mockReturnValue(`
Available recipes:
    ai:chat               Start a chat with Claude
    ai:commit-msg         Generate a commit message
    brew:bundle           Install Homebrew packages from Brewfile
    brew:update           Update all Homebrew packages
    system:backup         Backup important files
    zsh:reload            Reload zsh configuration
`);
    
    // Mock spawn to return a successful command execution
    (childProcess.spawn as any).mockImplementation(() => {
      const mockProcess = {
        stdout: {
          on: vi.fn((event, callback) => {
            if (event === 'data') {
              callback('Command output');
            }
            return mockProcess.stdout;
          }),
        },
        stderr: {
          on: vi.fn((event, callback) => {
            return mockProcess.stderr;
          }),
        },
        on: vi.fn((event, callback) => {
          if (event === 'close') {
            callback(0); // Exit code 0 (success)
          }
          return mockProcess;
        }),
      };
      
      return mockProcess;
    });
    
    // Create SDK instance
    sdk = new DotfilesSDK({
      rootDir: '/mock/dotfiles',
    });
  });
  
  describe('getCommands', () => {
    it('should return all commands when no namespace is provided', () => {
      const commands = sdk.getCommands();
      expect(commands).toHaveLength(6);
      expect(commands.map(cmd => cmd.name)).toContain('ai:chat');
      expect(commands.map(cmd => cmd.name)).toContain('brew:bundle');
    });
    
    it('should filter commands by namespace', () => {
      const aiCommands = sdk.getCommands('ai');
      expect(aiCommands).toHaveLength(2);
      expect(aiCommands.map(cmd => cmd.name)).toContain('ai:chat');
      expect(aiCommands.map(cmd => cmd.name)).toContain('ai:commit-msg');
      
      const brewCommands = sdk.getCommands('brew');
      expect(brewCommands).toHaveLength(2);
      expect(brewCommands.map(cmd => cmd.name)).toContain('brew:bundle');
      expect(brewCommands.map(cmd => cmd.name)).toContain('brew:update');
    });
  });
  
  describe('getCommand', () => {
    it('should return a specific command by name', () => {
      const command = sdk.getCommand('ai:chat');
      expect(command).toBeDefined();
      expect(command?.name).toBe('ai:chat');
      expect(command?.shortName).toBe('chat');
      expect(command?.namespace).toBe('ai');
      expect(command?.description).toBe('Start a chat with Claude');
    });
    
    it('should return undefined for non-existent command', () => {
      const command = sdk.getCommand('non:existent');
      expect(command).toBeUndefined();
    });
  });
  
  describe('execute', () => {
    it('should execute a command and return successful result', async () => {
      const result = await sdk.execute('ai:chat');
      
      expect(result).toBeDefined();
      expect(result.command).toBe('ai:chat');
      expect(result.args).toEqual([]);
      expect(result.stdout).toBe('Command output');
      expect(result.stderr).toBe('');
      expect(result.exitCode).toBe(0);
      expect(result.success).toBe(true);
      
      expect(childProcess.spawn).toHaveBeenCalledWith(
        'just', 
        ['ai:chat'], 
        expect.objectContaining({
          cwd: '/mock/dotfiles',
        })
      );
    });
    
    it('should pass arguments to the command', async () => {
      await sdk.execute('brew:bundle', ['--verbose']);
      
      expect(childProcess.spawn).toHaveBeenCalledWith(
        'just', 
        ['brew:bundle', '--verbose'], 
        expect.any(Object)
      );
    });
    
    it('should throw an error for non-existent command', async () => {
      await expect(sdk.execute('non:existent')).rejects.toThrow('Command not found');
    });
  });
});