/**
 * Rendering Consistency — renderCall and renderResult for all 6 tools.
 * Uses ad-hoc config (name, systemPrompt) instead of agent/agentScope.
 */

import { describe, test, expect, beforeAll } from "vitest";
import { createMockExtension } from "./extension-helpers.js";
import { fakeSingleResult } from "./helpers.js";
import { formatGuardrailLine, type Guardrails } from "../guardrails.js";
import { renderJobStatusLine, renderSingleResult, formatToolsBracket } from "../renderers.js";

let registeredTools: Map<string, any>;

beforeAll(async () => {
	const ctx = createMockExtension();
	registeredTools = ctx.registeredTools;

	const mod = await import("../index.js");
	mod.default(ctx.pi);
});

function getMockTheme() {
	return {
		fg: (color: string, text: string) => text,
		bold: (s: string) => s,
	};
}

describe("formatGuardrailLine", () => {
	const guardrails: Guardrails = { maxTurns: 25, maxCost: 0.50, maxTokens: 200000, maxTime: 300 };

	test("formatGuardrailLine with full guardrails shows guardrail values", () => {
		const result = formatGuardrailLine(guardrails);
		expect(result).toContain("25 turns");
		expect(result).toContain("$0.50");
		expect(result).toContain("tokens");
		expect(result).toContain("5m");
	});

	test("formatGuardrailLine with partial guardrails omits missing fields", () => {
		const partial: Guardrails = { maxTurns: 10, maxCost: 1.00 };
		const result = formatGuardrailLine(partial);
		expect(result).toBe("10 turns, $1.00");
	});

	test("formatGuardrailLine with undefined returns empty string", () => {
		const result = formatGuardrailLine(undefined);
		expect(result).toBe("");
	});

	test("formatGuardrailLine with empty guardrails returns empty string", () => {
		const result = formatGuardrailLine({});
		expect(result).toBe("");
	});
});

describe("renderJobStatusLine", () => {
	function getMockTheme() {
		return {
			fg: (color: string, text: string) => text,
			bold: (s: string) => s,
		};
	}

	test("renderJobStatusLine with a running job that has guardrails shows guardrail progress", () => {
		const job = {
			id: "codegen-a3f2b7",
			name: "codegen",
			task: "Refactor auth module",
			status: "running",
			startedAt: Date.now() - 150000, // 2m30s ago
			completedAt: null,
			tools: ["read", "write", "bash", "edit"],
			guardrails: { maxTurns: 25, maxCost: 0.50 },
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
		};
		const result = renderJobStatusLine(job as any, getMockTheme() as any);
		expect(result).toContain("⏳");
		expect(result).toContain("codegen");
		expect(result).toContain("18/25T");
		expect(result).toContain("$0.32/$0.50");
	});

	test("renderJobStatusLine with a running job that has no guardrails shows no guardrail progress", () => {
		const job = {
			id: "review-def456",
			name: "review",
			task: "Review the code",
			status: "running",
			startedAt: Date.now() - 30000,
			completedAt: null,
			tools: ["read", "grep"],
			result: {
				name: "review",
				task: "Review the code",
				exitCode: 0,
				messages: [],
				stderr: "",
				usage: {
					input: 5000,
					output: 1200,
					cacheRead: 3000,
					cacheWrite: 800,
					cost: 0.0342,
					contextTokens: 6000,
					turns: 3,
				},
			},
		};
		const result = renderJobStatusLine(job as any, getMockTheme() as any);
		expect(result).toContain("⏳");
		expect(result).toContain("review");
		expect(result).not.toContain("/T");
		expect(result).not.toContain("/$");
	});
});

describe("renderSingleResult guardrail stopReason", () => {
	function getMockTheme() {
		return {
			fg: (color: string, text: string) => text,
			bold: (s: string) => s,
		};
	}

	test('renderSingleResult with stopReason: "guardrail" shows [guardrail] tag', () => {
		const result = fakeSingleResult({
			name: "codegen",
			task: "Refactor auth module",
			exitCode: 1,
			stopReason: "guardrail",
			errorMessage: "Subagent killed: exceeded maxTurns (25)",
			usage: { input: 100000, output: 50000, cacheRead: 10000, cacheWrite: 5000, cost: 0.38, contextTokens: 142000, turns: 24 },
		});
		const rendered = renderSingleResult(result, getMockTheme() as any, false);
		const text = (rendered as any).text ?? (typeof rendered === "string" ? rendered : "");
		expect(text).toContain("[guardrail]");
	});

	test('renderSingleResult with stopReason: "guardrail" renders with error styling', () => {
		const result = fakeSingleResult({
			name: "builder",
			task: "Build the project",
			exitCode: 1,
			stopReason: "guardrail",
			errorMessage: "exceeded maxCost ($0.50)",
		});
		const rendered = renderSingleResult(result, getMockTheme() as any, false);
		const text = (rendered as any).text ?? (typeof rendered === "string" ? rendered : "");
		expect(text).toContain("✗");
	});
});

