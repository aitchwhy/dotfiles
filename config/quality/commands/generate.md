---
description: Regenerate Claude Code artifacts from SSOT
allowed-tools: Bash
---

# Regenerate Claude Artifacts

```bash
cd ~/dotfiles/config/quality
pnpm install --frozen-lockfile
pnpm run generate
pnpm run typecheck
```

Outputs to `config/quality/generated/claude/`:
- skills/
- personas/
- rules/
- settings.json
