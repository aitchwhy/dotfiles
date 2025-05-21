# AI Prompts Master Collection Structure

This document provides an overview of the organization and content of the AI Prompts Master Collection.

## Directory Structure

```
AI_Prompts_Master_Collection/
├── Core_Prompting/
│   ├── Base_Templates/
│   │   ├── code-generation-template.md
│   │   └── master-configuration.md
│   ├── Best_Practices/
│   │   ├── advanced-techniques.md
│   │   └── prompt-engineering-fundamentals.md
│   ├── System_Roles/
│   │   └── base-system-role.md
│   └── README.md
├── Provider_Specific/
│   ├── Claude/
│   │   ├── claude-code-repository-guidance.md
│   │   ├── claude_desktop_config.json
│   │   └── README.md
│   ├── OpenAI/
│   ├── Gemini/
│   ├── Cursor/
│   └── README.md
├── Use_Cases/
│   ├── Code_Generation/
│   │   ├── python-code-generation.md
│   │   └── typescript-code-generation.md
│   ├── Documentation/
│   ├── Research/
│   ├── Data_Analysis/
│   ├── Workflow_Automation/
│   └── README.md
├── Templates_Components/
│   ├── developer-profile.md
│   ├── task-templates.md
│   ├── workflow-integration.md
│   └── README.md
├── Tools_Integration/
│   └── README.md
├── Documentation_Reference/
│   ├── structure-overview.md
│   └── README.md
├── Archive/
│   ├── Duplicates/
│   ├── Low_Value/
│   ├── Merged_Originals/
│   └── README.md
└── README.md
```

## Key Components

### Core Prompting
Contains fundamental prompting techniques and templates that establish the foundation for effective AI interactions:

- **Base Templates**: Generic templates adaptable for various purposes
- **System Roles**: Definitions that shape AI behavior and capabilities
- **Best Practices**: Guidelines and principles for effective prompt engineering

### Provider Specific
Contains configurations and templates optimized for specific AI providers:

- **Claude**: Anthropic Claude-specific configurations and optimizations
- **OpenAI**: GPT-specific templates and best practices
- **Gemini**: Google Gemini-specific templates
- **Cursor**: Cursor IDE AI integration configurations

### Use Cases
Contains domain-specific prompt templates organized by purpose:

- **Code Generation**: Templates for generating different types of code
- **Documentation**: Prompts for creating technical documentation
- **Research**: Templates for research synthesis and analysis
- **Data Analysis**: Prompts for data exploration and interpretation
- **Workflow Automation**: Templates for automating development workflows

### Templates Components
Contains reusable prompt fragments and formatting templates:

- **Developer Profile**: Personal context and technical preferences
- **Task Templates**: Specific templates for different task types
- **Workflow Integration**: Guides for incorporating AI into development workflows

### Tools Integration
Contains resources for integrating AI with development tools and environments:

- CLI tools and configurations
- IDE integration settings
- Workflow automation scripts

### Documentation Reference
Contains guides, specifications, and best practices related to AI prompting:

- **Structure Overview**: Documentation of the collection's organization
- Various guides and reference materials

### Archive
Contains archived content that has been superseded:

- **Duplicates**: Files with content duplicated elsewhere
- **Low Value**: Files that provide minimal unique value
- **Merged Originals**: Original files that have been consolidated

## Usage Guide

To effectively use this collection:

1. Start with the appropriate base template from **Core_Prompting/Base_Templates/**
2. Add relevant context from **Templates_Components/developer-profile.md**
3. Select a task-specific template from **Use_Cases/** based on your needs
4. Consider provider-specific optimizations from **Provider_Specific/** if using a particular AI model
5. Integrate additional components as needed

Example workflow for generating TypeScript code:
1. Start with **Core_Prompting/Base_Templates/code-generation-template.md**
2. Add relevant sections from **Templates_Components/developer-profile.md** 
3. Incorporate specific guidelines from **Use_Cases/Code_Generation/typescript-code-generation.md**
4. If using Claude, add any necessary context from **Provider_Specific/Claude/** files