/**
 * Cycle 1: subagent-config — Config resolution, deriveName, parseTools, parseModelField
 */

import { describe, test, expect, vi } from "vitest";
import {
	resolveConfig,
	deriveName,
	parseTools,
	parseModelField,
	buildSpawnArgs,
	BARE_TASK_INJECTION,
} from "../subagent-config.js";
import type { Guardrails } from "../guardrails.js";

describe("resolveConfig guardrails", () => {
	describe("guardrails field on SubagentConfig", () => {
		test("config.guardrails is present as a Guardrails object", () => {
			const config = resolveConfig({ task: "Review" });
			expect(config.guardrails).toBeDefined();
			expect(typeof config.guardrails).toBe("object");
		});

		test("per-call maxTurns wins over global defaults", () => {
			const config = resolveConfig(
				{ task: "Review", maxTurns: 20 },
				undefined,
				"fake-settings.json",
				{ maxTurns: 50, maxCost: 1.00 } as Guardrails,
			);
			expect(config.guardrails.maxTurns).toBe(20);
			expect(config.guardrails.maxCost).toBe(1.00);
		});

		test("per-call maxCost overrides global maxCost, maxTurns from globals", () => {
			const config = resolveConfig(
				{ task: "Review" },
				undefined,
				"fake-settings.json",
				{ maxTurns: 50, maxCost: 1.00 } as Guardrails,
			);
			expect(config.guardrails.maxTurns).toBe(50);
			expect(config.guardrails.maxCost).toBe(1.00);
		});

		test("per-call takes maxCost, top-level takes maxTurns from globals", () => {
			const config = resolveConfig(
				{ task: "Review", maxCost: 0.30 },
				{ maxTurns: 40 },
				"fake-settings.json",
				{ maxTurns: 50, maxCost: 1.00 } as Guardrails,
			);
			expect(config.guardrails.maxTurns).toBe(40); // top-level wins over globals
			expect(config.guardrails.maxCost).toBe(0.30); // per-call wins
		});


		test("null global defaults yields per-call values only", () => {
			const config = resolveConfig(
				{ task: "Review", maxTurns: 20 },
				undefined,
				"fake-settings.json",
				null,
			);
			expect(config.guardrails.maxTurns).toBe(20);
			expect(config.guardrails.maxCost).toBeUndefined();
		});

		test("empty global defaults returns empty guardrails object", () => {
			const config = resolveConfig(
				{ task: "Review" },
				undefined,
				"fake-settings.json",
				null,
			);
			expect(config.guardrails).toEqual({});
		});

		test("per-call wins over top-level wins over globals: maxTurns=10, maxTokens=100000", () => {
			const config = resolveConfig(
				{ task: "Review", maxTurns: 10, maxTokens: 100000 },
				{ maxTurns: 30 },
				"fake-settings.json",
				{ maxTurns: 50, maxTokens: 500000 } as Guardrails,
			);
			expect(config.guardrails.maxTurns).toBe(10); // per-call wins
			expect(config.guardrails.maxTokens).toBe(100000); // per-call wins
			expect(config.guardrails.maxCost).toBeUndefined(); // no default
		});

		test("guardrails field defaults to empty object when no fields set", () => {
			const config = resolveConfig(
				{ task: "Review" },
				undefined,
				"fake-settings.json",
				null,
			);
			expect(config.guardrails).toEqual({});
		});

		test("all four guardrail fields resolved correctly", () => {
			const config = resolveConfig(
				{ task: "Review", maxTurns: 10, maxCost: 0.25 },
				{ maxTime: 300 },
				"fake-settings.json",
				{ maxTurns: 50, maxCost: 1.00, maxTokens: 500000, maxTime: 600 } as Guardrails,
			);
			expect(config.guardrails.maxTurns).toBe(10);
			expect(config.guardrails.maxCost).toBe(0.25);
			expect(config.guardrails.maxTokens).toBe(500000);
			expect(config.guardrails.maxTime).toBe(300);
		});
	});
});

