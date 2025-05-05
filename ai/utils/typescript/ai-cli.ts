/**
 * AI CLI TypeScript Library
 * Provides programmatic access to AI and API justfile commands
 */

import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

/**
 * Models configuration interface
 */
interface ModelConfig {
  id: string;
  name: string;
  released: string;
  context_window: number;
  recommended_for: string[];
  strengths: string[];
}

/**
 * API settings interface
 */
interface ApiSettings {
  endpoint: string;
  auth_type: string;
  env_var: string;
  rate_limit: number | null;
}

/**
 * Model provider interface
 */
interface ModelProvider {
  versions: ModelConfig[];
  api_settings: ApiSettings;
}

/**
 * Task recommendations interface
 */
interface TaskRecommendations {
  [key: string]: {
    first_choice: string;
    alternative: string;
    local_option: string | null;
  };
}

/**
 * Function calling capabilities interface
 */
interface FunctionCalling {
  [key: string]: number;
}

/**
 * Complete models configuration interface
 */
interface ModelsConfig {
  claude: ModelProvider;
  openai: ModelProvider;
  gemini: ModelProvider;
  opensource: ModelProvider;
  task_recommendations: TaskRecommendations;
  function_calling: FunctionCalling;
}

/**
 * Main AI CLI class
 */
export class AiCli {
  private just: string;
  private config: any;
  private models: ModelsConfig | null = null;

  /**
   * Creates a new AiCli instance
   * @param justPath - Path to the just executable
   * @param configDir - Path to the AI config directory
   */
  constructor(
    justPath: string = 'just',
    private configDir: string = path.join(process.env.HOME || '', '.config', 'ai')
  ) {
    this.just = justPath;
    this.config = this.loadConfig();
    this.loadModels();
  }

  /**
   * Load configuration from the config directory
   * @returns Configuration object
   */
  private loadConfig(): any {
    // Load basic config if available
    const configPath = path.join(this.configDir, 'config.json');
    if (fs.existsSync(configPath)) {
      try {
        return JSON.parse(fs.readFileSync(configPath, 'utf8'));
      } catch (error) {
        console.error('Error loading config:', error);
      }
    }
    return {};
  }

  /**
   * Load models configuration from llms.yaml
   */
  private loadModels() {
    const modelsPath = path.join(this.configDir, 'models', 'llms.yaml');
    if (fs.existsSync(modelsPath)) {
      try {
        // Using a simple YAML parser would be better, but for this example
        // we'll assume the yaml is parsed and available
        // In a real implementation, use js-yaml or similar
        console.log('Models config would be loaded from:', modelsPath);
        // this.models = parseYaml(fs.readFileSync(modelsPath, 'utf8'));
      } catch (error) {
        console.error('Error loading models:', error);
      }
    }
  }

  /**
   * Execute a just command and return the output
   * @param namespace - The just namespace
   * @param command - The command to execute
   * @param args - Command arguments
   * @returns Command output
   */
  private executeJust(namespace: string, command: string, args: string[] = []): string {
    try {
      const cmd = `${this.just} ${namespace}:${command} ${args.join(' ')}`;
      return execSync(cmd, { encoding: 'utf8' });
    } catch (error: any) {
      console.error(`Error executing command: ${error.message}`);
      return '';
    }
  }

  /**
   * Get recommended model for a specific task
   * @param task - The task type
   * @returns Model ID
   */
  public getRecommendedModel(task: string): string {
    if (this.models && this.models.task_recommendations[task]) {
      return this.models.task_recommendations[task].first_choice;
    }
    // Default to Claude 3.7 Sonnet
    return 'claude-3-7-sonnet-20250219';
  }

  /**
   * Generate code using AI
   * @param language - Programming language
   * @param prompt - The prompt for code generation
   * @returns Generated code
   */
  public generateCode(language: string, prompt: string): string {
    return this.executeJust('ai', 'code', [language, `"${prompt}"`]);
  }

  /**
   * Generate a commit message from git diff
   * @returns Generated commit message
   */
  public generateCommitMessage(): string {
    return this.executeJust('ai', 'commit-msg');
  }

