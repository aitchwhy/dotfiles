import { execSync, spawn } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';
import {
  Command,
  CommandOptions,
  CommandResult,
  Namespace,
  RecipeDefinition,
  SDKOptions,
  AIProvider,
  AIRequest,
  AIResponse,
} from './types';
import { parseJustfileCommands } from './parser';
import { executeAIRequest } from './ai';

/**
 * Main SDK class for interacting with dotfiles functionality
 */
export class DotfilesSDK {
  private rootDir: string;
  private justBin: string;
  private commands: Map<string, Command>;
  private aiProviders: Map<string, AIProvider>;
  
  /**
   * Create a new DotfilesSDK instance
   * @param options SDK configuration options
   */
  constructor(options?: SDKOptions) {
    this.rootDir = options?.rootDir || process.env.DOTFILES_ROOT || process.cwd();
    this.justBin = options?.justBin || 'just';
    this.commands = new Map();
    this.aiProviders = new Map();
    
    // Load commands from justfile
    this.loadCommands();
    
    // Load AI providers from config
    this.loadAIProviders();
  }
  
  /**
   * Load all commands from the justfile
   * @private
   */
  private loadCommands(): void {
    try {
      const output = execSync(`${this.justBin} --list --unsorted --show-hidden`, {
        cwd: this.rootDir,
        encoding: 'utf-8',
      });
      
      const commands = parseJustfileCommands(output);
      commands.forEach(cmd => this.commands.set(cmd.name, cmd));
    } catch (error) {
      console.error('Failed to load commands from justfile:', error);
    }
  }
  
  /**
   * Load AI providers from configuration
   * @private
   */
  private loadAIProviders(): void {
    const configPath = path.join(this.rootDir, 'config', 'ai', 'core', 'config.yaml');
    
    try {
      // Load provider configuration logic will be implemented here
      // This is a placeholder for now
    } catch (error) {
      console.error('Failed to load AI providers:', error);
    }
  }
  
  /**
   * Get all available commands, optionally filtered by namespace
   * @param namespace Optional namespace to filter commands
   * @returns Array of commands
   */
  public getCommands(namespace?: Namespace): Command[] {
    if (!namespace) {
      return Array.from(this.commands.values());
    }
    
    return Array.from(this.commands.values())
      .filter(cmd => cmd.namespace === namespace);
  }
  
  /**
   * Get a specific command by name
   * @param name Command name
   * @returns Command definition or undefined if not found
   */
  public getCommand(name: string): Command | undefined {
    return this.commands.get(name);
  }
  
  /**
   * Execute a justfile command
   * @param name Command name
   * @param args Command arguments
   * @param options Execution options
   * @returns Promise resolving to command result
   */
  public async execute(name: string, args: string[] = [], options?: CommandOptions): Promise<CommandResult> {
    const command = this.getCommand(name);
    
    if (!command) {
      throw new Error(`Command not found: ${name}`);
    }
    
    return new Promise((resolve, reject) => {
      const cmdArgs = [name, ...args];
      const cmdOptions = {
        cwd: options?.cwd || this.rootDir,
        env: {
          ...process.env,
          ...(options?.env || {}),
        },
      };
      
      const proc = spawn(this.justBin, cmdArgs, cmdOptions);
      
      let stdout = '';
      let stderr = '';
      
      proc.stdout.on('data', (data) => {
        stdout += data.toString();
        if (options?.onStdout) {
          options.onStdout(data.toString());
        }
      });
      
      proc.stderr.on('data', (data) => {
        stderr += data.toString();
        if (options?.onStderr) {
          options.onStderr(data.toString());
        }
      });
      
      proc.on('close', (code) => {
        const result: CommandResult = {
          command: name,
          args,
          stdout,
          stderr,
          exitCode: code ?? 0,
          success: code === 0,
        };
        
        if (code === 0) {
          resolve(result);
        } else {
          reject(result);
        }
      });
    });
  }
  
  /**
   * Make an AI request to a specific provider
   * @param provider Provider name
   * @param request AI request details
   * @returns Promise resolving to AI response
   */
  public async ai(provider: string, request: AIRequest): Promise<AIResponse> {
    const aiProvider = this.aiProviders.get(provider);
    
    if (!aiProvider) {
      throw new Error(`AI provider not found: ${provider}`);
    }
    
    return executeAIRequest(aiProvider, request);
  }
}