describe("subagent-config", () => {
	describe("resolveConfig", () => {
		test("bare task returns defaults with identity injection", () => {
			const config = resolveConfig({ task: "Review the auth module" });
			expect(config.name).toBe("review");
			expect(config.systemPrompt).toContain("subagent");
			expect(config.systemPrompt).toContain("best judgment");
			expect(config.tools).toBeUndefined(); // all tools = no --tools flag
			expect(config.model).toBeUndefined();
			expect(config.provider).toBeUndefined();
			expect(config.thinking).toBe("medium");
			expect(config.contextFiles).toBe(true);
			expect(config.extensions).toBe(false);
		});

		test("systemPrompt replaces injected identity", () => {
			const config = resolveConfig({
				task: "Review auth",
				systemPrompt: "You are a security auditor.",
			});
			expect(config.systemPrompt).toBe("You are a security auditor.");
			expect(config.systemPrompt).not.toContain("subagent operating");
		});

		test("name defaults to auto-derived from task", () => {
			expect(resolveConfig({ task: "Fix the login bug" }).name).toBe("fix");
			expect(resolveConfig({ task: "Implement the feature" }).name).toBe("implement");
		});

		test("explicit name overrides auto-derive", () => {
			const config = resolveConfig({ task: "Fix bug", name: "bugfixer" });
			expect(config.name).toBe("bugfixer");
		});

		test("short task word falls back to 'task'", () => {
			expect(resolveConfig({ task: "Do the thing" }).name).toBe("task");
			expect(resolveConfig({ task: "" }).name).toBe("task");
		});

		test("model shorthand parses provider and thinking", () => {
			const config = resolveConfig({
				task: "Plan",
				model: "anthropic/claude-sonnet-4-5:high",
			});
			expect(config.model).toBe("claude-sonnet-4-5");
			expect(config.provider).toBe("anthropic");
			expect(config.thinking).toBe("high");
		});

		test("explicit provider overrides shorthand provider", () => {
			const config = resolveConfig({
				task: "Plan",
				model: "anthropic/claude-sonnet-4-5",
				provider: "openai",
			});
			expect(config.provider).toBe("openai");
			expect(config.model).toBe("claude-sonnet-4-5");
		});

		test("explicit thinking overrides shorthand thinking", () => {
			const config = resolveConfig({
				task: "Plan",
				model: "anthropic/claude-sonnet-4-5:high",
				thinking: "low",
			});
			expect(config.thinking).toBe("low");
		});

		test("per-item values override top-level", () => {
			const config = resolveConfig(
				{ task: "Plan", provider: "google", thinking: "high", model: "gemini-2.5-pro" },
				{ task: "Top", provider: "anthropic", thinking: "low", model: "claude-sonnet-4-5" },
			);
			expect(config.provider).toBe("google");
			expect(config.thinking).toBe("high");
			expect(config.model).toBe("gemini-2.5-pro");
		});

		test("top-level values fill in when per-item omitted", () => {
			const config = resolveConfig(
				{ task: "Plan" },
				{ task: "Top", provider: "anthropic", thinking: "high" },
			);
			expect(config.provider).toBe("anthropic");
			expect(config.thinking).toBe("high");
		});

		test("tools string parses to array", () => {
			const config = resolveConfig({ task: "Look", tools: "read, grep, bash" });
			expect(config.tools).toEqual(["read", "grep", "bash"]);
		});

		test("tools omitted = undefined (all tools)", () => {
			const config = resolveConfig({ task: "Look" });
			expect(config.tools).toBeUndefined();
		});

		test("contextFiles defaults to true", () => {
			expect(resolveConfig({ task: "Do it" }).contextFiles).toBe(true);
		});

		test("extensions defaults to false", () => {
			expect(resolveConfig({ task: "Do it" }).extensions).toBe(false);
		});

		test("top-level systemPrompt used when per-item omitted", () => {
			const config = resolveConfig(
				{ task: "Do it" },
				{ task: "Top", systemPrompt: "Top prompt" },
			);
			expect(config.systemPrompt).toBe("Top prompt");
		});

		test("top-level tools used when per-item omitted", () => {
			const config = resolveConfig(
				{ task: "Do it" },
				{ task: "Top", tools: "read,grep" },
			);
			expect(config.tools).toEqual(["read", "grep"]);
		});

		test("per-item tools override top-level tools", () => {
			const config = resolveConfig(
				{ task: "Do it", tools: "write,bash" },
				{ task: "Top", tools: "read,grep" },
			);
			expect(config.tools).toEqual(["write", "bash"]);
		});

		test("per-item contextFiles overrides top-level", () => {
			const config = resolveConfig(
				{ task: "Do it", contextFiles: false },
				{ task: "Top", contextFiles: true },
			);
			expect(config.contextFiles).toBe(false);
		});

		test("per-item extensions overrides top-level", () => {
			const config = resolveConfig(
				{ task: "Do it", extensions: true },
				{ task: "Top", extensions: false },
			);
			expect(config.extensions).toBe(true);
		});
	});

	describe("deriveName", () => {
		test("extracts first significant word from task", () => {
			expect(deriveName("Review the auth module")).toBe("review");
			expect(deriveName("Fix the login bug")).toBe("fix");
		});

		test("lowercases", () => {
			expect(deriveName("IMPLEMENT the feature")).toBe("implement");
		});

		test("preserves hyphens within words", () => {
			expect(deriveName("auto-fix the bug")).toBe("auto-fix");
		});

		test("strips leading non-alpha chars to avoid hyphen-prefixed job IDs", () => {
			expect(deriveName("-fix the bug")).toBe("fix");
			expect(deriveName("#review the code")).toBe("review");
		});

		test("returns 'task' for empty input", () => {
			expect(deriveName("")).toBe("task");
			expect(deriveName("   ")).toBe("task");
		});

		test("returns 'task' for short words", () => {
			expect(deriveName("Do the thing")).toBe("task");
			expect(deriveName("Go fix it")).toBe("task");
		});

		test("returns 'task' when first word becomes empty after stripping", () => {
			expect(deriveName("--- the task")).toBe("task");
		});

		test("truncates long derived names", () => {
			expect(deriveName("comprehensive-architectural-review of the system").length).toBeLessThanOrEqual(20);
		});
	});

	describe("parseTools", () => {
		test("parses comma-separated tools", () => {
			expect(parseTools("read, grep, bash")).toEqual(["read", "grep", "bash"]);
		});

		test("single tool", () => {
			expect(parseTools("read")).toEqual(["read"]);
		});

		test("empty string returns empty array", () => {
			expect(parseTools("")).toEqual([]);
		});

		test("handles extra whitespace and empty elements", () => {
			expect(parseTools("read, , grep")).toEqual(["read", "grep"]);
		});
	});

	describe("parseModelField", () => {
		test("parses provider/model:thinking", () => {
			const result = parseModelField("anthropic/claude-sonnet-4-5:high");
			expect(result.provider).toBe("anthropic");
			expect(result.model).toBe("claude-sonnet-4-5");
			expect(result.thinking).toBe("high");
		});

		test("parses model:thinking without provider", () => {
			const result = parseModelField("claude-sonnet-4-5:high");
			expect(result.provider).toBeUndefined();
			expect(result.model).toBe("claude-sonnet-4-5");
			expect(result.thinking).toBe("high");
		});

		test("parses provider/model without thinking", () => {
			const result = parseModelField("anthropic/claude-sonnet-4-5");
			expect(result.provider).toBe("anthropic");
			expect(result.model).toBe("claude-sonnet-4-5");
			expect(result.thinking).toBeUndefined();
		});

		test("bare model id", () => {
			const result = parseModelField("claude-sonnet-4-5");
			expect(result.provider).toBeUndefined();
			expect(result.model).toBe("claude-sonnet-4-5");
			expect(result.thinking).toBeUndefined();
		});

		test("invalid thinking suffix is kept as part of model name", () => {
			const result = parseModelField("my-model:speed");
			// 'speed' is not a valid thinking level, so the whole string stays as the model
			expect(result.model).toBe("my-model:speed");
			expect(result.thinking).toBeUndefined();
		});
	});

	describe("buildSpawnArgs", () => {
		test("bare task includes injection prompt, --no-skills, --no-session, --no-extensions", () => {
			const config = resolveConfig({ task: "Review auth" });
			const args = buildSpawnArgs(config, config.systemPrompt!);
			expect(args).toContain("--no-session");
			expect(args).toContain("--no-skills");
			expect(args).toContain("--no-extensions");
		});

		test("thinking=medium suppresses --thinking flag", () => {
			const config = resolveConfig({ task: "Do it" }); // default thinking = medium
			const args = buildSpawnArgs(config, "Do it");
			expect(args).not.toContain("--thinking");
		});

		test("thinking=high adds --thinking high", () => {
			const config = resolveConfig({ task: "Do it", thinking: "high" });
			const args = buildSpawnArgs(config, "Do it");
			const idx = args.indexOf("--thinking");
			expect(idx).toBeGreaterThanOrEqual(0);
			expect(args[idx + 1]).toBe("high");
		});

		test("tools specified: --tools flag added with joined values", () => {
			const config = resolveConfig({ task: "Look", tools: "read, grep" });
			const args = buildSpawnArgs(config, "Look");
			const idx = args.indexOf("--tools");
			expect(idx).toBeGreaterThanOrEqual(0);
			expect(args[idx + 1]).toBe("read,grep");
		});

		test("contextFiles=false: --no-context-files added", () => {
			const config = resolveConfig({ task: "Do it", contextFiles: false });
			const args = buildSpawnArgs(config, "Do it");
			expect(args).toContain("--no-context-files");
		});

		test("contextFiles=true (default): no --no-context-files", () => {
			const config = resolveConfig({ task: "Do it" });
			const args = buildSpawnArgs(config, "Do it");
			expect(args).not.toContain("--no-context-files");
		});

		test("extensions=true: no --no-extensions", () => {
			const config = resolveConfig({ task: "Do it", extensions: true });
			const args = buildSpawnArgs(config, "Do it");
			expect(args).not.toContain("--no-extensions");
		});

		test("extensions=false (default): --no-extensions added", () => {
			const config = resolveConfig({ task: "Do it" });
			const args = buildSpawnArgs(config, "Do it");
			expect(args).toContain("--no-extensions");
		});

		test("model and provider passed as CLI flags", () => {
			const config = resolveConfig({ task: "Plan", model: "claude-sonnet-4-5", provider: "anthropic" });
			const args = buildSpawnArgs(config, "Plan");
			expect(args).toContain("--provider");
			expect(args).toContain("anthropic");
			expect(args).toContain("--model");
			expect(args).toContain("claude-sonnet-4-5");
		});
	});
});