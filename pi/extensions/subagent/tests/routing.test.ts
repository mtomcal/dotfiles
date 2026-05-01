/**
 * Routing Table — Tests for reading, formatting, and injecting subagent model routing.
 *
 * Slice 1: readRoutingTable — reads subagentModelRouting from settings.json
 * Slice 2: formatRoutingTable — formats routing entries as markdown
 * Slice 3: buildToolDescription — builds tool description with/without routing table
 * Slice 4: Integration — wiring into tool registration
 */

import { describe, test, expect, vi } from "vitest";
import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import {
	readRoutingTable,
	formatRoutingTable,
	buildToolDescription,
	type RoutingEntry,
} from "../routing.js";

// ─── Helpers ──────────────────────────────────────────────────────────

let tmpDir: string | null = null;

function getMockDir(): string {
	if (!tmpDir) {
		tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-routing-test-"));
	}
	return tmpDir;
}

function writeFixture(name: string, content: string): string {
	const dir = getMockDir();
	const filePath = path.join(dir, name);
	fs.writeFileSync(filePath, content, "utf-8");
	return filePath;
}

import { afterAll } from "vitest";

afterAll(() => {
	if (tmpDir) {
		try {
			for (const f of fs.readdirSync(tmpDir)) {
				fs.unlinkSync(path.join(tmpDir, f));
			}
			fs.rmdirSync(tmpDir);
		} catch { /* ignore cleanup errors */ }
	}
});

// ─── Sample Data ───────────────────────────────────────────────────────

const FULL_ROUTING = {
	subagentModelRouting: {
		scout: {
			description: "Fast codebase recon, return compressed context",
			model: "deepseek-v4-flash",
			provider: "ollama-cloud",
			thinking: "low",
			rationale: "Flash model for speed, low thinking because scouting needs retrieval not reasoning",
		},
		planner: {
			description: "Read-only analysis and implementation planning",
			model: "glm-5.1",
			provider: "ollama-cloud",
			thinking: "medium",
			rationale: "Good instruction-following and breadth, medium thinking balances depth and cost",
		},
		reviewer: {
			description: "Code quality, security, and architecture analysis",
			model: "deepseek-v4-pro",
			provider: "ollama-cloud",
			thinking: "high",
			rationale: "Deep reasoning required for catching subtle bugs and security issues",
		},
		implementer: {
			description: "Writing or modifying code autonomously",
			model: "glm-5.1",
			provider: "ollama-cloud",
			thinking: "medium",
			rationale: "Workhorse model for most implementation tasks, medium thinking balances quality and cost",
		},
		specialist: {
			description: "Deep domain reasoning for the hardest problems — race conditions, complex debugging, security auditing",
			model: "deepseek-v4-pro",
			provider: "ollama-cloud",
			thinking: "high",
			rationale: "Strongest reasoning model for tasks that exceed implementer capability",
		},
	},
};

const PARTIAL_ROUTING = {
	subagentModelRouting: {
		scout: {
			description: "Fast codebase recon",
			model: "fast-model",
			provider: "test-provider",
			thinking: "low",
			rationale: "Speed",
		},
		implementer: {
			description: "Writing code",
			model: "workhorse-model",
			provider: "test-provider",
			thinking: "medium",
			rationale: "Balance",
		},
	},
};

// ═══════════════════════════════════════════════════════════════════════
// Slice 1: readRoutingTable
// ═══════════════════════════════════════════════════════════════════════

