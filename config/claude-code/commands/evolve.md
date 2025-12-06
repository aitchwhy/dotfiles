# /evolve - Self-Evolution System

Run the dotfiles self-evolution system to grade health, reflect on issues, and propose improvements.

## Usage

Run one of these commands based on what you need:

### Full Cycle (Default)
```bash
just evolve
```
Runs graders, shows status, then reflects on issues with proposals.

### Status Dashboard
```bash
just evolve-status
```
Shows current health score, breakdown by grader, and top issues.

### Grade Only
```bash
just evolve grade
```
Runs all graders without reflection. Updates `.claude-metrics/latest.json`.

### Reflect Only
```bash
just evolve reflect
```
Analyzes latest grades and proposes fixes. Uses Claude API when online, local heuristics when offline.

### View Lessons
```bash
just evolve lessons
```
Shows accumulated lessons from past sessions and reflections.

### View History
```bash
just evolve history
```
Shows score history over time.

## How It Works

### Graders (Weight)
| Grader | Weight | Checks |
|--------|--------|--------|
| nix-health | 40% | flake check, eval, fmt, deprecated patterns |
| config-validity | 35% | JSON/YAML parsing, symlinks |
| git-hygiene | 25% | secrets, conventional commits, .gitignore |

### Automatic Behavior (via Hooks)
- **SessionStart**: Loads recent lessons as context, warns if metrics stale (>24h)
- **PostToolUse**: Validates JSON/YAML/Nix syntax after edits (warns, never blocks)
- **Stop**: Extracts learnings from session, triggers background grading

### Score Thresholds
- **≥90%**: `stable` - Configuration is healthy
- **70-89%**: `improve` - Some issues to address
- **<70%**: `urgent` - Critical issues need attention

## Example Session

```
You: just evolve-status

╔═══════════════════════════════════════╗
║        EVOLUTION STATUS               ║
╠═══════════════════════════════════════╣
║  Score: 85%                           ║
║  Status: improve                      ║
║  Age: 2h ago                          ║
╚═══════════════════════════════════════╝

Breakdown:
  nix-health: 90% ✓
  config-validity: 80% ✓
  git-hygiene: 78% ✓

Top issues:
  • needs nix fmt
  • 2 of last 10 commits non-conventional
```

```
You: just evolve

Running full evolution cycle...
[shows status + proposals]

Mode: Local (heuristic proposals)

Proposals:
  → Run: nix fmt ~/dotfiles
  → Use conventional format: feat:, fix:, docs:, refactor:, chore:
```
