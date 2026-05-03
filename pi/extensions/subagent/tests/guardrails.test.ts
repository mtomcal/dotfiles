/**
 * Guardrails Tests — Unit tests for guardrails.ts
 *
 * Tests cover:
 * - resolveGuardrails: per-call field wins over global defaults
 * - checkGuardrails: threshold breach detection in order maxTurns → maxCost → maxTokens → maxTime
 * - formatGuardrailProgress: usage vs limits formatting
 * - formatGuardrailLine: single guardrail line formatting
 * - readGuardrailDefaults: reading/validating subagentGuardrails from settings.json
 *
 * Spec: specs/subagent-guardrails.md
 */

import { describe, expect, test, vi, beforeEach, afterEach } from "vitest";
import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";

// ─── Import from the module under test ───────────────────────────────
// These imports will fail at parse time until guardrails.ts is created.

import type { Guardrails, UsageStats } from "../guardrails.js";
import {
	resolveGuardrails,
	checkGuardrails,
	formatGuardrailProgress,
	formatGuardrailLine,
	readGuardrailDefaults,
} from "../guardrails.js";

// ─── Mock helpers ─────────────────────────────────────────────────────

function makeTempSettingsJson(content: object | null): string {
	const tmp = path.join(os.tmpdir(), `guardrails-test-${Date.now()}-${Math.random()}.json`);
	if (content !== null) {
		fs.writeFileSync(tmp, JSON.stringify(content), "utf-8");
	}
	return tmp;
}

function removeTempFile(p: string): void {
	try { fs.unlinkSync(p); } catch { /* ignore */ }
}

/** Minimal UsageStats — other fields default to 0 */
function makeUsage(partial: Partial<UsageStats>): UsageStats {
	return {
		input: partial.input ?? 0,
		output: partial.output ?? 0,
		cacheRead: partial.cacheRead ?? 0,
		cacheWrite: partial.cacheWrite ?? 0,
		cost: partial.cost ?? 0,
		contextTokens: partial.contextTokens ?? 0,
		turns: partial.turns ?? 0,
	};
}

// ─── Tests ────────────────────────────────────────────────────────────

describe("resolveGuardrails", () => {
	test("per-call field wins over global default", () => {
		const perCall: Guardrails = { maxTurns: 20 };
		const globalDefaults: Guardrails = { maxTurns: 50, maxCost: 1.00 };
		const result = resolveGuardrails(perCall, globalDefaults);
		expect(result).toEqual({ maxTurns: 20, maxCost: 1.00 });
	});

	test("empty per-call uses global fallback", () => {
		const perCall: Guardrails = {};
		const globalDefaults: Guardrails = { maxTurns: 50 };
		const result = resolveGuardrails(perCall, globalDefaults);
		expect(result).toEqual({ maxTurns: 50 });
	});

	test("undefined per-call falls back to global", () => {
		const result = resolveGuardrails(undefined, { maxTurns: 50 });
		expect(result).toEqual({ maxTurns: 50 });
	});

	test("per-call with no globals returns per-call values", () => {
		const result = resolveGuardrails({ maxTurns: 20 }, null);
		expect(result).toEqual({ maxTurns: 20 });
	});

	test("both undefined returns empty object (all unlimited)", () => {
		const result = resolveGuardrails(undefined, null);
		expect(result).toEqual({});
	});

	test("partial per-call fills in missing from global", () => {
		const perCall: Guardrails = { maxTurns: 20, maxCost: 0.50 };
		const globalDefaults: Guardrails = { maxTurns: 50, maxCost: 1.00, maxTokens: 100000, maxTime: 300 };
		const result = resolveGuardrails(perCall, globalDefaults);
		expect(result).toEqual({ maxTurns: 20, maxCost: 0.50, maxTokens: 100000, maxTime: 300 });
	});

	test("global null with partial per-call returns per-call partial", () => {
		const result = resolveGuardrails({ maxTokens: 200000 }, null);
		expect(result).toEqual({ maxTokens: 200000 });
	});

	test("all four fields resolved correctly", () => {
		const perCall: Guardrails = { maxTurns: 15, maxCost: 0.25 };
		const globalDefaults: Guardrails = { maxTurns: 30, maxCost: 0.50, maxTokens: 500000, maxTime: 600 };
		const result = resolveGuardrails(perCall, globalDefaults);
		expect(result).toEqual({ maxTurns: 15, maxCost: 0.25, maxTokens: 500000, maxTime: 600 });
	});
});

