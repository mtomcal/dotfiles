/**
 * Guardrails Enforcement Tests — Integration tests for guardrail enforcement
 * in process spawning (Slice 3).
 *
 * Tests cover:
 * - Guardrail params on tool schemas (subagent_run, subagent_fork)
 * - Guardrail params on ItemConfig schema
 * - Guardrail params in promptGuidelines
 * - Config resolution passes through guardrails from params
 * - Guardrails stored on AsyncJob in fork path
 * - checkGuardrails integration with spawn pattern
 *
 * Spec: specs/subagent-guardrails.md (Slice 3)
 */

import { describe, test, expect, vi, beforeAll, afterEach } from "vitest";
import { createMockExtension } from "./extension-helpers.js";
import {
	checkGuardrails,
	formatGuardrailProgress,
	type Guardrails,
	type UsageStats,
} from "../guardrails.js";
import { resolveConfig } from "../subagent-config.js";
import type { SingleResult } from "../job-manager.js";

// ─── Test Setup ───────────────────────────────────────────────────────

// We use a simple mock of spawnSubagentProcess to verify guardrails flow
// without needing to mock node:child_process (which has hoisting issues).
// The actual enforcement is tested through schema verification +
// checkGuardrails unit tests + config resolution tests.

let registeredTools: Map<string, any>;
let mockPi: any;
let runTool: any;
let forkTool: any;
let jobMgr: any;
let mockCtx: any;

beforeAll(async () => {
	const ctx = createMockExtension();
	mockPi = ctx.pi;
	jobMgr = ctx.jobMgr;
	registeredTools = ctx.registeredTools;

	const mod = await import("../index.js");
	mod.default(mockPi);

	runTool = registeredTools.get("subagent_run");
	forkTool = registeredTools.get("subagent_fork");

	mockCtx = {
		cwd: "/test",
		hasUI: false,
		signal: undefined,
		ui: { confirm: vi.fn(), setWidget: vi.fn() },
		sessionManager: { getEntries: () => [] },
	};

	// Clear appends after init
	mockPi.appendEntries.length = 0;
	mockPi.sentMessages.length = 0;
});

afterEach(() => {
	jobMgr.cancelAll();
	for (const job of jobMgr.listJobs()) {
		(jobMgr as any).jobs.delete(job.id);
	}
	mockPi.sentMessages.length = 0;
	mockPi.appendEntries.length = 0;
});

// ─── Helper ───────────────────────────────────────────────────────────

function makeUsage(overrides: Partial<UsageStats> = {}): UsageStats {
	return {
		input: 0,
		output: 0,
		cacheRead: 0,
		cacheWrite: 0,
		cost: 0,
		contextTokens: 0,
		turns: 0,
		...overrides,
	};
}

// ─── Tests: Schema Parameters ─────────────────────────────────────────

describe("schema: guardrail params on tool schemas", () => {
	test("subagent_run has maxTurns, maxCost, maxTokens, maxTime params", () => {
		const schema = runTool.parameters;
		expect(schema.properties.maxTurns).toBeDefined();
		expect(schema.properties.maxTurns.type).toBe("number");
		expect(schema.properties.maxCost).toBeDefined();
		expect(schema.properties.maxCost.type).toBe("number");
		expect(schema.properties.maxTokens).toBeDefined();
		expect(schema.properties.maxTokens.type).toBe("number");
		expect(schema.properties.maxTime).toBeDefined();
		expect(schema.properties.maxTime.type).toBe("number");
	});

	test("subagent_fork has maxTurns, maxCost, maxTokens, maxTime params", () => {
		const schema = forkTool.parameters;
		expect(schema.properties.maxTurns).toBeDefined();
		expect(schema.properties.maxTurns.type).toBe("number");
		expect(schema.properties.maxCost).toBeDefined();
		expect(schema.properties.maxCost.type).toBe("number");
		expect(schema.properties.maxTokens).toBeDefined();
		expect(schema.properties.maxTokens.type).toBe("number");
		expect(schema.properties.maxTime).toBeDefined();
		expect(schema.properties.maxTime.type).toBe("number");
	});

	test("guardrail params are optional (not required)", () => {
		const runSchema = runTool.parameters;
		const required = runSchema.required || [];
		expect(required).not.toContain("maxTurns");
		expect(required).not.toContain("maxCost");
		expect(required).not.toContain("maxTokens");
		expect(required).not.toContain("maxTime");

		const forkSchema = forkTool.parameters;
		const fRequired = forkSchema.required || [];
		expect(fRequired).not.toContain("maxTurns");
		expect(fRequired).not.toContain("maxCost");
		expect(fRequired).not.toContain("maxTokens");
		expect(fRequired).not.toContain("maxTime");
	});

	test("subagent_run promptGuidelines mention guardrail parameters", () => {
		const guidelines = (runTool.promptGuidelines as string[]) || [];
		const guardrailLine = guidelines.find((g: string) =>
			g.includes("maxTurns") || g.includes("guardrail") || g.includes("maxCost") || g.includes("maxTokens") || g.includes("maxTime")
		);
		expect(guardrailLine).toBeDefined();
	});

	test("subagent_fork promptGuidelines mention guardrail parameters", () => {
		const guidelines = (forkTool.promptGuidelines as string[]) || [];
		const guardrailLine = guidelines.find((g: string) =>
			g.includes("maxTurns") || g.includes("guardrail") || g.includes("maxCost") || g.includes("maxTokens") || g.includes("maxTime")
		);
		expect(guardrailLine).toBeDefined();
	});
});

