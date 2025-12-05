# 6-Agent Expert Review

Trigger comprehensive multi-perspective review:

## Agent Perspectives

### 1. Architect
- System design quality
- SOLID principles adherence
- Scalability considerations

### 2. Security Engineer
- Vulnerability assessment
- Auth implementation
- Data protection

### 3. Performance Engineer
- Complexity analysis
- Resource efficiency
- Bottleneck identification

### 4. DX Advocate
- Code readability
- API ergonomics
- Documentation quality

### 5. Reliability Engineer
- Error handling completeness
- Observability coverage
- Recovery mechanisms

### 6. Adversarial Tester
- Edge case coverage
- Attack vector analysis
- Failure mode exploration

## Protocol

**Round 1**: Each agent reviews independently
**Round 2**: Cross-agent debate on findings
**Round 3**: Consensus building

## Output Format
```
┌─────────────────────────────────────────┐
│          EXPERT REVIEW SUMMARY          │
├─────────────────────────────────────────┤
│ Architect:        [PASS/CONCERN/FAIL]   │
│ Security:         [PASS/CONCERN/FAIL]   │
│ Performance:      [PASS/CONCERN/FAIL]   │
│ DX:               [PASS/CONCERN/FAIL]   │
│ Reliability:      [PASS/CONCERN/FAIL]   │
│ Adversarial:      [PASS/CONCERN/FAIL]   │
├─────────────────────────────────────────┤
│ Consensus:        [APPROVE/REVISE]      │
└─────────────────────────────────────────┘

Key Findings:
1. ...
2. ...

Required Changes:
1. ...
```
