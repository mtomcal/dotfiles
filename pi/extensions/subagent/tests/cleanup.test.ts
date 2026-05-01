/**
 * Cycle 9 cleanup: Verify old agents.ts is gone and subagent-config is used.
 */

import { describe, test, expect, beforeAll } from "vitest";
import { createMockExtension } from "./extension-helpers.js";

let registeredTools: Map<string, any>;

beforeAll(async () => {
	const ctx = createMockExtension();
	registeredTools = ctx.registeredTools;

	const mod = await import("../index.js");
	mod.default(ctx.pi);
});

describe("old subagent removal", () => {
	test("'subagent' tool is NOT registered (replaced by subagent_run)", () => {
		expect(registeredTools.has("subagent")).toBe(false);
	});

	test("only the 6 new tools are registered", () => {
		const names = Array.from(registeredTools.keys()).sort();
		const expected = [
			"subagent_cancel",
			"subagent_fork",
			"subagent_results",
			"subagent_run",
			"subagent_status",
			"subagent_wait",
		].sort();
		expect(names).toEqual(expected);
	});
});

describe("subagent-config module", () => {
	test("subagent-config exports resolveConfig", async () => {
		const mod = await import("../subagent-config.js");
		expect(typeof mod.resolveConfig).toBe("function");
	});

	test("subagent-config exports deriveName", async () => {
		const mod = await import("../subagent-config.js");
		expect(typeof mod.deriveName).toBe("function");
	});

	test("subagent-config exports parseModelField", async () => {
		const mod = await import("../subagent-config.js");
		expect(typeof mod.parseModelField).toBe("function");
	});

	test("subagent-config exports parseTools", async () => {
		const mod = await import("../subagent-config.js");
		expect(typeof mod.parseTools).toBe("function");
	});

	test("subagent-config exports normalizeOptional", async () => {
		const mod = await import("../subagent-config.js");
		expect(typeof mod.normalizeOptional).toBe("function");
	});

	test("subagent-config exports buildSpawnArgs", async () => {
		const mod = await import("../subagent-config.js");
		expect(typeof mod.buildSpawnArgs).toBe("function");
	});
});

describe("no agent discovery imports in index.ts", () => {
	test("index.ts does not import from agents.js", async () => {
		const fs = await import("node:fs");
		const content = fs.readFileSync(`${__dirname}/../index.ts`, "utf-8");
		expect(content).not.toContain("from './agents.js'");
	});

	test("index.ts does not reference AgentScope", async () => {
		const fs = await import("node:fs");
		const content = fs.readFileSync(`${__dirname}/../index.ts`, "utf-8");
		expect(content).not.toContain("AgentScope");
	});

	test("index.ts does not reference agentScope", async () => {
		const fs = await import("node:fs");
		const content = fs.readFileSync(`${__dirname}/../index.ts`, "utf-8");
		expect(content).not.toContain("agentScope");
	});

	test("index.ts imports from subagent-config.js", async () => {
		const fs = await import("node:fs");
		const content = fs.readFileSync(`${__dirname}/../index.ts`, "utf-8");
		expect(content).toContain("subagent-config.js");
	});
});