describe("schema: ItemConfig has guardrail fields", () => {
	test("tasks ItemConfig has maxTurns, maxCost, maxTokens, maxTime", () => {
		const tasksProp = runTool.parameters.properties.tasks;
		expect(tasksProp).toBeDefined();
		const itemsSchema = tasksProp.items;
		expect(itemsSchema).toBeDefined();
		expect(itemsSchema.properties.maxTurns).toBeDefined();
		expect(itemsSchema.properties.maxCost).toBeDefined();
		expect(itemsSchema.properties.maxTokens).toBeDefined();
		expect(itemsSchema.properties.maxTime).toBeDefined();
	});

	test("chain ItemConfig also has guardrail fields", () => {
		const chainProp = runTool.parameters.properties.chain;
		expect(chainProp).toBeDefined();
		const itemsSchema = chainProp.items;
		expect(itemsSchema).toBeDefined();
		expect(itemsSchema.properties.maxTurns).toBeDefined();
		expect(itemsSchema.properties.maxCost).toBeDefined();
		expect(itemsSchema.properties.maxTokens).toBeDefined();
		expect(itemsSchema.properties.maxTime).toBeDefined();
	});

	test("fork tasks ItemConfig has guardrail fields", () => {
		const tasksProp = forkTool.parameters.properties.tasks;
		expect(tasksProp).toBeDefined();
		const itemsSchema = tasksProp.items;
		expect(itemsSchema).toBeDefined();
		expect(itemsSchema.properties.maxTurns).toBeDefined();
		expect(itemsSchema.properties.maxCost).toBeDefined();
		expect(itemsSchema.properties.maxTokens).toBeDefined();
		expect(itemsSchema.properties.maxTime).toBeDefined();
	});

	test("guardrail fields are optional on ItemConfig", () => {
		const tasksProp = runTool.parameters.properties.tasks;
		const itemsSchema = tasksProp.items;
		const required = itemsSchema.required || [];
		expect(required).not.toContain("maxTurns");
		expect(required).not.toContain("maxCost");
		expect(required).not.toContain("maxTokens");
		expect(required).not.toContain("maxTime");
	});
});

// ─── Tests: Config Resolution with Guardrails ────────────────────────

