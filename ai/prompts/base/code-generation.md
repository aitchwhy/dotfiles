# Code Generation Base Template

## Task

Generate {{language}} code that accomplishes the following:

{{request}}

## Requirements

- The code should be complete, functional, and ready to use.
- Follow industry standard best practices for {{language}}.
- Include appropriate error handling for edge cases.
- Use clear, descriptive variable and function names.
- Add comments to explain complex logic or non-obvious design decisions.
- Optimize for readability and maintainability.

## Specific Guidelines

{{#if language == "typescript" || language == "javascript"}}
- Use modern ES syntax (ES6+)
- Prefer const/let over var
- Use explicit typing in TypeScript
- Follow common conventions like camelCase for variables
- Include JSDoc comments for public functions
{{/if}}

{{#if language == "python"}}
- Follow PEP 8 style guidelines
- Use type hints (for Python 3.6+)
- Include docstrings in Google or NumPy format
- Use list/dict comprehensions where appropriate
- Handle exceptions with specific error types
{{/if}}

{{#if language == "go"}}
- Follow Go conventions (gofmt-compatible)
- Use idiomatic error handling (return errors, don't panic)
- Provide clear doc comments for exported functions
- Use meaningful variable names over single-letter names
- Organize code in logical packages
{{/if}}

{{#if language == "rust"}}
- Use Result and Option types for error handling
- Include appropriate lifetime annotations
- Add doc comments with examples for public functions
- Follow Rust naming conventions (snake_case)
- Use pattern matching where appropriate
{{/if}}

{{#if language == "java" || language == "kotlin"}}
- Follow standard language conventions
- Include exception handling with specific types
- Use appropriate access modifiers
- Add JavaDoc comments for public methods
- Use modern language features where appropriate
{{/if}}

## Output Format

Provide only the complete code implementation without unnecessary explanation. Format it in a code block with the appropriate language tag. If you need to explain any aspects of the implementation, do so in comments within the code.

```{{language}}
// Your implementation will replace this line
```