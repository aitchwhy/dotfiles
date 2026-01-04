Run full quality audit on dotfiles:

1. `cd ~/dotfiles/config/quality`
2. `bun run typecheck` - Type errors
3. `bun run lint` - Lint errors
4. `bun run test` - Test failures
5. `ast-grep scan` - Pattern violations

Report all findings with file:line references.
