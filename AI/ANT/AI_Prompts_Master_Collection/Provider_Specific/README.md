# Provider-Specific Resources

This directory contains configurations, prompts, and guidelines optimized for specific AI models and providers. Each subdirectory is organized by AI provider and contains model-specific templates, configurations, and best practices.

## Contents

### Provider Directories

- **[Claude/](./Claude/)** - Resources specific to Anthropic's Claude models
  - Claude Desktop configuration files
  - Claude-specific prompt templates and system messages
  - Best practices for Claude's capabilities

### Model Configuration Files

- **[llm-models-configuration.yaml](./llm-models-configuration.yaml)** - Comprehensive configuration of LLM models with capabilities, context windows, and recommended use cases
- **[tool-specific-configurations.md](./tool-specific-configurations.md)** - Detailed configuration templates for different AI models and tools

## How to Use These Resources

1. **Choose the Right Model**: Use the model configuration files to understand the strengths and capabilities of different models

2. **Leverage Provider-Specific Features**: Each provider has unique capabilities - find templates that make the most of these features:
   - Claude's extended thinking mode and XML tagging
   - GPT's function calling and tool usage
   - DeepSeek's specialized code capabilities

3. **Optimize Configurations**: Apply the optimized configurations in your prompts to get better results:
   ```
   # Example: Using Claude 3.7 Sonnet with Extended Thinking
   I'd like you to engage extended thinking mode and act as a systems architect.
   
   When analyzing this architecture problem:
   1. Think step-by-step through the design considerations
   2. Consider multiple approaches before selecting the optimal solution
   3. Explicitly note assumptions and their implications
   4. Evaluate tradeoffs quantitatively where possible
   ```

4. **Mix and Match**: Combine provider-specific components with general templates from other directories

## Best Practices

1. **Know Your Model**: Different models have different strengths - choose the right one for your task

2. **Optimize Configuration**: Use the provider-specific configuration templates to get the best results

3. **Leverage Special Features**: Take advantage of unique capabilities:
   - Claude's XML tags and reasoning capabilities
   - GPT's tool usage and multimodal features
   - DeepSeek's programming expertise

4. **Keep Updated**: These configurations should be updated as models evolve and new capabilities are added