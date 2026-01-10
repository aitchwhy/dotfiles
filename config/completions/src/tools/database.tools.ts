/**
 * Database Client Tools
 */
import type { CliTool } from "../schemas";
import { nixTool } from "../schemas";

export const databaseTools: readonly CliTool[] = [
  nixTool("postgresql", "psql", "database", "postgresql_18", "PostgreSQL client"),
  nixTool("redis", "redis-cli", "database", "redis", "Redis CLI"),
  nixTool("usql", "usql", "database", "usql", "Universal SQL client"),
] as const;
