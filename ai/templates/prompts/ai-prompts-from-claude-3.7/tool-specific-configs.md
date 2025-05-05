# AI Tool-Specific Configurations

This document provides optimized configurations for specific AI tools and models to maximize their unique capabilities and strengths.

## Claude (Anthropic)

### Claude 3.7 Sonnet with Extended Thinking

#### Optimal Use Cases
- Complex reasoning tasks
- Detailed technical analysis
- Nuanced explanations balancing depth and clarity
- Code review and improvement
- Technical writing with precise language

#### Configuration Optimizations
```markdown
# Claude 3.7 Sonnet Configuration

I'd like you to engage extended thinking mode and act as [specific role].

When analyzing this problem:
1. Think step-by-step through the reasoning process
2. Consider multiple approaches before selecting the optimal solution
3. Explicitly note assumptions and their implications
4. Evaluate tradeoffs quantitatively where possible

Please structure your response according to:
[Insert relevant response format preferences]

For this specific task, I need:
[Insert task-specific template]
```

#### Special Features to Leverage
- Enable extended thinking mode for complex reasoning
- Request explicit reasoning paths for verification
- Use for tasks requiring careful nuance and precision
- Excellent for generating well-structured, hierarchical content

### Claude 3 Opus

#### Optimal Use Cases
- System design and architecture
- Comprehensive technical evaluations
- Complex document generation
- In-depth research synthesis
- Detailed code explanations

#### Configuration Optimizations
```markdown
# Claude 3 Opus Configuration

I'd like you to act as [specific role] with extensive expertise in [domain].

For this complex task, please:
1. First map out the entire solution space
2. Identify key decision points and dependencies
3. Develop a comprehensive approach
4. Elaborate on implementation details

Please structure your response with:
[Insert relevant response format preferences]

For this specific task, I need:
[Insert task-specific template]
```

#### Special Features to Leverage
- Superior context handling for complex, multi-part problems
- Capability to generate comprehensive technical documents
- Handles nuanced, complex instructions effectively
- Excellent for multi-stage reasoning tasks

## OpenAI Models

### GPT-4o

#### Optimal Use Cases
- Interactive problem-solving
- Multi-modal inputs (text + images)
- Creative technical solutions
- Real-time web research integration
- Code generation with clear explanations

#### Configuration Optimizations
```markdown
# GPT-4o Configuration

You are an expert [specific role] assisting with [task type].

Consider this problem holistically:
1. Analyze the complete context, including any provided images or references
2. Formulate a structured approach
3. Generate concrete implementation details
4. Explain your reasoning transparently

Please follow this response structure:
[Insert relevant response format preferences]

For this specific task, I need:
[Insert task-specific template]
```

#### Special Features to Leverage
- Ability to process and reference images in reasoning
- Browsing capabilities for real-time research
- Strong code generation capabilities with context awareness
- Good at creative solutions to technical problems

### GPT-4o with Advanced Data Analysis

#### Optimal Use Cases
- Statistical analysis and data exploration
- Code execution and verification
- Data visualization suggestions
- Iterative problem-solving with code
- Mathematical proofs and calculations

#### Configuration Optimizations
```markdown
# GPT-4o with Advanced Data Analysis Configuration

You are an expert data scientist and programmer helping with [specific task].

For this analysis:
1. Explore the data to understand its structure and characteristics
2. Suggest appropriate analytical approaches
3. Implement solutions using executable code
4. Validate results and check for errors
5. Visualize key findings effectively

I need the response to include:
[Insert relevant response format preferences]

For this specific task, I need:
[Insert task-specific template]
```

#### Special Features to Leverage
- Code execution capabilities for instant verification
- Iterative data exploration and analysis
- Creation of visualizations from data
- Ability to process and analyze uploaded files
- Mathematical computation capabilities

## DeepSeek Models

### DeepSeek Coder

#### Optimal Use Cases
- Complex software engineering tasks
- Programming language-specific optimizations
- Implementation of algorithms and data structures
- Code optimization and refactoring
- Technical software documentation

#### Configuration Optimizations
```markdown
# DeepSeek Coder Configuration

You are an expert software engineer specializing in [language/framework].

For this coding task:
1. Analyze requirements with attention to edge cases
2. Design a solution prioritizing [efficiency/readability/maintainability]
3. Implement with idiomatic patterns and best practices
4. Include comprehensive documentation and usage examples
5. Highlight optimization opportunities

Structure your response as follows:
[Insert relevant response format preferences]

For this specific task, I need:
[Insert task-specific template]
```