  /**
   * Review a code file
   * @param filePath - Path to the file
   * @returns Code review
   */
  public reviewCode(filePath: string): string {
    return this.executeJust('ai', 'review', [filePath]);
  }

  /**
   * Explain a code file
   * @param filePath - Path to the file
   * @returns Code explanation
   */
  public explainCode(filePath: string): string {
    return this.executeJust('ai', 'explain', [filePath]);
  }

  /**
   * Generate documentation for a file
   * @param filePath - Path to the file
   * @returns Generated documentation
   */
  public generateDocstrings(filePath: string): string {
    return this.executeJust('ai', 'docstrings', [filePath]);
  }

  /**
   * Translate code from one language to another
   * @param fromFile - Source file
   * @param toLanguage - Target language
   * @returns Translated code
   */
  public translateCode(fromFile: string, toLanguage: string): string {
    return this.executeJust('ai', 'translate', [fromFile, toLanguage]);
  }

  /**
   * Generate tests for a file
   * @param filePath - Path to the file
   * @returns Generated tests
   */
  public generateTests(filePath: string): string {
    return this.executeJust('ai', 'test-gen', [filePath]);
  }

  /**
   * Get conversation history
   * @param limit - Number of conversations to retrieve
   * @returns Conversation history
   */
  public getHistory(limit: number = 5): string {
    return this.executeJust('claude', 'history', [limit.toString()]);
  }

  /**
   * Get conversation details
   * @param sessionId - The conversation session ID
   * @returns Conversation details
   */
  public getConversationDetails(sessionId: string): string {
    return this.executeJust('claude', 'conversation-details', [sessionId]);
  }

  /**
   * Export conversation to a file
   * @param sessionId - The conversation session ID
   * @returns Export result
   */
  public exportConversation(sessionId: string): string {
    return this.executeJust('claude', 'export-conversation', [sessionId]);
  }

  /**
   * Generate a TypeScript function
   * @param description - Function description
   * @returns Generated function
   */
  public generateTsFunction(description: string): string {
    return this.executeJust('ai', 'typescript:function', [`"${description}"`]);
  }

  /**
   * Generate TypeScript interfaces from JSON
   * @param filePath - Path to JSON file
   * @returns Generated interfaces
   */
  public generateTsInterfaces(filePath: string): string {
    return this.executeJust('ai', 'typescript:interfaces-from-json', [filePath]);
  }

  /**
   * Generate a React component
   * @param name - Component name
   * @param propsDescription - Props description
   * @returns Generated component
   */
  public generateReactComponent(name: string, propsDescription: string): string {
    return this.executeJust('ai', 'typescript:react-component', [name, `"${propsDescription}"`]);
  }

  /**
   * Generate a Python function
   * @param description - Function description
   * @returns Generated function
   */
  public generatePythonFunction(description: string): string {
    return this.executeJust('ai', 'python:function', [`"${description}"`]);
  }

  /**
   * Analyze a Python file
   * @param filePath - Path to Python file
   * @returns Analysis result
   */
  public analyzePythonFile(filePath: string): string {
    return this.executeJust('ai', 'python:analyze', [filePath]);
  }

  /**
   * Generate a FastAPI route
   * @param endpoint - Endpoint path
   * @param description - Route description
   * @returns Generated route
   */
  public generateFastApiRoute(endpoint: string, description: string): string {
    return this.executeJust('ai', 'python:fastapi-route', [endpoint, `"${description}"`]);
  }

  /**
   * Generate a shell script
   * @param description - Script description
   * @returns Generated script
   */
  public generateShellScript(description: string): string {
    return this.executeJust('ai', 'shell:script', [`"${description}"`]);
  }

  /**
   * Refactor a shell script
   * @param filePath - Path to shell script
   * @returns Refactored script
   */
  public refactorShellScript(filePath: string): string {
    return this.executeJust('ai', 'shell:refactor', [filePath]);
  }

  /**
   * Generate a Nix expression
   * @param description - Expression description
   * @returns Generated expression
   */
  public generateNixExpression(description: string): string {
    return this.executeJust('ai', 'nix:expression', [`"${description}"`]);
  }

