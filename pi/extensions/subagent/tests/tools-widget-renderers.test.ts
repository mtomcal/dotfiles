/**
 * Slice 3: Widget and Renderers — Tools Display
 *
 * Tests the integration of `formatToolsBracket` into `renderWidgetContent`,
 * `renderSingleResult`, and `renderJobStatusLine` per AIAGT v1.4.0 rules
 * 24a, 24e, 24f, 24g, 25c, 25d.
 *
 * Rule 24a: Widget line 1 shows [tool1,tool2] after name (running & completed/failed). NOT on line 2. NOT in header.
 * Rule 24f: renderSingleResult() — On identity line, format: (provider/model) [tool1,tool2]
 * Rule 24g: renderJobStatusLine() — After name, format: ✓ name [tool1,tool2] (elapsed) task...
 * Rule 25c: Widget line 2 (snippet + tool call) must NOT show tools bracket
 * Rule 25d: Widget header line must NOT show tools bracket
 */

import { describe, test, expect, vi } from "vitest";
import type { Message } from "@earendil-works/pi-ai";
import type { AsyncJob, SingleResult } from "../job-manager.js";
import { renderWidgetContent } from "../widget.js";
import { renderSingleResult, renderJobStatusLine } from "../renderers.js";

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

function fakeUsageStats() {
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

function fakeMessage(text: string): Message {
	return {
		role: "assistant",
		content: [{ type: "text", text }],
	} as Message;
}

function fakeSingleResult(overrides: Partial<SingleResult> = {}): SingleResult {
	return {
		name: "reviewer",
		task: "Review the auth module",
		exitCode: 0,
		messages: [fakeMessage("Looks good.")],
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
			messages: [fakeMessage("The code looks great.")],
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

/** Mock theme that returns plain text (no color codes) for deterministic assertions. */
function mockTheme() {
	return {
		fg: (_color: string, text: string) => text,
		bold: (s: string) => s,
		italic: (s: string) => s,
		dim: (s: string) => s,
		underline: (s: string) => s,
		strikethrough: (s: string) => s,
		bg: (_color: string, text: string) => text,
		wrap: (s: string) => s,
		heading: (s: string) => s,
		success: (s: string) => s,
		warning: (s: string) => s,
		error: (s: string) => s,
		muted: (s: string) => s,
		accent: (s: string) => s,
		info: (s: string) => s,
		link: (s: string) => s,
		code: (s: string) => s,
		codeBlock: (s: string) => s,
		toolTitle: (s: string) => s,
		toolOutput: (s: string) => s,
	};
}

// ---------------------------------------------------------------------------
// Widget tests — renderWidgetContent
// ---------------------------------------------------------------------------

describe("renderWidgetContent — tools bracket integration", () => {
	// 1. Running job with tools: line 1 contains [read,grep] after name, before elapsed
	test("running job with tools shows [read,grep] after name on line 1", () => {
		const jobs: AsyncJob[] = [
			makeRunningJob({ name: "scanner", tools: ["read", "grep"] }),
		];
		const result = renderWidgetContent(jobs, 120);
		expect(result).toBeDefined();
		// Line 1 should contain the bracket after name
		const line1 = result![1]; // index 0 is header
		expect(line1).toContain("[read,grep]");
		// Bracket appears after the name
		expect(line1).toMatch(/scanner\s*\[read,grep\]/);
	});

	// 2. Running job with undefined tools: line 1 does NOT contain [
	test("running job with undefined tools omits bracket on line 1", () => {
		const jobs: AsyncJob[] = [
			makeRunningJob({ name: "scanner" }),
		];
		const result = renderWidgetContent(jobs, 120);
		expect(result).toBeDefined();
		const line1 = result![1];
		expect(line1).not.toContain("[read,grep]");
		// Should not have any bracket at all
		expect(line1).not.toMatch(/\[\w+/);
	});

	// 3. Completed job with tools: line contains [read,grep]
	test("completed job with tools shows bracket on its line", () => {
		const jobs: AsyncJob[] = [
			makeCompletedJob({
				name: "reviewer",
				tools: ["read", "grep"],
				result: fakeSingleResult({ name: "reviewer", tools: ["read", "grep"] }),
			}),
		];
		const result = renderWidgetContent(jobs, 120);
		expect(result).toBeDefined();
		const completedLine = result!.find((l) => l.includes("✓"));
		expect(completedLine).toContain("[read,grep]");
	});

	// 4. Completed job with undefined tools: no bracket
	test("completed job with undefined tools omits bracket", () => {
		const jobs: AsyncJob[] = [
			makeCompletedJob({ name: "reviewer" }),
		];
		const result = renderWidgetContent(jobs, 120);
		expect(result).toBeDefined();
		const completedLine = result!.find((l) => l.includes("✓"));
		expect(completedLine).not.toMatch(/\[\w+/);
	});

	// 5. Failed job with tools: line contains bracket
	test("failed job with tools shows bracket", () => {
		const jobs: AsyncJob[] = [
			makeFailedJob({
				name: "fixer",
				tools: ["read", "write"],
			}),
		];
		const result = renderWidgetContent(jobs, 120);
		expect(result).toBeDefined();
		const failedLine = result!.find((l) => l.includes("✗"));
		expect(failedLine).toContain("[read,write]");
	});

	// 6. Running job line 2 does NOT contain tools bracket (Rule 25c)
	test("running job line 2 does not contain tools bracket", () => {
		const jobs: AsyncJob[] = [
			makeRunningJob({
				name: "scanner",
				tools: ["read", "grep"],
				result: fakeSingleResult({
					name: "scanner",
					tools: ["read", "grep"],
					messages: [fakeMessage("Working on it...")],
				}),
			}),
		];
		const result = renderWidgetContent(jobs, 120);
		expect(result).toBeDefined();
		// Line 2 (index 2) should be the snippet line
		const line2 = result![2];
		// Line 2 must NOT contain the tools bracket
		expect(line2).not.toContain("[read,grep]");
	});

	// 7. Header line does NOT contain tools bracket (Rule 25d)
	test("header line does not contain tools bracket", () => {
		const jobs: AsyncJob[] = [
			makeRunningJob({ name: "scanner", tools: ["read", "grep"] }),
		];
		const result = renderWidgetContent(jobs, 120);
		expect(result).toBeDefined();
		const header = result![0];
		expect(header).not.toContain("[read,grep]");
		expect(header).not.toMatch(/\[\w+/);
	});

	// 8. Widget with mixed jobs (some with tools, some without)
	test("mixed jobs show correct per-job bracket display", () => {
		const jobs: AsyncJob[] = [
			makeRunningJob({ name: "with-tools", tools: ["read", "grep"] }),
			makeRunningJob({ name: "no-tools" }),
			makeCompletedJob({
				name: "reviewer",
				tools: ["bash"],
			}),
		];
		const result = renderWidgetContent(jobs, 120);
		expect(result).toBeDefined();

		// Find the line for "with-tools" job — should have bracket
		const withToolsLine = result!.find((l) => l.includes("with-tools"));
		expect(withToolsLine).toContain("[read,grep]");

		// Find the line for "no-tools" job — should NOT have bracket
		const noToolsLine = result!.find((l) => l.includes("no-tools"));
		expect(noToolsLine).not.toMatch(/\[\w+/);

		// Completed reviewer line should have [bash]
		const completedLine = result!.find((l) => l.includes("✓") && l.includes("reviewer"));
		expect(completedLine).toContain("[bash]");
	});
});

// ---------------------------------------------------------------------------
// renderSingleResult tests
// ---------------------------------------------------------------------------

describe("renderSingleResult — tools bracket integration", () => {
	const theme = mockTheme();

	// 9. Expanded view: identity line shows (provider/model) [read,grep] when tools defined
	test("expanded view shows (provider/model) [read,grep] on identity line", () => {
		const r = fakeSingleResult({
			name: "reviewer",
			provider: "anthropic",
			model: "claude-sonnet-4-5",
			tools: ["read", "grep"],
		});
		const component = renderSingleResult(r, theme as any, true);
		const text = renderComponentToText(component);
		// Should contain model config followed by tools bracket
		expect(text).toContain("(anthropic/claude-sonnet-4-5)");
		expect(text).toContain("[read,grep]");
		// Bracket should appear after the model parentheses
		const modelIdx = text.indexOf("(anthropic/claude-sonnet-4-5)");
		const bracketIdx = text.indexOf("[read,grep]");
		expect(bracketIdx).toBeGreaterThan(modelIdx);
	});

	// 10. Expanded view: identity line shows (provider/model) without bracket when tools undefined
	test("expanded view omits bracket when tools undefined", () => {
		const r = fakeSingleResult({
			name: "reviewer",
			provider: "anthropic",
			model: "claude-sonnet-4-5",
		});
		const component = renderSingleResult(r, theme as any, true);
		const text = renderComponentToText(component);
		expect(text).toContain("(anthropic/claude-sonnet-4-5)");
		expect(text).not.toMatch(/\[\w+,/);
	});

	// 11. Collapsed view: identity line shows bracket when defined, omits when undefined
	test("collapsed view shows bracket when tools defined", () => {
		const r = fakeSingleResult({
			name: "reviewer",
			provider: "openai",
			model: "gpt-4",
			tools: ["bash"],
		});
		const component = renderSingleResult(r, theme as any, false);
		const text = renderComponentToText(component);
		expect(text).toContain("[bash]");
		// Bracket should come after model parentheses
		const modelIdx = text.indexOf("(openai/gpt-4)");
		const bracketIdx = text.indexOf("[bash]");
		expect(bracketIdx).toBeGreaterThan(modelIdx);
	});

	test("collapsed view omits bracket when tools undefined", () => {
		const r = fakeSingleResult({
			name: "reviewer",
			provider: "openai",
			model: "gpt-4",
		});
		const component = renderSingleResult(r, theme as any, false);
		const text = renderComponentToText(component);
		expect(text).not.toMatch(/\[\w+/);
	});

	// 12. Result with tools but no provider/model: shows just [read,grep] after name
	test("shows bracket after name when tools defined but no provider/model", () => {
		const r = fakeSingleResult({
			name: "worker",
			tools: ["read", "grep"],
		});
		const component = renderSingleResult(r, theme as any, true);
		const text = renderComponentToText(component);
		expect(text).toContain("[read,grep]");
		// Should NOT contain model parentheses
		expect(text).not.toMatch(/\(\w+\/\w+\)/);
	});
});

// ---------------------------------------------------------------------------
// renderJobStatusLine tests
// ---------------------------------------------------------------------------

describe("renderJobStatusLine — tools bracket integration", () => {
	const theme = mockTheme();

	// 13. Job with tools: ✓ name [read,grep] (elapsed) task...
	test("shows bracket after name for completed job with tools", () => {
		const job = {
			id: "review-abc",
			name: "review",
			task: "Review the codebase",
			status: "completed",
			startedAt: Date.now() - 10000,
			completedAt: Date.now() - 1000,
			result: fakeSingleResult({ name: "review", tools: ["read", "grep"] }),
		};
		const line = renderJobStatusLine({ ...job, tools: ["read", "grep"] } as any, theme as any);

		// Should contain name, then bracket, then elapsed
		expect(line).toContain("[read,grep]");
		// Bracket should appear after name
		expect(line).toMatch(/review.*\[read,grep\]/);
		// Should contain elapsed time
		expect(line).toMatch(/\(\d+s\)/);
		// Should contain task preview
		expect(line).toContain("Review the codebase");
	});

	// 14. Job without tools: ✓ name (elapsed) task... — no bracket
	test("omits bracket for job without tools", () => {
		const job = {
			id: "review-abc",
			name: "review",
			task: "Review the codebase",
			status: "completed",
			startedAt: Date.now() - 10000,
			completedAt: Date.now() - 1000,
			result: fakeSingleResult({ name: "review" }),
		};
		const line = renderJobStatusLine(job, theme as any);
		expect(line).not.toMatch(/\[\w+/);
		// Should still have name and elapsed
		expect(line).toContain("review");
		expect(line).toMatch(/\(\d+s\)/);
	});

	// 15. Failed job with tools: bracket appears
	test("shows bracket for failed job with tools", () => {
		const job = {
			id: "fix-abc",
			name: "fix",
			task: "Fix the bug",
			status: "failed",
			startedAt: Date.now() - 8000,
			completedAt: Date.now() - 2000,
			result: fakeSingleResult({
				name: "fix",
				exitCode: 1,
				errorMessage: "Build failed",
				tools: ["bash", "write"],
			}),
		};
		const line = renderJobStatusLine({ ...job, tools: ["bash", "write"] } as any, theme as any);
		expect(line).toContain("[bash,write]");
	});
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Render a TUI Component to plain text for assertion purposes. */
function renderComponentToText(component: any): string {
	if (typeof component === "string") return component;
	if (component?.text !== undefined) return component.text;
	// Container: has children that are rows
	if (component?.children) {
		return component.children.map((c: any) => renderComponentToText(c)).join("\n");
	}
	// Fallback: try to toString
	return String(component);
}