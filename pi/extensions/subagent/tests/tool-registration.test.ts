/**
 * Cycle 10: Tool Descriptions and Prompt Guidelines.
 *
 * Verify all 6 tools are registered with correct names, descriptions,
 * promptSnippets, and promptGuidelines.
 */

import { describe, test, expect, vi, beforeAll } from "vitest";
import { createMockExtension } from "./extension-helpers.js";

let registeredTools: Map<string, any>;

const TOOL_NAMES = [
	"subagent_run",
	"subagent_fork",
	"subagent_status",
	"subagent_results",
	"subagent_wait",
	"subagent_cancel",
];

beforeAll(async () => {
	const ctx = createMockExtension();
	registeredTools = ctx.registeredTools;

	const mod = await import("../index.js");
	mod.default(ctx.pi);
});

describe("tool registration", () => {
	test("all six tools are registered", () => {
		for (const name of TOOL_NAMES) {
			expect(registeredTools.has(name), `Missing tool: ${name}`).toBe(true);
		}
	});

	test("each tool has name, description, parameters, promptSnippet", () => {
		for (const name of TOOL_NAMES) {
			const tool = registeredTools.get(name);
			expect(tool).toBeDefined();
			expect(typeof tool.name).toBe("string");
			expect(typeof tool.description).toBe("string");
			expect(tool.description.length).toBeGreaterThan(10);
			expect(tool.parameters).toBeDefined();
			expect(typeof tool.promptSnippet).toBe("string");
		}
	});

	test("subagent_run description is blocking-only (no async references)", () => {
		const tool = registeredTools.get("subagent_run")!;
		expect(tool.description).not.toMatch(/fork/i);
		expect(tool.description).not.toMatch(/background/i);
		expect(tool.description).not.toMatch(/notify/i);
	});

	test("subagent_fork description mentions background jobs and max 8", () => {
		const tool = registeredTools.get("subagent_fork")!;
		expect(tool.description).toMatch(/background/i);
		expect(tool.description).toMatch(/8/i);
	});

	test("subagent_fork has promptGuidelines", () => {
		const tool = registeredTools.get("subagent_fork")!;
		expect(tool.promptGuidelines).toBeDefined();
		expect(Array.isArray(tool.promptGuidelines)).toBe(true);
		expect(tool.promptGuidelines.length).toBeGreaterThan(0);
	});

	test("subagent_fork promptGuidelines mention continue and notification", () => {
		const tool = registeredTools.get("subagent_fork")!;
		const all = tool.promptGuidelines.join(" ");
		expect(all).toMatch(/continue/i);
		expect(all).toMatch(/notif/i);
	});

	test("subagent_status promptGuidelines mention polling not required", () => {
		const tool = registeredTools.get("subagent_status")!;
		expect(tool.promptGuidelines).toBeDefined();
		const all = tool.promptGuidelines.join(" ");
		expect(all).toMatch(/poll|notif/i);
	});

	test("subagent_wait promptGuidelines mention timeout default 300s", () => {
		const tool = registeredTools.get("subagent_wait")!;
		expect(tool.promptGuidelines).toBeDefined();
		const all = tool.promptGuidelines.join(" ");
		expect(all).toMatch(/300|5 minute/i);
	});

	test("subagent_cancel promptGuidelines mention all:true and completed cannot be cancelled", () => {
		const tool = registeredTools.get("subagent_cancel")!;
		expect(tool.promptGuidelines).toBeDefined();
		const all = tool.promptGuidelines.join(" ");
		expect(all).toMatch(/all.*true|cancel all/i);
		expect(all).toMatch(/completed/i);
	});

	test("subagent_results promptGuidelines mention completion notification", () => {
		const tool = registeredTools.get("subagent_results")!;
		expect(tool.promptGuidelines).toBeDefined();
		const all = tool.promptGuidelines.join(" ");
		expect(all).toMatch(/notif|summary/i);
	});

	test("subagent_run has no async references in description", () => {
		const tool = registeredTools.get("subagent_run")!;
		const d = tool.description.toLowerCase();
		expect(d).not.toContain("fork");
		expect(d).not.toContain("background");
		expect(d).not.toContain("notification");
	});

	test("each tool has a label", () => {
		for (const name of TOOL_NAMES) {
			const tool = registeredTools.get(name);
			expect(typeof tool.label).toBe("string", `${name} should have a label`);
		}
	});
});