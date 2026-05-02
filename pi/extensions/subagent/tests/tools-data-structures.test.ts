/**
 * Slice 1: Data Structures — Add `tools` Field
 *
 * Tests the `tools?: string[]` field on AsyncJob, SingleResult, and SerializedJob
 * per AIAGT v1.4.0 rules 21, 26, 27.
 */

import { describe, test, expect } from "vitest";
import { JobManager, type AsyncJob, type SingleResult, type SerializedJob } from "../job-manager.js";
import { fakeSingleResult, setupJobManager } from "./helpers.js";

describe("tools field on data structures", () => {
	// Assertion 1: AsyncJob type accepts optional `tools?: string[]` field
	test("AsyncJob interface accepts tools field", () => {
		const job: AsyncJob = {
			id: "test-abc123",
			name: "test",
			task: "Test task",
			status: "running",
			process: null,
			result: null,
			startedAt: Date.now(),
			completedAt: null,
			tools: ["read", "grep"],
		};
		expect(job.tools).toEqual(["read", "grep"]);
	});

	// Assertion 2: SingleResult type accepts optional `tools?: string[]` field
	test("SingleResult interface accepts tools field", () => {
		const result: SingleResult = {
			name: "test",
			task: "Test task",
			exitCode: 0,
			messages: [],
			stderr: "",
			usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
			tools: ["read", "write", "bash"],
		};
		expect(result.tools).toEqual(["read", "write", "bash"]);
	});

	// Assertion 3: SerializedJob type accepts optional `tools?: string[]` field
	test("SerializedJob interface accepts tools field", () => {
		const serialized: SerializedJob = {
			id: "test-abc123",
			name: "test",
			task: "Test task",
			status: "completed",
			result: null,
			startedAt: Date.now(),
			completedAt: Date.now(),
			tools: ["read"],
		};
		expect(serialized.tools).toEqual(["read"]);
	});

	// Assertion 4: createJob() returns a job with `tools: undefined` by default
	test("createJob returns job with tools undefined by default", () => {
		const { jobMgr } = setupJobManager();
		const job = jobMgr.createJob("test", "Test task");
		expect(job.tools).toBeUndefined();
	});

	// Assertion 5: After setting `job.tools = ["read","grep"]`, the field persists
	test("job.tools persists after assignment", () => {
		const { jobMgr } = setupJobManager();
		const job = jobMgr.createJob("test", "Test task");
		job.tools = ["read", "grep"];
		expect(job.tools).toEqual(["read", "grep"]);
	});

	// Assertion 6: serialize() includes `tools` on jobs that have it defined
	test("serialize includes tools when defined", () => {
		const { jobMgr } = setupJobManager();
		const job = jobMgr.createJob("test", "Test task");
		job.tools = ["read", "grep"];
		jobMgr.completeJob(job.id, fakeSingleResult({ tools: ["read", "grep"] }));

		const serialized = jobMgr.serialize();
		expect(serialized[0].tools).toEqual(["read", "grep"]);
	});

	// Assertion 7: serialize() omits `tools` when it's `undefined`
	test("serialize omits tools when undefined", () => {
		const { jobMgr } = setupJobManager();
		const job = jobMgr.createJob("test", "Test task");
		// No tools set
		jobMgr.completeJob(job.id, fakeSingleResult());

		const serialized = jobMgr.serialize();
		expect(serialized[0].tools).toBeUndefined();
	});

	// Assertion 8: deserialize() with `tools` data populates the field correctly
	test("deserialize populates tools when present in data", () => {
		const data: SerializedJob[] = [
			{
				id: "test-abc123",
				name: "test",
				task: "Test task",
				status: "completed",
				result: fakeSingleResult({ tools: ["read", "bash"] }),
				startedAt: Date.now(),
				completedAt: Date.now(),
				tools: ["read", "bash"],
			},
		];

		const mgr = new JobManager();
		mgr.deserialize(data);

		const job = mgr.getJob("test-abc123");
		expect(job).toBeDefined();
		expect(job!.tools).toEqual(["read", "bash"]);
		expect(job!.result?.tools).toEqual(["read", "bash"]);
	});

	// Assertion 9: deserialize() with missing `tools` field (legacy data) treats it as `undefined`
	test("deserialize treats missing tools as undefined (legacy compat)", () => {
		const data: SerializedJob[] = [
			{
				id: "legacy-xyz789",
				name: "legacy",
				task: "Legacy task",
				status: "completed",
				result: fakeSingleResult(),
				startedAt: Date.now(),
				completedAt: Date.now(),
				// No tools field — simulates old persisted data
			},
		];

		const mgr = new JobManager();
		mgr.deserialize(data);

		const job = mgr.getJob("legacy-xyz789");
		expect(job).toBeDefined();
		expect(job!.tools).toBeUndefined();
	});

	// Assertion 10: SingleResult constructed with `tools: ["read","write","bash"]` carries it through
	test("SingleResult with tools carries it through completeJob", () => {
		const { jobMgr } = setupJobManager();
		const job = jobMgr.createJob("test", "Test task");
		const resultWithTools = fakeSingleResult({ tools: ["read", "write", "bash"] });
		jobMgr.completeJob(job.id, resultWithTools);

		const completed = jobMgr.getJob(job.id);
		expect(completed!.result?.tools).toEqual(["read", "write", "bash"]);
	});

	// Assertion 11: SingleResult constructed without `tools` has `tools: undefined`
	test("SingleResult without tools has undefined", () => {
		const result = fakeSingleResult();
		expect(result.tools).toBeUndefined();
	});
});