# ------------------------------------------------------------
# 1️⃣  Create new directory scaffold in one go
# ------------------------------------------------------------
mkdir -p AI/{core,providers,integrations/{api,git},prompts/{base,code,templates},tasks,scripts/{bash,typescript},docs,legacy}

# ------------------------------------------------------------
# 2️⃣  Core files
# ------------------------------------------------------------
git mv AI/core/config.yaml AI/core/
git mv AI/core/constants.sh AI/core/
git mv AI/core/types.ts AI/core/
git mv AI/core/utils.{sh,ts} AI/core/
# Optional: place a short README
echo "# AI Core\nCanonical shared config & helpers." >AI/core/README.md

# ------------------------------------------------------------
# 3️⃣  Providers
# ------------------------------------------------------------
git mv AI/providers/* AI/providers/

# ------------------------------------------------------------
# 4️⃣  Prompts – flatten into single tree
# ------------------------------------------------------------
git mv AI/prompts/* AI/prompts/
git mv AI-2/prompts/* AI/prompts/ || true # ignore if none

# ------------------------------------------------------------
# 5️⃣  Integrations
# ------------------------------------------------------------
git mv AI/integrations/api-justfile AI/integrations/api/justfile
git mv AI/tools/git/* AI/integrations/git/

# ------------------------------------------------------------
# 6️⃣  Tasks
# ------------------------------------------------------------
git mv AI/tasks/task_*.txt AI/tasks/

# ------------------------------------------------------------
# 7️⃣  Scripts
# ------------------------------------------------------------
git mv AI/utils/ai_bash.sh AI/scripts/bash/
git mv AI/utils/typescript/* AI/scripts/typescript/

# ------------------------------------------------------------
# 8️⃣  Documentation & large reference docs
# ------------------------------------------------------------
git mv AI-2/*.md AI/docs/ || true
git mv AI-2/*.txt AI/docs/ || true
git mv AI-2/system-prompts-and-models-of-ai-tools AI/legacy/

# ------------------------------------------------------------
# 9️⃣  Remove now-empty AI-2/ folder (optional, keep history)
# ------------------------------------------------------------
git rm -r AI-2 || true

git tag ai-merge-$(date +%Y%m%d)
