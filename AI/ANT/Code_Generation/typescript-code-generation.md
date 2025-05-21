# TypeScript Code Generation

## Task

Generate TypeScript code that accomplishes the following:

{{request}}

## Requirements

- Write idiomatic, modern TypeScript (ES2020+)
- Include proper TypeScript types and interfaces
- Follow TypeScript best practices
- Include appropriate error handling
- Add JSDoc comments for public functions and classes
- Follow consistent naming conventions
- Optimize for readability and maintainability

## TypeScript-Specific Guidelines

### Types and Interfaces

- Use explicit typing (avoid `any` type when possible)
- Prefer interfaces for object shapes and API contracts
- Use type aliases for unions, intersections, and complex types
- Use generics when creating reusable components
- Consider using utility types (Partial, Pick, Omit, etc.) where appropriate
- Use readonly properties when applicable

### Naming Conventions

- Use PascalCase for interfaces, types, classes, and enums
- Use camelCase for variables, functions, and methods
- Use ALL_CAPS for constants and static readonly properties
- Prefix interfaces for objects with 'I' only when necessary for clarity
- Prefix type parameters with 'T' (e.g., `<TItem>`)

### Functions and Methods

- Use arrow functions for callbacks and anonymous functions
- Use function declarations for named functions
- Specify return types explicitly
- Use parameter destructuring for objects
- Provide default parameters when applicable

### Error Handling

- Use typed error objects or custom error classes
- Implement proper try/catch/finally blocks
- Consider using Result/Either patterns for complex error cases
- Provide meaningful error messages

### Modern Features

- Use optional chaining (`?.`) and nullish coalescing (`??`)
- Use template literals for string interpolation
- Use object/array destructuring
- Use async/await for asynchronous code
- Use Map and Set collections when appropriate

### Code Organization

- Group related functions and types together
- Use namespaces or modules to organize code
- Separate interface declarations from implementations
- Export types and interfaces that will be used externally

## Output Format

Provide the TypeScript code with appropriate type definitions in a code block with the language tag. Include imports at the top, followed by type/interface definitions, then implementation.

```typescript
// Your implementation will replace this line
```