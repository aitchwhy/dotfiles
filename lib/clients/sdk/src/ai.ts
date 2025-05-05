import axios from 'axios';
import * as fs from 'fs';
import * as path from 'path';
import { AIProvider, AIRequest, AIResponse, AICapability } from './types';

/**
 * Execute an AI request against a specific provider
 * @param provider The AI provider to use
 * @param request The AI request details
 * @returns Promise resolving to AI response
 */
export async function executeAIRequest(provider: AIProvider, request: AIRequest): Promise<AIResponse> {
  validateRequest(provider, request);
  
  // Select the appropriate execution strategy based on provider type
  switch (provider.type) {
    case 'openai':
      return executeOpenAIRequest(provider, request);
    case 'claude':
      return executeClaudeRequest(provider, request);
    case 'local':
      return executeLocalRequest(provider, request);
    default:
      throw new Error(`Unsupported provider type: ${provider.type}`);
  }
}

/**
 * Validate that a request is compatible with the provider's capabilities
 * @param provider The AI provider
 * @param request The AI request to validate
 */
function validateRequest(provider: AIProvider, request: AIRequest): void {
  // Check if the requested capability is supported
  if (request.capability && !provider.capabilities.includes(request.capability)) {
    throw new Error(`Provider ${provider.name} does not support capability: ${request.capability}`);
  }
  
  // Validate context length
  if (request.messages && provider.maxContextLength) {
    const totalTokens = estimateTokenCount(request.messages);
    if (totalTokens > provider.maxContextLength) {
      throw new Error(`Request exceeds provider context length: ${totalTokens} > ${provider.maxContextLength}`);
    }
  }
  
  // Validate model availability if specified
  if (request.model && provider.models && !provider.models.includes(request.model)) {
    throw new Error(`Provider ${provider.name} does not support model: ${request.model}`);
  }
}

/**
 * Roughly estimate token count for a set of messages
 * @param messages Array of messages
 * @returns Estimated token count
 */
function estimateTokenCount(messages: any[]): number {
  // Simple estimation: ~4 chars per token on average
  const messageString = JSON.stringify(messages);
  return Math.ceil(messageString.length / 4);
}

/**
 * Execute a request against the OpenAI API
 * @param provider The OpenAI provider configuration
 * @param request The AI request details
 * @returns Promise resolving to AI response
 */
async function executeOpenAIRequest(provider: AIProvider, request: AIRequest): Promise<AIResponse> {
  try {
    const apiKey = provider.apiKey || process.env.OPENAI_API_KEY;
    
    if (!apiKey) {
      throw new Error('OpenAI API key not found');
    }
    
    const response = await axios.post(
      provider.endpoint || 'https://api.openai.com/v1/chat/completions',
      {
        model: request.model || provider.defaultModel || 'gpt-4o',
        messages: request.messages,
        temperature: request.temperature ?? 0.7,
        max_tokens: request.maxTokens,
        top_p: request.topP ?? 1,
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
        },
      }
    );
    
    return {
      provider: provider.name,
      model: response.data.model,
      content: response.data.choices[0].message.content,
      usage: response.data.usage,
      raw: response.data,
    };
  } catch (error: any) {
    throw new Error(`OpenAI API error: ${error.message}`);
  }
}

/**
 * Execute a request against the Claude API
 * @param provider The Claude provider configuration
 * @param request The AI request details
 * @returns Promise resolving to AI response
 */
async function executeClaudeRequest(provider: AIProvider, request: AIRequest): Promise<AIResponse> {
  try {
    const apiKey = provider.apiKey || process.env.ANTHROPIC_API_KEY;
    
    if (!apiKey) {
      throw new Error('Anthropic API key not found');
    }
    
    const response = await axios.post(
      provider.endpoint || 'https://api.anthropic.com/v1/messages',
      {
        model: request.model || provider.defaultModel || 'claude-3-opus-20240229',
        messages: request.messages,
        max_tokens: request.maxTokens || 4096,
        temperature: request.temperature ?? 0.7,
        top_p: request.topP ?? 1,
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
      }
    );
    
    return {
      provider: provider.name,
      model: response.data.model,
      content: response.data.content[0].text,
      usage: response.data.usage,
      raw: response.data,
    };
  } catch (error: any) {
    throw new Error(`Claude API error: ${error.message}`);
  }
}

/**
 * Execute a request against a local AI model
 * @param provider The local provider configuration
 * @param request The AI request details
 * @returns Promise resolving to AI response
 */
async function executeLocalRequest(provider: AIProvider, request: AIRequest): Promise<AIResponse> {
  try {
    // Implementation for local models like Ollama would go here
    throw new Error('Local model execution not implemented yet');
  } catch (error: any) {
    throw new Error(`Local model error: ${error.message}`);
  }
}