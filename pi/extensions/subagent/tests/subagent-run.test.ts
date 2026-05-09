/**
 * Cycle 6+: subagent_run (Blocking) — tests for ad-hoc config.
 */

import { describe, test, expect, vi, beforeAll, afterEach } from "vitest";
import { createMockExtension } from "./extension-helpers.js";

let registeredTools: Map<string, any>;
let mockPi: any;
let runTool: any;
let mockCtx: any;
let jobMgr: any;

beforeAll(async () => {
	const ctx = createMockExtension();
	mockPi = ctx.pi;
	jobMgr = ctx.jobMgr;
	registeredTools = ctx.registeredTools;

	const mod = await import("../index.js");
	mod.default(mockPi);

	runTool = registeredTools.get("subagent_run");

	mockCtx = {
		cwd: "/test",
		hasUI: false,
		signal: undefined,
		ui: { confirm: vi.fn() },
	} as any;
});

afterEach(() => {
	jobMgr.cancelAll();
	for (const job of jobMgr.listJobs()) {
		(jobMgr as any).jobs.delete(job.id);
	}
});

describe("tool registration", () => {
	test("all six tools are registered", () => {
		const names = Array.from(registeredTools.keys());
		expect(names).toContain("subagent_run");
		expect(names).toContain("subagent_fork");
		expect(names).toContain("subagent_status");
		expect(names).toContain("subagent_results");
		expect(names).toContain("subagent_wait");
		expect(names).toContain("subagent_cancel");
	});

	test("subagent_run description mentions systemPrompt and ad-hoc", () => {
		expect(runTool.description).toContain("systemPrompt");
		expect(runTool.description).toContain("ad-hoc");
	});

	test("subagent_run description may mention agent discovery", () => {
		expect(runTool.description).toContain("agent");
	});
});

describe("subagent_run", () => {
	test("runTool is registered as subagent_run", () => {
		expect(runTool).toBeDefined();
		expect(runTool.name).toBe("subagent_run");
	});

	test("returns error when no mode is specified", async () => {
		const result = await runTool.execute("r3", {}, undefined, undefined, mockCtx);
		expect(result.content[0].text).toMatch(/invalid/i);
		expect(result.isError).toBe(true);
	});

	test("no agentScope or confirmProjectAgents params", () => {
		const schema = runTool.parameters;
		expect(schema.properties.agentScope).toBeUndefined();
		expect(schema.properties.confirmProjectAgents).toBeUndefined();
	});

	test("has name, systemPrompt, tools, model, contextFiles, extensions params", () => {
		const schema = runTool.parameters;
		expect(schema.properties.name).toBeDefined();
		expect(schema.properties.systemPrompt).toBeDefined();
		expect(schema.properties.tools).toBeDefined();
		expect(schema.properties.model).toBeDefined();
		expect(schema.properties.contextFiles).toBeDefined();
		expect(schema.properties.extensions).toBeDefined();
	});

	test("has agent param for named agent lookup", () => {
		const schema = runTool.parameters;
		expect(schema.properties.agent).toBeDefined(); // named agent lookup
	});

	test("subagent_fork has promptGuidelines mentioning systemPrompt", () => {
		const forkTool = registeredTools.get("subagent_fork");
		expect(forkTool.promptGuidelines).toBeDefined();
		expect(forkTool.promptGuidelines.length).toBeGreaterThan(0);
		const all = forkTool.promptGuidelines.join(" ");
		expect(all).toContain("systemPrompt");
	});
});
