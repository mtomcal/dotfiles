/**
 * Cycle 13: Remove Old subagent, Update agents.ts.
 *
 * Verify the old "subagent" tool is gone and that shared code (agents.ts)
 * still works correctly.
 */

import { describe, test, expect, beforeAll } from "vitest";
import { createMockExtension } from "./extension-helpers.js";
import * as agentsMod from "../agents.js";

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

describe("agents.ts exports still work", () => {
	test("discoverAgents is exported and callable", () => {
		expect(typeof agentsMod.discoverAgents).toBe("function");
	});

	test("parseModelField is exported and callable", () => {
		expect(typeof agentsMod.parseModelField).toBe("function");
	});

	test("parseModelField handles provider/model:thinking format", () => {
		const result = agentsMod.parseModelField("anthropic/claude-3-5-sonnet:high");
		expect(result.provider).toBe("anthropic");
		expect(result.model).toBe("claude-3-5-sonnet");
		expect(result.thinking).toBe("high");
	});

	test("parseModelField handles plain model name", () => {
		const result = agentsMod.parseModelField("claude-3-5-sonnet");
		expect(result.provider).toBeUndefined();
		expect(result.model).toBe("claude-3-5-sonnet");
		expect(result.thinking).toBeUndefined();
	});

	test("parseModelField handles model:thinking without provider", () => {
		const result = agentsMod.parseModelField("claude-3-5-sonnet:medium");
		expect(result.model).toBe("claude-3-5-sonnet");
		expect(result.thinking).toBe("medium");
	});

	test("normalizeOptional returns undefined for empty string", () => {
		expect(agentsMod.normalizeOptional("")).toBeUndefined();
		expect(agentsMod.normalizeOptional("   ")).toBeUndefined();
	});

	test("normalizeOptional returns trimmed value for non-empty", () => {
		expect(agentsMod.normalizeOptional("hello")).toBe("hello");
		expect(agentsMod.normalizeOptional("  openai  ")).toBe("openai");
		expect(agentsMod.normalizeOptional("gemini-2.5-pro")).toBe("gemini-2.5-pro");
	});

	test("formatAgentList returns text and remaining count", () => {
		const result = agentsMod.formatAgentList([], 5);
		expect(result.text).toBe("none");
		expect(result.remaining).toBe(0);
	});
});