/**
 * Core TypeScript type definitions for AI integrations
 * Version: 1.0.0 (May 2025)
 */

// Provider identifiers
export type Provider = 'anthropic' | 'openai' | 'google' | 'local';
export type ProviderModel = `${Provider}.${string}`;

// Model capabilities
export type ModelCapability = 
  | 'reasoning' 
  | 'code' 
  | 'multi-turn' 
  | 'embeddings' 
  | 'vision' 
  | 'tools'
  | 'function_calling';

// Chat roles
export type Role = 'system' | 'user' | 'assistant' | 'tool' | 'model';

// Model configuration
export interface ModelConfig {
  id: string;
  version: string;
  context_window: number;
  token_limit: number;
  cost_per_1k_input: number;
  cost_per_1k_output: number;
  streaming: boolean;
  capabilities: ModelCapability[];
  roles: Role[];
  tunable: boolean;
  endpoint?: string;
}

// Provider-specific API configuration
export interface ProviderConfig {
  api_endpoint: string;
  auth_type: 'bearer' | 'apikey' | 'basic' | 'none';
  env_var: string;
  api_version?: string;
  headers: Record<string, string>;
  rate_limit: {
    requests_per_minute: number;
    tokens_per_minute: number;
  };
  retry: {
    max_attempts: number;
    initial_delay_ms: number;
    max_delay_ms: number;
    backoff_factor: number;
  };
}

// Task-specific model recommendations
export interface TaskConfig {
  default: ProviderModel;
  alternatives: ProviderModel[];
  local_option: ProviderModel | null;
  parameters: ModelParameters;
}

// Model parameters for AI requests
export interface ModelParameters {
  temperature: number;
  max_tokens: number;
  top_p: number;
  frequency_penalty?: number;
  presence_penalty?: number;
  stop_sequences?: string[];
  timeout_ms?: number;
}

// Message for conversation
export interface Message {
  role: Role;
  content: string;
  name?: string;
  tool_calls?: ToolCall[];
  tool_call_id?: string;
}

// Tool call definition
export interface ToolCall {
  id: string;
  type: 'function';
  function: {
    name: string;
    arguments: string;
  };
}

// Tool definition
export interface Tool {
  type: 'function';
  function: {
    name: string;
    description: string;
    parameters: Record<string, any>;
    required?: string[];
  };
}

// Completion request options
export interface CompletionOptions {
  model: string;
  messages: Message[];
  tools?: Tool[];
  parameters?: Partial<ModelParameters>;
  stream?: boolean;
}

// Completion response
export interface CompletionResponse {
  id: string;
  model: string;
  created: number;
  content: string;
  finish_reason: 'stop' | 'length' | 'tool_calls' | 'content_filter' | 'error';
  usage: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
  tool_calls?: ToolCall[];
}

// Streaming completion chunk
export interface CompletionChunk {
  id: string;
  model: string;
  content?: string;
  tool_call?: Partial<ToolCall>;
  is_finished: boolean;
  finish_reason?: 'stop' | 'length' | 'tool_calls' | 'content_filter' | 'error';
}

// Client configuration
export interface ClientConfig {
  provider: Provider;
  model?: string;
  api_key?: string;
  base_url?: string;
  default_parameters?: Partial<ModelParameters>;
  timeout_ms?: number;
}

// Error types
export type ErrorType = 
  | 'authentication' 
  | 'rate_limit' 
  | 'server_error' 
  | 'client_error' 
  | 'timeout' 
  | 'invalid_request'
  | 'content_filter'
  | 'unknown';

// AI Error
export class AIError extends Error {
  constructor(
    message: string,
    public readonly type: ErrorType,
    public readonly status?: number,
    public readonly provider?: Provider,
    public readonly retryable: boolean = false
  ) {
    super(message);
    this.name = 'AIError';
  }
}

// Language for code-related operations
export type Language = 
  | 'typescript' 
  | 'javascript' 
  | 'python' 
  | 'go' 
  | 'rust' 
  | 'java' 
  | 'swift' 
  | 'kotlin'
  | 'ruby' 
  | 'php' 
  | 'c' 
  | 'cpp' 
  | 'csharp' 
  | 'bash' 
  | 'sql'
  | 'html' 
  | 'css' 
  | 'markdown' 
  | 'yaml' 
  | 'json';

// Task types for AI operations
export type TaskType = 
  | 'code_generation' 
  | 'code_review' 
  | 'documentation' 
  | 'commit_messages' 
  | 'api_design'
  | 'quick_assist' 
  | 'complex_reasoning';

// System configuration
export interface SystemConfig {
  version: string;
  default_provider: Provider;
  logging: {
    enabled: boolean;
    level: 'debug' | 'info' | 'warn' | 'error';
    path: string;
  };
  temp_directory: string;
  history_directory: string;
}

// Complete AI configuration
export interface AIConfig {
  system: SystemConfig;
  models: Record<Provider, Record<string, ModelConfig>>;
  providers: Record<Provider, ProviderConfig>;
  tasks: Record<TaskType, TaskConfig>;
  integrations: {
    git: {
      enable_commit_hook: boolean;
      hook_path: string;
      commit_message_format: 'conventional' | 'free' | 'custom';
      allow_ai_generation: boolean;
      allow_ai_suggestions: boolean;
      check_sensitive_info: boolean;
    };
    ide: {
      vscode: {
        extension_id: string;
        auto_suggest: boolean;
        inline_completion: boolean;
      };
      neovim: {
        enable_completion: boolean;
        keybindings: Record<string, string>;
      };
      cursor: {
        config_path: string;
        prompt_path: string;
      };
    };
    api: {
      openapi: {
        validator: string;
        linter_config: string;
        mock_server: string;
        generation_tool: string;
        default_output: string;
      };
      codegen: {
        api_client_format: string;
        python_client_format: string;
        enable_tanstack_query: boolean;
        generate_hooks: boolean;
      };
    };
  };
  defaults: {
    parameters: ModelParameters;
  };
  scripts: {
    bash_integration: boolean;
    zsh_integration: boolean;
    bash_source_path: string;
    shell_aliases: Record<string, string>;
  };
}