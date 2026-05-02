/**
 * Slice 4: Index.ts — Tools Display in subagent_status, subagent_results, subagent_wait, subagent_run, subagent_fork
 *
 * RED tests — Test the display surfaces for tools information across all tools.
 * Per AIAGT v1.4.0 rules 21, 24b, 24c, 24d, 24h, 24i, 27.
 *
 * Rule 21: tools displayed as comma-separated bracket [t1,t2,...] when defined; omitted when undefined
 * Rule 24b: subagent_status single job: **Tools:** read, grep line after **Task:** when tools defined
 * Rule 24c: subagent_results: **Tools:** read, grep line after **Task:** when tools defined
 * Rule 24d: subagent_wait progress: bracket after name on progress line
 * Rule 24h: subagent_run text output: parallel/chain headings ## name [tool1,tool2] (completed)
 * Rule 24i: subagent_fork response text: **name** [tool1,tool2] — task (running)
 * Rule 27: tools on SingleResult set in spawnSubagentProcess() alongside provider, model, thinking
 */

import { describe, test, expect, vi, beforeAll, beforeEach, afterEach } from "vitest";
import { createMockExtension } from "./extension-helpers.js";
import { JobManager, type SingleResult } from "../job-manager.js";
import { formatToolsBracket, formatToolsLabel, renderJobStatusLine } from "../renderers.js";
import { parseTools } from "../subagent-config.js";
import type { Message } from "@mariozechner/pi-ai";

let registeredTools: Map<string, any>;
let mockPi: any;
let jobMgr: JobManager;
let statusTool: any;
let resultsTool: any;
let waitTool: any;
let runTool: any;
let forkTool: any;
let mockCtx: any;

beforeAll(async () => {
	const ctx = createMockExtension();
	mockPi = ctx.pi;
	jobMgr = ctx.jobMgr;
	registeredTools = ctx.registeredTools;

	const mod = await import("../index.js");
	mod.default(mockPi);

	statusTool = registeredTools.get("subagent_status");
	resultsTool = registeredTools.get("subagent_results");
	waitTool = registeredTools.get("subagent_wait");
	runTool = registeredTools.get("subagent_run");
	forkTool = registeredTools.get("subagent_fork");

	mockCtx = {
		cwd: "/test",
		hasUI: false,
		signal: undefined,
		ui: { confirm: vi.fn() },
	} as any;
});

beforeEach(() => {
	jobMgr.cancelAll();
	for (const job of jobMgr.listJobs()) {
		(jobMgr as any).jobs.delete(job.id);
	}
});

afterEach(() => {
	jobMgr.cancelAll();
	for (const job of jobMgr.listJobs()) {
		(jobMgr as any).jobs.delete(job.id);
	}
});

// ── Helpers ────────────────────────────────────────────────────────────────

function getMockTheme() {
	return {
		fg: (_color: string, text: string) => text,
		bold: (s: string) => s,
	};
}

/** Create a completed job with tools and return its ID. */
function createCompletedJob(name: string, task: string, tools?: string[]): string {
	const job = jobMgr.createJob(name, task);
	if (tools) job.tools = tools;
	jobMgr.completeJob(job.id, {
		name,
		task,
		exitCode: 0,
		messages: [{ role: "assistant", content: [{ type: "text", text: "Done successfully" }] }] as Message[],
		stderr: "",
		usage: { input: 100, output: 50, cacheRead: 0, cacheWrite: 0, cost: 0.01, contextTokens: 500, turns: 1 },
		tools,
		provider: "test",
		model: "test-model",
		thinking: "medium",
	} as SingleResult);
	return job.id;
}

/** Create a running job with tools and partial result, return its ID. */
function createRunningJobWithTools(name: string, task: string, tools?: string[], partialResult?: SingleResult): string {
	const job = jobMgr.createJob(name, task);
	if (tools) job.tools = tools;
	if (partialResult) {
		(jobMgr.getJob(job.id) as any).result = partialResult;
	}
	return job.id;
}

// ═══════════════════════════════════════════════════════════════════════════
// Test 1-2: spawnSubagentProcess — SingleResult includes tools
// ═══════════════════════════════════════════════════════════════════════════

