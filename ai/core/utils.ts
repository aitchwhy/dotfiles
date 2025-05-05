/**
 * Core utilities for AI operations
 * Version: 1.0.0 (May 2025)
 */

import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'js-yaml';
import { execSync } from 'child_process';
import {
  AIConfig,
  AIError,
  ClientConfig,
  CompletionOptions,
  CompletionResponse,
  ErrorType,
  ModelParameters,
  Provider,
  ProviderModel,
  SystemConfig,
  TaskType
} from './types';

/**
 * Default configuration paths
 */
const CONFIG_PATHS = {
  BASE: process.env.AI_CONFIG_DIR || path.join(process.env.HOME || '', '.config', 'ai'),
  CONFIG: path.join(process.env.AI_CONFIG_DIR || path.join(process.env.HOME || '', '.config', 'ai'), 'core', 'config.yaml'),
  HISTORY: path.join(process.env.AI_CONFIG_DIR || path.join(process.env.HOME || '', '.config', 'ai'), 'history'),
  PROMPTS: path.join(process.env.AI_CONFIG_DIR || path.join(process.env.HOME || '', '.config', 'ai'), 'prompts'),
  CACHE: path.join(process.env.HOME || '', '.cache', 'ai')
};

/**
 * Global configuration object loaded lazily
 */
let globalConfig: AIConfig | null = null;

/**
 * Load the global configuration
 * @returns The loaded configuration
 */
export function loadConfig(): AIConfig {
  if (globalConfig) {
    return globalConfig;
  }

  try {
    const configPath = process.env.AI_CONFIG_PATH || CONFIG_PATHS.CONFIG;
    if (!fs.existsSync(configPath)) {
      throw new AIError(`Configuration file not found at ${configPath}`, 'client_error');
    }

    const configContent = fs.readFileSync(configPath, 'utf-8');
    globalConfig = yaml.load(configContent) as AIConfig;
    
    // Expand environment variables in paths
    expandEnvironmentVariables(globalConfig);
    
    return globalConfig;
  } catch (error) {
    if (error instanceof AIError) {
      throw error;
    }
    throw new AIError(`Failed to load configuration: ${error instanceof Error ? error.message : String(error)}`, 'client_error');
  }
}

/**
 * Expand environment variables in configuration strings
 * @param obj The object to process
 */
function expandEnvironmentVariables(obj: any): void {
  if (typeof obj !== 'object' || obj === null) {
    return;
  }

  for (const key in obj) {
    const value = obj[key];
    
    if (typeof value === 'string' && value.includes('${')) {
      obj[key] = value.replace(/\${([^}]+)}/g, (_, envVar) => {
        return process.env[envVar] || '';
      });
    } else if (typeof value === 'object') {
      expandEnvironmentVariables(value);
    }
  }
}

/**
 * Get recommended model for a specific task
 * @param task The task type
 * @param preferLocal Whether to prefer local models
 * @returns The recommended model
 */
export function getRecommendedModel(task: TaskType, preferLocal: boolean = false): ProviderModel {
  const config = loadConfig();
  const taskConfig = config.tasks[task];
  
  if (!taskConfig) {
    throw new AIError(`No configuration found for task: ${task}`, 'client_error');
  }
  
  if (preferLocal && taskConfig.local_option) {
    return taskConfig.local_option;
  }
  
  return taskConfig.default;
}

/**
 * Parse a provider model string
 * @param model The provider model string (e.g., "anthropic.claude-3-opus")
 * @returns Provider and model name
 */
export function parseProviderModel(model: ProviderModel): { provider: Provider, model: string } {
  const [provider, ...modelParts] = model.split('.');
  return {
    provider: provider as Provider,
    model: modelParts.join('.')
  };
}

/**
 * Get model parameters for a given task
 * @param task The task type
 * @param overrides Parameter overrides
 * @returns The model parameters
 */
export function getTaskParameters(task: TaskType, overrides?: Partial<ModelParameters>): ModelParameters {
  const config = loadConfig();
  const taskConfig = config.tasks[task];
  
  if (!taskConfig) {
    // Fall back to default parameters
    return {
      ...config.defaults.parameters,
      ...overrides
    };
  }
  
  return {
    ...config.defaults.parameters,
    ...taskConfig.parameters,
    ...overrides
  };
}

/**
 * Create a client configuration for a provider
 * @param provider The provider
 * @param model Optional model name
 * @returns Client configuration
 */
export function createClientConfig(provider: Provider, model?: string): ClientConfig {
  const config = loadConfig();
  const providerConfig = config.providers[provider];
  
  if (!providerConfig) {
    throw new AIError(`No configuration found for provider: ${provider}`, 'client_error');
  }
  
  // Get API key from environment
  const apiKey = process.env[providerConfig.env_var];
  if (!apiKey) {
    throw new AIError(`API key not found for provider ${provider} (env var: ${providerConfig.env_var})`, 'authentication');
  }
  
  return {
    provider,
    model: model,
    api_key: apiKey,
    base_url: providerConfig.api_endpoint,
    default_parameters: config.defaults.parameters,
    timeout_ms: config.defaults.parameters.timeout_ms
  };
}

