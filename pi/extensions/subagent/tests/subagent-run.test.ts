/**
 * Cycle 6: subagent_run (Blocking) and tool registration.
 *
 * RED: Tests for subagent_run and verifying all 6 tools are registered.
 */

import { describe, test, expect, beforeAll } from "vitest";
import { createMockExtension } from "./extension-helpers.js";

let registeredTools: Map<string, any>;
let mockPi: any;
let runTool: any;
let mockCtx: any;

beforeAll(async () => {
	const ctx = createMockExtension();
	mockPi = ctx.pi;
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

	test("subagent_run has no async references in description", () => {
		expect(runTool.description).not.toContain("fork");
		expect(runTool.description).not.toContain("background");
	});
});

describe("subagent_run", () => {
	test("is registered as a tool", () => {
		expect(runTool).toBeDefined();
	});

	test("returns error for missing agent", async () => {
		const result = await runTool.execute("r1", { task: "Some task" }, undefined, undefined, mockCtx);
		expect(result.content[0].text).toMatch(/invalid|agent/i);
	});

	test("returns error for unknown agent", async () => {
		const result = await runTool.execute("r2", { agent: "nonexistent-agent", task: "Some task" }, undefined, undefined, mockCtx);
		expect(result.isError).toBe(true);
		expect(result.content[0].text).toContain("nonexistent-agent");
	});

	test("returns error when no mode specified", async () => {
		const result = await runTool.execute("r3", {}, undefined, undefined, mockCtx);
		expect(result.content[0].text).toMatch(/invalid/i);
	});

	test("has valid chain parameter schema", () => {
		// Verify parameters schema includes chain
		const schema = runTool.parameters;
		expect(schema.properties).toHaveProperty("chain");
		expect(schema.properties).toHaveProperty("tasks");
		expect(schema.properties).toHaveProperty("agent");
		expect(schema.properties).toHaveProperty("task");
	});

	test("subagent tool is NOT registered (replaced by subagent_run)", () => {
		expect(registeredTools.has("subagent")).toBe(false);
	});

	test("subagent_fork has promptGuidelines", () => {
		const forkTool = registeredTools.get("subagent_fork");
		expect(forkTool.promptGuidelines).toBeDefined();
		expect(forkTool.promptGuidelines.length).toBeGreaterThan(0);
		expect(forkTool.promptGuidelines[0]).toContain("fork");
	});
});
