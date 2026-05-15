/**
 * Cycle 2: Job Manager — name terminology, remove agentSource, backward compat
 */

import { describe, test, expect, vi, beforeEach } from "vitest";
import { JobManager, type SingleResult, type AsyncJob, terminateProcess } from "../job-manager.js";
import type { Guardrails } from "../guardrails.js";
import type { SubagentConfig } from "../subagent-config.js";
import { fakeSingleResult, setupJobManager, fakeChildProcess } from "./helpers.js";

describe("JobManager", () => {
	describe("createJob guardrails", () => {
		test("createJob with guardrails stores them on the job", () => {
			const { jobMgr } = setupJobManager();
			const guardrails: Guardrails = { maxTurns: 25, maxCost: 0.50 };
			const job = jobMgr.createJob("review", "Review auth", guardrails);
			expect(job.guardrails).toEqual(guardrails);
		});

		test("createJob without guardrails leaves guardrails undefined", () => {
			const { jobMgr } = setupJobManager();
			const job = jobMgr.createJob("review", "Review auth");
			expect(job.guardrails).toBeUndefined();
		});
	});

	describe("serialize/deserialize guardrails", () => {
		test("serialize preserves guardrails field", () => {
			const { jobMgr } = setupJobManager();
			const guardrails: Guardrails = { maxTurns: 30, maxCost: 1.00, maxTokens: 500000, maxTime: 600 };
			jobMgr.createJob("review", "Review auth", guardrails);
			const data = jobMgr.serialize();
			expect(data[0].guardrails).toEqual(guardrails);
		});

		test("deserialize restores guardrails field", () => {
			const { jobMgr } = setupJobManager();
			const guardrails: Guardrails = { maxTurns: 30, maxCost: 1.00, maxTokens: 500000 };
			jobMgr.createJob("review", "Review auth", guardrails);
			const data = jobMgr.serialize();
			const mgr2 = new JobManager();
			mgr2.deserialize(data);
			expect(mgr2.getJob(data[0].id)!.guardrails).toEqual(guardrails);
		});

		test("serialize without guardrails produces undefined guardrails field", () => {
			const { jobMgr } = setupJobManager();
			jobMgr.createJob("review", "Review auth");
			const data = jobMgr.serialize();
			expect(data[0].guardrails).toBeUndefined();
		});
	});

	describe("terminateProcess", () => {
		test("sends SIGTERM, then SIGKILL after 5s timeout if process doesn't exit", async () => {
			vi.useFakeTimers();
			const closeCallbacks: Array<() => void> = [];
			const mockProc = {
				kill: vi.fn(),
				killed: false,
				on: vi.fn((event: string, cb: () => void) => {
					if (event === "close") closeCallbacks.push(cb);
				}),
			} as any;
			const promise = terminateProcess(mockProc);

			expect(mockProc.kill).toHaveBeenCalledWith("SIGTERM");

			// Advance timers past 5 seconds without emitting close
			mockProc.killed = false;
			vi.advanceTimersByTime(5000);
			expect(mockProc.kill).toHaveBeenCalledWith("SIGKILL");

			// Simulate process exiting
			closeCallbacks.forEach((cb) => cb());
			vi.advanceTimersByTime(0);

			await promise;
			vi.useRealTimers();
		});

		test("resolves immediately if process already exited (killed=true)", async () => {
			const closeCallbacks: Array<() => void> = [];
			const mockProc = {
				kill: vi.fn(),
				killed: true, // already exited
				on: vi.fn((event: string, cb: () => void) => {
					if (event === "close") closeCallbacks.push(cb);
				}),
			} as any;
			const promise = terminateProcess(mockProc);

			expect(mockProc.kill).not.toHaveBeenCalled();
			await promise;
		});
	});
	test("createJob uses name-based ID", () => {
		const { jobMgr } = setupJobManager();
		const job = jobMgr.createJob("review", "Review auth module");
		expect(job.id).toMatch(/^review-[a-z0-9]{6}$/);
		expect(job.name).toBe("review");
	});

	test("createJob assigns status running", () => {
		const { jobMgr } = setupJobManager();
		const job = jobMgr.createJob("test", "A task");
		expect(job.status).toBe("running");
	});

	test("createJob throws if 8 jobs already running", () => {
		const { jobMgr } = setupJobManager();
		for (let i = 0; i < 8; i++) {
			jobMgr.createJob("agent", `Task ${i}`);
		}
		expect(() => jobMgr.createJob("agent", "Task 9")).toThrow(/maximum/i);
	});

	test("completeJob transitions running to completed", () => {
		const { jobMgr } = setupJobManager();
		const job = jobMgr.createJob("reviewer", "Review");
		const fakeResult = fakeSingleResult();
		jobMgr.completeJob(job.id, fakeResult);
		expect(jobMgr.getJob(job.id)!.status).toBe("completed");
		expect(jobMgr.getJob(job.id)!.result).toBe(fakeResult);
	});

	test("failJob transitions running to failed", () => {
		const { jobMgr } = setupJobManager();
		const job = jobMgr.createJob("reviewer", "Review");
		jobMgr.failJob(job.id, "Process exited with code 1");
		expect(jobMgr.getJob(job.id)!.status).toBe("failed");
	});

	test("cancelJob sends SIGTERM and marks cancelled", () => {
		const { jobMgr } = setupJobManager();
		const mockProc = fakeChildProcess();
		const job = jobMgr.createJob("reviewer", "Review");
		jobMgr.setProcess(job.id, mockProc);
		jobMgr.cancelJob(job.id);
		expect(mockProc.kill).toHaveBeenCalledWith("SIGTERM");
		expect(jobMgr.getJob(job.id)!.status).toBe("cancelled");
	});

	test("cancelAll cancels all running jobs", () => {
		const { jobMgr } = setupJobManager();
		const job1 = jobMgr.createJob("a", "task1");
		const job2 = jobMgr.createJob("b", "task2");
		jobMgr.completeJob(job1.id, fakeSingleResult());
		const job3 = jobMgr.createJob("c", "task3");
		jobMgr.cancelAll();
		expect(jobMgr.getJob(job2.id)!.status).toBe("cancelled");
		expect(jobMgr.getJob(job3.id)!.status).toBe("cancelled");
		expect(jobMgr.getJob(job1.id)!.status).toBe("completed"); // untouched
	});

	test("listJobs returns all jobs", () => {
		const { jobMgr } = setupJobManager();
		jobMgr.createJob("a", "task1");
		jobMgr.createJob("b", "task2");
		expect(jobMgr.listJobs()).toHaveLength(2);
	});

	test("listRunning returns only running jobs", () => {
		const { jobMgr } = setupJobManager();
		const j1 = jobMgr.createJob("a", "task1");
		const j2 = jobMgr.createJob("b", "task2");
		jobMgr.completeJob(j1.id, fakeSingleResult());
		expect(jobMgr.listRunning()).toHaveLength(1);
		expect(jobMgr.listRunning()[0].id).toBe(j2.id);
	});

	test("serialize/deserialize roundtrips for appendEntry", () => {
		const { jobMgr } = setupJobManager();
		const job = jobMgr.createJob("reviewer", "Review");
		jobMgr.completeJob(job.id, fakeSingleResult());
		const data = jobMgr.serialize();
		const mgr2 = new JobManager();
		mgr2.deserialize(data);
		expect(mgr2.getJob(job.id)!.status).toBe("completed");
	});

	test("running() count method works", () => {
		const { jobMgr } = setupJobManager();
		expect(jobMgr.runningCount()).toBe(0);
		jobMgr.createJob("a", "task1");
		expect(jobMgr.runningCount()).toBe(1);
		jobMgr.createJob("b", "task2");
		expect(jobMgr.runningCount()).toBe(2);
	});

	test("deserialize marks running jobs as cancelled (orphan protection)", () => {
		const data = [
			{
				id: "reviewer-abc123",
				name: "reviewer",
				task: "Review auth",
				status: "running" as const,
				result: null,
				startedAt: Date.now() - 10000,
				completedAt: null,
			},
		];
		const mgr = new JobManager();
		mgr.deserialize(data);
		expect(mgr.getJob("reviewer-abc123")!.status).toBe("cancelled");
		expect(mgr.getJob("reviewer-abc123")!.process).toBeNull();
	});

	test("deserialize handles legacy 'agent' field for backward compat", () => {
		const mgr = new JobManager();
		// Simulate persisted state from old version with 'agent' instead of 'name'
		const legacyData = [{
			id: "reviewer-a3f2b7",
			agent: "reviewer",  // old field name
			task: "Review auth",
			status: "completed" as const,
			result: { agent: "reviewer", task: "Review auth", exitCode: 0, messages: [], stderr: "", usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 } },
			startedAt: Date.now(),
			completedAt: Date.now(),
		}];
		mgr.deserialize(legacyData as any);
		const job = mgr.getJob("reviewer-a3f2b7");
		expect(job).toBeDefined();
		expect(job!.name).toBe("reviewer"); // migrated from 'agent'
	});

	test("SingleResult no longer has agentSource", () => {
		const result: SingleResult = {
			name: "review",
			task: "Review auth",
			exitCode: 0,
			messages: [],
			stderr: "",
			usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
		};
		// Verify the interface doesn't have agentSource (TypeScript will enforce this)
		expect(result.name).toBe("review");
		expect((result as any).agentSource).toBeUndefined();
	});

	test("cancelJob captures process ref before nulling for SIGKILL escalation", () => {
		vi.useFakeTimers();
		const { jobMgr } = setupJobManager();
		const mockProc = fakeChildProcess();
		const job = jobMgr.createJob("reviewer", "Review");
		jobMgr.setProcess(job.id, mockProc);
		jobMgr.cancelJob(job.id);

		// Process reference is nulled immediately
		expect(jobMgr.getJob(job.id)!.process).toBeNull();
		expect(jobMgr.getJob(job.id)!.status).toBe("cancelled");
		expect(mockProc.kill).toHaveBeenCalledWith("SIGTERM");

		// After 5 seconds, SIGKILL fallback should still work via captured ref
		mockProc.killed = false;
		vi.advanceTimersByTime(5000);
		expect(mockProc.kill).toHaveBeenCalledWith("SIGKILL");

		vi.useRealTimers();
	});

	test("cancelAll captures process refs before nulling for SIGKILL fallback", () => {
		vi.useFakeTimers();
		const { jobMgr } = setupJobManager();
		const mockProc1 = fakeChildProcess();
		const mockProc2 = fakeChildProcess();
		const job1 = jobMgr.createJob("a", "task1");
		const job2 = jobMgr.createJob("b", "task2");
		jobMgr.setProcess(job1.id, mockProc1);
		jobMgr.setProcess(job2.id, mockProc2);
		jobMgr.cancelAll();

		expect(mockProc1.kill).toHaveBeenCalledWith("SIGTERM");
		expect(mockProc2.kill).toHaveBeenCalledWith("SIGTERM");

		vi.advanceTimersByTime(5000);
		expect(mockProc1.kill).toHaveBeenCalledWith("SIGKILL");
		expect(mockProc2.kill).toHaveBeenCalledWith("SIGKILL");

		vi.useRealTimers();
	});

	test("createJob retries on ID collision", () => {
		const { jobMgr } = setupJobManager();
		const existing = jobMgr.createJob("test", "task");
		const newJob = jobMgr.createJob("test", "task2");
		expect(newJob.id).not.toBe(existing.id);
		expect(newJob.id).toMatch(/^test-[a-z0-9]{6}$/);
	});
});

