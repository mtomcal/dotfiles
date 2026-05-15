/**
 * Message Renderer for Completion Notifications.
 * Uses name (not agent) in notification details.
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
			name: "code-reviewer",
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

	if (overrides.details) {
		defaults.details = { ...defaults.details, ...overrides.details };
	}

	return { ...defaults, ...overrides, details: defaults.details };
}

describe("subagent-result message renderer", () => {
	test("renderer is registered under 'subagent-result' key", () => {
		expect(mockPi.messageRenderers.has("subagent-result")).toBe(true);
	});

	test("renderer is a function", () => {
		const renderer = mockPi.messageRenderers.get("subagent-result");
		expect(typeof renderer).toBe("function");
	});

	test("returns a component with text for valid message", () => {
		const renderer = mockPi.messageRenderers.get("subagent-result");
		const component = renderer(
			fakeNotificationMessage(),
			{ expanded: false },
			getMockTheme(),
		);
		const text = component?.text ?? "";
		expect(text).toContain("code-reviewer");
		expect(text).toContain("completed");
	});

	test("collapsed mode includes name", () => {
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
		const message = fakeNotificationMessage({
			details: { status: "completed" },
		});
		const component = renderer(message, { expanded: false }, getMockTheme());
		const text = component?.text ?? "";
		expect(text).toContain("completed");
	});

	test("expanded mode returns a Container", () => {
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
		expect(() => renderer(message, { expanded: false }, getMockTheme())).not.toThrow();
	});

	test("includes usage stats in collapsed mode", () => {
		const renderer = mockPi.messageRenderers.get("subagent-result");
		const component = renderer(
			fakeNotificationMessage(),
			{ expanded: false },
			getMockTheme(),
		);
		const text = component?.text ?? "";
		expect(text).toMatch(/3|turn/i);
	});

	test("notification uses name, not agent field", () => {
		const renderer = mockPi.messageRenderers.get("subagent-result");
		const message = fakeNotificationMessage({
			details: { name: "review" },
		});
		const component = renderer(message, { expanded: false }, getMockTheme());
		const text = component?.text ?? "";
		expect(text).toContain("review");
		// The old 'agent' field should not be in the output
		expect(text).not.toContain("(user)");
		expect(text).not.toContain("(project)");
	});

	test("collapsed mode shows resume suggestion for guardrail-failed", () => {
		const renderer = mockPi.messageRenderers.get("subagent-result");
		const message = fakeNotificationMessage({
			details: {
				status: "failed",
				summary: "Killed by guardrail",
				resumable: true,
			},
		});
		const component = renderer(message, { expanded: false }, getMockTheme());
		const text = component?.text ?? "";
		expect(text).toContain("Resumable");
	});
});