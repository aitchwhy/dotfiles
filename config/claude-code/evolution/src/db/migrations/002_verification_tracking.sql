-- Evolution System Verification Tracking Schema
-- Created: 2025-12-06
-- Tables: 3, Views: 1
-- Purpose: Enable verification-first development with TDD enforcement

-- ============================================================================
-- Verification Claims: Track claims requiring test evidence
-- ============================================================================
CREATE TABLE IF NOT EXISTS verification_claims (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    claim_text TEXT NOT NULL,
    claim_type TEXT NOT NULL CHECK (claim_type IN ('behavior', 'fix', 'feature', 'refactor')),
    verification_status TEXT NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'failed', 'skipped')),
    test_file TEXT,
    test_name TEXT,
    test_output TEXT,
    verified_at TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_verification_claims_session ON verification_claims(session_id);
CREATE INDEX idx_verification_claims_status ON verification_claims(verification_status);
CREATE INDEX idx_verification_claims_created_at ON verification_claims(created_at);

-- ============================================================================
-- TDD Cycles: Track Red-Green-Refactor phase transitions
-- ============================================================================
CREATE TABLE IF NOT EXISTS tdd_cycles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    cycle_number INTEGER NOT NULL,
    phase TEXT NOT NULL CHECK (phase IN ('red', 'green', 'refactor')),
    test_file TEXT,
    source_file TEXT,
    started_at TEXT NOT NULL DEFAULT (datetime('now')),
    completed_at TEXT
);

CREATE INDEX idx_tdd_cycles_session ON tdd_cycles(session_id);
CREATE INDEX idx_tdd_cycles_phase ON tdd_cycles(phase);

-- ============================================================================
-- Assumption Log: Track detected assumption language
-- ============================================================================
CREATE TABLE IF NOT EXISTS assumption_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    assumption_text TEXT NOT NULL,
    context TEXT,
    severity TEXT NOT NULL CHECK (severity IN ('high', 'medium', 'low')),
    logged_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_assumption_log_session ON assumption_log(session_id);
CREATE INDEX idx_assumption_log_severity ON assumption_log(severity);

-- ============================================================================
-- Views for Verification Analytics
-- ============================================================================

-- Session effectiveness: verification rate per session
CREATE VIEW IF NOT EXISTS v_session_effectiveness AS
SELECT
    session_id,
    COUNT(*) as total_claims,
    SUM(CASE WHEN verification_status = 'verified' THEN 1 ELSE 0 END) as verified_claims,
    SUM(CASE WHEN verification_status = 'failed' THEN 1 ELSE 0 END) as failed_claims,
    SUM(CASE WHEN verification_status = 'pending' THEN 1 ELSE 0 END) as pending_claims,
    ROUND(100.0 * SUM(CASE WHEN verification_status = 'verified' THEN 1 ELSE 0 END) / COUNT(*), 2) as verification_rate
FROM verification_claims
GROUP BY session_id;

-- TDD compliance: track phase transitions
CREATE VIEW IF NOT EXISTS v_tdd_compliance AS
SELECT
    session_id,
    COUNT(DISTINCT cycle_number) as total_cycles,
    SUM(CASE WHEN phase = 'red' THEN 1 ELSE 0 END) as red_phases,
    SUM(CASE WHEN phase = 'green' THEN 1 ELSE 0 END) as green_phases,
    SUM(CASE WHEN phase = 'refactor' THEN 1 ELSE 0 END) as refactor_phases
FROM tdd_cycles
GROUP BY session_id;

-- Assumption trends: track assumption frequency by severity
CREATE VIEW IF NOT EXISTS v_assumption_trends AS
SELECT
    date(logged_at) as date,
    severity,
    COUNT(*) as count,
    GROUP_CONCAT(DISTINCT assumption_text) as sample_texts
FROM assumption_log
GROUP BY date(logged_at), severity
ORDER BY date DESC,
    CASE severity WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END;
