# Advanced Prompting Techniques

This document outlines sophisticated AI prompting methods to achieve superior results for complex tasks. These techniques can be combined with task-specific templates for maximum effectiveness.

## Chain of Thought Prompting

### Description
Guide the AI through explicit reasoning steps before reaching a conclusion. This produces more accurate results for complex reasoning tasks.

### Implementation
```markdown
# Chain of Thought Request

I need you to solve this problem step-by-step:

[Problem description]

Please:
1. First, identify the key elements of this problem
2. Break down the approach into clear logical steps
3. Execute each step, showing your work
4. Evaluate the result for correctness
5. Summarize the final answer

Format each step clearly and explain your reasoning at each stage.
```

### When to Use
- Complex logical problems
- Multi-step calculations
- Debugging scenarios
- Complex decision-making with multiple factors

## Recursive Refinement

### Description
Use a staged approach where the AI first generates a draft, then iteratively improves it through self-critique and revision.

### Implementation
```markdown
# Recursive Refinement Request

I need a [type of content] about [subject]. Please approach this in three stages:

## Stage 1: Initial Draft
Create a first version that covers the core elements.

## Stage 2: Self-Critique
Review your draft and identify:
- Areas that need more detail or clarity
- Potential inaccuracies or omissions
- Structural improvements
- Stronger examples or evidence

## Stage 3: Refined Version
Create an improved version that addresses all the issues identified in your critique.

Present both the critique and the final refined version.
```

### When to Use
- Complex writing tasks
- System designs that require optimization
- Code that needs to balance multiple objectives
- Analyses where accuracy is critical

## Persona-Based Prompting

### Description
Direct the AI to adopt specific expert perspectives to leverage specialized knowledge and approaches.

### Implementation
```markdown
# Expert Perspective Request

I need analysis on [topic] from multiple expert perspectives.

Please approach this sequentially as the following experts:

1. As a senior systems architect with 15+ years of experience:
   [Specific questions/aspects to address]

2. As a security specialist focused on zero-trust implementations:
   [Specific questions/aspects to address]

3. As a DevOps engineer who prioritizes maintainability and observability:
   [Specific questions/aspects to address]

4. As a synthesis expert, integrate the perspectives above into final recommendations.

For each perspective, note key insights, blind spots, and specific recommendations.
```

### When to Use
- Getting well-rounded analysis of complex problems
- Identifying potential issues from different viewpoints
- Challenging initial assumptions
- Complex design decisions with multiple stakeholders

## Template Decomposition

### Description
Break complex outputs into parameterized templates with clear placeholders for the AI to fill in.

### Implementation
```markdown
# Template Decomposition Request

I need a [document type] with the following structure. For each section, I've provided guidance on what to include:

# [TITLE: Create a concise, descriptive title]

## Executive Summary
[EXEC_SUMMARY: Provide a 3-5 sentence overview that captures the key points]

## Problem Statement
[PROBLEM: Describe the current situation, challenges, and why this needs to be addressed]

## Proposed Approach
[APPROACH: Detail the recommended solution with justification]

## Implementation Steps
[STEPS: List 5-7 concrete actions in chronological order with owners and timeline]

## Success Metrics
[METRICS: Define 3-5 measurable indicators of success]

Please complete each section according to the instructions in brackets, then remove the bracketed instructions from the final output.
```

### When to Use
- Standardized document creation
- Complex outputs with consistent structure
- When you need to ensure all components are included
- Content that follows established patterns or protocols

## Comparative Analysis Framework

### Description
Structure a detailed comparison across multiple dimensions with explicit evaluation criteria.

### Implementation
```markdown
# Comparative Analysis Request

Please evaluate these options against the specified criteria:

## Options to Evaluate
- [Option 1]
- [Option 2]
- [Option 3]

## Evaluation Criteria
For each criterion, rate options on a scale of 1-10 and provide specific justification:

1. [Criterion 1] (Weight: X%)
   - What constitutes a score of 1-3, 4-7, and 8-10
   - Specific aspects to consider

2. [Criterion 2] (Weight: Y%)
   - What constitutes a score of 1-3, 4-7, and 8-10
   - Specific aspects to consider

3. [Criterion 3] (Weight: Z%)
   - What constitutes a score of 1-3, 4-7, and 8-10
   - Specific aspects to consider

## Output Format
- Provide individual criterion scores with justification
- Calculate weighted total scores
- Rank options from best to worst
- Explain key differentiators
- Include sensitivity analysis (how would rankings change if weights shifted)
```