/**
 * Check if the environmental requirements are met
 * @param showWarnings Whether to log warnings to console
 * @returns Whether all requirements are met
 */
export function checkEnvironment(showWarnings: boolean = true): boolean {
  try {
    // Check for Just command
    const justExists = commandExists('just');
    if (!justExists && showWarnings) {
      console.warn('Warning: "just" command not found. Install it for full functionality.');
    }
    
    // Check for provider API keys
    const config = loadConfig();
    const missingKeys: string[] = [];
    
    for (const [provider, providerConfig] of Object.entries(config.providers)) {
      const apiKey = process.env[providerConfig.env_var];
      if (!apiKey) {
        missingKeys.push(`${provider} (${providerConfig.env_var})`);
      }
    }
    
    if (missingKeys.length > 0 && showWarnings) {
      console.warn(`Warning: Missing API keys for: ${missingKeys.join(', ')}`);
    }
    
    return justExists && missingKeys.length === 0;
  } catch (error) {
    if (showWarnings) {
      console.error('Error checking environment:', error instanceof Error ? error.message : String(error));
    }
    return false;
  }
}

/**
 * Check if a command exists in the PATH
 * @param command The command to check
 * @returns Whether the command exists
 */
export function commandExists(command: string): boolean {
  try {
    execSync(`which ${command}`, { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

/**
 * Format error message and type from API response
 * @param statusCode HTTP status code
 * @param errorData Error data from API
 * @param provider Provider name
 * @returns Error type and message
 */
export function formatError(statusCode: number, errorData: any, provider: Provider): { type: ErrorType, message: string, retryable: boolean } {
  // Default values
  let type: ErrorType = 'unknown';
  let message = 'An unknown error occurred';
  let retryable = false;
  
  // Handle based on status code
  if (statusCode >= 500) {
    type = 'server_error';
    message = 'Server error occurred';
    retryable = true;
  } else if (statusCode === 429) {
    type = 'rate_limit';
    message = 'Rate limit exceeded';
    retryable = true;
  } else if (statusCode === 401 || statusCode === 403) {
    type = 'authentication';
    message = 'Authentication error';
    retryable = false;
  } else if (statusCode >= 400 && statusCode < 500) {
    type = 'client_error';
    message = 'Client error occurred';
    retryable = false;
  }
  
  // Provider-specific error formatting
  if (provider === 'anthropic') {
    if (errorData.error?.type) {
      message = errorData.error.message || message;
      
      if (errorData.error.type === 'content_filter') {
        type = 'content_filter';
        retryable = false;
      }
    }
  } else if (provider === 'openai') {
    if (errorData.error) {
      message = errorData.error.message || message;
      
      if (errorData.error.type === 'tokens' || errorData.error.code === 'context_length_exceeded') {
        type = 'invalid_request';
        message = 'Token limit exceeded';
        retryable = false;
      } else if (errorData.error.code === 'content_filter') {
        type = 'content_filter';
        retryable = false;
      }
    }
  }
  
  return { type, message, retryable };
}

/**
 * Execute a just command and return the output
 * @param namespace The just namespace
 * @param command The command name
 * @param args Command arguments
 * @returns Command output
 */
export function executeJust(namespace: string, command: string, args: string[] = []): string {
  try {
    if (!commandExists('just')) {
      throw new AIError('just command not found', 'client_error');
    }
    
    const cmd = `just ${namespace}:${command} ${args.join(' ')}`;
    return execSync(cmd, { encoding: 'utf8' });
  } catch (error) {
    if (error instanceof Error) {
      throw new AIError(`Error executing command: ${error.message}`, 'client_error');
    }
    throw new AIError(`Unknown error executing command`, 'client_error');
  }
}

/**
 * Sanitize content to prevent prompt injection
 * @param content The content to sanitize
 * @returns Sanitized content
 */
export function sanitizeContent(content: string): string {
  // Remove potential prompt injection markers
  content = content.replace(/```prompt|<prompt>|<system>/gi, '');
  
  // Escape backticks and angle brackets
  content = content.replace(/`/g, '\\`');
  content = content.replace(/</g, '&lt;');
  content = content.replace(/>/g, '&gt;');
  
  return content;
}

/**
 * Extract code from a Markdown string
 * @param markdown Markdown string potentially containing code blocks
 * @param language Optional language filter
 * @returns Extracted code
 */
export function extractCodeFromMarkdown(markdown: string, language?: string): string {
  const codeBlockRegex = /```(?:([a-zA-Z0-9_-]+)\n)?([\s\S]*?)```/g;
  let match;
  let code = '';
  
  while ((match = codeBlockRegex.exec(markdown)) !== null) {
    const [_, blockLanguage, blockCode] = match;
    
    // If language is specified, only extract blocks with that language
    if (!language || !blockLanguage || blockLanguage === language) {
      code += blockCode.trim() + '\n\n';
    }
  }
  
  return code.trim();
}