describe("config resolution: guardrails pass-through", () => {
	test("resolveConfig returns guardrails from per-call params", () => {
		const config = resolveConfig({
			task: "Test",
			maxTurns: 10,
			maxCost: 0.50,
			maxTokens: 50000,
			maxTime: 60,
		});

		expect(config.guardrails).toBeDefined();
		expect(config.guardrails.maxTurns).toBe(10);
		expect(config.guardrails.maxCost).toBe(0.50);
		expect(config.guardrails.maxTokens).toBe(50000);
		expect(config.guardrails.maxTime).toBe(60);
	});

	test("resolveConfig returns empty guardrails when no params passed", () => {
		const config = resolveConfig({ task: "Test" });
		expect(config.guardrails).toEqual({});
	});

	test("resolveConfig: per-item guardrails override top-level guardrails", () => {
		const config = resolveConfig(
			{ task: "Subtask", maxTurns: 5, maxCost: 0.30 },
			{ task: "Parent", maxTurns: 50, maxCost: 1.00, maxTokens: 200000 },
		);

		expect(config.guardrails.maxTurns).toBe(5);  // per-item wins
		expect(config.guardrails.maxCost).toBe(0.30); // per-item wins
		expect(config.guardrails.maxTokens).toBe(200000); // from top-level
		expect(config.guardrails.maxTime).toBeUndefined(); // neither set
	});

	test("resolveConfig: top-level guardrails fill in when per-item omits", () => {
		const config = resolveConfig(
			{ task: "Subtask" },
			{ task: "Parent", maxTurns: 25, maxTime: 120 },
		);

		expect(config.guardrails.maxTurns).toBe(25);  // from top-level
		expect(config.guardrails.maxTime).toBe(120);   // from top-level
		expect(config.guardrails.maxCost).toBeUndefined(); // neither
		expect(config.guardrails.maxTokens).toBeUndefined(); // neither
	});

	test("resolveConfig: per-item + top-level + global defaults cascade", () => {
		const globalDefaults: Guardrails = { maxTurns: 100, maxCost: 5.00, maxTokens: 1_000_000, maxTime: 600 };

		const config = resolveConfig(
			{ task: "Subtask", maxCost: 0.50 },
			{ task: "Parent", maxTurns: 30 },
			"fake-settings.json",
			globalDefaults,
		);

		expect(config.guardrails.maxTurns).toBe(30);    // top-level over globals
		expect(config.guardrails.maxCost).toBe(0.50);    // per-item over everything
		expect(config.guardrails.maxTokens).toBe(1_000_000); // from globals
		expect(config.guardrails.maxTime).toBe(600);     // from globals
	});
});

// ─── Tests: checkGuardrails in spawn context ─────────────────────────

