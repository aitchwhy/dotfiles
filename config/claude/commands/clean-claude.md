Clean exported Claude conversation markdown files by stripping inline base64 image data.

The user may provide file paths as arguments: `/clean-claude <file.md> [file2.md ...]`
If no files are specified, look for `.md` files in the current working directory that contain `data:image/` and offer to clean them.

## Background

Chrome extensions like "AI Chat Exporter" embed screenshots as `![alt](data:image/webp;base64,...)` inline in markdown. Claude can't render these images from markdown — they're tokenized as raw text, wasting ~93% of the file on useless base64 characters. An 860 KB export becomes ~700K tokens (3.5x the context window), causing Claude Desktop to fail with timeouts and stalled compaction.

## Steps

1. **Analyze the file(s).** For each file, count `![...](data:image/...)` patterns. Report:
   - Number of base64 images found
   - Current file size
   - Estimated size after cleaning

2. **Strip base64 images.** Replace each `![alt](data:image/...;base64,...)` with `[Image: alt]` (or `[Image: unnamed]` if no alt text). Use this Python one-liner pattern:
   ```python
   import re
   pattern = r'!\[([^\]]*)\]\(data:image/[^)]+\)'
   cleaned = re.sub(pattern, lambda m: f'[Image: {m.group(1) or "unnamed"}]', content)
   ```

3. **Report results.** Show before/after file size, percentage reduction, and confirm all conversation text (prompts, responses) is intact.

4. **Verify.** Run `wc -c` on the cleaned file to confirm it's under 100 KB. If any `data:image/` patterns remain, report them as errors.

The script at `~/dotfiles/scripts/clean-markdown-images.sh` can also be used directly if preferred.