#### Special Features to Leverage
- Exceptional code generation quality
- Strong understanding of software engineering principles
- Ability to work within existing codebases
- Effective at complex algorithm implementation
- Language-specific optimization knowledge

## Multi-Tool Workflows

### Research → Analysis → Implementation

This workflow combines multiple AI tools for comprehensive solutions.

#### Process Flow
1. **Research Phase** (GPT-4o with browsing)
   - Gather relevant information
   - Identify state-of-the-art approaches
   - Collect reference examples

2. **Analysis Phase** (Claude 3.7 Sonnet with Extended Thinking)
   - Evaluate approaches from research
   - Perform detailed tradeoff analysis
   - Develop conceptual design
   
3. **Implementation Phase** (DeepSeek Coder)
   - Convert design into concrete implementation
   - Optimize for target environment
   - Develop tests and documentation

#### Configuration Example
```markdown
# Multi-Tool Workflow: Research Phase

You are a research specialist gathering information on [topic].

Please find the most relevant and current information about:
- Core concepts and principles
- Leading approaches and methodologies
- Benchmark results and comparisons
- Implementation considerations

Format findings as a structured research brief with sections for each area and citations.

# Multi-Tool Workflow: Analysis Phase (For Claude)

Using the research provided, perform a comprehensive analysis:

1. Evaluate each approach against these criteria:
   - [List criteria with weights]
2. Identify key tradeoffs and dependencies
3. Recommend an optimal approach with justification
4. Outline a conceptual design

# Multi-Tool Workflow: Implementation Phase (For DeepSeek)

Based on the provided conceptual design, implement a solution that:
1. Follows the specified approach
2. Optimizes for [specific requirements]
3. Includes error handling and edge cases
4. Provides documentation and usage examples
```

### Design → Feedback → Refinement

This iterative workflow improves quality through multiple models.

#### Process Flow
1. **Initial Design** (GPT-4o or Claude Opus)
   - Generate comprehensive first draft
   - Include all required components
   - Document design decisions

2. **Critical Feedback** (Claude with Extended Thinking)
   - Analyze for weaknesses and gaps
   - Identify optimization opportunities
   - Suggest specific improvements
   
3. **Refinement** (Original or specialized model)
   - Incorporate feedback
   - Optimize critical components
   - Finalize the solution

#### Configuration Example
```markdown
# Initial Design Phase

Create a comprehensive design for [system/document/code].

Requirements:
- [List key requirements]
- [List constraints]
- [List quality attributes]

Provide a complete initial design including:
- [List expected deliverables]

# Feedback Phase (For Claude)

Review the provided design critically:

1. Evaluate against these criteria:
   - [List evaluation criteria]
2. Identify potential weaknesses, including:
   - Performance bottlenecks
   - Scalability issues
   - Security concerns
   - Maintenance challenges
3. Suggest specific improvements for each issue
4. Prioritize recommendations by impact

# Refinement Phase

Based on the feedback provided, refine the initial design:

1. Address each identified issue with specific changes
2. Optimize the critical components 
3. Justify any feedback points not incorporated
4. Provide a complete, refined version
```

## Custom Configuration Templating

### Configuration Template Structure

Create your own tool-specific configurations using this template:

```markdown
# [Tool Name] Configuration for [Task Type]

## Context Setting
[Establish role, expertise level, and general approach]

## Task Instructions
[Specific task details and requirements]

## Processing Guidelines
[How the AI should approach the problem]
- Step 1: [Specific instruction]
- Step 2: [Specific instruction]
- etc.

## Output Format
[Response structure and formatting requirements]

## Additional Parameters
[Any special modes or settings to enable]
```

### Calibration Process

To optimize configurations for specific models:

1. **Baseline Testing**
   - Test the same prompt across different models
   - Note differences in output quality and approach
   - Identify relative strengths and weaknesses

2. **Parameter Tuning**
   - Adjust instructions based on model strengths
   - Modify level of detail in task breakdown
   - Calibrate output format specificity

3. **Iteration**
   - Refine based on output quality
   - Create model-specific instruction sets
   - Document effective patterns
