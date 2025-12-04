---
description: Codebase analysis and statistics
allowed-tools: Bash, Read, Grep, Glob
---

# Codebase Analysis: $ARGUMENTS

## 1. Statistics

```bash
echo "=== File Counts ==="
fd -e ts -e tsx | wc -l | xargs echo "TypeScript:"
fd -e py | wc -l | xargs echo "Python:"
fd -e nix | wc -l | xargs echo "Nix:"

echo "=== Lines of Code ==="
tokei . 2>/dev/null || cloc . 2>/dev/null || wc -l $(fd -e ts -e tsx)
```

## 2. Dependencies

```bash
echo "=== Package.json deps ==="
jq '.dependencies | keys | length' package.json 2>/dev/null
jq '.devDependencies | keys | length' package.json 2>/dev/null
```

## 3. Structure

```bash
echo "=== Directory Structure ==="
tree -L 2 -d 2>/dev/null || find . -type d -maxdepth 2
```

## 4. Patterns

- Search for TODOs: `rg "TODO|FIXME|HACK" --type ts`
- Find large files: `fd -e ts -e tsx -x wc -l {} | sort -rn | head -10`

## 5. Report

Summarize findings with:
- Project health indicators
- Technical debt areas
- Suggested improvements