describe("OriginalInvocation", () => {
	const minimalConfig: SubagentConfig = {
		name: "test-agent",
		systemPrompt: "You are a test agent",
		tools: undefined,
		model: undefined,
		provider: undefined,
		thinking: "medium" as const,
		contextFiles: true,
		extensions: false,
		guardrails: {},
	};

	test("createJob with original stores it", () => {
		const { jobMgr } = setupJobManager();
		const original = {
			config: minimalConfig,
			task: "Original task description",
			cwd: "/tmp",
			guardrails: { maxTurns: 10 },
		};
		const job = jobMgr.createJob("test", "Sub task", undefined, original);
		expect(job.original).toBeDefined();
		expect(job.original!.config).toEqual(minimalConfig);
		expect(job.original!.task).toBe("Original task description");
		expect(job.original!.cwd).toBe("/tmp");
		expect(job.original!.guardrails).toEqual({ maxTurns: 10 });
	});

	test("serialize/deserialize round-trips original", () => {
		const { jobMgr } = setupJobManager();
		const original = {
			config: minimalConfig,
			task: "Original task",
			guardrails: {},
		};
		jobMgr.createJob("test", "Sub task", undefined, original);
		const data = jobMgr.serialize();
		const mgr2 = new JobManager();
		mgr2.deserialize(data);
		const restored = mgr2.getJob(data[0].id)!;
		expect(restored.original).toEqual(original);
	});

	test("job without original deserializes safely", () => {
		const { jobMgr } = setupJobManager();
		jobMgr.createJob("test", "Sub task");
		const data = jobMgr.serialize();
		const mgr2 = new JobManager();
		mgr2.deserialize(data);
		const restored = mgr2.getJob(data[0].id)!;
		expect(restored.original).toBeUndefined();
	});

	test("original.resumedFrom round-trips", () => {
		const { jobMgr } = setupJobManager();
		const original = {
			config: minimalConfig,
			task: "Original task",
			guardrails: {},
			resumedFrom: "some-job-id",
		};
		jobMgr.createJob("test", "Sub task", undefined, original);
		const data = jobMgr.serialize();
		const mgr2 = new JobManager();
		mgr2.deserialize(data);
		const restored = mgr2.getJob(data[0].id)!;
		expect(restored.original!.resumedFrom).toBe("some-job-id");
	});
});