describe("renderCall for subagent_run", () => {
	test("single mode shows name and task", () => {
		const tool: any = registeredTools.get("subagent_run");
		const component = tool.renderCall(
			{ name: "reviewer", task: "Review the auth module" },
			getMockTheme(),
			{},
		);
		const text = component?.text ?? "";
		expect(text).toContain("reviewer");
		expect(text).toContain("Review the auth module");
	});

	test("bare task shows auto-derived name", () => {
		const tool: any = registeredTools.get("subagent_run");
		const component = tool.renderCall(
			{ task: "Fix the login bug" },
			getMockTheme(),
			{},
		);
		const text = component?.text ?? "";
		expect(text).toContain("fix");
	});

	test("parallel mode renders count", () => {
		const tool: any = registeredTools.get("subagent_run");
		const component = tool.renderCall(
			{
				tasks: [
					{ task: "Review auth" },
					{ task: "Write tests" },
				],
			},
			getMockTheme(),
			{},
		);
		const text = component?.text ?? "";
		expect(text).toContain("parallel");
		expect(text).toContain("2");
	});

	test("chain mode renders step count", () => {
		const tool: any = registeredTools.get("subagent_run");
		const component = tool.renderCall(
			{
				chain: [
					{ task: "Plan the feature" },
					{ task: "Implement {previous}" },
				],
			},
			getMockTheme(),
			{},
		);
		const text = component?.text ?? "";
		expect(text).toContain("chain");
		expect(text).toContain("2");
	});

	test("renders with model and provider", () => {
		const tool: any = registeredTools.get("subagent_run");
		const component = tool.renderCall(
			{ task: "Review", model: "claude-sonnet-4-5", provider: "anthropic" },
			getMockTheme(),
			{},
		);
		const text = component?.text ?? "";
		expect(text).toContain("anthropic");
		expect(text).toContain("claude-sonnet-4-5");
	});

	test("no agentSource in any rendering parameters", () => {
		const tool: any = registeredTools.get("subagent_run");
		const schema = tool.parameters;
		expect(schema.properties.agentScope).toBeUndefined();
		expect(schema.properties.confirmProjectAgents).toBeUndefined();
	});
});

describe("renderCall for subagent_fork", () => {
	test("renders fork icon and job info", () => {
		const tool: any = registeredTools.get("subagent_fork");
		const component = tool.renderCall(
			{ task: "Review auth module" },
			getMockTheme(),
			{},
		);
		const text = component?.text ?? "";
		expect(text).toContain("fork");
		// Auto-derived name from task
		expect(text).toContain("review");
	});

	test("parallel fork renders task count", () => {
		const tool: any = registeredTools.get("subagent_fork");
		const component = tool.renderCall(
			{
				tasks: [
					{ task: "task a" },
					{ task: "task b" },
					{ task: "task c" },
				],
			},
			getMockTheme(),
			{},
		);
		const text = component?.text ?? "";
		expect(text).toContain("3");
	});
});

describe("renderCall for status/results/wait/cancel", () => {
	test("subagent_status: lists all jobs when no jobId", () => {
		const tool: any = registeredTools.get("subagent_status");
		const component = tool.renderCall({}, getMockTheme(), {});
		expect(component?.text).toContain("subagent_status");
	});

	test("subagent_status: shows specific jobId", () => {
		const tool: any = registeredTools.get("subagent_status");
		const component = tool.renderCall({ jobId: "reviewer-ab12" }, getMockTheme(), {});
		expect(component?.text).toContain("reviewer-ab12");
	});

	test("subagent_results: shows job ID", () => {
		const tool: any = registeredTools.get("subagent_results");
		const component = tool.renderCall({ jobId: "reviewer-ab12" }, getMockTheme(), {});
		expect(component?.text).toContain("reviewer-ab12");
	});

	test("subagent_wait: shows job ID and timeout", () => {
		const tool: any = registeredTools.get("subagent_wait");
		const component = tool.renderCall({ jobId: "reviewer-ab12", timeout: 120 }, getMockTheme(), {});
		expect(component?.text).toContain("reviewer-ab12");
		expect(component?.text).toContain("120");
	});

	test("subagent_cancel: shows jobId when cancelling specific job", () => {
		const tool: any = registeredTools.get("subagent_cancel");
		const component = tool.renderCall({ jobId: "reviewer-ab12" }, getMockTheme(), {});
		expect(component?.text).toContain("reviewer-ab12");
	});

	test("subagent_cancel: shows cancel all", () => {
		const tool: any = registeredTools.get("subagent_cancel");
		const component = tool.renderCall({ all: true }, getMockTheme(), {});
		expect(component?.text).toMatch(/all/i);
	});
});

describe("renderResult", () => {
	test("subagent_run renderResult produces output for completed single result", () => {
		const tool: any = registeredTools.get("subagent_run");
		const result = fakeSingleResult({ exitCode: 0 });
		const rendered = tool.renderResult(
			{
				content: [{ type: "text", text: "Done" }],
				details: {
					mode: "single",
					results: [result],
				},
			},
			{ expanded: false },
			getMockTheme(),
			{},
		);
		const text = rendered?.text ?? "";
		expect(text).toContain("reviewer");
		// No agentSource tag
		expect(text).not.toContain("(user)");
		expect(text).not.toContain("(project)");
	});

	test("subagent_status renderResult handles empty status", () => {
		const tool: any = registeredTools.get("subagent_status");
		const rendered = tool.renderResult(
			{
				content: [{ type: "text", text: "No subagent jobs." }],
				details: { jobs: [], running: 0, total: 0 },
			},
			{ expanded: false },
			getMockTheme(),
			{},
		);
		const text = rendered?.text ?? "";
		expect(text).toMatch(/no subagent|0/i);
	});

	test("subagent_fork renderResult shows fork prefix", () => {
		const tool: any = registeredTools.get("subagent_fork");
		const rendered = tool.renderResult(
			{
				content: [{ type: "text", text: "Forked 1 job" }],
				details: { jobs: [] },
			},
			{ expanded: false },
			getMockTheme(),
			{},
		);
		const text = rendered?.text ?? "";
		expect(text).toContain("1 job");
	});
});