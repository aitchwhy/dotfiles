import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'js-yaml';
import { AIProvider, SDKError, ErrorCode } from './types';

/**
 * Load YAML configuration file
 * @param filePath Path to YAML file
 * @returns Parsed YAML content
 */
export function loadYamlConfig<T>(filePath: string): T {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    return yaml.load(content) as T;
  } catch (error: any) {
    throw new SDKError({
      code: ErrorCode.CONFIG_ERROR,
      message: `Failed to load YAML config from ${filePath}`,
      cause: error,
    });
  }
}

/**
 * Load AI provider configurations from config file
 * @param configPath Path to the config directory
 * @returns Map of provider names to provider configurations
 */
export function loadAIProviders(configPath: string): Map<string, AIProvider> {
  const providers = new Map<string, AIProvider>();
  const configFile = path.join(configPath, 'core', 'config.yaml');
  
  try {
    if (fs.existsSync(configFile)) {
      const config = loadYamlConfig<{providers: AIProvider[]}>(configFile);
      
      if (config.providers && Array.isArray(config.providers)) {
        config.providers.forEach(provider => {
          providers.set(provider.name, provider);
        });
      }
    }
  } catch (error) {
    console.warn(`Failed to load AI providers from ${configFile}:`, error);
  }
  
  return providers;
}

/**
 * Find the dotfiles root directory
 * @returns Path to the dotfiles root
 */
export function findDotfilesRoot(): string {
  // Try environment variable first
  if (process.env.DOTFILES_ROOT) {
    return process.env.DOTFILES_ROOT;
  }
  
  // Try current directory and its parents
  let currentDir = process.cwd();
  
  while (currentDir !== path.parse(currentDir).root) {
    // Check for dotfiles markers (README.md, justfile, etc.)
    if (
      fs.existsSync(path.join(currentDir, 'justfile')) &&
      fs.existsSync(path.join(currentDir, 'README.md'))
    ) {
      return currentDir;
    }
    
    // Move up to parent directory
    currentDir = path.dirname(currentDir);
  }
  
  // Default to home directory's dotfiles
  const homeDir = process.env.HOME || process.env.USERPROFILE || '';
  const homeDotfiles = path.join(homeDir, 'dotfiles');
  
  if (fs.existsSync(homeDotfiles)) {
    return homeDotfiles;
  }
  
  throw new SDKError({
    code: ErrorCode.CONFIG_ERROR,
    message: 'Could not find dotfiles root directory',
  });
}

/**
 * Format an error message with standardized structure
 * @param error Error object or message
 * @returns Formatted error message
 */
export function formatError(error: unknown): string {
  if (error instanceof SDKError) {
    return `[${error.code}] ${error.message}${error.cause ? `: ${error.cause}` : ''}`;
  } else if (error instanceof Error) {
    return `[ERROR] ${error.message}`;
  } else {
    return `[ERROR] ${String(error)}`;
  }
}