describe("checkGuardrails", () => {
	test("breaches maxTurns", () => {
		const usage = makeUsage({ turns: 26, cost: 0, contextTokens: 0 });
		const guardrails: Guardrails = { maxTurns: 25 };
		const result = checkGuardrails(usage, guardrails, 0);
		expect(result).toEqual({ breached: true, reason: "exceeded maxTurns (25)" });
	});

	test("breaches maxCost", () => {
		const usage = makeUsage({ turns: 10, cost: 0.60 });
		const guardrails: Guardrails = { maxCost: 0.50 };
		const result = checkGuardrails(usage, guardrails, 0);
		expect(result).toEqual({ breached: true, reason: "exceeded maxCost ($0.50)" });
	});

	test("within bounds returns null", () => {
		const usage = makeUsage({ turns: 5, cost: 0, contextTokens: 0 });
		const guardrails: Guardrails = { maxTurns: 10 };
		const result = checkGuardrails(usage, guardrails, 0);
		expect(result).toBeNull();
	});

	test("empty guardrails returns null (no limits)", () => {
		const usage = makeUsage({ turns: 5, cost: 0, contextTokens: 0 });
		const guardrails: Guardrails = {};
		const result = checkGuardrails(usage, guardrails, 0);
		expect(result).toBeNull();
	});

	test("breaches maxTime", () => {
		const usage = makeUsage({ turns: 5, cost: 0, contextTokens: 0 });
		const guardrails: Guardrails = { maxTime: 300 };
		const result = checkGuardrails(usage, guardrails, 310000);
		expect(result).toEqual({ breached: true, reason: "exceeded maxTime (300s)" });
	});

	test("maxTurns checked before maxCost when both breached", () => {
		const usage = makeUsage({ turns: 26, cost: 0.60, contextTokens: 0 });
		const guardrails: Guardrails = { maxTurns: 25, maxCost: 0.50 };
		const result = checkGuardrails(usage, guardrails, 0);
		expect(result).toEqual({ breached: true, reason: "exceeded maxTurns (25)" });
	});

	test("breaches maxTokens", () => {
		const usage = makeUsage({ turns: 5, cost: 0, contextTokens: 250000 });
		const guardrails: Guardrails = { maxTokens: 200000 };
		const result = checkGuardrails(usage, guardrails, 0);
		expect(result).toEqual({ breached: true, reason: "exceeded maxTokens (200000)" });
	});

	test("maxCost checked before maxTokens when both breached", () => {
		const usage = makeUsage({ turns: 5, cost: 0.60, contextTokens: 250000 });
		const guardrails: Guardrails = { maxCost: 0.50, maxTokens: 200000 };
		const result = checkGuardrails(usage, guardrails, 0);
		expect(result).toEqual({ breached: true, reason: "exceeded maxCost ($0.50)" });
	});

	test("maxTokens checked before maxTime when both breached", () => {
		const usage = makeUsage({ turns: 5, cost: 0, contextTokens: 250000 });
		const guardrails: Guardrails = { maxTokens: 200000, maxTime: 300 };
		const result = checkGuardrails(usage, guardrails, 310000);
		expect(result).toEqual({ breached: true, reason: "exceeded maxTokens (200000)" });
	});

	test("exact threshold is within bounds", () => {
		const usage = makeUsage({ turns: 25, cost: 0.50, contextTokens: 200000 });
		const guardrails: Guardrails = { maxTurns: 25, maxCost: 0.50, maxTokens: 200000 };
		const result = checkGuardrails(usage, guardrails, 300000);
		expect(result).toBeNull();
	});

	test("maxTime exactly at threshold is within bounds", () => {
		const usage = makeUsage({ turns: 5, cost: 0, contextTokens: 0 });
		const guardrails: Guardrails = { maxTime: 300 };
		const result = checkGuardrails(usage, guardrails, 300000);
		expect(result).toBeNull();
	});

	test("just over maxTime breaches", () => {
		const usage = makeUsage({ turns: 5, cost: 0, contextTokens: 0 });
		const guardrails: Guardrails = { maxTime: 300 };
		const result = checkGuardrails(usage, guardrails, 300001);
		expect(result).toEqual({ breached: true, reason: "exceeded maxTime (300s)" });
	});

	test("cost with many decimal places breaches correctly", () => {
		const usage = makeUsage({ turns: 5, cost: 0.5001 });
		const guardrails: Guardrails = { maxCost: 0.50 };
		const result = checkGuardrails(usage, guardrails, 0);
		expect(result).toEqual({ breached: true, reason: "exceeded maxCost ($0.50)" });
	});
});