describe("readRoutingTable", () => {
	test("reads subagentModelRouting with all 5 categories from a valid settings.json", () => {
		const filePath = writeFixture("full-routing.json", JSON.stringify(FULL_ROUTING));
		const result = readRoutingTable(filePath);
		expect(result).not.toBeNull();
		expect(result).toHaveLength(5);

		// Verify each category is present with correct values
		const categories = result!.map((e) => e.category).sort();
		expect(categories).toEqual(["implementer", "planner", "reviewer", "scout", "specialist"]);

		// Spot-check a few values
		const scout = result!.find((e) => e.category === "scout")!;
		expect(scout.model).toBe("deepseek-v4-flash");
		expect(scout.provider).toBe("ollama-cloud");
		expect(scout.thinking).toBe("low");
		expect(scout.rationale).toContain("Flash model");

		const reviewer = result!.find((e) => e.category === "reviewer")!;
		expect(reviewer.model).toBe("deepseek-v4-pro");
		expect(reviewer.thinking).toBe("high");
	});

	test("returns null when subagentModelRouting key is missing", () => {
		const filePath = writeFixture("no-routing.json", JSON.stringify({ defaultProvider: "test" }));
		const result = readRoutingTable(filePath);
		expect(result).toBeNull();
	});

	test("returns null when settings.json is empty object", () => {
		const filePath = writeFixture("empty.json", JSON.stringify({}));
		const result = readRoutingTable(filePath);
		expect(result).toBeNull();
	});

	test("returns null when subagentModelRouting is present but empty object", () => {
		const filePath = writeFixture("empty-routing.json", JSON.stringify({ subagentModelRouting: {} }));
		const result = readRoutingTable(filePath);
		expect(result).toBeNull();
	});

	test("returns null when subagentModelRouting is null", () => {
		const filePath = writeFixture("null-routing.json", JSON.stringify({ subagentModelRouting: null }));
		const result = readRoutingTable(filePath);
		expect(result).toBeNull();
	});

	test("returns null when subagentModelRouting is an empty array", () => {
		const filePath = writeFixture("array-routing.json", JSON.stringify({ subagentModelRouting: [] }));
		const result = readRoutingTable(filePath);
		expect(result).toBeNull();
	});

	test("returns partial data when only some categories are configured", () => {
		const filePath = writeFixture("partial-routing.json", JSON.stringify(PARTIAL_ROUTING));
		const result = readRoutingTable(filePath);
		expect(result).not.toBeNull();
		expect(result).toHaveLength(2);

		const names = result!.map((e) => e.category).sort();
		expect(names).toEqual(["implementer", "scout"]);

		const scout = result!.find((e) => e.category === "scout")!;
		expect(scout.model).toBe("fast-model");
		expect(scout.thinking).toBe("low");
	});

	test("returns null when settings.json does not exist", () => {
		const result = readRoutingTable("/tmp/nonexistent-settings-xxxx.json");
		expect(result).toBeNull();
	});

	test("returns null when settings.json is malformed JSON", () => {
		const filePath = writeFixture("malformed.json", "{ invalid json }");
		const result = readRoutingTable(filePath);
		expect(result).toBeNull();
	});

	test("returns entries sorted alphabetically by category", () => {
		const filePath = writeFixture("full-routing.json", JSON.stringify(FULL_ROUTING));
		const result = readRoutingTable(filePath);
		expect(result).not.toBeNull();
		// Categories should be sorted: implementer, planner, reviewer, scout, specialist
		for (let i = 1; i < result!.length; i++) {
			expect(result![i - 1].category.localeCompare(result![i].category)).toBeLessThanOrEqual(0);
		}
	});

	test("each entry has all required fields (model, provider, thinking, rationale)", () => {
		const filePath = writeFixture("full-routing.json", JSON.stringify(FULL_ROUTING));
		const result = readRoutingTable(filePath);
		expect(result).not.toBeNull();
		for (const entry of result!) {
			expect(typeof entry.category).toBe("string");
			expect(entry.category.length).toBeGreaterThan(0);
			expect(typeof entry.model).toBe("string");
			expect(entry.model.length).toBeGreaterThan(0);
			expect(typeof entry.provider).toBe("string");
			expect(entry.provider.length).toBeGreaterThan(0);
			expect(typeof entry.thinking).toBe("string");
			expect(["off", "minimal", "low", "medium", "high", "xhigh"]).toContain(entry.thinking);
			expect(typeof entry.rationale).toBe("string");
		}
	});

	test("invalid thinking level defaults to medium", () => {
		const filePath = writeFixture(
			"invalid-thinking.json",
			JSON.stringify({
				subagentModelRouting: {
					test: { model: "m", provider: "p", thinking: "ultra" },
				},
			}),
		);
		const result = readRoutingTable(filePath);
		expect(result).not.toBeNull();
		expect(result![0].thinking).toBe("medium");
	});

	test("non-object entry values are skipped (null, string, array)", () => {
		const filePath = writeFixture(
			"bad-entries.json",
			JSON.stringify({
				subagentModelRouting: {
					valid: { model: "m", provider: "p", thinking: "low" },
					bad_null: null,
					bad_string: "not an object",
					bad_array: [],
				},
			}),
		);
		const result = readRoutingTable(filePath);
		expect(result).not.toBeNull();
		expect(result!.map((e) => e.category)).toEqual(["valid"]);
	});

	test("entry with only model (no provider) is skipped", () => {
		const filePath = writeFixture(
			"model-only.json",
			JSON.stringify({
				subagentModelRouting: {
					modelOnly: { model: "only-model", provider: "", thinking: "medium" },
				},
			}),
		);
		const result = readRoutingTable(filePath);
		expect(result).toBeNull(); // both model and provider required
	});

	test("entry with only provider (no model) is skipped", () => {
		const filePath = writeFixture(
			"provider-only.json",
			JSON.stringify({
				subagentModelRouting: {
					providerOnly: { model: "", provider: "only-provider", thinking: "medium" },
				},
			}),
		);
		const result = readRoutingTable(filePath);
		expect(result).toBeNull(); // both model and provider required
	});

	test("entry missing both model AND provider is skipped", () => {
		const filePath = writeFixture(
			"no-model-provider.json",
			JSON.stringify({
				subagentModelRouting: {
					valid: { model: "m", provider: "p" },
					invalid: { description: "no model or provider", thinking: "medium" },
				},
			}),
		);
		const result = readRoutingTable(filePath);
		expect(result).not.toBeNull();
		expect(result!.map((e) => e.category)).toEqual(["valid"]);
	});

	test("logs warning when subagentModelRouting is absent", () => {
		const warnSpy = vi.spyOn(console, "warn").mockImplementation(() => {});
		const filePath = writeFixture("no-routing.json", JSON.stringify({}));
		const result = readRoutingTable(filePath);
		expect(result).toBeNull();
		expect(warnSpy).toHaveBeenCalledWith(
			expect.stringContaining("subagentModelRouting is absent"),
		);
		warnSpy.mockRestore();
	});

	test("logs warning when subagentModelRouting is present but empty", () => {
		const warnSpy = vi.spyOn(console, "warn").mockImplementation(() => {});
		const filePath = writeFixture("empty-routing.json", JSON.stringify({ subagentModelRouting: {} }));
		const result = readRoutingTable(filePath);
		expect(result).toBeNull();
		expect(warnSpy).toHaveBeenCalledWith(
			expect.stringContaining("present but empty"),
		);
		warnSpy.mockRestore();
	});

	test("logs warning for unknown category names but still accepts them", () => {
		const warnSpy = vi.spyOn(console, "warn").mockImplementation(() => {});
		const filePath = writeFixture(
			"typo-category.json",
			JSON.stringify({
				subagentModelRouting: {
					implmenter: { model: "m", provider: "p", thinking: "medium" },
					valid: { model: "m", provider: "p", thinking: "low" },
				},
			}),
		);
		const result = readRoutingTable(filePath);
		expect(result).not.toBeNull();
		// Unknown category is still included
		expect(result!.map((e) => e.category)).toContain("implmenter");
		expect(warnSpy).toHaveBeenCalledWith(
			expect.stringContaining("unknown routing category"),
		);
		warnSpy.mockRestore();
	});

	test("logs warning when settings file does not exist", () => {
		const warnSpy = vi.spyOn(console, "warn").mockImplementation(() => {});
		const result = readRoutingTable("/tmp/nonexistent-settings-xxxx.json");
		expect(result).toBeNull();
		expect(warnSpy).toHaveBeenCalledWith(
			expect.stringContaining("not found"),
		);
		warnSpy.mockRestore();
	});

	test("logs warning when settings file is not valid JSON", () => {
		const warnSpy = vi.spyOn(console, "warn").mockImplementation(() => {});
		const filePath = writeFixture("malformed.json", "{ invalid json }");
		const result = readRoutingTable(filePath);
		expect(result).toBeNull();
		expect(warnSpy).toHaveBeenCalledWith(
			expect.stringContaining("not valid JSON"),
		);
		warnSpy.mockRestore();
	});

	test("non-string field values are coerced to empty strings", () => {
		const filePath = writeFixture(
			"bad-types.json",
			JSON.stringify({
				subagentModelRouting: {
					bad: {
						model: 123,
						provider: true,
						description: { nested: "object" },
						thinking: ["array"],
						rationale: null,
					},
					valid: { model: "m", provider: "p", thinking: "medium" },
				},
			}),
		);
		const result = readRoutingTable(filePath);
		expect(result).not.toBeNull();
		expect(result!.map((e) => e.category)).toEqual(["valid"]);
	});

	test("non-empty array subagentModelRouting is rejected", () => {
		const filePath = writeFixture(
			"array-routing.json",
			JSON.stringify({
				subagentModelRouting: [{ model: "m", provider: "p" }],
			}),
		);
		const result = readRoutingTable(filePath);
		expect(result).toBeNull();
	});

	test("empty category name is skipped", () => {
		const filePath = writeFixture(
			"empty-category.json",
			JSON.stringify({
				subagentModelRouting: {
					"": { model: "m", provider: "p", thinking: "medium" },
					valid: { model: "m2", provider: "p2", thinking: "medium" },
				},
			}),
		);
		const result = readRoutingTable(filePath);
		expect(result).not.toBeNull();
		expect(result!.map((e) => e.category)).toEqual(["valid"]);
	});

	test("invalid thinking level logs warning and defaults to medium", () => {
		const warnSpy = vi.spyOn(console, "warn").mockImplementation(() => {});
		const filePath = writeFixture(
			"bad-thinking.json",
			JSON.stringify({
				subagentModelRouting: {
					test: { model: "m", provider: "p", thinking: "ultra" },
				},
			}),
		);
		const result = readRoutingTable(filePath);
		expect(result).not.toBeNull();
		expect(result![0].thinking).toBe("medium");
		expect(warnSpy).toHaveBeenCalledWith(
			expect.stringContaining('invalid thinking level "ultra"'),
		);
		warnSpy.mockRestore();
	});
});

