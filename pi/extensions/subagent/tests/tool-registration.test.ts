/**
 * Tool Descriptions and Prompt Guidelines — ad-hoc config version.
 */

import { describe, test, expect, beforeAll, vi } from "vitest";
import { createMockExtension } from "./extension-helpers.js";
import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";

let registeredTools: Map<string, any>;
let tmpDir: string;

const TOOL_NAMES = [
	"subagent_run",
	"subagent_fork",
	"subagent_status",
	"subagent_results",
	"subagent_wait",
	"subagent_cancel",
];

beforeAll(async () => {
	// Use a unique temp directory to avoid conflicts with other test fixtures
	tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-subagent-routing-test-"));

	const routingFixture = {
		subagentModelRouting: {
			scout: { description: "Fast codebase recon, return compressed context", model: "deepseek-v4-flash", provider: "ollama-cloud", thinking: "low", rationale: "Flash model for speed" },
			planner: { description: "Read-only analysis and implementation planning", model: "glm-5.1", provider: "ollama-cloud", thinking: "medium", rationale: "Good instruction-following and breadth" },
			reviewer: { description: "Code quality, security, and architecture analysis", model: "deepseek-v4-pro", provider: "ollama-cloud", thinking: "high", rationale: "Deep reasoning required" },
			implementer: { description: "Writing or modifying code autonomously", model: "glm-5.1", provider: "ollama-cloud", thinking: "medium", rationale: "Workhorse model" },
			"expert (1st)": { description: "Deep domain reasoning — delegate hard problems or consult when stuck. Primary expert.", model: "deepseek-v4-pro", provider: "ollama-cloud", thinking: "high", rationale: "Strongest reasoner for deep domain problems" },
			"expert (2nd)": { description: "Expert consultation fallback — same issue, different perspective.", model: "glm-5.1", provider: "ollama-cloud", thinking: "high", rationale: "Different architectural perspective" },
			"expert (3rd)": { description: "Expert consultation fallback — same issue, third architecture.", model: "kimi-k2.6", provider: "opencode-go", thinking: "high", rationale: "Final consultation before user escalation" },
		},
	};
	const settingsPath = path.join(tmpDir, "settings.json");
	fs.writeFileSync(settingsPath, JSON.stringify(routingFixture), "utf-8");

	// Set env var to point extension to the test fixture
	vi.stubEnv("PI_SUBAGENT_SETTINGS_PATH", settingsPath);

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

	test("subagent_run parameters include agent but NOT agentScope, confirmProjectAgents", () => {
		const schema = registeredTools.get("subagent_run")!.parameters;
		expect(schema.properties.agent).toBeDefined();
		expect(schema.properties.agentScope).toBeUndefined();
		expect(schema.properties.confirmProjectAgents).toBeUndefined();
	});

	test("subagent_fork parameters include agent, name, systemPrompt, tasks", () => {
		const schema = registeredTools.get("subagent_fork")!.parameters;
		expect(schema.properties.agent).toBeDefined();
		expect(schema.properties.name).toBeDefined();
		expect(schema.properties.systemPrompt).toBeDefined();
		expect(schema.properties.tasks).toBeDefined();
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
			expect(typeof tool.label).toBe("string");
		}
	});

	describe("routing table injection", () => {
		test("subagent_run description includes subagent model routing section", () => {
			const tool = registeredTools.get("subagent_run")!;
			expect(tool.description).toContain("### Subagent Model Routing");
		});

		test("subagent_run description includes routing table with all 7 categories", () => {
			const tool = registeredTools.get("subagent_run")!;
			expect(tool.description).toContain("| Category | Description | Model | Provider | Thinking | Rationale |");
			expect(tool.description).toContain("| scout |");
			expect(tool.description).toContain("| planner |");
			expect(tool.description).toContain("| reviewer |");
			expect(tool.description).toContain("| implementer |");
			expect(tool.description).toContain("| expert (1st) |");
			expect(tool.description).toContain("| expert (2nd) |");
			expect(tool.description).toContain("| expert (3rd) |");
			});

		test("subagent_run description includes footnote about deviation requiring justification", () => {
			const tool = registeredTools.get("subagent_run")!;
			expect(tool.description).toContain("Deviation requires explicit justification");
		});

		test("subagent_fork description includes subagent model routing section", () => {
			const tool = registeredTools.get("subagent_fork")!;
			expect(tool.description).toContain("### Subagent Model Routing");
		});

		test("subagent_fork description includes routing table with all 7 categories", () => {
			const tool = registeredTools.get("subagent_fork")!;
			expect(tool.description).toContain("| Category | Description | Model | Provider | Thinking | Rationale |");
			expect(tool.description).toContain("| scout |");
			expect(tool.description).toContain("| implementer |");
			expect(tool.description).toContain("| expert (1st) |");
		});

		test("other tool descriptions do NOT include routing section", () => {
			const noRoutingTools = ["subagent_status", "subagent_results", "subagent_wait", "subagent_cancel"];
			for (const name of noRoutingTools) {
				const tool = registeredTools.get(name);
				expect(tool.description).not.toContain("### Subagent Model Routing");
			}
		});

		test("routing table does not include fallback chains — each category maps to exactly one row", () => {
			const tool = registeredTools.get("subagent_run")!;
			// Each category should appear exactly once
			const runLines = tool.description.split("\n");
			const tableRows = runLines.filter((l: string) => l.startsWith("| ") && !l.startsWith("| ---"));
			const categoryCols = tableRows.slice(1).map((l: string) => l.split("|")[1]?.trim()).filter(Boolean);
			expect(new Set(categoryCols).size).toBe(categoryCols.length);
		});

		test("subagent_run description still contains base description text", () => {
			const tool = registeredTools.get("subagent_run")!;
			expect(tool.description).toContain("systemPrompt");
			expect(tool.description).toContain("Blocks until completion");
		});

		test("subagent_fork description still contains base description text", () => {
			const tool = registeredTools.get("subagent_fork")!;
			expect(tool.description).toContain("systemPrompt");
			expect(tool.description).toContain("Returns immediately");
		});
	});
});

import { afterAll } from "vitest";
afterAll(() => {
	if (tmpDir) {
		try {
			const files = fs.readdirSync(tmpDir);
			for (const f of files) fs.unlinkSync(path.join(tmpDir, f));
			fs.rmdirSync(tmpDir);
		} catch { /* ignore */ }
	}
});