/**
 * Cycle 1: Job Manager Core — In-memory job tracker tests.
 *
 * RED: These tests should all pass (job-manager.ts is already implemented).
 * We verify correctness before moving to Cycle 2.
 */

import { describe, test, expect, vi } from "vitest";
import { JobManager } from "../job-manager.js";
import { fakeSingleResult, setupJobManager } from "./helpers.js";

describe("JobManager", () => {
	test("createJob assigns agent-prefixed ID and status running", () => {
		const { jobMgr } = setupJobManager();
		const job = jobMgr.createJob("code-reviewer", "Review auth module");
		expect(job.id).toMatch(/^code-reviewer-[a-z0-9]{6}$/);
		expect(job.agent).toBe("code-reviewer");
		expect(job.task).toBe("Review auth module");
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
		const mockProc = { kill: vi.fn(), killed: false } as any;
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
				id: "reviewer-abc1",
				agent: "reviewer",
				task: "Review auth",
				status: "running" as const,
				result: null,
				startedAt: Date.now() - 10000,
				completedAt: null,
			},
		];
		const mgr = new JobManager();
		mgr.deserialize(data);
		expect(mgr.getJob("reviewer-abc1")!.status).toBe("cancelled");
		expect(mgr.getJob("reviewer-abc1")!.process).toBeNull();
	});

	test("cancelJob captures process ref before nulling for SIGKILL escalation", () => {
		vi.useFakeTimers();
		const { jobMgr } = setupJobManager();
		const mockProc = { kill: vi.fn(), killed: false } as any;
		const job = jobMgr.createJob("reviewer", "Review");
		jobMgr.setProcess(job.id, mockProc);
		jobMgr.cancelJob(job.id);

		// Process reference is nulled immediately (job.process is null)
		expect(jobMgr.getJob(job.id)!.process).toBeNull();
		expect(jobMgr.getJob(job.id)!.status).toBe("cancelled");

		// But the SIGTERM was sent via the captured reference
		expect(mockProc.kill).toHaveBeenCalledWith("SIGTERM");

		// After 5 seconds, SIGKILL fallback should still work via captured ref
		mockProc.killed = false; // process didn't die from SIGTERM
		vi.advanceTimersByTime(5000);
		expect(mockProc.kill).toHaveBeenCalledWith("SIGKILL");

		vi.useRealTimers();
	});

	test("cancelAll captures process refs before nulling for SIGKILL fallback", () => {
		vi.useFakeTimers();
		const { jobMgr } = setupJobManager();
		const mockProc1 = { kill: vi.fn(), killed: false } as any;
		const mockProc2 = { kill: vi.fn(), killed: false } as any;
		const job1 = jobMgr.createJob("a", "task1");
		const job2 = jobMgr.createJob("b", "task2");
		jobMgr.setProcess(job1.id, mockProc1);
		jobMgr.setProcess(job2.id, mockProc2);
		jobMgr.cancelAll();

		// Both got SIGTERM
		expect(mockProc1.kill).toHaveBeenCalledWith("SIGTERM");
		expect(mockProc2.kill).toHaveBeenCalledWith("SIGTERM");

		// After 5s, SIGKILL fallback fires for both
		vi.advanceTimersByTime(5000);
		expect(mockProc1.kill).toHaveBeenCalledWith("SIGKILL");
		expect(mockProc2.kill).toHaveBeenCalledWith("SIGKILL");

		vi.useRealTimers();
	});

	test("createJob retries on ID collision", () => {
		const { jobMgr } = setupJobManager();
		// Force a collision by pre-creating a job with a known ID
		const existing = jobMgr.createJob("test", "task");
		const newJob = jobMgr.createJob("test", "task2");
		// New job should have a different ID (collision avoidance)
		expect(newJob.id).not.toBe(existing.id);
		expect(newJob.id).toMatch(/^test-[a-z0-9]{6}$/);
	});
});