// ═══════════════════════════════════════════════════════════════════════
// Slice 2: formatRoutingTable
// ═══════════════════════════════════════════════════════════════════════

describe("formatRoutingTable", () => {
	const SAMPLE_ENTRIES: RoutingEntry[] = [
		{ category: "implementer", description: "Writing or modifying code autonomously", model: "glm-5.1", provider: "ollama-cloud", thinking: "medium", rationale: "Workhorse model for most implementation tasks" },
		{ category: "planner", description: "Read-only analysis and implementation planning", model: "glm-5.1", provider: "ollama-cloud", thinking: "medium", rationale: "Good instruction-following and breadth" },
	];

	test("produces correct markdown table with header and rows", () => {
		const md = formatRoutingTable(SAMPLE_ENTRIES);

		// Has header row
		expect(md).toContain("| Category | Description | Model | Provider | Thinking | Rationale |");
		// Has separator
		expect(md).toContain("|----------|-------------|-------|----------|----------|-----------|");
		// Has data rows
		expect(md).toContain("| implementer |");
		expect(md).toContain("| planner |");
	});

	test("each row has all 6 columns", () => {
		const md = formatRoutingTable(SAMPLE_ENTRIES);
		const lines = md.split("\n");
		// Skip header and separator
		for (let i = 2; i < lines.length; i++) {
			const cells = lines[i].split("|").filter((c) => c.trim().length > 0);
			expect(cells).toHaveLength(6);
		}
	});

	test("returns empty string for empty entries array", () => {
		const md = formatRoutingTable([]);
		expect(md).toBe("");
	});

	test("escapes pipe characters in description", () => {
		const entries: RoutingEntry[] = [
			{ category: "test", description: "Pipe | inside", model: "m", provider: "p", thinking: "medium", rationale: "r" },
		];
		const md = formatRoutingTable(entries);
		expect(md).toContain("Pipe \\| inside");
	});

	test("escapes pipe characters in rationale", () => {
		const entries: RoutingEntry[] = [
			{ category: "test", description: "desc", model: "m", provider: "p", thinking: "medium", rationale: "a | b | c" },
		];
		const md = formatRoutingTable(entries);
		expect(md).toContain("a \\| b \\| c");
	});

	test("escapes pipe characters in category name", () => {
		const entries: RoutingEntry[] = [
			{ category: "weird|name", description: "desc", model: "m", provider: "p", thinking: "medium", rationale: "r" },
		];
		const md = formatRoutingTable(entries);
		expect(md).toContain("weird\\|name");
		// Verify it's not just buried somewhere — check it appears in a table row
		expect(md).toMatch(/^\| weird\\\|name \|/m);
	})

	test("escapes bold/italic markdown in description", () => {
		const entries: RoutingEntry[] = [
			{ category: "test", description: "Use **bold** and *italic* here", model: "m", provider: "p", thinking: "medium", rationale: "r" },
		];
		const md = formatRoutingTable(entries);
		// Bold markers should be escaped so they don't render as markdown
		// Actual output: Use \**bold\** (each * is preceded by a backslash)
		expect(md).toContain("\\*\\*bold\\*\\*");  // JS: \\ = one backslash
	});

	test("escapes inline code markers in rationale", () => {
		const entries: RoutingEntry[] = [
			{ category: "test", description: "d", model: "m", provider: "p", thinking: "medium", rationale: "Use `code` and `more` here" },
		];
		const md = formatRoutingTable(entries);
		expect(md).toContain("\\`code\\`");
	});

	test("escapes brackets in description to prevent link parsing", () => {
		const entries: RoutingEntry[] = [
			{ category: "test", description: "See [docs](https://example.com)", model: "m", provider: "p", thinking: "medium", rationale: "r" },
		];
		const md = formatRoutingTable(entries);
		expect(md).toContain("\\[docs\\]");
	});

	test("replaces newlines with spaces to prevent table row splitting", () => {
		const entries: RoutingEntry[] = [
			{ category: "test", description: "Line 1\nLine 2\r\nLine 3", model: "m", provider: "p", thinking: "medium", rationale: "r" },
		];
		const md = formatRoutingTable(entries);
		// Should not contain raw newlines in the description cell
		expect(md).not.toMatch(/Line 1\nLine 2/);
		expect(md).toContain("Line 1 Line 2 Line 3");
	});

	test("escapes special characters in model field", () => {
		const entries: RoutingEntry[] = [
			{ category: "test", description: "d", model: "model|with|pipes", provider: "p", thinking: "medium", rationale: "r" },
		];
		const md = formatRoutingTable(entries);
		expect(md).toContain("model\\|with\\|pipes");
	});

	test("escapes special characters in provider field", () => {
		const entries: RoutingEntry[] = [
			{ category: "test", description: "d", model: "m", provider: "provider|with|pipes", thinking: "medium", rationale: "r" },
		];
		const md = formatRoutingTable(entries);
		expect(md).toContain("provider\\|with\\|pipes");
	});;

	test("produces deterministic output (same input = same output)", () => {
		const a = formatRoutingTable(SAMPLE_ENTRIES);
		const b = formatRoutingTable(SAMPLE_ENTRIES);
		expect(a).toBe(b);
	});

	test("works with single entry", () => {
		const entries: RoutingEntry[] = [
			{ category: "scout", description: "Fast recon", model: "fast-model", provider: "fast-provider", thinking: "low", rationale: "Speed" },
		];
		const md = formatRoutingTable(entries);
		expect(md).toContain("| scout |");
		expect(md).toContain("fast-model");
		expect(md).toContain("fast-provider");
		expect(md).toContain("low");
	});

	test("validates exact row content in correct column positions", () => {
		// This tests column ordering — if Model/Provider were swapped, this would fail
		const entries: RoutingEntry[] = [
			{ category: "scout", description: "Fast recon", model: "scout-model", provider: "scout-provider", thinking: "low", rationale: "Speed" },
		];
		const md = formatRoutingTable(entries);
		const lines = md.split("\n");
		// Header is line 0, separator is line 1, data row is line 2
		// Find data row: starts with "| ", and is NOT the header, and is NOT the separator
		const dataRow = lines.find((l) => {
			if (!l.startsWith("| ")) return false;
			if (l.includes("| ---")) return false; // separator row
			if (l.includes("Category")) return false; // header row
			return true;
		})!;
		// Parse cells in order: category | description | model | provider | thinking | rationale
		const cells = dataRow.split("|").map((c) => c.trim()).filter((c) => c.length > 0);
		expect(cells[0]).toBe("scout");
		expect(cells[1]).toBe("Fast recon");
		expect(cells[2]).toBe("scout-model");    // Model is 3rd cell
		expect(cells[3]).toBe("scout-provider"); // Provider is 4th cell
		expect(cells[4]).toBe("low");
		expect(cells[5]).toBe("Speed");
	});
});

