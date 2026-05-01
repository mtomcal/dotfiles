/**
 * Test utilities for extension tool tests.
 */

import { vi } from "vitest";
import { JobManager, type SingleResult } from "../job-manager.js";
import { fakeSingleResult } from "./helpers.js";

export interface SentMessage {
	customType: string;
	content: string;
	display: boolean;
	details: any;
	options?: { triggerTurn?: boolean; deliverAs?: string };
}

/**
 * Create a mock ExtensionAPI for testing tool implementations.
 */
export function createMockExtension(): {
	pi: any;
	registeredTools: Map<string, any>;
	jobMgr: JobManager;
} {
	const jobMgr = new JobManager();
	const registeredTools = new Map<string, any>();
	const messageRenderers = new Map<string, Function>();

	const pi = {
		jobMgr,
		sentMessages: [] as SentMessage[],
		appendEntries: [] as any[],
		eventHandlers: new Map<string, Function[]>(),
		registeredTools,
		messageRenderers,

		registerTool(tool: any) {
			registeredTools.set(tool.name, tool);
		},

		sendMessage(message: any, options?: any) {
			pi.sentMessages.push({ ...message, options });
		},

		appendEntry(customType: string, data?: any) {
			pi.appendEntries.push({ customType, data });
		},

		on(event: string, handler: Function) {
			if (!pi.eventHandlers.has(event)) {
				pi.eventHandlers.set(event, []);
			}
			pi.eventHandlers.get(event)!.push(handler);
		},

		emit(event: string, data?: any) {
			const handlers = pi.eventHandlers.get(event) || [];
			for (const handler of handlers) {
				handler(data, {
					ui: { confirm: vi.fn().mockResolvedValue(true) },
					cwd: "/test",
					hasUI: true,
					signal: undefined,
					sessionManager: {
						getEntries: () => [],
					},
				});
			}
		},

		registerMessageRenderer(customType: string, renderer: Function) {
			messageRenderers.set(customType, renderer);
		},
	};

	return { pi, registeredTools, jobMgr };
}

/**
 * Build a minimal fake SingleResult for tests.
 */
export function makeFakeResult(overrides?: Partial<SingleResult>): SingleResult {
	const base: SingleResult = {
		name: "test-agent",
		task: "test task",
		exitCode: 0,
		messages: [],
		stderr: "",
		usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
		provider: "test",
		model: "test-model",
		thinking: "medium",
		step: 1,
		...overrides,
	};
	return base;
}