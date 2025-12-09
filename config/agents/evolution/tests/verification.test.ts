/**
 * Verification System Tests
 *
 * Tests for the verification-first enforcement hooks.
 * Covers multiple languages: TypeScript, JavaScript, Python, Go, Rust, Shell
 */

import { describe, expect, test } from 'bun:test';

// ============================================================================
// Multi-Language TDD Enforcer Tests
// ============================================================================

describe('TDD Enforcer - Multi-Language', () => {
  // Language configurations (mirroring the hook)
  const LANGUAGES = {
    typescript: {
      extensions: ['.ts', '.tsx'],
      testPatterns: [/\.test\.[tj]sx?$/, /\.spec\.[tj]sx?$/, /_test\.[tj]sx?$/],
    },
    javascript: {
      extensions: ['.js', '.jsx', '.mjs', '.cjs'],
      testPatterns: [/\.test\.[jt]sx?$/, /\.spec\.[jt]sx?$/],
    },
    python: {
      extensions: ['.py'],
      testPatterns: [/^test_.*\.py$/, /.*_test\.py$/],
    },
    go: {
      extensions: ['.go'],
      testPatterns: [/_test\.go$/],
    },
    rust: {
      extensions: ['.rs'],
      testPatterns: [/_test\.rs$/, /^tests\/.*\.rs$/],
    },
    shell: {
      extensions: ['.sh', '.bash', '.zsh'],
      testPatterns: [/\.bats$/, /_test\.sh$/, /\.test\.sh$/],
    },
  };

  function getLanguage(path: string) {
    for (const [name, config] of Object.entries(LANGUAGES)) {
      if (config.extensions.some((ext) => path.endsWith(ext))) {
        return { name, config };
      }
    }
    return null;
  }

  function isTestFile(path: string, patterns: RegExp[]): boolean {
    const fileName = path.replace(/^.*\//, '');
    return patterns.some((p) => p.test(fileName) || p.test(path));
  }

  describe('Language detection', () => {
    const cases = [
      { path: '/src/user.ts', expected: 'typescript' },
      { path: '/components/Button.tsx', expected: 'typescript' },
      { path: '/lib/utils.js', expected: 'javascript' },
      { path: '/pages/Home.jsx', expected: 'javascript' },
      { path: '/app/models/user.py', expected: 'python' },
      { path: '/cmd/server/main.go', expected: 'go' },
      { path: '/src/lib.rs', expected: 'rust' },
      { path: '/scripts/deploy.sh', expected: 'shell' },
      { path: '/config.json', expected: null },
      { path: '/README.md', expected: null },
      { path: '/schema.sql', expected: null },
    ];

    test.each(cases)('detects $path as $expected', ({ path, expected }) => {
      const result = getLanguage(path);
      if (expected === null) {
        expect(result).toBeNull();
      } else {
        expect(result?.name).toBe(expected);
      }
    });
  });

  describe('TypeScript/JavaScript test detection', () => {
    const tsPatterns = LANGUAGES.typescript.testPatterns;

    const testFiles = [
      'user.test.ts',
      'auth.spec.tsx',
      'api_test.ts',
      'handler.test.js',
      'component.spec.jsx',
    ];

    test.each(testFiles)('recognizes %s as test file', (file) => {
      expect(isTestFile(file, tsPatterns)).toBe(true);
    });

    const sourceFiles = ['user.ts', 'auth.tsx', 'handler.js', 'component.jsx'];

    test.each(sourceFiles)('recognizes %s as source file', (file) => {
      expect(isTestFile(file, tsPatterns)).toBe(false);
    });
  });

  describe('Python test detection', () => {
    const pyPatterns = LANGUAGES.python.testPatterns;

    const testFiles = ['test_user.py', 'user_test.py', 'test_auth_service.py'];

    test.each(testFiles)('recognizes %s as test file', (file) => {
      expect(isTestFile(file, pyPatterns)).toBe(true);
    });

    const sourceFiles = ['user.py', 'auth_service.py', 'models.py', '__init__.py'];

    test.each(sourceFiles)('recognizes %s as source file', (file) => {
      expect(isTestFile(file, pyPatterns)).toBe(false);
    });
  });

  describe('Go test detection', () => {
    const goPatterns = LANGUAGES.go.testPatterns;

    test('recognizes user_test.go as test file', () => {
      expect(isTestFile('user_test.go', goPatterns)).toBe(true);
    });

    test('recognizes handler_test.go as test file', () => {
      expect(isTestFile('handler_test.go', goPatterns)).toBe(true);
    });

    test('recognizes user.go as source file', () => {
      expect(isTestFile('user.go', goPatterns)).toBe(false);
    });
  });

  describe('Rust test detection', () => {
    const rustPatterns = LANGUAGES.rust.testPatterns;

    test('recognizes lib_test.rs as test file', () => {
      expect(isTestFile('lib_test.rs', rustPatterns)).toBe(true);
    });

    test('recognizes tests/integration.rs as test file', () => {
      expect(isTestFile('tests/integration.rs', rustPatterns)).toBe(true);
    });

    test('recognizes lib.rs as source file', () => {
      expect(isTestFile('lib.rs', rustPatterns)).toBe(false);
    });
  });

  describe('Shell test detection', () => {
    const shellPatterns = LANGUAGES.shell.testPatterns;

    const testFiles = ['deploy.bats', 'build_test.sh', 'setup.test.sh'];

    test.each(testFiles)('recognizes %s as test file', (file) => {
      expect(isTestFile(file, shellPatterns)).toBe(true);
    });

    const sourceFiles = ['deploy.sh', 'build.sh', 'setup.bash'];

    test.each(sourceFiles)('recognizes %s as source file', (file) => {
      expect(isTestFile(file, shellPatterns)).toBe(false);
    });
  });

  describe('Excluded paths', () => {
    const EXCLUDED_DIRS = [
      '/node_modules/',
      '/.git/',
      '/dist/',
      '/build/',
      '/migrations/',
      '/scripts/',
      '/__pycache__/',
      '/.venv/',
      '/vendor/',
      '/target/',
    ];

    function isExcludedPath(path: string): boolean {
      return EXCLUDED_DIRS.some((dir) => path.includes(dir));
    }

    const excludedPaths = [
      '/project/node_modules/lodash/index.js',
      '/project/.git/hooks/pre-commit',
      '/project/dist/bundle.js',
      '/project/migrations/001_initial.sql',
      '/project/__pycache__/module.pyc',
      '/project/.venv/lib/python/site.py',
      '/project/vendor/github.com/pkg/errors/errors.go',
      '/project/target/debug/myapp',
    ];

    test.each(excludedPaths)('excludes %s', (path) => {
      expect(isExcludedPath(path)).toBe(true);
    });

    const includedPaths = ['/project/src/user.ts', '/app/models/user.py', '/cmd/main.go'];

    test.each(includedPaths)('includes %s', (path) => {
      expect(isExcludedPath(path)).toBe(false);
    });
  });

  describe('Excluded files', () => {
    const EXCLUDED_FILES = [
      /^__init__\.py$/,
      /^conftest\.py$/,
      /^setup\.py$/,
      /^main\.go$/,
      /^mod\.rs$/,
      /^lib\.rs$/,
      /\.d\.ts$/,
      /index\.[tj]sx?$/,
    ];

    function isExcludedFile(path: string): boolean {
      const fileName = path.replace(/^.*\//, '');
      return EXCLUDED_FILES.some((pattern) => pattern.test(fileName));
    }

    const excludedFiles = [
      '/app/__init__.py',
      '/tests/conftest.py',
      '/setup.py',
      '/cmd/main.go',
      '/src/mod.rs',
      '/src/lib.rs',
      '/types/global.d.ts',
      '/src/index.ts',
      '/components/index.tsx',
    ];

    test.each(excludedFiles)('excludes %s', (path) => {
      expect(isExcludedFile(path)).toBe(true);
    });

    const includedFiles = [
      '/app/user.py',
      '/tests/test_user.py',
      '/cmd/server.go',
      '/src/handler.rs',
      '/src/user.ts',
    ];

    test.each(includedFiles)('includes %s', (path) => {
      expect(isExcludedFile(path)).toBe(false);
    });
  });

  describe('Expected test path generation', () => {
    describe('TypeScript', () => {
      function getTestPaths(sourcePath: string): string[] {
        const dir = sourcePath.replace(/\/[^/]+$/, '');
        const base = sourcePath.replace(/^.*\//, '').replace(/\.[^.]+$/, '');
        const ext = sourcePath.match(/\.[^.]+$/)?.[0] || '.ts';
        return [
          `${dir}/${base}.test${ext}`,
          `${dir}/${base}.spec${ext}`,
          `${dir}/__tests__/${base}.test${ext}`,
        ];
      }

      test('generates paths for /src/user.ts', () => {
        const paths = getTestPaths('/src/user.ts');
        expect(paths).toContain('/src/user.test.ts');
        expect(paths).toContain('/src/user.spec.ts');
        expect(paths).toContain('/src/__tests__/user.test.ts');
      });
    });

    describe('Python', () => {
      function getTestPaths(sourcePath: string): string[] {
        const dir = sourcePath.replace(/\/[^/]+$/, '');
        const base = sourcePath.replace(/^.*\//, '').replace(/\.py$/, '');
        return [`${dir}/test_${base}.py`, `${dir}/${base}_test.py`, `${dir}/tests/test_${base}.py`];
      }

      test('generates paths for /app/user.py', () => {
        const paths = getTestPaths('/app/user.py');
        expect(paths).toContain('/app/test_user.py');
        expect(paths).toContain('/app/user_test.py');
        expect(paths).toContain('/app/tests/test_user.py');
      });
    });

    describe('Go', () => {
      function getTestPaths(sourcePath: string): string[] {
        const dir = sourcePath.replace(/\/[^/]+$/, '');
        const base = sourcePath.replace(/^.*\//, '').replace(/\.go$/, '');
        return [`${dir}/${base}_test.go`];
      }

      test('generates paths for /pkg/user.go', () => {
        const paths = getTestPaths('/pkg/user.go');
        expect(paths).toEqual(['/pkg/user_test.go']);
      });
    });

    describe('Rust', () => {
      function getTestPaths(sourcePath: string): string[] {
        const dir = sourcePath.replace(/\/[^/]+$/, '');
        const base = sourcePath.replace(/^.*\//, '').replace(/\.rs$/, '');
        return [`${dir}/${base}_test.rs`, `${dir}/tests/${base}.rs`];
      }

      test('generates paths for /src/handler.rs', () => {
        const paths = getTestPaths('/src/handler.rs');
        expect(paths).toContain('/src/handler_test.rs');
        expect(paths).toContain('/src/tests/handler.rs');
      });
    });
  });
});

// ============================================================================
// Assumption Detector Tests
// ============================================================================

describe('Assumption Detector', () => {
  const HIGH_SEVERITY_PATTERNS = [
    /should now (?:have|work|be|fix)/gi,
    /should work/gi,
    /this (?:should|will) fix/gi,
    /will now (?:have|work|be)/gi,
    /this fixes/gi,
  ];

  const MEDIUM_SEVERITY_PATTERNS = [
    /probably (?:works?|fixed|correct)/gi,
    /likely (?:works?|fixed|correct|resolved)/gi,
  ];

  function detectAssumptions(text: string): { high: string[]; medium: string[] } {
    const high: string[] = [];
    const medium: string[] = [];

    for (const pattern of HIGH_SEVERITY_PATTERNS) {
      pattern.lastIndex = 0;
      for (const match of text.matchAll(pattern)) {
        high.push(match[0]);
      }
    }

    for (const pattern of MEDIUM_SEVERITY_PATTERNS) {
      pattern.lastIndex = 0;
      for (const match of text.matchAll(pattern)) {
        medium.push(match[0]);
      }
    }

    return { high, medium };
  }

  describe('High severity detection (BLOCK)', () => {
    const blockingPhrases = [
      { input: 'This should now work correctly', expected: 'should now work' },
      { input: 'The function should work after this change', expected: 'should work' },
      { input: 'This will fix the bug', expected: 'will fix' },
      { input: 'This should fix the issue', expected: 'should fix' },
      { input: 'Users will now have access', expected: 'will now have' },
      { input: 'The API will now be available', expected: 'will now be' },
      { input: 'This fixes the problem', expected: 'This fixes' },
    ];

    test.each(blockingPhrases)('blocks: "$input"', ({ input, expected }) => {
      const result = detectAssumptions(input);
      expect(result.high.length).toBeGreaterThan(0);
      expect(result.high.some((h) => h.toLowerCase().includes(expected.toLowerCase()))).toBe(true);
    });
  });

  describe('Allowed phrases (no detection)', () => {
    const allowedPhrases = [
      'VERIFIED via test: API responds with 200',
      'Test confirms the behavior is correct',
      'UNVERIFIED: This claim needs testing',
      'The test suite passed all assertions',
      'pytest test_user.py passed',
      'go test ./... completed',
      'cargo test succeeded',
    ];

    test.each(allowedPhrases)('allows: "%s"', (input) => {
      const result = detectAssumptions(input);
      expect(result.high.length).toBe(0);
    });
  });

  describe('Medium severity detection (warn only)', () => {
    const warningPhrases = [
      { input: 'This probably works', match: 'probably works' },
      { input: 'The bug is likely fixed', match: 'likely fixed' },
      { input: 'This is probably correct', match: 'probably correct' },
    ];

    test.each(warningPhrases)('warns on: "$input"', ({ input }) => {
      const result = detectAssumptions(input);
      expect(result.medium.length).toBeGreaterThan(0);
      expect(result.high.length).toBe(0);
    });
  });
});

// ============================================================================
// Verification Gate Tests
// ============================================================================

describe('Verification Gate', () => {
  describe('Claim status tracking', () => {
    type ClaimStatus = 'pending' | 'verified' | 'failed' | 'skipped';

    interface Claim {
      status: ClaimStatus;
      text: string;
    }

    function shouldBlock(claims: Claim[]): boolean {
      return claims.some((c) => c.status === 'pending');
    }

    test('blocks when pending claims exist', () => {
      const claims: Claim[] = [
        { status: 'verified', text: 'Feature A works' },
        { status: 'pending', text: 'Feature B works' },
      ];
      expect(shouldBlock(claims)).toBe(true);
    });

    test('allows when all claims verified', () => {
      const claims: Claim[] = [
        { status: 'verified', text: 'Feature A works' },
        { status: 'verified', text: 'Feature B works' },
      ];
      expect(shouldBlock(claims)).toBe(false);
    });

    test('allows when claims failed (explicit acknowledgment)', () => {
      const claims: Claim[] = [
        { status: 'verified', text: 'Feature A works' },
        { status: 'failed', text: 'Feature B has known issue' },
      ];
      expect(shouldBlock(claims)).toBe(false);
    });

    test('allows when claims skipped (explicit skip)', () => {
      const claims: Claim[] = [
        { status: 'verified', text: 'Feature A works' },
        { status: 'skipped', text: 'Feature B skipped for now' },
      ];
      expect(shouldBlock(claims)).toBe(false);
    });

    test('allows when no claims exist', () => {
      const claims: Claim[] = [];
      expect(shouldBlock(claims)).toBe(false);
    });
  });
});

// ============================================================================
// Schema Tests
// ============================================================================

describe('Verification Schemas', () => {
  test('VerificationStatus enum has correct values', async () => {
    const { VerificationStatus } = await import('../src/db/schema');
    expect(VerificationStatus.options).toEqual(['pending', 'verified', 'failed', 'skipped']);
  });

  test('ClaimType enum has correct values', async () => {
    const { ClaimType } = await import('../src/db/schema');
    expect(ClaimType.options).toEqual(['behavior', 'fix', 'feature', 'refactor']);
  });

  test('TddPhase enum has correct values', async () => {
    const { TddPhase } = await import('../src/db/schema');
    expect(TddPhase.options).toEqual(['red', 'green', 'refactor']);
  });

  test('AssumptionSeverity enum has correct values', async () => {
    const { AssumptionSeverity } = await import('../src/db/schema');
    expect(AssumptionSeverity.options).toEqual(['high', 'medium', 'low']);
  });
});