// ═══════════════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════════
// Slice 3: buildToolDescription
// ═══════════════════════════════════════════════════════════════════════

describe("buildToolDescription", () => {
	const BASE = "Run a subagent synchronously. Provide `systemPrompt` to define the subagent's role.";

	const SAMPLE_ENTRIES: RoutingEntry[] = [
		{ category: "scout", description: "Fast codebase recon", model: "deepseek-v4-flash", provider: "ollama-cloud", thinking: "low", rationale: "Speed" },
		{ category: "implementer", description: "Writing code", model: "glm-5.1", provider: "ollama-cloud", thinking: "medium", rationale: "Workhorse" },
	];

	test("appends routing table header when table is present", () => {
		const desc = buildToolDescription(BASE, SAMPLE_ENTRIES);
		expect(desc).toContain("### Subagent Model Routing");
		expect(desc).toContain("prescribes model/provider/thinking per intent category");
	});

	test("appends the markdown routing table when entries are provided", () => {
		const desc = buildToolDescription(BASE, SAMPLE_ENTRIES);
		expect(desc).toContain("| Category | Description | Model | Provider | Thinking | Rationale |");
		expect(desc).toContain("| scout |");
		expect(desc).toContain("| implementer |");
		expect(desc).toContain("deepseek-v4-flash");
		expect(desc).toContain("glm-5.1");
	});

	test("appends footnote about deviation requiring justification when table is present", () => {
		const desc = buildToolDescription(BASE, SAMPLE_ENTRIES);
		expect(desc).toContain("Deviation requires explicit justification");
	});

	test("appends warning about quality degradation when deviating", () => {
		const desc = buildToolDescription(BASE, SAMPLE_ENTRIES);
		expect(desc).toContain("degrade output quality");
	});

	test("appends fallback note when routing table is null", () => {
		const desc = buildToolDescription(BASE, null);
		expect(desc).toContain("No subagent model routing configured");
		expect(desc).toContain("Using default model and thinking level");
	});

	test("appends fallback note when routing table is empty array", () => {
		const desc = buildToolDescription(BASE, []);
		expect(desc).toContain("No subagent model routing configured");
		expect(desc).toContain("Using default model and thinking level");
	});

	test("does NOT include routing table in fallback case", () => {
		const desc = buildToolDescription(BASE, null);
		expect(desc).not.toContain("### Subagent Model Routing");
		expect(desc).not.toContain("| Category |");
	});

	test("preserves base description in both cases", () => {
		const withRouting = buildToolDescription(BASE, SAMPLE_ENTRIES);
		const withoutRouting = buildToolDescription(BASE, null);
		expect(withRouting).toContain(BASE);
		expect(withoutRouting).toContain(BASE);
	});

	test("base description appears at the beginning", () => {
		const desc = buildToolDescription(BASE, SAMPLE_ENTRIES);
		expect(desc.startsWith(BASE)).toBe(true);
	});

	test("does not modify base description content", () => {
		const withRouting = buildToolDescription(BASE, SAMPLE_ENTRIES);
		const withoutRouting = buildToolDescription(BASE, null);
		const baseInWith = withRouting.slice(0, BASE.length);
		const baseInWithout = withoutRouting.slice(0, BASE.length);
		expect(baseInWith).toBe(BASE);
		expect(baseInWithout).toBe(BASE);
	});
});

