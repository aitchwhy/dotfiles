# Research Integration Framework

Incorporate new research findings into the system.

## Arguments
$ARGUMENTS - Topic or paper to research (optional)

## Instructions

### 1. Search for Relevant Research

If topic provided, search for:
- Recent arxiv papers (last 6 months)
- Official documentation updates
- Best practice guides
- Conference talks/proceedings

Focus areas:
- Agent self-evolution and improvement
- LLM calibration and confidence
- MCP specification updates
- TypeScript/Zod patterns
- Testing methodologies
- Observability practices

### 2. Evaluate Relevance

For each finding, assess:

```
┌─────────────────────────────────────────┐
│ RELEVANCE ASSESSMENT                    │
├─────────────────────────────────────────┤
│ Source:        [paper/docs/blog]        │
│ Date:          [publication date]       │
│ Credibility:   [high/medium/low]        │
│ Applicability: [direct/indirect/none]   │
│ Conflicts:     [list any conflicts]     │
└─────────────────────────────────────────┘
```

### 3. Propose Updates

For applicable findings:

```markdown
## Proposed Update

**Source**: [citation]
**Finding**: [key insight]
**Current State**: [what CLAUDE.md says now]
**Proposed Change**: [specific update]
**Scope**: [global|stack|project]
**Confidence**: [X%]

### Validation Required
- [ ] Tested in project A
- [ ] Tested in project B
- [ ] Tested in project C
- [ ] 6-agent review passed
- [ ] No contradictions found
```

### 4. Flag Contradictions

If finding contradicts existing patterns:

```
⚠️ CONTRADICTION DETECTED

Existing: [current pattern in CLAUDE.md]
Research: [new finding]
Resolution Options:
1. Update existing (if research is stronger)
2. Keep existing (if battle-tested)
3. Context-dependent (both valid in different scenarios)

Recommendation: [option number + rationale]
```

### 5. Integration Pipeline

```
Research Found
     │
     ▼
┌─────────────┐
│ Relevance   │──No──▶ Archive for reference
│ Check       │
└─────┬───────┘
      │ Yes
      ▼
┌─────────────┐
│ Conflict    │──Yes──▶ Resolution required
│ Check       │
└─────┬───────┘
      │ No
      ▼
┌─────────────┐
│ Scope       │
│ Assignment  │
└─────┬───────┘
      │
      ▼
┌─────────────┐
│ Validation  │──Fail──▶ Revise or reject
│ (3 projects)│
└─────┬───────┘
      │ Pass
      ▼
┌─────────────┐
│ 6-Agent     │──Concerns──▶ Address feedback
│ Review      │
└─────┬───────┘
      │ Approved
      ▼
┌─────────────┐
│ Merge to    │
│ CLAUDE.md   │
└─────────────┘
```

## Output Format

```
┌─────────────────────────────────────────────────────────────┐
│                    RESEARCH REPORT                          │
├─────────────────────────────────────────────────────────────┤
│ Topic: [searched topic]                                     │
│ Sources Reviewed: [N]                                       │
│ Relevant Findings: [N]                                      │
│ Proposed Updates: [N]                                       │
│ Contradictions: [N]                                         │
├─────────────────────────────────────────────────────────────┤
│ FINDINGS                                                    │
│                                                             │
│ 1. [Finding title]                                          │
│    Source: [citation]                                       │
│    Applicability: [direct/indirect]                         │
│    Proposed scope: [global/stack/project]                   │
│                                                             │
│ 2. [Finding title]                                          │
│    ...                                                      │
├─────────────────────────────────────────────────────────────┤
│ NEXT STEPS                                                  │
│ - [ ] Validate finding 1 in ember project                   │
│ - [ ] Request 6-agent review for finding 2                  │
│ - [ ] Resolve contradiction with existing pattern X         │
└─────────────────────────────────────────────────────────────┘
```

## Research Log

Log all research to `~/.claude/improvements.jsonl`:

```json
{
  "timestamp": "2025-12-04T19:00:00Z",
  "type": "research",
  "topic": "LLM calibration techniques",
  "sourcesReviewed": 5,
  "findingsCount": 2,
  "proposedUpdates": 1,
  "status": "pending_validation"
}
```

## Weekly Sync Schedule

Recommended topics for weekly rotation:
- Week 1: Agent architectures & self-evolution
- Week 2: TypeScript & frontend patterns
- Week 3: Testing & reliability
- Week 4: Observability & performance

## Notes

- Always cite sources with links
- Prefer peer-reviewed over blog posts
- Weight battle-tested over theoretical
- When in doubt, add to project scope first (not global)
- 48-hour validation period before global merge
