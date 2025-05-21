# Template Components

This directory contains reusable components that can be incorporated into various AI prompts and instructions. These components are designed to be modular, allowing you to mix and match them based on your specific needs.

## What's Included

### User Profiles
- **[developer-profile.md](./developer-profile.md)** - Detailed developer profile for personalizing AI responses to match technical preferences and workflow patterns

### Response Format Templates
- Coming soon: Response formatting guidelines for different output types (code, analysis, documentation)

### System Role Components
- Coming soon: Modular components for building custom system roles

## How to Use These Components

These components can be included in your prompts in several ways:

1. **Direct Inclusion** - Copy and paste relevant sections into your prompt
2. **Reference by Link** - If your AI assistant can access files, reference these components by path
3. **Mixed Approach** - Include the most relevant parts directly, reference others by path

Example:

```
I'd like you to help me design a new web service architecture. 
Please refer to my developer profile at /Templates_Components/developer-profile.md
to understand my preferences and technical environment.

For this task, I need:
[your specific requirements]

Please format your response according to my communication preferences in the profile.
```

## Customization

These templates should be customized to match your specific needs:

1. For the developer profile, update sections to match your actual preferences
2. Add, remove, or modify sections based on what's relevant to your work
3. Consider creating domain-specific variants for different types of projects

## Best Practices

- Keep components modular so they can be mixed and matched
- Update components as your preferences and environment evolve
- Use consistent terminology across all components
- Include examples where appropriate to illustrate usage