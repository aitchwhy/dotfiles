# Orchestrator Architecture

## Overview

The Orchestrator architecture handles LLM provider interactions in the Chat module. It provides a unified interface for making requests to different LLM providers (Anthropic, Gemini) while maintaining type safety and promoting code reuse.

This document explains the design decisions, implementation details, and usage patterns for the orchestrator components.

## Key Components

### 1. Core Interface & Base Class

- **`Orchestrator` Interface**: Defines the contract that all provider implementations must follow
- **`BaseOrchestrator` Abstract Class**: Implements common functionality shared across providers
- **Provider-Specific Implementations**: `AnthropicOrchestrator` and `GeminiOrchestrator`

### 2. Factory Pattern

- **`OrchestratorFactory`**: Type for factory functions that instantiate orchestrators
- **`createOrchestrator`**: Factory implementation that selects the appropriate orchestrator based on provider

### 3. Type Safety

- **Provider-Specific Message Types**: `AnthropicMessage`, `GeminiMessage`
- **Zod Schemas**: `anthropicMessageSchema`, `geminiMessageSchema`

## Design Decisions

### Why an Interface + Abstract Class Pattern?

1. **Interface Definition**: The `Orchestrator` interface defines the clear contract that all providers must implement.
2. **Code Reuse**: The `BaseOrchestrator` abstract class implements common functionality to avoid duplication.
3. **Flexibility**: Each provider can extend the base class while adding provider-specific functionality.

```typescript
export interface Orchestrator {
  getModelName(): string;
  getClient(): Client;
  getSystemPrompt(): string;
  parseMessages<T>(messages: ChatMessage[]): T[];
  processChat(messages: ChatMessage[]): Promise<ChatMessage>;
}

export abstract class BaseOrchestrator implements Orchestrator {
  // Common implementation
  // Abstract methods must be implemented by subclasses
}
```

### Why a Factory Pattern?

1. **Dynamic Selection**: The factory can choose the appropriate orchestrator at runtime.
2. **Configuration Injection**: Common dependencies are injected once.
3. **Clean API**: Client code doesn't need to know implementation details.

```typescript
const orchestratorFactory = createOrchestrator(ctx);
const orchestrator = orchestratorFactory("anthropic"); // or "gemini"
```

### Why Type-Safe Messages with Zod?

1. **Runtime Validation**: Zod validates messages at runtime to catch potential issues.
2. **Type Inference**: TypeScript types are derived from Zod schemas.
3. **Consistency**: Ensures consistent message formats across the application.

```typescript
export const anthropicMessageSchema = z.object({
  role: z.enum(["user", "assistant", "system"]),
  content: z.string(),
}) satisfies SchemaLike<AnthropicMessage>;
```

## Implementation Details

### Message Parsing

Each provider implements a `parseMessages<T>` method that transforms our internal `ChatMessage` format into the provider-specific format:

- **Anthropic**: Uses string content fields
- **Gemini**: Uses arrays of parts with text fields

### Response Handling

The `createResponseMessage` helper method in the base class ensures consistent response formatting:

```typescript
protected createResponseMessage(text: string, modelName: string, finishReason?: string): ChatMessage {
  return {
    message_id: generateRandomId("msg"),
    timestamp: new Date().toISOString(),
    role: "assistant",
    content: [{ content_type: "text", text }],
    metadata: {
      model_name: modelName,
      finish_reason: finishReason,
    },
  };
}
```

### Error Handling & Logging

All error handling and logging follows a consistent pattern with standardized log messages.

## Provider Implementations

### Anthropic (`AnthropicOrchestrator`)

- Uses the Claude API for chat completions
- Supports tool usage (with the MnrTool for medical necessity reviews)
- Handles multi-step tool interactions

### Gemini (`GeminiOrchestrator`)

- Uses Google's Gemini API
- Simpler implementation without tool support (currently)

## Usage Examples

### Basic Usage

```typescript
// Create the factory with dependencies
const orchestratorFactory = createOrchestrator({
  logger,
  platform,
  clients: {
    anthropic: new Anthropic({ apiKey: "..." }),
    gemini: new GoogleGenAI({ apiKey: "..." }),
  },
});

// Get an orchestrator instance
const orchestrator = orchestratorFactory("anthropic");

// Process messages
const response = await orchestrator.processChat(messages);
```

## Testing

The architecture is designed for testability:

- **Unit Tests**: Test individual orchestrators and their components
- **Integration Tests**: Test complete provider implementations with mocked clients
- **Mocks**: Easy to create mock implementations for testing

## Future Extensibility

To add a new provider:

1. Create a new implementation class extending `BaseOrchestrator`
2. Define provider-specific message types and schemas
3. Add the provider type to the `Provider` union type
4. Update the factory function to handle the new provider

## Performance Considerations

- **Lazy Loading**: Provider implementations are loaded dynamically to avoid circular dependencies
- **Reused Clients**: Client instances are created once and reused
- **Structured Logging**: Performance metrics are logged consistently

## Conclusion

The orchestrator architecture provides a clean, type-safe approach to working with multiple LLM providers. It balances flexibility and standardization while making it easy to add new providers in the future.