// Slice 4: Integration
// ═══════════════════════════════════════════════════════════════════════

describe("integration: readRoutingTable → buildToolDescription", () => {
	test("reads file → builds tool description with routing table", () => {
		const filePath = writeFixture("full-routing.json", JSON.stringify(FULL_ROUTING));
		const table = readRoutingTable(filePath);
		const desc = buildToolDescription("Base.", table);

		expect(desc).toContain("### Subagent Model Routing");
		expect(desc).toContain("deepseek-v4-flash");
		expect(desc).toContain("glm-5.1");
		expect(desc).toContain("deepseek-v4-pro");
		expect(desc).toContain("Deviation requires explicit justification");
		// All 5 categories present
		expect(desc).toContain("| scout |");
		expect(desc).toContain("| planner |");
		expect(desc).toContain("| reviewer |");
		expect(desc).toContain("| implementer |");
		expect(desc).toContain("| specialist |");
	});

	test("reads partial file → builds tool description with partial table", () => {
		const filePath = writeFixture("partial-routing.json", JSON.stringify(PARTIAL_ROUTING));
		const table = readRoutingTable(filePath);
		const desc = buildToolDescription("Base.", table);

		expect(desc).toContain("### Subagent Model Routing");
		expect(desc).toContain("fast-model");
		expect(desc).toContain("workhorse-model");
		// Only 2 categories
		expect(desc).toContain("| scout |");
		expect(desc).toContain("| implementer |");
		expect(desc).not.toContain("| planner |");
		expect(desc).not.toContain("| reviewer |");
		expect(desc).not.toContain("| specialist |");
	});

	test("missing file → builds tool description with fallback note", () => {
		const table = readRoutingTable("/tmp/nonexistent-settings-xxxx.json");
		const desc = buildToolDescription("Base.", table);

		expect(desc).toContain("No subagent model routing configured");
		expect(desc).not.toContain("### Subagent Model Routing");
		// Base description preserved
		expect(desc.startsWith("Base.")).toBe(true);
	});

	test("malformed JSON → builds tool description with fallback note", () => {
		const filePath = writeFixture("malformed.json", "{ invalid json }");
		const table = readRoutingTable(filePath);
		const desc = buildToolDescription("Base.", table);

		expect(desc).toContain("No subagent model routing configured");
		expect(desc).not.toContain("### Subagent Model Routing");
	});

	test("empty routing object → builds tool description with fallback note", () => {
		const filePath = writeFixture("empty-routing.json", JSON.stringify({ subagentModelRouting: {} }));
		const table = readRoutingTable(filePath);
		const desc = buildToolDescription("Base.", table);

		expect(desc).toContain("No subagent model routing configured");
		expect(desc).not.toContain("### Subagent Model Routing");
	});

	test("each category maps to exactly one row (no duplicate rows)", () => {
		const filePath = writeFixture("full-routing.json", JSON.stringify(FULL_ROUTING));
		const table = readRoutingTable(filePath);
		expect(table).not.toBeNull();

		// Count how many times each category appears in the markdown
		const desc = buildToolDescription("Base.", table);
		const lines = desc.split("\n");
		const tableRows = lines.filter((l) => l.startsWith("| ") && !l.startsWith("| ---"));
		const categoryCols = tableRows.slice(1).map((l) => {
			const cells = l.split("|").map((c) => c.trim()).filter(Boolean);
			return cells[0];
		});

		// All categories should be unique (no duplicates)
		expect(new Set(categoryCols).size).toBe(categoryCols.length);
		// And there should be 5 data rows
		expect(categoryCols).toHaveLength(5);
	});
});

