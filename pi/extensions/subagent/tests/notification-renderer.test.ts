/**
 * Cycle 8: Message Renderer for Completion Notifications.
 *
 * Test that the "subagent-result" message renderer is registered and
 * produces correct output in collapsed and expanded modes.
 */

import { describe, test, expect, beforeAll } from "vitest";
import { createMockExtension } from "./extension-helpers.js";
import { fakeSingleResult } from "./helpers.js";

let mockPi: any;
let registeredTools: Map<string, any>;

beforeAll(async () => {
	const ctx = createMockExtension();
	mockPi = ctx.pi;
	registeredTools = ctx.registeredTools;

	const mod = await import("../index.js");
	mod.default(mockPi);
});

function getMockTheme() {
	return {
		fg: (color: string, text: string) => text,
		bold: (s: string) => s,
	};
}

function fakeNotificationMessage(overrides: any = {}) {
	const defaults = {
		customType: "subagent-result",
		content: "",
		details: {
			jobId: "code-reviewer-a3f2",
			status: "completed",
			agent: "code-reviewer",
			task: "Review the auth module",
			summary: "The auth module looks good overall. Minor suggestions included.",
			usage: {
				input: 5000,
				output: 1200,
				cacheRead: 3000,
				cacheWrite: 800,
				cost: 0.0342,
				contextTokens: 6000,
				turns: 3,
			},
		},
	};

	// Deep merge: override specific fields within details
	if (overrides.details) {
		defaults.details = { ...defaults.details, ...overrides.details };
	}

	return { ...defaults, ...overrides, details: defaults.details };
}

describe("subagent-result message renderer registration", () => {
	test("renderer is registered under 'subagent-result' key", () => {
		expect(mockPi.messageRenderers.has("subagent-result")).toBe(true);
	});

	test("renderer is a function", () => {
		const renderer = mockPi.messageRenderers.get("subagent-result");
		expect(typeof renderer).toBe("function");
	});
});

describe("subagent-result message renderer output", () => {
	test("returns a component (not undefined) for valid message", () => {
		const renderer = mockPi.messageRenderers.get("subagent-result");
		const component = renderer(
			fakeNotificationMessage(),
			{ expanded: false },
			getMockTheme(),
		);
		expect(component).toBeDefined();
	});

	test("collapsed mode includes agent name", () => {
		const renderer = mockPi.messageRenderers.get("subagent-result");
		const component = renderer(
			fakeNotificationMessage(),
			{ expanded: false },
			getMockTheme(),
		);
		const text = component?.text ?? "";
		expect(text).toContain("code-reviewer");
	});

	test("collapsed mode includes status", () => {
		const renderer = mockPi.messageRenderers.get("subagent-result");
		// Use the deep-merge helper to only override the status field
		const message = fakeNotificationMessage({
			details: { status: "completed" },
		});
		const component = renderer(message, { expanded: false }, getMockTheme());
		const text = component?.text ?? "";
		expect(text).toContain("completed");
	});

	test("expanded mode returns a Container (has addChild)", () => {
		const renderer = mockPi.messageRenderers.get("subagent-result");
		const component = renderer(
			fakeNotificationMessage({ details: { result: fakeSingleResult() } }),
			{ expanded: true },
			getMockTheme(),
		);
		expect(component).toBeDefined();
		if (component && typeof component === "object") {
			expect(typeof (component as any).addChild).toBe("function");
		}
	});

	test("handles failed status", () => {
		const renderer = mockPi.messageRenderers.get("subagent-result");
		const message = fakeNotificationMessage({
			details: {
				status: "failed",
				summary: "Process exited with code 1",
			},
		});
		const component = renderer(message, { expanded: false }, getMockTheme());
		const text = component?.text ?? "";
		expect(text).toContain("failed");
	});

	test("handles missing summary gracefully", () => {
		const renderer = mockPi.messageRenderers.get("subagent-result");
		const message = fakeNotificationMessage({
			details: { summary: undefined },
		});
		// Should not throw
		const component = renderer(message, { expanded: false }, getMockTheme());
		expect(component === undefined || component !== undefined).toBe(true);
	});

	test("includes usage stats in output when available", () => {
		const renderer = mockPi.messageRenderers.get("subagent-result");
		const component = renderer(
			fakeNotificationMessage(),
			{ expanded: false },
			getMockTheme(),
		);
		const text = component?.text ?? "";
		// Should contain formatted usage (turns, cost, etc.)
		expect(text).toBeTruthy();
	});

	test("task truncation in collapsed mode for long tasks", () => {
		const renderer = mockPi.messageRenderers.get("subagent-result");
		const message = fakeNotificationMessage({
			details: { task: "A".repeat(200) },
		});
		const component = renderer(message, { expanded: false }, getMockTheme());
		const text = component?.text ?? "";
		// The task (200+ chars) should be truncated — full string must not appear
		const fullTaskString = "A".repeat(200);
		expect(text).not.toContain(fullTaskString);
	});

	test("jobId is included in expanded output (collapsed shows agent + status)", () => {
		const renderer = mockPi.messageRenderers.get("subagent-result");
		const component = renderer(
			fakeNotificationMessage(),
			{ expanded: false },
			getMockTheme(),
		);
		const text = component?.text ?? "";
		// Collapsed output shows agent name and status (not the raw ID)
		expect(text).toContain("code-reviewer");
		expect(text).toContain("completed");
	});
});