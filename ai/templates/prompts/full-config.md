# AI Master Configuration

## System Overview

This document serves as the central configuration for all AI interactions. The complete system consists of:

1. **Master Configuration** (this file) - Core principles and system overview
2. **Developer Profile** - Your personal context and technical preferences
3. **Response Formatting** - Output structure and visual presentation guidelines
4. **Task Templates** - Purpose-specific prompt templates for different scenarios
5. **Advanced Techniques** - Advanced prompting methods for complex tasks
6. **Tool-Specific Configs** - Model-specific optimization guidelines

## Core Principles

1. **Maximum Context Efficiency**
   - Provide just enough context for optimal output
   - Use reference links to previous conversations when building on past work
   - Clearly separate instructions from content

2. **Structured Output by Default**
   - All responses should follow consistent structural patterns
   - Visual elements should be used where they enhance clarity
   - Complex information should be organized in digestible segments

3. **Progressive Enhancement**
   - Start with base prompts and add specific modules as needed
   - Build complex prompts by combining simpler templates
   - Refine outputs through iterative instructions

4. **Tool Specialization**
   - Use optimal AI model for each specific task
   - Leverage unique capabilities of different AI systems
   - Chain tools together for complex workflows

## Usage Methodology

1. **Task Analysis**
   - Determine primary goal of interaction
   - Identify relevant template modules
   - Consider required output formats

2. **Prompt Assembly**
   - Include developer profile (abbreviated if appropriate)
   - Add task-specific template
   - Specify response format requirements
   - Include any specialized techniques

3. **Response Management**
   - Evaluate output quality against requirements
   - Use follow-up prompts for refinement
   - Extract and store reusable components

4. **Continuous Improvement**
   - Note effective prompt patterns
   - Update templates based on successful interactions
   - Develop specialized templates for recurring tasks

## Integration Framework

These templates support integration with:

- **Claude Models** (Sonnet, Opus, Haiku)
- **OpenAI Models** (GPT-4, GPT-4o)
- **DeepSeek Models** (DeepSeek Coder)
- **Open Source Models** (via Ollama integration)
- **AI-powered Development Tools** (Cursor, GitHub Copilot)
- **Document Processing Tools** (for export/import)

## Template Evolution Strategy

For maximum effectiveness, treat these templates as living documents:

1. When an AI generates exceptionally good output, capture the prompt structure
2. When complex tasks are completed successfully, document the prompt chain
3. When outputs require significant refinement, note the refinement pattern
4. Regularly update templates with new capabilities as AI models evolve

## Quick Reference

| Task Type | Primary Template | Secondary Templates | Optimal AI Model |
|-----------|------------------|---------------------|------------------|
| Code Generation | `coding-primary.md` | `visual-code.md`, `advanced-reasoning.md` | DeepSeek Coder/Claude Sonnet |
| Code Review | `code-analysis.md` | `structured-feedback.md` | Claude Sonnet w/Extended Thinking |
| System Design | `system-design.md` | `visual-architecture.md` | Claude Opus/GPT-4 |
| Data Analysis | `data-analysis.md` | `visual-data.md` | Claude Sonnet |
| Technical Writing | `technical-docs.md` | `doc-formatting.md` | Claude Sonnet |
| Research | `research-synthesis.md` | `citation-format.md` | GPT-4o with browsing |