// ═══════════════════════════════════════════════════════════════════════
// Slice 5: reloadRoutingTable (hot-reload via /reload-routing command)
// ═══════════════════════════════════════════════════════════════════════

describe("reloadRoutingTable (hot-reload)", () => {
	// Import at runtime so each call gets fresh module-level state
	// Note: we cannot reset the module-level routingTable binding in tests,
	// so we only test the return value and verify the function is callable.

	test("returns 5 entries for full routing fixture", async () => {
		const { reloadRoutingTable } = await import("../routing.js");
		const filePath = writeFixture("reload-full.json", JSON.stringify(FULL_ROUTING));
		const result = reloadRoutingTable(filePath);
		expect(result).not.toBeNull();
		expect(result).toHaveLength(5);
	});

	test("returns null when file not found", async () => {
		const { reloadRoutingTable } = await import("../routing.js");
		const result = reloadRoutingTable("/tmp/nonexistent-reload-test.json");
		expect(result).toBeNull();
	});

	test("accepts explicit path parameter", async () => {
		const { reloadRoutingTable } = await import("../routing.js");
		const filePath = writeFixture("reload-env.json", JSON.stringify(PARTIAL_ROUTING));
		const result = reloadRoutingTable(filePath);
		expect(result).not.toBeNull();
		expect(result).toHaveLength(2);
	});

	test("returns null for empty routing object", async () => {
		const { reloadRoutingTable } = await import("../routing.js");
		const filePath = writeFixture("reload-empty.json", JSON.stringify({ subagentModelRouting: {} }));
		const result = reloadRoutingTable(filePath);
		expect(result).toBeNull();
	});

	test("second reload overwrites first table", async () => {
		const { reloadRoutingTable } = await import("../routing.js");
		const path1 = writeFixture("reload-a.json", JSON.stringify(PARTIAL_ROUTING));
		const path2 = writeFixture("reload-b.json", JSON.stringify({
			subagentModelRouting: {
				planner: { description: "Planning", model: "model-b", provider: "prov-b", thinking: "high", rationale: "R" },
			},
		}));
		const first = reloadRoutingTable(path1);
		expect(first).toHaveLength(2);
		const second = reloadRoutingTable(path2);
		expect(second).toHaveLength(1);
		expect(second![0].category).toBe("planner");
		expect(second![0].model).toBe("model-b");
	});
});