describe("formatGuardrailProgress", () => {
	test("all four dimensions", () => {
		const usage = makeUsage({ turns: 18, cost: 0.32, contextTokens: 84000 });
		const guardrails: Guardrails = { maxTurns: 25, maxCost: 0.50, maxTokens: 200000, maxTime: 300 };
		const result = formatGuardrailProgress(usage, guardrails, 150000);
		expect(result).toBe("18/25T $0.32/$0.50 84k/200k 2m30s/5m");
	});

	test("only turns dimension", () => {
		const usage = makeUsage({ turns: 5, cost: 0.01, contextTokens: 10000 });
		const guardrails: Guardrails = { maxTurns: 20 };
		const result = formatGuardrailProgress(usage, guardrails, 30000);
		expect(result).toBe("5/20T");
	});

	test("undefined guardrails returns empty string", () => {
		const usage = makeUsage({ turns: 3, cost: 0, contextTokens: 5000 });
		const result = formatGuardrailProgress(usage, undefined, 10000);
		expect(result).toBe("");
	});

	test("only turns and cost", () => {
		const usage = makeUsage({ turns: 10, cost: 0.50, contextTokens: 100000 });
		const guardrails: Guardrails = { maxTurns: 10, maxCost: 1.00, maxTokens: 500000 };
		const result = formatGuardrailProgress(usage, guardrails, 120000);
		expect(result).toBe("10/10T $0.50/$1.00 100k/500k");
	});

	test("cost format always shows two decimal places", () => {
		const usage = makeUsage({ turns: 1, cost: 0.05, contextTokens: 0 });
		const guardrails: Guardrails = { maxCost: 1.00 };
		const result = formatGuardrailProgress(usage, guardrails, 0);
		expect(result).toBe("$0.05/$1.00");
	});

	test("tokens under 1000 shown as number", () => {
		const usage = makeUsage({ turns: 1, cost: 0, contextTokens: 500 });
		const guardrails: Guardrails = { maxTokens: 1000 };
		const result = formatGuardrailProgress(usage, guardrails, 0);
		expect(result).toBe("500/1000");
	});

	test("tokens 1k to 10k shown with one decimal", () => {
		const usage = makeUsage({ turns: 1, cost: 0, contextTokens: 9500 });
		const guardrails: Guardrails = { maxTokens: 20000 };
		const result = formatGuardrailProgress(usage, guardrails, 0);
		expect(result).toBe("9.5k/20k");
	});

	test("time under a minute", () => {
		const usage = makeUsage({ turns: 1, cost: 0, contextTokens: 0 });
		const guardrails: Guardrails = { maxTime: 60 };
		const result = formatGuardrailProgress(usage, guardrails, 30000);
		expect(result).toBe("30s/60s");
	});

	test("time exactly at Xm without seconds suffix", () => {
		const usage = makeUsage({ turns: 1, cost: 0, contextTokens: 0 });
		const guardrails: Guardrails = { maxTime: 120 };
		const result = formatGuardrailProgress(usage, guardrails, 60000);
		expect(result).toBe("1m/2m");
	});

	test("time with minutes and seconds elapsed", () => {
		const usage = makeUsage({ turns: 1, cost: 0, contextTokens: 0 });
		const guardrails: Guardrails = { maxTime: 300 };
		const result = formatGuardrailProgress(usage, guardrails, 150000);
		expect(result).toBe("2m30s/5m");
	});

	test("guardrails with all undefined fields returns empty string", () => {
		const usage = makeUsage({ turns: 1, cost: 0, contextTokens: 0 });
		const guardrails: Guardrails = {};
		const result = formatGuardrailProgress(usage, guardrails, 0);
		expect(result).toBe("");
	});
});

describe("formatGuardrailLine", () => {
	test("all four fields", () => {
		const guardrails: Guardrails = { maxTurns: 25, maxCost: 0.50, maxTokens: 200000, maxTime: 300 };
		const result = formatGuardrailLine(guardrails);
		expect(result).toBe("25 turns, $0.50, 200k tokens, 5m");
	});

	test("only turns", () => {
		const guardrails: Guardrails = { maxTurns: 20 };
		const result = formatGuardrailLine(guardrails);
		expect(result).toBe("20 turns");
	});

	test("undefined guardrails returns empty string", () => {
		const result = formatGuardrailLine(undefined);
		expect(result).toBe("");
	});

	test("only cost", () => {
		const guardrails: Guardrails = { maxCost: 1.00 };
		const result = formatGuardrailLine(guardrails);
		expect(result).toBe("$1.00");
	});

	test("turns and cost only", () => {
		const guardrails: Guardrails = { maxTurns: 15, maxCost: 0.75 };
		const result = formatGuardrailLine(guardrails);
		expect(result).toBe("15 turns, $0.75");
	});

	test("tokens only", () => {
		const guardrails: Guardrails = { maxTokens: 500000 };
		const result = formatGuardrailLine(guardrails);
		expect(result).toBe("500k tokens");
	});

	test("time only at Xm", () => {
		const guardrails: Guardrails = { maxTime: 300 };
		const result = formatGuardrailLine(guardrails);
		expect(result).toBe("5m");
	});

	test("time only under a minute", () => {
		const guardrails: Guardrails = { maxTime: 45 };
		const result = formatGuardrailLine(guardrails);
		expect(result).toBe("45s");
	});

	test("time with Xm Ys format", () => {
		const guardrails: Guardrails = { maxTime: 125 };
		const result = formatGuardrailLine(guardrails);
		expect(result).toBe("2m 5s");
	});

	test("empty guardrails object returns empty string", () => {
		const guardrails: Guardrails = {};
		const result = formatGuardrailLine(guardrails);
		expect(result).toBe("");
	});

	test("cost always shows two decimal places", () => {
		const guardrails: Guardrails = { maxCost: 1 };
		const result = formatGuardrailLine(guardrails);
		expect(result).toBe("$1.00");
	});
});

