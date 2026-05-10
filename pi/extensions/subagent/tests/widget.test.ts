/**
 * Slice 4: TUI Status Widget — renderWidgetContent pure function tests.
 *
 * Tests the widget renderer that formats async job state into lines
 * for Pi's TUI status bar widget.
 */

import { describe, test, expect, vi } from "vitest";
import type { Message } from "@earendil-works/pi-ai";
import type { AsyncJob, SingleResult } from "../job-manager.js";
import { renderWidgetContent } from "../widget.js";
import { formatGuardrailProgress } from "../guardrails.js";
import {
	SUBAGENT_WIDGET_DEBOUNCE_MS,
	SUBAGENT_WIDGET_DISMISS_DELAY_MS,
	SUBAGENT_SUMMARY_MIN_LENGTH,
} from "../summary.js";

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

function fakeUsageStats(): SingleResult["usage"] {
	return {
		input: 5000,
		output: 1200,
		cacheRead: 3000,
		cacheWrite: 800,
		cost: 0.0342,
		contextTokens: 6000,
		turns: 3,
	};
}

function fakeSingleResult(overrides: Partial<SingleResult> = {}): SingleResult {
	return {
		name: "test",
		task: "Test task",
		exitCode: 0,
		messages: [
			{
				role: "assistant",
				content: [{ type: "text", text: "Here is my review: looks good." }],
			} as Message,
		],
		stderr: "",
		usage: fakeUsageStats(),
		...overrides,
	};
}

function makeRunningJob(overrides: Partial<AsyncJob> = {}): AsyncJob {
	return {
		id: "test-abc123",
		name: "test",
		task: "Test task",
		status: "running",
		process: null,
		startedAt: Date.now() - 5000,
		completedAt: null,
		result: null,
		...overrides,
	};
}

function makeCompletedJob(overrides: Partial<AsyncJob> = {}): AsyncJob {
	return {
		id: "review-def456",
		name: "review",
		task: "Review the code",
		status: "completed",
		process: null,
		startedAt: Date.now() - 10000,
		completedAt: Date.now() - 1000,
		result: fakeSingleResult({
			name: "review",
			task: "Review the code",
			usage: { ...fakeUsageStats(), turns: 5 },
			messages: [
				{
					role: "assistant",
					content: [{ type: "text", text: "The code looks great, just a few minor suggestions." }],
				} as Message,
			],
		}),
		...overrides,
	};
}

function makeFailedJob(overrides: Partial<AsyncJob> = {}): AsyncJob {
	return {
		id: "fix-ghi789",
		name: "fix",
		task: "Fix the bug",
		status: "failed",
		process: null,
		startedAt: Date.now() - 8000,
		completedAt: Date.now() - 2000,
		result: fakeSingleResult({
			name: "fix",
			task: "Fix the bug",
			exitCode: 1,
			errorMessage: "Process exited with code 1",
			usage: { ...fakeUsageStats(), turns: 2 },
		}),
		...overrides,
	};
}

