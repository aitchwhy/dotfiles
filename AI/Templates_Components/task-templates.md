# Task-Specific Templates

These templates provide specialized prompting patterns for common task types. They are designed to be combined with your Developer Profile and Response Format preferences.

## Code Generation Template

```markdown
# Code Generation Request

## Task Description
[Brief description of the code you need]

## Requirements
- Language: [Programming language and version]
- Framework/Libraries: [Any specific libraries or frameworks]
- Performance needs: [Time/space complexity requirements]
- Edge cases to handle: [List specific edge cases]

## Expected Functionality
[Detailed description of what the code should do]

## Output Format
- Provide clean, efficient implementation with type annotations
- Include relevant error handling
- Add comments explaining complex logic or design decisions
- Demonstrate usage with example inputs/outputs
- Discuss any performance considerations or tradeoffs

## Additional Context
[Any other relevant information or constraints]
```

## Code Review Template

```markdown
# Code Review Request

## Code to Review
```[language]
[Paste code here]
```

## Review Focus
- [Specific aspects to focus on, e.g., "performance", "security", "readability"]
- [Any specific concerns or questions]

## Expected Output
- Identify potential issues (bugs, performance problems, security vulnerabilities)
- Suggest improvements with specific code examples
- Highlight good practices already present
- Analyze overall code structure and organization
- Provide a table scoring the code on key dimensions (1-10):
  - Correctness, Performance, Maintainability, Security, Readability

## Additional Context
[Relevant background information about the code purpose, environment, etc.]
```

## System Design Template

```markdown
# System Design Request

## Design Task
[Brief description of the system to be designed]

## Requirements
- Functionality: [Key functional requirements]
- Scale: [Expected scale/load characteristics]
- Constraints: [Budget, technology, or other constraints]
- Quality attributes: [Reliability, performance, security needs]

## Expected Deliverables
- High-level architecture diagram
- Component breakdown with responsibilities
- Data model and flow
- API design (if applicable)
- Technology stack recommendations with rationale
- Scalability considerations
- Potential failure modes and mitigations

## Output Format Preferences
- Start with executive summary of the approach
- Include visual architecture diagram
- Provide component tables with responsibilities and interfaces
- Include sequence diagrams for key flows
- List technology choices with explicit rationale

## Additional Context
[Any background information or existing systems to consider]
```

## Data Analysis Template

```markdown
# Data Analysis Request

## Analysis Goal
[What insight or outcome you're seeking]

## Data Description
- Source: [Where the data comes from]
- Format: [CSV, JSON, etc.]
- Size: [Approximate size or dimensions]
- Key fields: [Important columns or attributes]
- Special characteristics: [Missing values, outliers, etc.]

## Analysis Requirements
- Specific questions to answer: [List questions]
- Metrics to calculate: [List metrics]
- Visualizations needed: [Types of charts/plots]
- Statistical methods to apply: [If applicable]

## Output Format Preferences
- Present key findings first as executive summary
- Include properly labeled visualizations
- Provide tables summarizing statistical results
- Document methodology and assumptions
- Include recommendations based on findings

## Additional Context
[Any relevant background information or hypotheses]
```

## Technical Documentation Template

```markdown
# Technical Documentation Request

## Documentation Purpose
[What this documentation will be used for and by whom]

## Subject Matter
[The system, code, or process to document]

## Documentation Requirements
- Target audience: [Who will read this]
- Technical depth: [Beginner, intermediate, expert]
- Sections to include: [List required sections]
- Examples needed: [Specific examples to include]

## Format Preferences
- Include table of contents
- Use hierarchical structure with clear navigation
- Provide code examples for key operations
- Include diagrams for complex concepts
- Add troubleshooting section for common issues

## Additional Context
[Any background information or existing documentation to reference]
```

## Research Synthesis Template

```markdown
# Research Synthesis Request

## Research Topic
[The subject to research]

## Research Objectives
- Key questions to answer: [List specific questions]
- Scope boundaries: [What to include/exclude]
- Required depth: [How comprehensive should this be]

## Source Preferences
- Preferred authorities: [Any specific sources to prioritize]
- Recency requirements: [How recent should sources be]
- Source types: [Academic papers, industry reports, etc.]

## Output Format
- Begin with executive summary of key findings
- Structure information hierarchically by subtopic
- Include comparison tables for competing approaches/views
- Provide citations for all significant claims
- End with synthesis of implications and next steps

## Additional Context
[Your current knowledge level, specific applications of the research, etc.]
```

## Technical Comparison Template

```markdown
# Technical Comparison Request

## Items to Compare
[List the technologies, methods, or tools to compare]

## Comparison Criteria
[List the 5-7 most important factors for evaluation]

## Usage Context
[How and where the solution will be used]

## Constraints
[Any limitations that would affect the decision]

## Output Format
- Start with brief overview of each option
- Create weighted comparison table (criteria weighted by importance)
- Score each option 1-10 on each criterion with clear rationale
- Include pros/cons section for each option
- Provide final recommendation with justification
- Address potential objections to the recommendation

## Additional Context
[Your experience level with these options, specific requirements, etc.]
```

## Troubleshooting Template

```markdown
# Troubleshooting Request

## Problem Description
[Detailed description of the issue]

## Environment Details
- Hardware: [Relevant hardware specifications]
- Software: [OS, application versions, etc.]
- Configuration: [Relevant configuration details]
- Recent changes: [Any recent changes that might be relevant]

## Observed Behavior
[What's actually happening]

## Expected Behavior
[What should be happening]

## Troubleshooting Already Attempted
[Steps you've already taken to diagnose or fix]

## Output Format
- Analyze possible root causes systematically
- Provide diagnostic steps in order of likelihood
- Include specific commands or code to run for diagnosis
- Suggest solutions with step-by-step implementation
- Explain preventative measures for the future

## Additional Context
[Error logs, screenshots, or other relevant information]
```

## Project Planning Template

```markdown
# Project Planning Request

## Project Description
[Brief description of the project]

## Project Goals
- Primary objectives: [List main goals]
- Success criteria: [How success will be measured]
- Constraints: [Time, budget, resource constraints]

## Scope
- In scope: [Features/components definitely included]
- Out of scope: [What's explicitly excluded]
- Potential extensions: [Nice-to-haves if time permits]

## Output Format
- Provide project breakdown structure with major components
- Create task dependency diagram
- Include risk assessment table with mitigation strategies
- Suggest timeline with milestones
- Recommend resource allocation approach
- Include key decision points and criteria

## Additional Context
[Team composition, expertise areas, relevant experience, etc.]
```