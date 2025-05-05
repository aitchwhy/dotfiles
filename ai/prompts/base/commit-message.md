# Commit Message Generation Template

## Task

Generate a commit message for the following changes that follows the Conventional Commits specification.

## Staged Changes

```
{{diff}}
```

## Current Status

```
{{status}}
```

## Requirements

1. **Format**: Follow the Conventional Commits specification:
   ```
   <type>(<scope>): <description>
   
   [optional body]
   
   [optional footer(s)]
   ```

2. **Types**: Use one of the following types:
   - `feat`: A new feature
   - `fix`: A bug fix
   - `docs`: Documentation only changes
   - `style`: Changes that do not affect the meaning of the code (white-space, formatting, etc)
   - `refactor`: A code change that neither fixes a bug nor adds a feature
   - `perf`: A code change that improves performance
   - `test`: Adding missing tests or correcting existing tests
   - `build`: Changes that affect the build system or external dependencies
   - `ci`: Changes to CI configuration files and scripts
   - `chore`: Other changes that don't modify src or test files

3. **Scope**: (Optional) Specify the component or area of the codebase affected by the change.

4. **Description**:
   - Use the imperative, present tense: "add" not "added" or "adds"
   - Don't capitalize the first letter
   - No period (.) at the end
   - Be concise but descriptive (50 characters or less)

5. **Breaking Changes**: If the commit includes a breaking change, add a `!` after the type/scope and include a "BREAKING CHANGE:" section in the footer.

## Guidelines

- Focus on **why** a change was made, not just what was changed
- Group related changes into a single commit with a comprehensive message
- Be specific about what was changed and the impact
- Use consistent terminology with the codebase
- Include ticket/issue numbers if applicable

## Output Format

Your response should include ONLY the commit message itself, with no additional explanation or commentary.