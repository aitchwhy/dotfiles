# Code Review Base Template

## Task

Perform a comprehensive code review of the following {{language}} code:

```{{language}}
{{code}}
```

## Requirements

Conduct a thorough analysis that covers:

1. **Code Quality**
   - Evaluate readability and maintainability
   - Identify any code smells or anti-patterns
   - Check adherence to {{language}} best practices
   - Assess organization and structure

2. **Functionality**
   - Identify any bugs or logical errors
   - Check for edge cases that may not be handled
   - Verify that the code accomplishes its apparent purpose
   - Identify any potential performance issues

3. **Security**
   - Identify potential security vulnerabilities
   - Flag any unsafe operations or practices
   - Check for proper input validation and sanitization
   - Look for potential information leakage

4. **Improvements**
   - Suggest specific refactoring opportunities
   - Recommend alternative approaches where appropriate
   - Highlight areas that could benefit from better documentation
   - Suggest optimizations for performance or resource usage

## Review Format

Structure your review with the following sections:

1. **Summary**: A brief overview of the code and its purpose (based on your analysis).

2. **Strengths**: Highlight 2-3 positive aspects of the code.

3. **Issues**: List concrete issues categorized by severity:
   - Critical: Bugs, security issues, or problems that could cause system failure
   - Major: Significant architectural problems, performance issues, or maintainability concerns
   - Minor: Style issues, documentation gaps, or minor code smells

4. **Recommendations**: Provide specific, actionable suggestions for improvement, including code examples where appropriate.

5. **Questions**: Note any areas where clarification from the author would be helpful.

## Guidelines

- Be thorough but constructive in your feedback
- Provide specific line references when discussing issues
- Include sample code for suggested improvements
- Focus on objective issues rather than stylistic preferences (unless they violate established conventions)
- Acknowledge uncertainty when making assumptions about intent
- Consider both immediate fixes and longer-term improvements