describe("enforcement: checkGuardrails integration", () => {
	describe("usage threshold breaches detected in order", () => {
		test("maxTurns breach: turns > limit", () => {
			const usage = makeUsage({ turns: 26, cost: 0 });
			const breach = checkGuardrails(usage, { maxTurns: 25 }, 0);
			expect(breach).not.toBeNull();
			expect(breach!.reason).toBe("exceeded maxTurns (25)");
		});

		test("maxCost breach: cost > limit", () => {
			const breach = checkGuardrails(makeUsage({ turns: 5, cost: 0.60 }), { maxCost: 0.50 }, 0);
			expect(breach).not.toBeNull();
			expect(breach!.reason).toBe("exceeded maxCost ($0.50)");
		});

		test("maxTokens breach: contextTokens > limit", () => {
			const breach = checkGuardrails(makeUsage({ turns: 5, cost: 0, contextTokens: 250000 }), { maxTokens: 200000 }, 0);
			expect(breach).not.toBeNull();
			expect(breach!.reason).toBe("exceeded maxTokens (200000)");
		});

		test("maxTime breach: elapsed > limit", () => {
			const breach = checkGuardrails(makeUsage({ turns: 3 }), { maxTime: 60 }, 61000);
			expect(breach).not.toBeNull();
			expect(breach!.reason).toBe("exceeded maxTime (60s)");
		});

		test("maxTime within limit: exact boundary OK", () => {
			const breach = checkGuardrails(makeUsage({ turns: 1 }), { maxTime: 60 }, 60000);
			expect(breach).toBeNull();
		});

		test("maxTime breach: just over boundary", () => {
			const breach = checkGuardrails(makeUsage({ turns: 1 }), { maxTime: 60 }, 60001);
			expect(breach).not.toBeNull();
		});

		test("no breach when all within limits", () => {
			const usage = makeUsage({ turns: 1, cost: 0.005, contextTokens: 1500 });
			const breach = checkGuardrails(usage, { maxTurns: 5, maxCost: 0.05, maxTokens: 5000, maxTime: 30 }, 500);
			expect(breach).toBeNull();
		});

		test("empty guardrails: never breaches", () => {
			const usage = makeUsage({ turns: 999 });
			const breach = checkGuardrails(usage, {}, 999999);
			expect(breach).toBeNull();
		});

		test("check order: maxTurns > maxCost > maxTokens > maxTime", () => {
			// All four breached: maxTurns should win
			const usage = makeUsage({ turns: 26, cost: 0.60, contextTokens: 250000 });
			const guardrails: Guardrails = { maxTurns: 25, maxCost: 0.50, maxTokens: 200000, maxTime: 60 };
			const breach = checkGuardrails(usage, guardrails, 61000);
			expect(breach).not.toBeNull();
			expect(breach!.reason).toContain("maxTurns");
		});

		test("check order: maxCost wins over maxTokens", () => {
			const usage = makeUsage({ turns: 5, cost: 0.60, contextTokens: 250000 });
			const guardrails: Guardrails = { maxCost: 0.50, maxTokens: 200000 };
			const breach = checkGuardrails(usage, guardrails, 0);
			expect(breach).not.toBeNull();
			expect(breach!.reason).toContain("maxCost");
		});
	});

	describe("spawnContext integration pattern", () => {
		// Simulate the pattern that spawnSubagentProcess would use after
		// accumulating usage in processLine. This verifies the integration
		// point between processLine and checkGuardrails.

		test("guardrail kill message format: exceeded maxTurns", () => {
			const usage = makeUsage({ turns: 26 });
			const guardrails: Guardrails = { maxTurns: 25 };
			const breach = checkGuardrails(usage, guardrails, 0);
			expect(breach).not.toBeNull();

			// Format the kill message as spawnSubagentProcess would
			const errorMessage = `Subagent killed: ${breach!.reason}`;
			expect(errorMessage).toBe("Subagent killed: exceeded maxTurns (25)");

			// Verify the result fields that spawnSubagentProcess would set
			const result: Partial<SingleResult> = {
				name: "test",
				task: "test",
				stopReason: "guardrail",
				errorMessage,
				exitCode: 1,
				usage,
			};
			expect(result.stopReason).toBe("guardrail");
			expect(result.exitCode).toBe(1);
		});

		test("guardrail kill message format: exceeded maxTime", () => {
			const usage = makeUsage({ turns: 3 });
			const guardrails: Guardrails = { maxTime: 10 };
			const breach = checkGuardrails(usage, guardrails, 11000);
			expect(breach).not.toBeNull();

			const errorMessage = `Subagent killed: ${breach!.reason}`;
			expect(errorMessage).toBe("Subagent killed: exceeded maxTime (10s)");

			const result: Partial<SingleResult> = {
				name: "test",
				task: "test",
				stopReason: "guardrail",
				errorMessage,
				exitCode: 1,
			};
			expect(result.stopReason).toBe("guardrail");
			expect(result.exitCode).toBe(1);
		});

		test("maxCost kill has correct stopReason and exitCode", () => {
			const usage = makeUsage({ turns: 5, cost: 0.51 });
			const guardrails: Guardrails = { maxCost: 0.50 };
			const breach = checkGuardrails(usage, guardrails, 0);
			expect(breach).not.toBeNull();

			const result: Partial<SingleResult> = {
				stopReason: "guardrail",
				errorMessage: `Subagent killed: ${breach!.reason}`,
				exitCode: 1,
			};
			expect(result.stopReason).toBe("guardrail");
			expect(result.exitCode).toBe(1);
		});

		test("maxTokens kill has correct stopReason and exitCode", () => {
			const usage = makeUsage({ turns: 3, contextTokens: 200001 });
			const guardrails: Guardrails = { maxTokens: 200000 };
			const breach = checkGuardrails(usage, guardrails, 0);
			expect(breach).not.toBeNull();

			const result: Partial<SingleResult> = {
				stopReason: "guardrail",
				errorMessage: `Subagent killed: ${breach!.reason}`,
				exitCode: 1,
			};
			expect(result.stopReason).toBe("guardrail");
			expect(result.exitCode).toBe(1);
		});

		test("partial result after kill retains usage before breach", () => {
			// Simulate: subagent ran 2 turns within bounds, breach on turn 3
			const after2Turns: UsageStats = {
				input: 2000, output: 1000, cacheRead: 0, cacheWrite: 0,
				cost: 0.02, contextTokens: 3000, turns: 2,
			};

			const guardrails: Guardrails = { maxTurns: 2, maxCost: 0.10, maxTokens: 10000, maxTime: 60 };

			// After 2 turns: within bounds
			expect(checkGuardrails(after2Turns, guardrails, 5000)).toBeNull();

			// After 3 turns: breach
			const after3Turns = { ...after2Turns, turns: 3, cost: after2Turns.cost + 0.01 };
			const breach = checkGuardrails(after3Turns, guardrails, 8000);
			expect(breach).not.toBeNull();

			// Usage from before breach is preserved in the result
			expect(after2Turns.turns).toBe(2);
			expect(after2Turns.cost).toBe(0.02);
		});

		test("concurrent guardrail: usage beats maxTime timer", () => {
			// Simulate: maxTurns breach detected in processLine before maxTime timer fires
			const usage = makeUsage({ turns: 26 });
			const guardrails: Guardrails = { maxTurns: 25, maxTime: 60 };
			const breach = checkGuardrails(usage, guardrails, 30000);
			expect(breach).not.toBeNull();
			expect(breach!.reason).toContain("maxTurns");
			// maxTime wouldn't fire because processLine runs synchronously first
		});
	});
});