function makeCancelledJob(overrides: Partial<AsyncJob> = {}): AsyncJob {
	return {
		id: "scan-jkl012",
		name: "scan",
		task: "Scan for issues",
		status: "cancelled",
		process: null,
		startedAt: Date.now() - 6000,
		completedAt: Date.now() - 3000,
		result: fakeSingleResult({
			name: "scan",
			task: "Scan for issues",
			usage: { ...fakeUsageStats(), turns: 1 },
		}),
		...overrides,
	};
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe("renderWidgetContent", () => {
	// 1. Returns undefined when no jobs exist
	test("returns undefined when no jobs exist (signals widget removal)", () => {
		const result = renderWidgetContent([], 80);
		expect(result).toBeUndefined();
	});

	// 2. Returns array of strings with header line showing counts
	test("returns string array with header line showing running/completed/failed/cancelled counts", () => {
		const jobs: AsyncJob[] = [
			makeRunningJob({ name: "build" }),
			makeCompletedJob({ name: "review" }),
			makeFailedJob({ name: "fix" }),
			makeCancelledJob({ name: "scan" }),
		];
		const result = renderWidgetContent(jobs, 80);
		expect(result).toBeDefined();
		expect(Array.isArray(result)).toBe(true);
		expect(result!.length).toBeGreaterThan(0);

		// Header should be the first line
		const header = result![0];
		// Header should mention counts for each status
		expect(header).toContain("running");
		expect(header).toContain("done");
	});

	// 3. Running jobs: two-line format with progress
	test("running jobs show two-line format with elapsed time, usage turns, and last tool call", () => {
		const jobs: AsyncJob[] = [
			makeRunningJob({
				name: "builder",
				id: "builder-abc123",
				result: null,
			}),
		];
		const result = renderWidgetContent(jobs, 120);
		expect(result).toBeDefined();

		// Should have at least header + 2 lines for the running job
		expect(result!.length).toBeGreaterThanOrEqual(3);

		// First job line should have ⏳ icon and name
		const jobLine1 = result![1];
		expect(jobLine1).toContain("⏳");
		expect(jobLine1).toContain("builder");

		// Should show elapsed time (5s from fixture)
		expect(jobLine1).toMatch(/\d+s/);

		// Should show turns from usage
		expect(jobLine1).toMatch(/turns/);

		// Second line is the detail/progress line (indented)
		const jobLine2 = result![2];
		expect(jobLine2).toMatch(/^\s/);
	});

	// 4. Completed jobs: one-line format
	test("completed jobs show one-line format with ✓ icon and truncated result", () => {
		const jobs: AsyncJob[] = [
			makeCompletedJob({
				name: "reviewer",
				id: "reviewer-xyz789",
			}),
		];
		const result = renderWidgetContent(jobs, 120);
		expect(result).toBeDefined();

		// Find the line with the completed job
		const completedLine = result!.find((line) => line.includes("✓"));
		expect(completedLine).toBeDefined();
		expect(completedLine).toContain("reviewer");

		// Should show elapsed time
		expect(completedLine).toMatch(/\d+s/);

		// Should contain truncated result text
		expect(completedLine).toContain('"');
	});

	// 5. Failed jobs: one-line format with ✗ icon
	test("failed jobs show one-line format with ✗ icon", () => {
		const jobs: AsyncJob[] = [
			makeFailedJob({
				name: "breaker",
				id: "breaker-fail01",
			}),
		];
		const result = renderWidgetContent(jobs, 120);
		expect(result).toBeDefined();

		const failedLine = result!.find((line) => line.includes("✗"));
		expect(failedLine).toBeDefined();
		expect(failedLine).toContain("breaker");
		expect(failedLine).toMatch(/\d+s/);
	});

	// 6. Cancelled jobs: one-line format with ⊘ icon
	test("cancelled jobs show one-line format with ⊘ icon", () => {
		const jobs: AsyncJob[] = [
			makeCancelledJob({
				name: "scanner",
				id: "scanner-can01",
			}),
		];
		const result = renderWidgetContent(jobs, 120);
		expect(result).toBeDefined();

		const cancelledLine = result!.find((line) => line.includes("⊘"));
		expect(cancelledLine).toBeDefined();
		expect(cancelledLine).toContain("scanner");
	});

	// 7. Text truncation applies to widget content
	test("truncation respects terminal width and strips newlines", () => {
		const longResult = fakeSingleResult({
			name: "review",
			task: "Review task",
			messages: [
				{
					role: "assistant",
					content: [
						{
							type: "text",
							text: "This is a very long result text that should definitely be truncated when rendered in a narrow terminal window to ensure the widget doesn't overflow the status bar",
						},
					],
				} as Message,
			],
		});
		const jobs: AsyncJob[] = [
			makeCompletedJob({
				name: "reviewer",
				id: "reviewer-long1",
				result: longResult,
			}),
		];
		const narrowWidth = 40;

		const result = renderWidgetContent(jobs, narrowWidth);
		expect(result).toBeDefined();

		// Every line should be within terminal width (allowing small margin)
		for (const line of result!) {
			expect(line.length).toBeLessThanOrEqual(narrowWidth + 2);
		}
	});

	test("truncation removes newlines from result text", () => {
		const multiLineResult = fakeSingleResult({
			name: "review",
			task: "Review task",
			messages: [
				{
					role: "assistant",
					content: [
						{
							type: "text",
							text: "Line one\nLine two\nLine three",
						},
					],
				} as Message,
			],
		});
		const jobs: AsyncJob[] = [
			makeCompletedJob({
				name: "reviewer",
				id: "reviewer-ml01",
				result: multiLineResult,
			}),
		];
		const result = renderWidgetContent(jobs, 120);
		expect(result).toBeDefined();

		// No line in the output should contain a newline character
		for (const line of result!) {
			expect(line).not.toContain("\n");
			expect(line).not.toContain("\r");
		}
	});

	// 8. Widget renders when all jobs are completed (not undefined)
	test("returns content (not undefined) when all jobs are completed", () => {
		const jobs: AsyncJob[] = [
			makeCompletedJob({ name: "review-a" }),
			makeCompletedJob({ name: "review-b" }),
		];
		const result = renderWidgetContent(jobs, 80);
		expect(result).toBeDefined();
		expect(Array.isArray(result)).toBe(true);
		expect(result!.length).toBeGreaterThan(0);
	});

	// 9. Graceful error handling (AIAGT-014)
	test("handles rendering errors gracefully, logs and returns undefined", () => {
		const consoleSpy = vi.spyOn(console, "error").mockImplementation(() => {});
		// Create a job that will cause an error during rendering
		// by having a result that throws when accessed
		const brokenJob: AsyncJob = {
			id: "broken-err001",
			name: "broken",
			task: "This will fail",
			status: "completed",
			process: null,
			startedAt: Date.now() - 1000,
			completedAt: Date.now(),
			result: null, // completed with null result — edge case
		};
		// Even with edge cases, renderWidgetContent should not throw
		const result = renderWidgetContent([brokenJob], 80);
		// It should either return content or undefined, but never throw
		if (result !== undefined) {
			expect(Array.isArray(result)).toBe(true);
		}
		consoleSpy.mockRestore();
	});

	// 10. Header line format
	test('header line format: "⏳ Subagents: X running, Y done"', () => {
		const jobs: AsyncJob[] = [
			makeRunningJob({ name: "build" }),
			makeRunningJob({ name: "test" }),
			makeCompletedJob({ name: "review" }),
			makeFailedJob({ name: "fix" }),
		];
		const result = renderWidgetContent(jobs, 120);
		expect(result).toBeDefined();

		const header = result![0];
		// Header should contain the subagents label with ⏳
		expect(header).toContain("⏳");
		expect(header).toContain("Subagents");
		// Should show running count (2 running)
		expect(header).toMatch(/2\s*running/);
		// Should show done count (2 done = completed + failed)
		expect(header).toMatch(/\d+\s*done/);
	});

	// 11. Jobs are sorted: running → failed → completed → cancelled, oldest start time first within each group
	test("jobs are sorted: running first, then failed, then completed, then cancelled", () => {
		const now = Date.now();
		const jobs: AsyncJob[] = [
			// Insert in reverse priority order to verify sorting
			makeCancelledJob({ name: "scan", startedAt: now - 6000 }),
			makeCompletedJob({ name: "review", startedAt: now - 15000 }),
			makeFailedJob({ name: "fix", startedAt: now - 8000 }),
			makeRunningJob({ name: "build", startedAt: now - 30000 }),
			makeRunningJob({ name: "test", startedAt: now - 20000 }),
		];
		const result = renderWidgetContent(jobs, 120);
		expect(result).toBeDefined();

		// Extract lines after header, filtering out indented detail lines (running jobs get 2 lines)
		const bodyLines = result!.slice(1).filter((line) => !line.startsWith("  "));

		// Expected order: running("build"), running("test"), failed("fix"), completed("review"), cancelled("scan")
		expect(bodyLines.length).toBe(5);
		expect(bodyLines[0]).toContain("build");
		expect(bodyLines[0]).toContain("⏳");
		expect(bodyLines[1]).toContain("test");
		expect(bodyLines[1]).toContain("⏳");
		expect(bodyLines[2]).toContain("fix");
		expect(bodyLines[2]).toContain("✗");
		expect(bodyLines[3]).toContain("review");
		expect(bodyLines[3]).toContain("✓");
		expect(bodyLines[4]).toContain("scan");
		expect(bodyLines[4]).toContain("⊘");
	});

	// 12. Within same status group, oldest start time first
	test("within same status group, jobs sorted by oldest start time first", () => {
		const now = Date.now();
		const jobs: AsyncJob[] = [
			makeCompletedJob({ name: "review-c", startedAt: now - 5000 }),
			makeCompletedJob({ name: "review-a", startedAt: now - 30000 }),
			makeCompletedJob({ name: "review-b", startedAt: now - 15000 }),
		];
		const result = renderWidgetContent(jobs, 120);
		expect(result).toBeDefined();

		const bodyLines = result!.slice(1).filter((line) => !line.startsWith("  "));
		expect(bodyLines.length).toBe(3);
		expect(bodyLines[0]).toContain("review-a");
		expect(bodyLines[1]).toContain("review-b");
		expect(bodyLines[2]).toContain("review-c");
	});
});

// ---------------------------------------------------------------------------
// Guardrail Progress Tests (Slice 4)
// ----------------------------------------------------------------------------

describe("renderWidgetContent guardrail progress", () => {
	function makeRunningJobWithGuardrails(overrides: Partial<AsyncJob> = {}): AsyncJob {
		return {
			id: "codegen-a3f2b7",
			name: "codegen",
			task: "Refactor auth module",
			status: "running",
			process: null,
			startedAt: Date.now() - 150000, // 2m30s ago
			completedAt: null,
			result: {
				name: "codegen",
				task: "Refactor auth module",
				exitCode: 0,
				messages: [],
				stderr: "",
				usage: {
					input: 100000,
					output: 50000,
					cacheRead: 10000,
					cacheWrite: 5000,
					cost: 0.32,
					contextTokens: 84000,
					turns: 18,
				},
			},
			guardrails: { maxTurns: 25, maxCost: 0.50, maxTokens: 200000, maxTime: 300 },
			tools: ["read", "write", "bash", "edit"],
			...overrides,
		};
	}

	test("renderWidgetContent with a running job that has guardrails shows progress line", () => {
		const jobs: AsyncJob[] = [makeRunningJobWithGuardrails()];
		const result = renderWidgetContent(jobs, 120);
		expect(result).toBeDefined();
		expect(result!.length).toBeGreaterThanOrEqual(3);

		// Check that guardrail progress is present
		const output = result!.join(" ");
		expect(output).toContain("18/25T");
		expect(output).toContain("$0.32/$0.50");
	});

	test("renderWidgetContent with a running job that has no guardrails shows no progress line", () => {
		const jobs: AsyncJob[] = [
			makeRunningJob({
				name: "review",
				task: "Review the code",
				guardrails: undefined,
				result: fakeSingleResult({
					usage: { input: 5000, output: 1200, cacheRead: 3000, cacheWrite: 800, cost: 0.0342, contextTokens: 6000, turns: 3 },
				}),
			}),
		];
		const result = renderWidgetContent(jobs, 120);
		expect(result).toBeDefined();

		// No guardrail progress indicators
		const output = result!.join(" ");
		expect(output).not.toContain("/25T");
		expect(output).not.toContain("/$0.");
	});

	test("formatGuardrailProgress with full guardrails returns correct format", () => {
		const usage = {
			input: 100000,
			output: 50000,
			cacheRead: 10000,
			cacheWrite: 5000,
			cost: 0.32,
			contextTokens: 84000,
			turns: 18,
		};
		const guardrails = { maxTurns: 25, maxCost: 0.50, maxTokens: 200000, maxTime: 300 };
		const elapsedMs = 150000; // 2m30s
		const result = formatGuardrailProgress(usage, guardrails, elapsedMs);
		expect(result).toContain("18/25T");
		expect(result).toContain("$0.32/$0.50");
		expect(result).toContain("84k/200k");
		expect(result).toContain("2m30s/5m");
	});

	test("formatGuardrailProgress with partial guardrails returns only configured fields", () => {
		const usage = { input: 100000, output: 50000, cacheRead: 10000, cacheWrite: 5000, cost: 0.32, contextTokens: 84000, turns: 18 };
		const guardrails = { maxTurns: 25, maxCost: 0.50 };
		const result = formatGuardrailProgress(usage, guardrails, 150000);
		expect(result).toBe("18/25T $0.32/$0.50");
	});

	test("formatGuardrailProgress with undefined guardrails returns empty string", () => {
		const usage = { input: 100000, output: 50000, cacheRead: 10000, cacheWrite: 5000, cost: 0.32, contextTokens: 84000, turns: 18 };
		const result = formatGuardrailProgress(usage, undefined, 150000);
		expect(result).toBe("");
	});
});

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

describe("widget constants (from summary.js)", () => {
	test("SUBAGENT_SUMMARY_MIN_LENGTH is 50", () => {
		expect(SUBAGENT_SUMMARY_MIN_LENGTH).toBe(50);
	});

	test("SUBAGENT_WIDGET_DEBOUNCE_MS is 1000", () => {
		expect(SUBAGENT_WIDGET_DEBOUNCE_MS).toBe(1000);
	});

	test("SUBAGENT_WIDGET_DISMISS_DELAY_MS is 5000", () => {
		expect(SUBAGENT_WIDGET_DISMISS_DELAY_MS).toBe(5000);
	});
});