  /**
   * Create a Nix development shell for a project
   * @param filePath - Path to project
   * @returns Generated shell
   */
  public createNixDevShell(filePath: string): string {
    return this.executeJust('ai', 'nix:devshell', [filePath]);
  }

  /**
   * API namespace methods
   */
  public api = {
    /**
     * Validate an OpenAPI specification
     * @param specFile - Path to specification file
     * @returns Validation result
     */
    validateSpec: (specFile: string): string => {
      return this.executeJust('api', 'optic:validate', [specFile]);
    },

    /**
     * Start an API proxy server
     * @param specFile - Path to specification file
     * @param port - Server port
     * @returns Proxy result
     */
    startProxy: (specFile: string, port: number = 8081): string => {
      return this.executeJust('api', 'optic:proxy', [specFile, port.toString()]);
    },

    /**
     * Compare two OpenAPI specifications
     * @param specBefore - Path to before specification
     * @param specAfter - Path to after specification
     * @returns Diff result
     */
    diffSpecs: (specBefore: string, specAfter: string): string => {
      return this.executeJust('api', 'optic:diff', [specBefore, specAfter]);
    },

    /**
     * Lint an OpenAPI specification
     * @param specFile - Path to specification file
     * @param ruleset - Ruleset to use
     * @returns Lint result
     */
    lintSpec: (specFile: string, ruleset: string = 'spectral:oas'): string => {
      return this.executeJust('api', 'spectral:lint', [specFile, ruleset]);
    },

    /**
     * Generate a Spectral ruleset
     * @param outputPath - Output path
     * @returns Generation result
     */
    generateRuleset: (outputPath: string): string => {
      return this.executeJust('api', 'spectral:generate-ruleset', [outputPath]);
    },

    /**
     * Make an HTTP GET request
     * @param url - Request URL
     * @param args - Additional arguments
     * @returns Request result
     */
    get: (url: string, ...args: string[]): string => {
      return this.executeJust('api', 'httpie:get', [url, ...args]);
    },

    /**
     * Make an HTTP POST request
     * @param url - Request URL
     * @param args - Additional arguments
     * @returns Request result
     */
    post: (url: string, ...args: string[]): string => {
      return this.executeJust('api', 'httpie:post', [url, ...args]);
    },

    /**
     * Generate a TypeScript client from OpenAPI spec
     * @param specFile - Path to specification file
     * @param outputDir - Output directory
     * @returns Generation result
     */
    generateClient: (specFile: string, outputDir: string): string => {
      return this.executeJust('api', 'generate-client', [specFile, outputDir]);
    },

    /**
     * Generate a Python client from OpenAPI spec
     * @param specFile - Path to specification file
     * @param outputDir - Output directory
     * @returns Generation result
     */
    generatePythonClient: (specFile: string, outputDir: string): string => {
      return this.executeJust('api', 'generate-python-client', [specFile, outputDir]);
    },

    /**
     * Create a new OpenAPI specification
     * @param outputPath - Output path
     * @param title - API title
     * @param version - API version
     * @returns Creation result
     */
    createSpec: (outputPath: string, title: string = 'API', version: string = '1.0.0'): string => {
      return this.executeJust('api', 'create-spec', [outputPath, title, version]);
    },

    /**
     * Convert between YAML and JSON formats
     * @param specFile - Source specification file
     * @param outputFile - Output specification file
     * @returns Conversion result
     */
    convertSpec: (specFile: string, outputFile: string): string => {
      return this.executeJust('api', 'convert', [specFile, outputFile]);
    },

    /**
     * Start a mock server based on OpenAPI spec
     * @param specFile - Path to specification file
     * @param port - Server port
     * @returns Mock server result
     */
    startMock: (specFile: string, port: number = 8080): string => {
      return this.executeJust('api', 'mock', [specFile, port.toString()]);
    },
  };
}

// Example usage
// const ai = new AiCli();
// console.log(ai.generateCode('typescript', 'Create a function to sort an array'));