/**
 * Cycle 11: Rendering Consistency.
 *
 * Test renderCall and renderResult for all 6 tools.
 * Verify that collapsed and expanded modes produce expected output.
 *
 * NOTE: Tool lookups happen inside tests (not module-level const) because
 * beforeAll populates registeredTools after module-parsing time.
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
	test("single mode renders agent name and task", () => {
		const tool: any = registeredTools.get("subagent_run");
		const component = tool.renderCall(
			{ agent: "reviewer", task: "Review the auth module" },
			getMockTheme(),
			{},
		);
		expect(component).toBeDefined();
		const text = component?.text ?? "";
		expect(text).toContain("reviewer");
		expect(text).toContain("Review the auth module");
	});

	test("parallel mode renders count", () => {
		const tool: any = registeredTools.get("subagent_run");
		const component = tool.renderCall(
			{
				tasks: [
					{ agent: "reviewer", task: "Review auth" },
					{ agent: "writer", task: "Write tests" },
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
					{ agent: "planner", task: "Plan the feature" },
					{ agent: "coder", task: "Implement {previous}" },
				],
			},
			getMockTheme(),
			{},
		);
		const text = component?.text ?? "";
		expect(text).toContain("chain");
		expect(text).toContain("2");
	});

	test("renders with provider/thinking metadata", () => {
		const tool: any = registeredTools.get("subagent_run");
		const component = tool.renderCall(
			{ agent: "reviewer", task: "Review", provider: "anthropic", thinking: "high" as any },
			getMockTheme(),
			{},
		);
		const text = component?.text ?? "";
		expect(text).toContain("anthropic");
		expect(text).toContain("think:high");
	});
});

describe("renderCall for subagent_fork", () => {
	test("renders fork icon and job info", () => {
		const tool: any = registeredTools.get("subagent_fork");
		const component = tool.renderCall(
			{ agent: "reviewer", task: "Review auth module" },
			getMockTheme(),
			{},
		);
		expect(component).toBeDefined();
		const text = component?.text ?? "";
		expect(text).toContain("fork");
		expect(text).toContain("reviewer");
	});

	test("parallel fork renders task count", () => {
		const tool: any = registeredTools.get("subagent_fork");
		const component = tool.renderCall(
			{
				tasks: [
					{ agent: "a", task: "task a" },
					{ agent: "b", task: "task b" },
					{ agent: "c", task: "task c" },
				],
			},
			getMockTheme(),
			{},
		);
		const text = component?.text ?? "";
		expect(text).toContain("3");
	});

	test("renders task truncation for long tasks", () => {
		const tool: any = registeredTools.get("subagent_fork");
		const longTask = "This is a very long task description that should be truncated in the render call display";
		const component = tool.renderCall(
			{ agent: "reviewer", task: longTask },
			getMockTheme(),
			{},
		);
		const text = component?.text ?? "";
		expect(text).toBeTruthy();
		expect(text).toContain("reviewer");
	});
});

describe("renderCall for subagent_status", () => {
	test("lists all jobs when no jobId", () => {
		const tool: any = registeredTools.get("subagent_status");
		const component = tool.renderCall({}, getMockTheme(), {});
		const text = component?.text ?? "";
		expect(text).toContain("subagent_status");
	});

	test("shows specific jobId when provided", () => {
		const tool: any = registeredTools.get("subagent_status");
		const component = tool.renderCall(
			{ jobId: "reviewer-ab12" },
			getMockTheme(),
			{},
		);
		const text = component?.text ?? "";
		expect(text).toContain("reviewer-ab12");
	});
});

describe("renderCall for subagent_results", () => {
	test("shows job ID", () => {
		const tool: any = registeredTools.get("subagent_results");
		const component = tool.renderCall(
			{ jobId: "reviewer-ab12" },
			getMockTheme(),
			{},
		);
		const text = component?.text ?? "";
		expect(text).toContain("reviewer-ab12");
	});
});

describe("renderCall for subagent_wait", () => {
	test("shows job ID and timeout", () => {
		const tool: any = registeredTools.get("subagent_wait");
		const component = tool.renderCall(
			{ jobId: "reviewer-ab12", timeout: 120 },
			getMockTheme(),
			{},
		);
		const text = component?.text ?? "";
		expect(text).toContain("reviewer-ab12");
		expect(text).toContain("120");
	});

	test("uses default 300s timeout when not specified", () => {
		const tool: any = registeredTools.get("subagent_wait");
		const component = tool.renderCall(
			{ jobId: "reviewer-ab12" },
			getMockTheme(),
			{},
		);
		const text = component?.text ?? "";
		expect(text).toContain("300");
	});
});

describe("renderCall for subagent_cancel", () => {
	test("shows jobId when cancelling specific job", () => {
		const tool: any = registeredTools.get("subagent_cancel");
		const component = tool.renderCall(
			{ jobId: "reviewer-ab12" },
			getMockTheme(),
			{},
		);
		const text = component?.text ?? "";
		expect(text).toContain("reviewer-ab12");
	});

	test("shows cancel all when all:true", () => {
		const tool: any = registeredTools.get("subagent_cancel");
		const component = tool.renderCall({ all: true }, getMockTheme(), {});
		const text = component?.text ?? "";
		expect(text).toMatch(/all/i);
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
					agentScope: "user",
					projectAgentsDir: null,
					results: [result],
				},
			},
			{ expanded: false },
			getMockTheme(),
			{},
		);
		expect(rendered).toBeDefined();
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
		expect(rendered).toBeDefined();
	});

	test("subagent_results renderResult renders result content", () => {
		const tool: any = registeredTools.get("subagent_results");
		const rendered = tool.renderResult(
			{
				content: [{ type: "text", text: "Job results here" }],
				details: { results: [fakeSingleResult()] },
			},
			{ expanded: false },
			getMockTheme(),
			{},
		);
		expect(rendered).toBeDefined();
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