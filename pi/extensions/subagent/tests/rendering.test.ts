/**
 * Rendering Consistency — renderCall and renderResult for all 6 tools.
 * Uses ad-hoc config (name, systemPrompt) instead of agent/agentScope.
 */

import { describe, test, expect, beforeAll } from "vitest";
import { createMockExtension } from "./extension-helpers.js";
import { fakeSingleResult } from "./helpers.js";

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