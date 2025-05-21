# Python Code Generation

## Task

Generate Python code that accomplishes the following:

{{request}}

## Requirements

- Write clean, idiomatic Python code (Python 3.8+)
- Follow PEP 8 style guidelines
- Include type hints (PEP 484)
- Add docstrings in Google or NumPy format
- Handle errors and edge cases appropriately
- Write testable and maintainable code
- Optimize for readability and clarity

## Python-Specific Guidelines

### Type Annotations

- Add type hints for function parameters and return values
- Use typing module's container types (List, Dict, Set, etc.)
- Consider using TypedDict for dictionaries with specific formats
- Use Optional[] for parameters that could be None
- Use Union[] for parameters with multiple possible types
- Use Protocol for structural typing when needed

### Functions and Classes

- Follow single responsibility principle
- Use descriptive function and variable names
- Make effective use of default parameters
- Use dataclasses for data containers when appropriate
- Implement proper magic methods in classes when needed
- Include type hints in class attributes and methods

### Documentation

- Include docstrings for all public modules, classes, and functions
- Use Google-style docstrings with Parameters, Returns, Raises sections
- Add examples for complex functions
- Note any assumptions or limitations

### Error Handling

- Use specific exception types rather than generic Exception
- Create custom exceptions for domain-specific errors
- Use context managers (with statements) for resource handling
- Implement proper try/except/finally blocks
- Add informative error messages

### Python Idioms

- Use list/dict/set comprehensions where appropriate
- Use generator expressions for large data processing
- Use tuple unpacking for multiple returns
- Use the walrus operator (:=) for assignment expressions (Python 3.8+)
- Use f-strings for string formatting
- Use pathlib for file path operations
- Use context managers for resource management

## Output Format

Provide the Python code with type hints and docstrings in a code block with the language tag. Include imports at the top, followed by class/function definitions, then implementation.

```python
# Your implementation will replace this line
```