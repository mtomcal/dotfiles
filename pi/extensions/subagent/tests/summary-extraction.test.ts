/**
 * Slice 1: Constants and Summary Extraction — RED tests.
 * These tests import from "../summary.js" which does NOT exist yet.
 * They are expected to FAIL until the source module is implemented.
 */

import { describe, test, expect } from "vitest";
import {
	extractSummary,
	truncateForWidget,
	SUBAGENT_SUMMARY_MIN_LENGTH,
	SUBAGENT_WIDGET_DEBOUNCE_MS,
	SUBAGENT_WIDGET_DISMISS_DELAY_MS,
} from "../summary.js";
import type { Message } from "@earendil-works/pi-ai";

// ── Helpers ────────────────────────────────────────────────────────────────

/** Build an assistant Message with the given text content parts. */
function assistantMsg(...texts: string[]): Message {
	return {
		role: "assistant",
		content: texts.map((t) => ({ type: "text" as const, text: t })),
	} as Message;
}

/** Build a user Message (used to ensure extractSummary skips non-assistant). */
function userMsg(text: string): Message {
	return {
		role: "user",
		content: [{ type: "text", text }],
		timestamp: Date.now(),
	};
}

/** Build an assistant Message that contains a tool-call part (no text). */
function toolCallMsg(name: string): Message {
	return {
		role: "assistant",
		content: [{ type: "toolCall", name, arguments: {}, id: "tc-1" }],
	} as Message;
}

// ── Constants ──────────────────────────────────────────────────────────────

describe("constants", () => {
	test("SUBAGENT_SUMMARY_MIN_LENGTH equals 50", () => {
		expect(SUBAGENT_SUMMARY_MIN_LENGTH).toBe(50);
	});

	test("SUBAGENT_WIDGET_DEBOUNCE_MS equals 1000", () => {
		expect(SUBAGENT_WIDGET_DEBOUNCE_MS).toBe(1000);
	});

	test("SUBAGENT_WIDGET_DISMISS_DELAY_MS equals 5000", () => {
		expect(SUBAGENT_WIDGET_DISMISS_DELAY_MS).toBe(5000);
	});
});

// ── extractSummary ─────────────────────────────────────────────────────────

describe("extractSummary", () => {
	test("returns the last assistant text block ≥ 50 chars when scanning backward", () => {
		const longA = "A".repeat(80);
		const longB = "B".repeat(60);
		const messages: Message[] = [
			assistantMsg(longA),           // index 0 — earlier, ≥50
			assistantMsg("short note"),    // index 1 — <50, skipped
			assistantMsg(longB),           // index 2 — later, ≥50 — should win
		];

		const result = extractSummary(messages);
		expect(result).toBe(longB);
	});

	test("skips text blocks under 50 chars and returns the first substantive one found scanning backward", () => {
		const longA = "Z".repeat(75);
		const messages: Message[] = [
			assistantMsg(longA),           // index 0 — ≥50
			assistantMsg("hi"),           // index 1 — <50, skipped
			assistantMsg("brief"),         // index 2 — <50, skipped
		];

		const result = extractSummary(messages);
		expect(result).toBe(longA);
	});

	test("falls back to the last text block if none meet the 50-char threshold", () => {
		const shortA = "alpha";
		const shortB = "beta gamma delta";
		const messages: Message[] = [
			assistantMsg(shortA),
			assistantMsg(shortB),
		];

		const result = extractSummary(messages);
		// Scanning backward, shortB is the last text block
		expect(result).toBe(shortB);
	});

	test("returns empty string when there are no assistant messages", () => {
		const messages: Message[] = [
			userMsg("hello"),
			userMsg("world"),
		];

		const result = extractSummary(messages);
		expect(result).toBe("");
	});

	test("returns empty string for empty messages array", () => {
		const result = extractSummary([]);
		expect(result).toBe("");
	});

	test("skips assistant messages that only contain tool calls (no text parts)", () => {
		const longA = "C".repeat(55);
		const messages: Message[] = [
			assistantMsg(longA),
			toolCallMsg("bash"),
		];

		const result = extractSummary(messages);
		expect(result).toBe(longA);
	});

	test("skips user messages entirely", () => {
		const longA = "D".repeat(60);
		const messages: Message[] = [
			userMsg("E".repeat(100)),
			assistantMsg(longA),
		];

		const result = extractSummary(messages);
		expect(result).toBe(longA);
	});

	test("handles assistant message with multiple text parts — uses the last qualifying one scanning backward through parts", () => {
		const longA = "X".repeat(52);
		const shortB = "tiny";
		const messages: Message[] = [
			assistantMsg(longA, shortB),
		];

		// The function scans backward through all text blocks in all
		// assistant messages. shortB is encountered first (< 50),
		// then longA is encountered and returned.
		const result = extractSummary(messages);
		expect(result).toBe(longA);
	});
});

// ── truncateForWidget ──────────────────────────────────────────────────────

describe("truncateForWidget", () => {
	// Widget rendering indents with a 2-char prefix ("  "), so
	// effective available width = maxWidth - 2.

	test("truncates at first newline boundary", () => {
		const text = "line one\nline two continues";
		const result = truncateForWidget(text, 80);
		expect(result).toBe("line one");
	});

	test("clips to maxWidth after prefix is subtracted", () => {
		// With a 2-char indent prefix, effective width = 20 - 2 = 18
		const text = "a".repeat(50);
		const result = truncateForWidget(text, 20);
		expect(result.length).toBeLessThanOrEqual(18);
		expect(result).toBe("a".repeat(18));
	});

	test("handles text with no newlines", () => {
		const text = "just one long continuous line without breaks";
		const result = truncateForWidget(text, 80);
		// Should return text up to (maxWidth - 2) chars, full text if shorter
		expect(result.length).toBeLessThanOrEqual(80 - 2);
		expect(result).toBe(text.slice(0, 78));
	});

	test("handles empty string", () => {
		const result = truncateForWidget("", 80);
		expect(result).toBe("");
	});

	test("handles maxWidth of 0 gracefully (fallback to default)", () => {
		const text = "some reasonable text here";
		const result = truncateForWidget(text, 0);
		// Should not crash; a sensible default (e.g. 80) should apply
		expect(typeof result).toBe("string");
		expect(result.length).toBeGreaterThan(0);
		expect(result.length).toBeLessThanOrEqual(80);
	});

	test("handles undefined maxWidth gracefully (fallback to default)", () => {
		const text = "another piece of text content";
		const result = truncateForWidget(text, undefined as unknown as number);
		expect(typeof result).toBe("string");
		expect(result.length).toBeGreaterThan(0);
	});

	test("prefers newline boundary over hard clip when newline is within width", () => {
		const text = "short\nthis is a much longer second line that would need clipping";
		// effective width = 60 - 2 = 58, newline at pos 5
		const result = truncateForWidget(text, 60);
		expect(result).toBe("short");
	});

	test("hard clips when newline is beyond effective width", () => {
		const text = "a".repeat(30) + "\nsecond line";
		// effective width = 20 - 2 = 18, newline at pos 30 (beyond 18)
		const result = truncateForWidget(text, 20);
		expect(result).toBe("a".repeat(18));
	});

	test("adds ellipsis when truncating (if implementation chooses to)", () => {
		const text = "a".repeat(100);
		const result = truncateForWidget(text, 20);
		// Whether ellipsis is added is an implementation detail;
		// just ensure the result is meaningfully shorter than input.
		expect(result.length).toBeLessThan(text.length);
	});
});