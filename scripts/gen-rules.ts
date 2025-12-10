#!/usr/bin/env bun
/**
 * gen-rules.ts - Generate editor-specific rule files from canonical sources
 *
 * Combines AGENT.md and SKILL.md files into .cursorrules
 *
 * Usage: bun run scripts/gen-rules.ts
 */

import { readdir, readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";

const DOTFILES = process.env.DOTFILES || `${process.env.HOME}/dotfiles`;

// File paths
const AGENT_MD = join(DOTFILES, "config/agents/AGENT.md");
const SKILLS_DIR = join(DOTFILES, "config/agents/skills");
const CURSOR_RULES = join(DOTFILES, ".cursorrules");

type Skill = {
  name: string;
  content: string;
};

async function loadAgentMd(): Promise<string> {
  try {
    return await readFile(AGENT_MD, "utf-8");
  } catch {
    console.error(`Failed to read ${AGENT_MD}`);
    process.exit(1);
  }
}

async function loadSkills(): Promise<Skill[]> {
  const skills: Skill[] = [];

  try {
    const dirs = await readdir(SKILLS_DIR, { withFileTypes: true });

    for (const dir of dirs) {
      if (!dir.isDirectory()) continue;

      const skillPath = join(SKILLS_DIR, dir.name, "SKILL.md");
      try {
        const content = await readFile(skillPath, "utf-8");
        skills.push({ name: dir.name, content });
      } catch {
        // Skip directories without SKILL.md
      }
    }
  } catch {
    console.warn("Skills directory not found, continuing without skills");
  }

  return skills;
}

function extractDescription(content: string): string {
  // Try to extract description from YAML frontmatter
  const match = content.match(/description:\s*(.+)/);
  if (match) return match[1].trim();

  // Fallback: use first non-empty line after frontmatter
  const withoutFrontmatter = content.replace(/^---[\s\S]*?---\n*/m, "");
  const firstLine = withoutFrontmatter.split("\n").find((l) => l.trim());
  return firstLine?.replace(/^#+\s*/, "").trim() || "No description";
}

function generateCursorRules(agent: string, skills: Skill[]): string {
  const lines: string[] = [
    "# Cursor Rules",
    "# Auto-generated from config/agents/ - DO NOT EDIT DIRECTLY",
    "# Run: just gen-context",
    "",
    "---",
    "",
    agent,
  ];

  if (skills.length > 0) {
    lines.push("");
    lines.push("---");
    lines.push("");
    lines.push("## Skills Reference");
    lines.push("");
    lines.push(
      "The following domain skills are available. Reference them when working in their domains."
    );
    lines.push("");

    for (const skill of skills) {
      const desc = extractDescription(skill.content);
      lines.push(`- **${skill.name}**: ${desc}`);
    }
  }

  lines.push("");
  lines.push("---");
  lines.push(`Generated: ${new Date().toISOString()}`);

  return lines.join("\n");
}

async function main(): Promise<void> {
  console.log("Generating editor rules from canonical sources...");

  const agent = await loadAgentMd();
  const skills = await loadSkills();

  console.log(`Loaded AGENT.md and ${skills.length} skills`);

  // Generate Cursor rules
  const cursorContent = generateCursorRules(agent, skills);
  await writeFile(CURSOR_RULES, cursorContent, "utf-8");
  console.log(`Wrote ${CURSOR_RULES}`);

  console.log("Done!");
}

main().catch(console.error);
