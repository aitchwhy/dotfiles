-- Evolution System Initial Schema
-- Created: 2025-12-06
-- Tables: 8, Views: 4

-- ============================================================================
-- Sessions: Claude Code session tracking
-- ============================================================================
CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    started_at TEXT NOT NULL,
    ended_at TEXT,
    working_directory TEXT NOT NULL,
    hostname TEXT NOT NULL,
    git_branch TEXT,
    initial_score REAL,
    final_score REAL,
    files_modified INTEGER DEFAULT 0,
    commits_made INTEGER DEFAULT 0,
    metadata TEXT
);

CREATE INDEX idx_sessions_started_at ON sessions(started_at);
CREATE INDEX idx_sessions_working_directory ON sessions(working_directory);

-- ============================================================================
-- Tasks: Work items within sessions
-- ============================================================================
CREATE TABLE IF NOT EXISTS tasks (
    id TEXT PRIMARY KEY,
    session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    started_at TEXT NOT NULL,
    ended_at TEXT,
    description TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')),
    files_touched TEXT,
    metadata TEXT
);

CREATE INDEX idx_tasks_session_id ON tasks(session_id);
CREATE INDEX idx_tasks_status ON tasks(status);

-- ============================================================================
-- Commits: Git commits during sessions
-- ============================================================================
CREATE TABLE IF NOT EXISTS commits (
    id TEXT PRIMARY KEY,  -- Git SHA
    session_id TEXT REFERENCES sessions(id) ON DELETE SET NULL,
    created_at TEXT NOT NULL,
    message TEXT NOT NULL,
    files_changed INTEGER NOT NULL,
    insertions INTEGER NOT NULL,
    deletions INTEGER NOT NULL,
    is_conventional BOOLEAN NOT NULL,
    commit_type TEXT,
    scope TEXT
);

CREATE INDEX idx_commits_session_id ON commits(session_id);
CREATE INDEX idx_commits_created_at ON commits(created_at);
CREATE INDEX idx_commits_is_conventional ON commits(is_conventional);

-- ============================================================================
-- Lessons: Accumulated learnings
-- ============================================================================
CREATE TABLE IF NOT EXISTS lessons (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at TEXT NOT NULL,
    lesson TEXT NOT NULL,
    source TEXT NOT NULL CHECK (source IN ('reflection', 'session', 'manual', 'grader')),
    category TEXT,
    confidence REAL DEFAULT 1.0,
    times_applied INTEGER DEFAULT 0,
    last_applied_at TEXT
);

CREATE INDEX idx_lessons_source ON lessons(source);
CREATE INDEX idx_lessons_category ON lessons(category);
CREATE INDEX idx_lessons_created_at ON lessons(created_at);

-- ============================================================================
-- Metrics: Time-series storage for DORA and custom metrics
-- ============================================================================
CREATE TABLE IF NOT EXISTS metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recorded_at TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    metric_value REAL NOT NULL,
    labels TEXT,
    UNIQUE(recorded_at, metric_name, labels)
);

CREATE INDEX idx_metrics_recorded_at ON metrics(recorded_at);
CREATE INDEX idx_metrics_name ON metrics(metric_name);

-- ============================================================================
-- Evolution Cycles: Aggregate grading sessions
-- ============================================================================
CREATE TABLE IF NOT EXISTS evolution_cycles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    started_at TEXT NOT NULL,
    ended_at TEXT NOT NULL,
    overall_score REAL NOT NULL,
    recommendation TEXT NOT NULL CHECK (recommendation IN ('stable', 'improve', 'urgent')),
    trigger TEXT NOT NULL CHECK (trigger IN ('manual', 'session_end', 'scheduled', 'ci')),
    session_id TEXT REFERENCES sessions(id) ON DELETE SET NULL,
    proposals TEXT,
    applied_proposals TEXT
);

CREATE INDEX idx_evolution_cycles_started_at ON evolution_cycles(started_at);
CREATE INDEX idx_evolution_cycles_recommendation ON evolution_cycles(recommendation);

-- ============================================================================
-- Grader Runs: Individual grader results
-- ============================================================================
CREATE TABLE IF NOT EXISTS grader_runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    evolution_cycle_id INTEGER NOT NULL REFERENCES evolution_cycles(id) ON DELETE CASCADE,
    grader_name TEXT NOT NULL,
    started_at TEXT NOT NULL,
    ended_at TEXT NOT NULL,
    score REAL NOT NULL,
    passed BOOLEAN NOT NULL,
    issues TEXT NOT NULL,  -- JSON array
    raw_output TEXT,
    execution_time_ms INTEGER
);

CREATE INDEX idx_grader_runs_cycle_id ON grader_runs(evolution_cycle_id);
CREATE INDEX idx_grader_runs_grader_name ON grader_runs(grader_name);
CREATE INDEX idx_grader_runs_passed ON grader_runs(passed);

-- ============================================================================
-- Research: Documentation lookups and external references
-- ============================================================================
CREATE TABLE IF NOT EXISTS research (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at TEXT NOT NULL,
    query TEXT NOT NULL,
    source_url TEXT,
    content_summary TEXT NOT NULL,
    relevance_score REAL,
    related_lesson_id INTEGER REFERENCES lessons(id) ON DELETE SET NULL,
    metadata TEXT
);

CREATE INDEX idx_research_created_at ON research(created_at);
CREATE INDEX idx_research_related_lesson ON research(related_lesson_id);

-- ============================================================================
-- Views for Analytics
-- ============================================================================

-- DORA metrics view
CREATE VIEW IF NOT EXISTS v_dora_metrics AS
SELECT
    date(started_at) as date,
    COUNT(DISTINCT id) as deploy_count,
    AVG(final_score - initial_score) as avg_improvement
FROM sessions
WHERE ended_at IS NOT NULL
GROUP BY date(started_at);

-- Score trend over time
CREATE VIEW IF NOT EXISTS v_score_trend AS
SELECT
    date(started_at) as date,
    AVG(overall_score) as avg_score,
    MIN(overall_score) as min_score,
    MAX(overall_score) as max_score,
    COUNT(*) as cycle_count
FROM evolution_cycles
GROUP BY date(started_at)
ORDER BY date DESC;

-- Lesson effectiveness analytics
CREATE VIEW IF NOT EXISTS v_lesson_effectiveness AS
SELECT
    category,
    COUNT(*) as lesson_count,
    AVG(times_applied) as avg_applications,
    AVG(confidence) as avg_confidence
FROM lessons
GROUP BY category;

-- Grader performance trends
CREATE VIEW IF NOT EXISTS v_grader_trends AS
SELECT
    grader_name,
    date(started_at) as date,
    AVG(score) as avg_score,
    SUM(CASE WHEN passed THEN 1 ELSE 0 END) as pass_count,
    COUNT(*) as total_runs,
    AVG(execution_time_ms) as avg_execution_time_ms
FROM grader_runs
GROUP BY grader_name, date(started_at);
