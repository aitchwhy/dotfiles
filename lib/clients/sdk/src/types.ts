/**
 * Type definitions for the dotfiles SDK
 */

// General Types

/**
 * Namespaces for justfile commands
 */
export type Namespace = 'ai' | 'git' | 'nvim' | 'zsh' | 'brew' | 'system' | string;

/**
 * Command definition
 */
export interface Command {
  /** Full command name (with namespace if present) */
  name: string;
  /** Command name without namespace */
  shortName: string;
  /** Command namespace (undefined if no namespace) */
  namespace?: Namespace;
  /** Command description */
  description: string;
  /** Command parameters */
  parameters: Parameter[];
}

/**
 * Recipe definition from justfile
 */
export interface RecipeDefinition {
  /** Recipe name */
  name: string;
  /** Recipe dependencies */
  dependencies: string[];
  /** Recipe parameters */
  parameters: Parameter[];
  /** Recipe code */
  code: string;
  /** Recipe description */
  description?: string;
}

/**
 * Parameter definition
 */
export interface Parameter {
  /** Parameter name */
  name: string;
  /** Parameter type */
  type: string;
  /** Default value (undefined if no default) */
  defaultValue?: string;
  /** Whether the parameter is required */
  required: boolean;
}

/**
 * Command execution options
 */
export interface CommandOptions {
  /** Working directory for command execution */
  cwd?: string;
  /** Environment variables */
  env?: Record<string, string>;
  /** Callback for stdout data */
  onStdout?: (data: string) => void;
  /** Callback for stderr data */
  onStderr?: (data: string) => void;
}

/**
 * Command execution result
 */
export interface CommandResult {
  /** Command name */
  command: string;
  /** Command arguments */
  args: string[];
  /** Command stdout */
  stdout: string;
  /** Command stderr */
  stderr: string;
  /** Exit code */
  exitCode: number;
  /** Whether the command succeeded */
  success: boolean;
}

/**
 * SDK configuration options
 */
export interface SDKOptions {
  /** Path to dotfiles root */
  rootDir?: string;
  /** Path to just binary */
  justBin?: string;
}

// AI Types

/**
 * Supported AI providers
 */
export type AIProviderType = 'openai' | 'claude' | 'local' | string;

/**
 * AI capabilities
 */
export type AICapability = 
  | 'code-generation'
  | 'code-review'
  | 'commit-message'
  | 'documentation'
  | 'summarization'
  | 'question-answering'
  | string;

/**
 * AI provider configuration
 */
export interface AIProvider {
  /** Provider name */
  name: string;
  /** Provider type */
  type: AIProviderType;
  /** Provider endpoint */
  endpoint?: string;
  /** API key (fallback to env var if not provided) */
  apiKey?: string;
  /** Default model */
  defaultModel?: string;
  /** Available models */
  models?: string[];
  /** Maximum context length */
  maxContextLength?: number;
  /** Supported capabilities */
  capabilities: AICapability[];
}

/**
 * AI message
 */
export interface AIMessage {
  /** Message role */
  role: 'system' | 'user' | 'assistant' | 'tool';
  /** Message content */
  content: string;
  /** Tool calls for this message (if role is 'tool') */
  toolCalls?: any[];
  /** Tool call ID this message is responding to (if role is 'tool') */
  toolCallId?: string;
}

/**
 * AI request
 */
export interface AIRequest {
  /** Messages for the AI */
  messages?: AIMessage[];
  /** Capability to use */
  capability?: AICapability;
  /** Model to use (defaults to provider's default) */
  model?: string;
  /** Maximum tokens to generate */
  maxTokens?: number;
  /** Temperature (0-1) */
  temperature?: number;
  /** Top-p sampling (0-1) */
  topP?: number;
  /** Raw options to pass to the provider */
  raw?: Record<string, any>;
}

/**
 * AI response
 */
export interface AIResponse {
  /** Provider name */
  provider: string;
  /** Model used */
  model: string;
  /** Response content */
  content: string;
  /** Usage statistics */
  usage?: {
    promptTokens?: number;
    completionTokens?: number;
    totalTokens?: number;
  };
  /** Raw response from the provider */
  raw: any;
}

// Error Handling

/**
 * Error codes
 */
export enum ErrorCode {
  COMMAND_NOT_FOUND = 'COMMAND_NOT_FOUND',
  COMMAND_EXECUTION_ERROR = 'COMMAND_EXECUTION_ERROR',
  CONFIG_ERROR = 'CONFIG_ERROR',
  AI_PROVIDER_ERROR = 'AI_PROVIDER_ERROR',
  AI_EXECUTION_ERROR = 'AI_EXECUTION_ERROR',
  UNEXPECTED_ERROR = 'UNEXPECTED_ERROR',
}

/**
 * SDK error
 */
export class SDKError extends Error {
  /** Error code */
  code: ErrorCode;
  /** Cause of the error */
  cause?: Error;
  
  constructor(options: { message: string; code: ErrorCode; cause?: Error }) {
    super(options.message);
    this.name = 'SDKError';
    this.code = options.code;
    this.cause = options.cause;
  }
}