---
description: Implementation planning
---

# Implementation Planning

Generate a detailed implementation plan before coding.

## Arguments
$ARGUMENTS - Description of the task to plan

## Instructions

1. **Understand Requirements**
   - Parse the task description
   - Identify explicit and implicit requirements
   - Note constraints and dependencies

2. **Research Phase**
   - Read relevant existing code
   - Identify patterns to follow
   - Note integration points
   - DO NOT write code yet

3. **Generate Plan**
   ```markdown
   ## Task: [Brief description]

   ### Requirements
   - [ ] Requirement 1
   - [ ] Requirement 2

   ### Files to Modify
   | File | Action | Reason |
   |------|--------|--------|
   | path/to/file.ts | modify | Add X |

   ### Implementation Steps
   1. Step 1
   2. Step 2

   ### Test Strategy
   - Unit tests for: ...
   - Integration tests for: ...

   ### Risks & Mitigations
   - Risk: ...
     Mitigation: ...
   ```

4. **Request Approval**
   Present plan and wait for user confirmation before proceeding.