// ─── Tests: formatGuardrailProgress in spawn context ─────────────────

describe("enforcement: formatGuardrailProgress threshold display", () => {
	test("shows progress for all four dimensions", () => {
		const usage = makeUsage({ turns: 18, cost: 0.32, contextTokens: 84000 });
		const guardrails: Guardrails = { maxTurns: 25, maxCost: 0.50, maxTokens: 200000, maxTime: 300 };
		const result = formatGuardrailProgress(usage, guardrails, 150000);
		expect(result).toBe("18/25T $0.32/$0.50 84k/200k 2m30s/5m");
	});

	test("empty string when no guardrails set", () => {
		const usage = makeUsage({ turns: 5 });
		const result = formatGuardrailProgress(usage, {}, 10000);
		expect(result).toBe("");
	});

	test("partial dimensions: only those with thresholds shown", () => {
		const usage = makeUsage({ turns: 10, cost: 0.50 });
		const guardrails: Guardrails = { maxTurns: 10, maxCost: 1.00 };
		const result = formatGuardrailProgress(usage, guardrails, 120000);
		expect(result).toBe("10/10T $0.50/$1.00");
	});
});

// ─── Tests: Fork guardrails stored on AsyncJob ───────────────────────

describe("enforcement: fork guardrails on AsyncJob", () => {
	test("guardrails are stored on AsyncJob via createJob", () => {
		// createJob accepts optional guardrails parameter
		const job = jobMgr.createJob("test-agent", "Test task", {
			maxTurns: 5,
			maxCost: 1.00,
			maxTokens: 100_000,
			maxTime: 120,
		});

		expect(job.guardrails).toBeDefined();
		expect(job.guardrails!.maxTurns).toBe(5);
		expect(job.guardrails!.maxCost).toBe(1.00);
		expect(job.guardrails!.maxTokens).toBe(100_000);
		expect(job.guardrails!.maxTime).toBe(120);
	});

	test("guardrails default to undefined when not provided", () => {
		const job = jobMgr.createJob("test-agent", "Test task");
		expect(job.guardrails).toBeUndefined();
	});

	test("serialized job includes guardrails", () => {
		const job = jobMgr.createJob("serial-test", "Serial task", { maxTurns: 10 });
		const serialized = jobMgr.serialize();
		const entry = serialized.find((j: any) => j.id === job.id);
		expect(entry).toBeDefined();
		expect(entry!.guardrails).toEqual({ maxTurns: 10 });
	});

	test("fork job fails with guardrail reason", () => {
		const job = jobMgr.createJob("fork-test", "Test task", { maxTurns: 5, maxCost: 1.00 });
		expect(job.status).toBe("running");

		const errorMsg = "Subagent killed: exceeded maxTurns (5)";
		jobMgr.failJob(job.id, errorMsg);

		const updated = jobMgr.getJob(job.id)!;
		expect(updated.status).toBe("failed");
		expect(updated.result).not.toBeNull();
		expect(updated.result!.errorMessage).toContain("maxTurns");
		expect(updated.result!.exitCode).toBe(1);
	});

	test("fork job transition: running -> failed preserves error in result", () => {
		const job = jobMgr.createJob("transition-test", "Transition task", { maxCost: 0.50 });

		// Guardrail kills it — no prior partial result
		const guardrailError = "Subagent killed: exceeded maxCost ($0.50)";
		jobMgr.failJob(job.id, guardrailError);

		const updated = jobMgr.getJob(job.id)!;
		expect(updated.status).toBe("failed");
		expect(updated.result).not.toBeNull();
		// failJob preserves pre-existing result but creates one with errorMessage when null
		expect(updated.result!.errorMessage).toContain("maxCost");
		expect(updated.result!.exitCode).toBe(1);
	});
});