### When to Use
- Technology selection decisions
- Architecture or design alternatives
- Investment or prioritization decisions
- Strategic option evaluation

## Decision Tree Construction

### Description
Map out a complex decision process with conditional branches based on different scenarios.

### Implementation
```markdown
# Decision Tree Request

Help me build a decision tree for [scenario/problem].

## Initial Conditions
- [Describe starting state and key variables]

## Primary Decision Points
For each primary decision point:
1. Identify the key question at this stage
2. List all possible choices (2-4 options)
3. For each choice:
   - Describe immediate consequences
   - Identify subsequent decision points
   - Note critical dependencies or assumptions

## Evaluation Metrics
At each terminal node (end state), evaluate:
- [Metric 1]
- [Metric 2]
- [Metric 3]

## Visual Representation
Create a text-based diagram of the decision tree showing:
- Decision nodes (questions)
- Option branches
- Terminal nodes (outcomes)
- Critical path highlighting
```

### When to Use
- Complex decision processes with multiple variables
- Scenario planning
- Risk assessment
- Troubleshooting guides

## System Interaction Modeling

### Description
Model complex interactions between system components, focusing on interfaces, dependencies, and data flows.

### Implementation
```markdown
# System Interaction Model Request

Help me understand interactions between components in [system name].

## System Components
- [Component 1]: [Brief description of responsibility]
- [Component 2]: [Brief description of responsibility]
- [Component 3]: [Brief description of responsibility]

## For Each Interface Between Components
1. Identify direction of dependency
2. Describe data/control flow
3. Document interface contract (API, events, etc.)
4. Note synchronicity (sync/async)
5. Identify potential failure modes
6. Document retry/resilience patterns

## Sequence Diagrams
Create text-based sequence diagrams for these key flows:
- [Flow 1]
- [Flow 2]
- [Flow 3]

## Critical Path Analysis
Identify and analyze:
- Performance bottlenecks
- Single points of failure
- Scalability constraints
- Data consistency challenges
```

### When to Use
- Complex distributed system design
- API design and documentation
- Troubleshooting integration issues
- Performance optimization

## Layered Explanation

### Description
Structure explanations across multiple levels of abstraction, from conceptual to implementation details.

### Implementation
```markdown
# Layered Explanation Request

Please explain [topic/concept] using a layered approach:

## Layer 1: Conceptual Overview (ELI5)
Explain the core concept as you would to a non-technical person, using analogies and simplified models.

## Layer 2: Functional Understanding
Explain how this works from a functional perspective - what it does, major components, and how they interact.

## Layer 3: Technical Implementation
Provide implementation details including:
- Specific technologies/methods used
- Important algorithms or patterns
- Code examples where appropriate
- Performance considerations

## Layer 4: Advanced Considerations
Discuss:
- Edge cases and how they're handled
- Optimization techniques
- Alternative approaches
- Common misconceptions
```

### When to Use
- Explaining complex technical concepts
- Educational content
- Technical documentation for diverse audiences
- Knowledge transfer

## Edge Case Exploration

### Description
Systematically identify and address uncommon but important scenarios that might be overlooked.

### Implementation
```markdown
# Edge Case Exploration Request

For this [system/code/process], help me identify and address edge cases:

## System Description
[Brief description of the system/code/process]

## Normal Operation
[Description of typical usage patterns and expected behavior]

## Edge Case Categories
For each category, identify specific edge cases and how to handle them:

1. Input Boundaries
   - Minimum/maximum values
   - Empty/null inputs
   - Malformed inputs
   - Extremely large inputs

2. Resource Constraints
   - Memory limitations
   - CPU constraints
   - Network issues
   - Timeouts

3. Concurrent Operations
   - Race conditions
   - Deadlocks
   - Contention scenarios

4. Integration Points
   - External system failures
   - API contract changes
   - Versioning issues

5. State Transitions
   - Interrupted operations
   - Invalid state sequences
   - Recovery scenarios

## For Each Edge Case
1. Describe the scenario
2. Explain potential impact
3. Recommend detection method
4. Provide handling strategy
5. Suggest testing approach
```

### When to Use
- Critical system design
- Security-sensitive applications
- High-reliability requirements
- Complex state management scenarios
