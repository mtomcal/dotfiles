/**
 * Slice 2: Formatting Utilities — formatToolsBracket and formatToolsLabel
 *
 * Tests the bracket and label formatting utilities for subagent tools display
 * per AIAGT v1.4.0 rules 21–23, 25.
 *
 * Rule 21: tools displayed as comma-separated bracket [t1,t2,...] when defined; omitted when undefined
 * Rule 22: bracket convention uses [] for tool scope, () for model config — distinct visual delimiters
 * Rule 23: truncation at 30 chars with +N overflow: [read,write,bash,edit,grep,find +1]
 * Rule 25: tools must NOT appear on notifications, widget line 2, widget header
 */

import { describe, test, expect } from "vitest";
import { formatToolsBracket, formatToolsLabel, SUBAGENT_TOOLS_BRACKET_MAX_CHARS } from "../renderers.js";

describe("SUBAGENT_TOOLS_BRACKET_MAX_CHARS constant", () => {
	// Assertion 13: Constant SUBAGENT_TOOLS_BRACKET_MAX_CHARS is 30
	test("constant value is 30", () => {
		expect(SUBAGENT_TOOLS_BRACKET_MAX_CHARS).toBe(30);
	});
});

describe("formatToolsBracket", () => {
	// Assertion 1: formatToolsBracket(["read", "grep"]) returns "[read,grep]" (no spaces in bracket)
	test("formats two tools without spaces", () => {
		expect(formatToolsBracket(["read", "grep"])).toBe("[read,grep]");
	});

	// Assertion 2: formatToolsBracket(undefined) returns "" (empty string)
	test("returns empty string for undefined", () => {
		expect(formatToolsBracket(undefined)).toBe("");
	});

	// Assertion 3: formatToolsBracket([]) returns "" (empty array = omitted)
	test("returns empty string for empty array", () => {
		expect(formatToolsBracket([])).toBe("");
	});

	// Assertion 5: formatToolsBracket(["bash"]) returns "[bash]" (single tool)
	test("formats single tool", () => {
		expect(formatToolsBracket(["bash"])).toBe("[bash]");
	});

	// Assertion 4: formatToolsBracket with 7 tools returns truncated
	test("truncates at 30 chars with overflow count", () => {
		// 7 tools: read,write,bash,edit,grep,find,ls
		// Greedy: include tools while the full result (with overflow suffix) fits ≤ 30
		// - 5 tools: "[read,write,bash,edit,grep] +2]" = 29 chars ≤ 30, include grep
		// - 6 tools: "[read,write,bash,edit,grep,find] +1]" = 31 chars > 30, backtrack
		// - Result: "[read,write,bash,edit,grep] +2]" = 29 chars (after backtrack)
		expect(formatToolsBracket(["read", "write", "bash", "edit", "grep", "find", "ls"])).toBe(
			"[read,write,bash,edit,grep +2]",
		);
	});

	// Assertion 6: formatToolsBracket(["a", "b", "c", "d", "e"]) stays under 30 chars
	test("short tool names stay under 30 chars", () => {
		const result = formatToolsBracket(["a", "b", "c", "d", "e"]);
		expect(result).toBe("[a,b,c,d,e]");
		expect(result.length).toBeLessThanOrEqual(30);
	});

	// Assertion 7: single long tool name under 30 chars
	test("long tool name under 30 chars stays as-is", () => {
		expect(formatToolsBracket(["subagent_run"])).toBe("[subagent_run]");
	});

	// Assertion 8: tool name that pushes past 30 triggers truncation
	test("long tool names trigger truncation", () => {
		// "subagent_run" alone is 15 chars: "[subagent_run]"
		// Adding more tools should truncate
		const tools = ["subagent_run", "subagent_fork", "subagent_status", "subagent_results", "subagent_wait", "subagent_cancel"];
		const result = formatToolsBracket(tools);
		// Full bracket would be: "[subagent_run,subagent_fork,...]" = 84 chars
		// Should truncate and include overflow
		expect(result).toMatch(/^\[subagent_run/);
		expect(result).toMatch(/\+\d+\]$/);
		// The result with overflow should be ≤ 30 chars
		// "[subagent_run]" + " +5]" = 15 + 5 = 20 chars
		expect(result.length).toBeLessThanOrEqual(30);
	});
});

describe("formatToolsLabel", () => {
	// Assertion 9: formatToolsLabel(["read", "grep"]) returns "**Tools:** read, grep" (markdown with spaces)
	test("formats tools as markdown with spaces", () => {
		expect(formatToolsLabel(["read", "grep"])).toBe("**Tools:** read, grep");
	});

	// Assertion 10: formatToolsLabel(undefined) returns "" (empty string)
	test("returns empty string for undefined", () => {
		expect(formatToolsLabel(undefined)).toBe("");
	});

	// Assertion 11: formatToolsLabel([]) returns "" (empty array)
	test("returns empty string for empty array", () => {
		expect(formatToolsLabel([])).toBe("");
	});

	// Assertion 12: formatToolsLabel with 3 tools returns full list without truncation
	test("formats three tools without truncation", () => {
		expect(formatToolsLabel(["read", "write", "bash"])).toBe("**Tools:** read, write, bash");
	});
});