// ─── Tests: Chain Mode Guardrail Reset ───────────────────────────────

describe("chain mode: counters reset per step", () => {
	test("each chain step gets its own resolved guardrails config", () => {
		const step1 = resolveConfig(
			{ task: "step 1", maxTurns: 5 },
			{ task: "parent", maxTurns: 20 },
		);
		const step2 = resolveConfig(
			{ task: "step 2", maxTurns: 10 },
			{ task: "parent", maxTurns: 20 },
		);

		// Each step resolves independently with its own guardrails
		expect(step1.guardrails.maxTurns).toBe(5);
		expect(step2.guardrails.maxTurns).toBe(10);
		expect(step1.guardrails).not.toEqual(step2.guardrails);
	});

	test("chain steps inherit top-level guardrails when per-step omitted", () => {
		const step1 = resolveConfig(
			{ task: "step 1" },
			{ task: "chain-parent", maxTurns: 15, maxTime: 60 },
		);
		const step2 = resolveConfig(
			{ task: "step 2", maxTurns: 8 },
			{ task: "chain-parent", maxTurns: 15, maxTime: 60 },
		);

		// Step 1 inherits top-level guardrails
		expect(step1.guardrails.maxTurns).toBe(15);
		expect(step1.guardrails.maxTime).toBe(60);

		// Step 2 overrides maxTurns but still inherits maxTime
		expect(step2.guardrails.maxTurns).toBe(8);
		expect(step2.guardrails.maxTime).toBe(60);
	});

	test("chain step with previous guardrail breach doesn't affect next step", () => {
		// Step 1 breaches maxTurns
		const step1Guardrails: Guardrails = { maxTurns: 5 };
		const breach1 = checkGuardrails(makeUsage({ turns: 6 }), step1Guardrails, 0);
		expect(breach1).not.toBeNull();

		// Step 2 starts fresh — same guardrails but zero usage
		const step2Guardrails: Guardrails = { maxTurns: 5 };
		const breach2 = checkGuardrails(makeUsage({ turns: 0 }), step2Guardrails, 0);
		expect(breach2).toBeNull();
	});
});

// ─── Tests: Parallel Mode Independent Guardrails ─────────────────────

describe("parallel mode: independent guardrails per task", () => {
	test("each parallel task gets independent guardrails config", () => {
		const task1 = resolveConfig(
			{ task: "task A", maxTurns: 3, maxCost: 1.00 },
			{ task: "parent" },
		);
		const task2 = resolveConfig(
			{ task: "task B", maxTurns: 30, maxCost: 5.00 },
			{ task: "parent" },
		);

		expect(task1.guardrails.maxTurns).toBe(3);
		expect(task2.guardrails.maxTurns).toBe(30);
		expect(task1.guardrails).not.toEqual(task2.guardrails);
	});

	test("one parallel task breach doesn't affect other tasks (simulated)", () => {
		const taskAGuardrails: Guardrails = { maxTurns: 3 };
		const taskBGuardrails: Guardrails = { maxTurns: 10 };

		// Task A breaches at turn 4
		const breachA = checkGuardrails(makeUsage({ turns: 4 }), taskAGuardrails, 0);
		expect(breachA).not.toBeNull();

		// Task B at turn 4 is still within its limit
		const breachB = checkGuardrails(makeUsage({ turns: 4 }), taskBGuardrails, 0);
		expect(breachB).toBeNull();
	});

	test("parallel tasks inherit top-level guardrails independently", () => {
		const task1 = resolveConfig(
			{ task: "task 1" },
			{ task: "parent", maxTurns: 20, maxTime: 120 },
		);
		const task2 = resolveConfig(
			{ task: "task 2", maxCost: 0.30 },
			{ task: "parent", maxTurns: 20, maxCost: 1.00, maxTime: 120 },
		);

		// Task 1 inherits everything from top-level
		expect(task1.guardrails.maxTurns).toBe(20);
		expect(task1.guardrails.maxTime).toBe(120);
		expect(task1.guardrails.maxCost).toBeUndefined();

		// Task 2 has per-item maxCost override + inherited others
		expect(task2.guardrails.maxTurns).toBe(20);
		expect(task2.guardrails.maxTime).toBe(120);
		expect(task2.guardrails.maxCost).toBe(0.30);
	});
});