describe("readGuardrailDefaults", () => {
	let warnSpy: ReturnType<typeof vi.spyOn>;

	beforeEach(() => {
		warnSpy = vi.spyOn(console, "warn").mockImplementation(() => {});
	});

	afterEach(() => {
		warnSpy.mockRestore();
	});

	test("valid settings.json with subagentGuardrails returns Guardrails", () => {
		const tmp = makeTempSettingsJson({ subagentGuardrails: { maxTurns: 25, maxCost: 0.50, maxTokens: 200000, maxTime: 300 } });
		try {
			const result = readGuardrailDefaults(tmp);
			expect(result).toEqual({ maxTurns: 25, maxCost: 0.50, maxTokens: 200000, maxTime: 300 });
		} finally {
			removeTempFile(tmp);
		}
	});

	test("settings.json without subagentGuardrails returns null", () => {
		const tmp = makeTempSettingsJson({ someOtherKey: "value" });
		try {
			const result = readGuardrailDefaults(tmp);
			expect(result).toBeNull();
		} finally {
			removeTempFile(tmp);
		}
	});

	test("nonexistent file returns null with console.warn", () => {
		const result = readGuardrailDefaults("/nonexistent/path/settings.json");
		expect(result).toBeNull();
		expect(warnSpy).toHaveBeenCalled();
	});

	test("invalid field types are ignored with warning", () => {
		const tmp = makeTempSettingsJson({ subagentGuardrails: { maxTurns: "fifty", maxCost: 0.50, maxTokens: 200000 } });
		try {
			const result = readGuardrailDefaults(tmp);
			expect(result).toEqual({ maxCost: 0.50, maxTokens: 200000 });
			expect(warnSpy).toHaveBeenCalled();
		} finally {
			removeTempFile(tmp);
		}
	});

	test("empty subagentGuardrails object returns null", () => {
		const tmp = makeTempSettingsJson({ subagentGuardrails: {} });
		try {
			const result = readGuardrailDefaults(tmp);
			expect(result).toBeNull();
		} finally {
			removeTempFile(tmp);
		}
	});

	test("partial valid fields are returned", () => {
		const tmp = makeTempSettingsJson({ subagentGuardrails: { maxTurns: 20, maxCost: "invalid" } });
		try {
			const result = readGuardrailDefaults(tmp);
			expect(result).toEqual({ maxTurns: 20 });
		} finally {
			removeTempFile(tmp);
		}
	});

	test("invalid JSON returns null with warning", () => {
		const tmp = path.join(os.tmpdir(), `guardrails-test-invalid-${Date.now()}.json`);
		fs.writeFileSync(tmp, "not valid json {", "utf-8");
		try {
			const result = readGuardrailDefaults(tmp);
			expect(result).toBeNull();
			expect(warnSpy).toHaveBeenCalled();
		} finally {
			removeTempFile(tmp);
		}
	});

	test("all invalid field types returns null", () => {
		const tmp = makeTempSettingsJson({ subagentGuardrails: { maxTurns: "twenty", maxCost: false } });
		try {
			const result = readGuardrailDefaults(tmp);
			expect(result).toBeNull();
		} finally {
			removeTempFile(tmp);
		}
	});

	test("maxTime field correctly read", () => {
		const tmp = makeTempSettingsJson({ subagentGuardrails: { maxTime: 600 } });
		try {
			const result = readGuardrailDefaults(tmp);
			expect(result).toEqual({ maxTime: 600 });
		} finally {
			removeTempFile(tmp);
		}
	});
});
