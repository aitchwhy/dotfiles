#!/usr/bin/env bun
/**
 * Grader CLI - Outputs JSON for grade.sh compatibility
 *
 * Usage: bun run src/graders/cli.ts <grader-name>
 * Output: {"grader":"<name>","score":0.0-1.0,"passed":bool,"issues":["..."]}
 */
import { createGrader } from './index';

const graderName = process.argv[2];

if (!graderName) {
	console.log(
		JSON.stringify({
			grader: 'unknown',
			score: 0,
			passed: false,
			issues: ['Usage: cli.ts <grader-name>'],
		})
	);
	process.exit(1);
}

const grader = createGrader(graderName);

if (!grader) {
	console.log(
		JSON.stringify({
			grader: graderName,
			score: 0,
			passed: false,
			issues: [`grader '${graderName}' not found`],
		})
	);
	process.exit(0);
}

const result = await grader.run();

if (!result.ok) {
	console.log(
		JSON.stringify({
			grader: graderName,
			score: 0,
			passed: false,
			issues: [result.error.message],
		})
	);
	process.exit(0);
}

// Transform to grade.sh expected format
console.log(
	JSON.stringify({
		grader: graderName,
		score: result.data.score,
		passed: result.data.passed,
		issues: result.data.issues.map((i) => i.message),
	})
);
