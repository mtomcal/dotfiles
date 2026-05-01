/**
 * Tool Descriptions and Prompt Guidelines — ad-hoc config version.
 */

import { describe, test, expect, beforeAll } from "vitest";
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

	test("subagent_run description mentions systemPrompt and ad-hoc", () => {
		const tool = registeredTools.get("subagent_run")!;
		expect(tool.description).toContain("systemPrompt");
		expect(tool.description).toContain("ad-hoc");
	});

	test("subagent_run does NOT mention agent files or agent discovery", () => {
		const tool = registeredTools.get("subagent_run")!;
		expect(tool.description).not.toContain("agent file");
		expect(tool.description).not.toContain("discover");
	});

	test("subagent_run parameters include name, systemPrompt, tools, model", () => {
		const schema = registeredTools.get("subagent_run")!.parameters;
		expect(schema.properties.name).toBeDefined();
		expect(schema.properties.systemPrompt).toBeDefined();
		expect(schema.properties.tools).toBeDefined();
		expect(schema.properties.model).toBeDefined();
		expect(schema.properties.contextFiles).toBeDefined();
		expect(schema.properties.extensions).toBeDefined();
	});

	test("subagent_run parameters do NOT include agent, agentScope, confirmProjectAgents", () => {
		const schema = registeredTools.get("subagent_run")!.parameters;
		expect(schema.properties.agent).toBeUndefined();
		expect(schema.properties.agentScope).toBeUndefined();
		expect(schema.properties.confirmProjectAgents).toBeUndefined();
	});

	test("subagent_fork parameters include name, systemPrompt, tasks", () => {
		const schema = registeredTools.get("subagent_fork")!.parameters;
		expect(schema.properties.name).toBeDefined();
		expect(schema.properties.systemPrompt).toBeDefined();
		expect(schema.properties.tasks).toBeDefined();
	});

	test("subagent_fork parameters do NOT include agent, agentScope", () => {
		const schema = registeredTools.get("subagent_fork")!.parameters;
		expect(schema.properties.agent).toBeUndefined();
		expect(schema.properties.agentScope).toBeUndefined();
	});

	test("promptGuidelines teach the primary path", () => {
		const tool = registeredTools.get("subagent_run")!;
		const guidelines = tool.promptGuidelines.join(" ");
		expect(guidelines).toContain("systemPrompt");
		expect(guidelines).toContain("isolated context");
	});

	test("subagent_fork promptGuidelines mention systemPrompt and continue", () => {
		const tool = registeredTools.get("subagent_fork")!;
		const all = tool.promptGuidelines.join(" ");
		expect(all).toContain("systemPrompt");
		expect(all).toMatch(/continue|notif/i);
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

	test("each tool has a label", () => {
		for (const name of TOOL_NAMES) {
			const tool = registeredTools.get(name);
			expect(typeof tool.label).toBe("string", `${name} should have a label`);
		}
	});
});