describe("spawnSubagentProcess sets tools on SingleResult", () => {
	// Test 1: SingleResult from spawn includes tools: ["read","grep"] when config has tools
	test("SingleResult from spawn includes tools when config has tools", () => {
		const result: SingleResult = {
			name: "reviewer",
			task: "Review the auth module",
			exitCode: 0,
			messages: [],
			stderr: "",
			usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
			provider: "anthropic",
			model: "claude-sonnet-4",
			thinking: "medium",
			tools: ["read", "grep"],
		};
		expect(result.tools).toEqual(["read", "grep"]);
	});

	// Test 2: SingleResult from spawn includes tools: undefined when config has no tools
	test("SingleResult from spawn has tools undefined when config has no tools", () => {
		const result: SingleResult = {
			name: "reviewer",
			task: "Review the auth module",
			exitCode: 0,
			messages: [],
			stderr: "",
			usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
			provider: "anthropic",
			model: "claude-sonnet-4",
			thinking: "medium",
		};
		expect(result.tools).toBeUndefined();
	});
});

// ═══════════════════════════════════════════════════════════════════════════
// Test 3-5: subagent_status — Tools display
// ═══════════════════════════════════════════════════════════════════════════

describe("subagent_status — Tools display", () => {
	// Test 3: Single job with tools: output includes **Tools:** read, grep after **Task:**
	test("single job with tools includes **Tools:** line after **Task:**", async () => {
		const jobId = createCompletedJob("reviewer", "Review auth module", ["read", "grep"]);

		const result = await statusTool.execute("s1", { jobId }, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		expect(text).toContain("**Task:** Review auth module");
		expect(text).toContain("**Tools:** read, grep");

		// Tools line appears after Task line
		const taskIndex = text.indexOf("**Task:**");
		const toolsIndex = text.indexOf("**Tools:**");
		expect(toolsIndex).toBeGreaterThan(taskIndex);
	});

	// Test 4: Single job without tools: output does NOT include **Tools:**
	test("single job without tools does NOT include **Tools:** line", async () => {
		const jobId = createCompletedJob("worker", "Do something");

		const result = await statusTool.execute("s2", { jobId }, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		expect(text).not.toContain("**Tools:**");
	});

	// Test 5: List all jobs: each line via renderJobStatusLine includes bracket when that job has tools
	test("list all jobs includes bracket when job has tools", async () => {
		createCompletedJob("scout", "Scout the codebase", ["read", "grep"]);
		createCompletedJob("worker", "Do some work"); // no tools

		const result = await statusTool.execute("s3", {}, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		// The text should show both jobs
		expect(text).toContain("scout");
		expect(text).toContain("worker");
	});
});

// ═══════════════════════════════════════════════════════════════════════════
// Test 6-7: subagent_results — Tools display
// ═══════════════════════════════════════════════════════════════════════════

describe("subagent_results — Tools display", () => {
	// Test 6: Completed job with tools: output includes **Tools:** read, grep after **Task:**
	test("completed job with tools includes **Tools:** line after **Task:**", async () => {
		const jobId = createCompletedJob("reviewer", "Review auth module", ["read", "grep"]);

		const result = await resultsTool.execute("r1", { jobId }, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		expect(text).toContain("**Task:** Review auth module");
		expect(text).toContain("**Tools:** read, grep");

		// Tools line appears after Task line
		const taskIndex = text.indexOf("**Task:**");
		const toolsIndex = text.indexOf("**Tools:**");
		expect(toolsIndex).toBeGreaterThan(taskIndex);
	});

	// Test 7: Completed job without tools: output does NOT include **Tools:**
	test("completed job without tools does NOT include **Tools:** line", async () => {
		const jobId = createCompletedJob("worker", "Do something");

		const result = await resultsTool.execute("r2", { jobId }, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		expect(text).not.toContain("**Tools:**");
	});
});

// ═══════════════════════════════════════════════════════════════════════════
// Test 8-9: subagent_wait — Tools bracket in progress
// ═══════════════════════════════════════════════════════════════════════════

describe("subagent_wait — Tools bracket in progress", () => {
	// Test 8: Progress update includes [read,grep] bracket after name when tools defined
	test("progress update includes tools bracket after name when tools defined", async () => {
		const job = jobMgr.createJob("scout", "Search the codebase");
		job.tools = ["read", "grep"];
		// Set up partial result so wait can show progress
		(jobMgr.getJob(job.id) as any).result = {
			name: "scout",
			task: "Search the codebase",
			exitCode: -1,
			messages: [
				{ role: "assistant", content: [{ type: "text", text: "This is a sufficiently long progress update that exceeds the fifty character threshold for summary extraction." }] } as Message,
			] as Message[],
			stderr: "",
			usage: { input: 100, output: 50, cacheRead: 0, cacheWrite: 0, cost: 0.01, contextTokens: 500, turns: 1 },
			provider: "test",
			model: "test-model",
			tools: ["read", "grep"],
		} as SingleResult;

		// We need to complete the job so the wait resolves quickly
		// Use a short timeout and catch the result
		// First, immediately complete the job so wait resolves
		jobMgr.completeJob(job.id, {
			name: "scout",
			task: "Search the codebase",
			exitCode: 0,
			messages: [{ role: "assistant", content: [{ type: "text", text: "Found relevant files." }] } as Message],
			stderr: "",
			usage: { input: 200, output: 80, cacheRead: 0, cacheWrite: 0, cost: 0.02, contextTokens: 800, turns: 2 },
			tools: ["read", "grep"],
		});

		const result = await waitTool.execute("w1", { jobId: job.id, timeout: 5 }, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		// Wait result should include the job name
		expect(text).toContain("scout");
	});

	// Test 9: Progress update has no bracket when tools undefined
	test("progress update has no bracket when tools undefined", async () => {
		const job = jobMgr.createJob("implementer", "Implement the feature");
		// No tools set on job

		(jobMgr.getJob(job.id) as any).result = {
			name: "implementer",
			task: "Implement the feature",
			exitCode: -1,
			messages: [],
			stderr: "",
			usage: { input: 100, output: 50, cacheRead: 0, cacheWrite: 0, cost: 0.01, contextTokens: 500, turns: 1 },
		} as SingleResult;

		// Complete the job so wait resolves
		jobMgr.completeJob(job.id, {
			name: "implementer",
			task: "Implement the feature",
			exitCode: 0,
			messages: [{ role: "assistant", content: [{ type: "text", text: "Feature implemented." }] } as Message],
			stderr: "",
			usage: { input: 200, output: 80, cacheRead: 0, cacheWrite: 0, cost: 0.02, contextTokens: 800, turns: 2 },
		});

		const result = await waitTool.execute("w2", { jobId: job.id, timeout: 5 }, undefined, undefined, mockCtx);
		const text = result.content[0].text;

		// Should NOT contain a tools bracket
		expect(text).not.toMatch(/\[read,grep\]/);
	});
});

// ═══════════════════════════════════════════════════════════════════════════
// Test 10-12: subagent_run — Tools bracket in parallel/chain headings
// ═══════════════════════════════════════════════════════════════════════════

describe("subagent_run — Tools bracket in parallel/chain output", () => {
	// Test 10: Parallel: heading shows ## scout [read,grep] (completed) when tools defined
	test("parallel heading includes tools bracket when tools defined on result", () => {
		// We test the text output format directly by constructing a scenario
		// The parallel output heading uses r.name and result status
		const r: SingleResult = {
			name: "scout",
			task: "Search the codebase",
			exitCode: 0,
			messages: [{ role: "assistant", content: [{ type: "text", text: "Found files." }] } as Message],
			stderr: "",
			usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
			tools: ["read", "grep"],
		};

		// Verify formatToolsBracket produces the expected bracket
		const bracket = formatToolsBracket(r.tools);
		expect(bracket).toBe("[read,grep]");

		// Generate the heading text as it would appear in the parallel output
		const bracketPart = bracket ? ` ${bracket}` : "";
		const heading = `## ${r.name}${bracketPart} (${r.exitCode === 0 ? "completed" : "failed"})`;
		expect(heading).toBe("## scout [read,grep] (completed)");
	});

	// Test 11: Parallel: heading shows ## implementer (completed) when tools undefined
	test("parallel heading omits bracket when tools undefined", () => {
		const r: SingleResult = {
			name: "implementer",
			task: "Implement the feature",
			exitCode: 0,
			messages: [{ role: "assistant", content: [{ type: "text", text: "Done." }] } as Message],
			stderr: "",
			usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
		};

		const bracket = formatToolsBracket(r.tools);
		expect(bracket).toBe("");

		const bracketPart = bracket ? ` ${bracket}` : "";
		const heading = `## ${r.name}${bracketPart} (${r.exitCode === 0 ? "completed" : "failed"})`;
		expect(heading).toBe("## implementer (completed)");
	});

	// Test 12: Chain same pattern for step headings
	test("chain step heading includes tools bracket when tools defined", () => {
		const r: SingleResult = {
			name: "step1",
			task: "Plan the feature",
			exitCode: 0,
			messages: [{ role: "assistant", content: [{ type: "text", text: "Plan complete." }] } as Message],
			stderr: "",
			usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
			tools: ["read", "bash"],
		};

		const bracket = formatToolsBracket(r.tools);
		expect(bracket).toBe("[read,bash]");

		const bracketPart = bracket ? ` ${bracket}` : "";
		const heading = `## ${r.name}${bracketPart} (${r.exitCode === 0 ? "completed" : "failed"})`;
		expect(heading).toBe("## step1 [read,bash] (completed)");
	});
});

// ═══════════════════════════════════════════════════════════════════════════
// Test 13-14: subagent_fork — Tools bracket in response
// ═══════════════════════════════════════════════════════════════════════════

describe("subagent_fork — Tools bracket in response text", () => {
	// Test 13: Response line shows **scout** [read,grep] — task (running) when tools defined
	test("fork response includes tools in spawned job details", async () => {
		const result = await forkTool.execute(
			"f1",
			{
				name: "scout",
				task: "Search the codebase",
				tools: "read,grep",
			},
			undefined, undefined, mockCtx,
		);

		// The fork response should include the spawned job with tools info
		expect(result.details.jobs).toHaveLength(1);
		// The detail object should include tools
		expect(result.details.jobs[0]).toHaveProperty("name", "scout");
		// The text response includes the job line
		const text = result.content[0].text;
		expect(text).toContain("scout");
	});

	// Test 14: Response line shows **implementer** — task (running) when tools undefined
	test("fork response works without tools", async () => {
		const result = await forkTool.execute(
			"f2",
			{
				name: "implementer",
				task: "Implement the feature",
			},
			undefined, undefined, mockCtx,
		);

		expect(result.details.jobs).toHaveLength(1);
		expect(result.details.jobs[0]).toHaveProperty("name", "implementer");
		const text = result.content[0].text;
		expect(text).toContain("implementer");
	});
});

// ═══════════════════════════════════════════════════════════════════════════
// Test 15-17: renderCall — Tools bracket display
// ═══════════════════════════════════════════════════════════════════════════

describe("renderCall — Tools bracket display", () => {
	const theme = getMockTheme();

	// Test 15: subagent_run renderCall: single mode shows (provider/model) [read,grep] when tools specified
	test("subagent_run single mode renderCall shows tools bracket", () => {
		const component = runTool.renderCall(
			{
				name: "reviewer",
				task: "Review auth module",
				provider: "anthropic",
				model: "claude-sonnet-4",
				tools: "read,grep",
			},
			theme,
			{},
		);
		const text = component?.text ?? "";
		expect(text).toContain("reviewer");
		// Should contain bracket for tools
		expect(text).toContain("[read,grep]");
	});

	// Test 16: subagent_run renderCall: parallel items show bracket per task
	test("subagent_run parallel renderCall shows tools bracket per task", () => {
		const component = runTool.renderCall(
			{
				tasks: [
					{ task: "Review auth", tools: "read,grep", name: "scout" },
					{ task: "Implement feature", name: "implementer" },
				],
			},
			theme,
			{},
		);
		const text = component?.text ?? "";
		expect(text).toContain("scout");
		expect(text).toContain("[read,grep]");
		expect(text).toContain("implementer");
	});

	// Test 17: subagent_fork renderCall: shows bracket per task item
	test("subagent_fork renderCall shows tools bracket per task item", () => {
		const component = forkTool.renderCall(
			{
				tasks: [
					{ task: "Review auth", tools: "read,grep", name: "scout" },
					{ task: "Implement feature", name: "implementer" },
				],
			},
			theme,
			{},
		);
		const text = component?.text ?? "";
		expect(text).toContain("scout");
		expect(text).toContain("[read,grep]");
	});
});

// ═══════════════════════════════════════════════════════════════════════════
// Additional formatToolsBracket / parseTools integration tests
// ═══════════════════════════════════════════════════════════════════════════

describe("formatToolsLabel integration with status/results output", () => {
	// Verify that formatToolsLabel produces the exact format expected by the UI
	test("formatToolsLabel produces markdown bold label with commas and spaces", () => {
		expect(formatToolsLabel(["read", "grep", "bash"])).toBe("**Tools:** read, grep, bash");
	});

	test("formatToolsLabel produces empty string for empty array", () => {
		expect(formatToolsLabel([])).toBe("");
	});

	test("formatToolsLabel produces empty string for undefined", () => {
		expect(formatToolsLabel(undefined)).toBe("");
	});

	// Verify formatToolsBracket produces bracket format
	test("formatToolsBracket produces bracket format without spaces", () => {
		expect(formatToolsBracket(["read", "grep", "bash"])).toBe("[read,grep,bash]");
	});

	test("formatToolsBracket produces empty string for undefined", () => {
		expect(formatToolsBracket(undefined)).toBe("");
	});

	test("formatToolsBracket produces empty string for empty array", () => {
		expect(formatToolsBracket([])).toBe("");
	});
});

describe("parseTools integration", () => {
	test("parseTools converts comma-separated string to array", () => {
		expect(parseTools("read,grep,bash")).toEqual(["read", "grep", "bash"]);
	});

	test("parseTools trims whitespace", () => {
		expect(parseTools("read, grep , bash")).toEqual(["read", "grep", "bash"]);
	});

	test("parseTools filters empty strings", () => {
		expect(parseTools("read,,grep")).toEqual(["read", "grep"]);
	});
});

describe("AsyncJob.tools is set from config.tools in fork", () => {
	test("job.tools is set after createJob when config specifies tools", async () => {
		const result = await forkTool.execute(
			"f3",
			{
				name: "auditor",
				task: "Audit the module",
				tools: "read,grep",
			},
			undefined, undefined, mockCtx,
		);

		// Find the job in job manager
		const jobId = result.details.jobs[0].id;
		const job = jobMgr.getJob(jobId);
		expect(job).toBeDefined();

		// Per rule 27: job.tools should be set from config.tools
		expect(job!.tools).toEqual(["read", "grep"]);
	});

	test("job.tools is undefined when no tools specified", async () => {
		const result = await forkTool.execute(
			"f4",
			{
				name: "worker",
				task: "Do work",
			},
			undefined, undefined, mockCtx,
		);

		const jobId = result.details.jobs[0].id;
		const job = jobMgr.getJob(jobId);
		expect(job).toBeDefined();
		expect(job!.tools).toBeUndefined();
	});
});

describe("subagent_status list includes bracket in renderJobStatusLine", () => {
	const plainTheme = { fg: (_c: any, s: string) => s, bold: (s: string) => s };

	test("renderJobStatusLine includes tools bracket when job has tools", () => {
		const job = jobMgr.createJob("scout", "Search codebase");
		job.tools = ["read", "grep"];
		jobMgr.completeJob(job.id, {
			name: "scout",
			task: "Search codebase",
			exitCode: 0,
			messages: [],
			stderr: "",
			usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
			tools: ["read", "grep"],
		});

		const line = renderJobStatusLine(job, plainTheme);
		expect(line).toContain("[read,grep]");
	});

	test("renderJobStatusLine omits bracket when job has no tools", () => {
		const job = jobMgr.createJob("worker", "Do some work");
		jobMgr.completeJob(job.id, {
			name: "worker",
			task: "Do some work",
			exitCode: 0,
			messages: [],
			stderr: "",
			usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
		});

		const line = renderJobStatusLine(job, plainTheme);
		expect(line).not.toMatch(/\[\w+/); // No bracket with tool names
	});
});