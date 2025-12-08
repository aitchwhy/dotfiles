-- =============================================================================
-- Migration 003: Generator Drift & Reflector System
-- =============================================================================
-- Adds tables for tracking drift from Factory generators, rule violations,
-- and patch proposals from the Reflector agent.

-- =============================================================================
-- Generator Drift Table
-- =============================================================================
-- Tracks drift detected by `fcs reconcile` in Factory-generated projects

CREATE TABLE IF NOT EXISTS generator_drift (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    detected_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    file_path TEXT NOT NULL,
    drift_type TEXT NOT NULL CHECK (drift_type IN ('missing-import', 'missing-zod-schema', 'missing-result-type', 'missing-export', 'invalid-import-path')),
    severity TEXT NOT NULL CHECK (severity IN ('error', 'warning')),
    message TEXT NOT NULL,
    line_number INTEGER,
    generator_name TEXT,  -- e.g., 'api', 'ui', 'monorepo'
    project_path TEXT NOT NULL,
    fix_applied INTEGER NOT NULL DEFAULT 0,
    fix_applied_at TEXT,
    session_id TEXT REFERENCES sessions(id)
);

CREATE INDEX IF NOT EXISTS idx_drift_by_type ON generator_drift(drift_type);
CREATE INDEX IF NOT EXISTS idx_drift_by_generator ON generator_drift(generator_name);
CREATE INDEX IF NOT EXISTS idx_drift_by_project ON generator_drift(project_path);

-- =============================================================================
-- Rule Violations Table
-- =============================================================================
-- Tracks violations from enforcers, graders, and hooks

CREATE TABLE IF NOT EXISTS rule_violations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    detected_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    rule_source TEXT NOT NULL CHECK (rule_source IN ('hook', 'grader', 'enforcer', 'linter')),
    rule_name TEXT NOT NULL,
    file_path TEXT,
    line_number INTEGER,
    violation_message TEXT NOT NULL,
    severity TEXT NOT NULL CHECK (severity IN ('error', 'warning', 'info')),
    auto_fixed INTEGER NOT NULL DEFAULT 0,
    session_id TEXT REFERENCES sessions(id)
);

CREATE INDEX IF NOT EXISTS idx_violations_by_rule ON rule_violations(rule_name);
CREATE INDEX IF NOT EXISTS idx_violations_by_source ON rule_violations(rule_source);
CREATE INDEX IF NOT EXISTS idx_violations_by_severity ON rule_violations(severity);

-- =============================================================================
-- Patch Proposals Table
-- =============================================================================
-- Tracks patches proposed by the Reflector agent

CREATE TABLE IF NOT EXISTS patch_proposals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    patch_type TEXT NOT NULL CHECK (patch_type IN ('skill-update', 'rule-update', 'hook-update', 'generator-fix', 'schema-change')),
    target_file TEXT NOT NULL,
    description TEXT NOT NULL,
    rationale TEXT NOT NULL,
    patch_content TEXT NOT NULL,  -- The actual diff or new content
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'applied')),
    confidence REAL NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
    evidence_count INTEGER NOT NULL DEFAULT 0,  -- Number of violations/drifts supporting this patch
    reviewed_at TEXT,
    applied_at TEXT,
    applied_by TEXT  -- 'auto' or 'manual'
);

CREATE INDEX IF NOT EXISTS idx_patches_by_status ON patch_proposals(status);
CREATE INDEX IF NOT EXISTS idx_patches_by_type ON patch_proposals(patch_type);

-- =============================================================================
-- Link Table: Patches <-> Evidence
-- =============================================================================
-- Links patch proposals to the drift/violations that motivated them

CREATE TABLE IF NOT EXISTS patch_evidence (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    patch_id INTEGER NOT NULL REFERENCES patch_proposals(id) ON DELETE CASCADE,
    evidence_type TEXT NOT NULL CHECK (evidence_type IN ('drift', 'violation')),
    evidence_id INTEGER NOT NULL,
    UNIQUE(patch_id, evidence_type, evidence_id)
);

CREATE INDEX IF NOT EXISTS idx_evidence_by_patch ON patch_evidence(patch_id);

-- =============================================================================
-- Views for Analysis
-- =============================================================================

-- Drift hotspots by generator
CREATE VIEW IF NOT EXISTS v_drift_hotspots AS
SELECT
    generator_name,
    drift_type,
    COUNT(*) as occurrence_count,
    COUNT(DISTINCT file_path) as affected_files,
    SUM(CASE WHEN fix_applied = 1 THEN 1 ELSE 0 END) as fixed_count,
    MAX(detected_at) as last_seen
FROM generator_drift
GROUP BY generator_name, drift_type
ORDER BY occurrence_count DESC;

-- High-frequency rule violations
CREATE VIEW IF NOT EXISTS v_violation_patterns AS
SELECT
    rule_source,
    rule_name,
    severity,
    COUNT(*) as total_violations,
    COUNT(DISTINCT file_path) as affected_files,
    SUM(CASE WHEN auto_fixed = 1 THEN 1 ELSE 0 END) as auto_fixed_count,
    MIN(detected_at) as first_seen,
    MAX(detected_at) as last_seen
FROM rule_violations
GROUP BY rule_source, rule_name, severity
ORDER BY total_violations DESC;

-- Patch proposal summary
CREATE VIEW IF NOT EXISTS v_patch_summary AS
SELECT
    patch_type,
    status,
    COUNT(*) as count,
    AVG(confidence) as avg_confidence,
    AVG(evidence_count) as avg_evidence
FROM patch_proposals
GROUP BY patch_type, status
ORDER BY patch_type, status;

-- Active issues requiring attention (unfixed drift + unresolved violations)
CREATE VIEW IF NOT EXISTS v_active_issues AS
SELECT
    'drift' as issue_type,
    id,
    detected_at,
    file_path,
    drift_type as issue_name,
    message,
    severity,
    project_path as context
FROM generator_drift
WHERE fix_applied = 0
UNION ALL
SELECT
    'violation' as issue_type,
    id,
    detected_at,
    file_path,
    rule_name as issue_name,
    violation_message as message,
    severity,
    rule_source as context
FROM rule_violations
WHERE auto_fixed = 0
ORDER BY detected_at DESC;
