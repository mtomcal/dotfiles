/**
 * Test helpers for subagent extension tests.
 */

import { JobManager, type SingleResult } from "../job-manager.js";

export function fakeUsageStats(): SingleResult["usage"] {
	return {
		input: 5000,
		output: 1200,
		cacheRead: 3000,
		cacheWrite: 800,
		cost: 0.0342,
		contextTokens: 6000,
		turns: 3,
	};
}

export function fakeSingleResult(overrides: Partial<SingleResult> = {}): SingleResult {
	return {
		agent: "reviewer",
		agentSource: "user",
		task: "Review the auth module",
		exitCode: 0,
		messages: [
			{
				role: "assistant",
				content: [{ type: "text", text: "Here is my review: looks good." }],
			},
		],
		stderr: "",
		usage: fakeUsageStats(),
		...overrides,
	};
}

export interface TestContext {
	jobMgr: JobManager;
}

export function setupJobManager(): TestContext {
	return {
		jobMgr: new JobManager(),
	};
}
