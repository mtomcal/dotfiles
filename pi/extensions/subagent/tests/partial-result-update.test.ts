/**
 * Slice 2: Partial Result Updates on Running Jobs
 *
 * RED tests — `updatePartialResult` does not yet exist on JobManager.
 * These tests define the expected contract for the new method.
 */

import { describe, test, expect, vi } from "vitest";
import type { Message } from "@mariozechner/pi-ai";
import { JobManager, type SingleResult } from "../job-manager.js";
import { fakeUsageStats, fakeSingleResult, fakeChildProcess } from "./helpers.js";

describe("updatePartialResult", () => {
	test("creating a job leaves result as null (baseline)", () => {
		const jobMgr = new JobManager();
		const job = jobMgr.createJob("reviewer", "Review auth module");
		expect(job.result).toBeNull();
	});

	test("updatePartialResult updates result on a running job", () => {
		const jobMgr = new JobManager();
		const job = jobMgr.createJob("reviewer", "Review auth module");
		const partial = fakeSingleResult();
		jobMgr.updatePartialResult(job.id, partial);
		expect(jobMgr.getJob(job.id)!.result).toBe(partial);
	});

	test("updatePartialResult does not update a completed job (frozen state)", () => {
		const jobMgr = new JobManager();
		const job = jobMgr.createJob("reviewer", "Review auth module");
		const finalResult = fakeSingleResult({ exitCode: 0 });
		jobMgr.completeJob(job.id, finalResult);

		const partial = fakeSingleResult({ exitCode: 1, stderr: "late update" });
		jobMgr.updatePartialResult(job.id, partial);

		// Result should remain the original completed result
		expect(jobMgr.getJob(job.id)!.result).toBe(finalResult);
		expect(jobMgr.getJob(job.id)!.status).toBe("completed");
	});

	test("updatePartialResult does not update a failed job (frozen state)", () => {
		const jobMgr = new JobManager();
		const job = jobMgr.createJob("reviewer", "Review auth module");
		jobMgr.failJob(job.id, "Process exited with code 1");

		const partial = fakeSingleResult({ stderr: "late partial" });
		jobMgr.updatePartialResult(job.id, partial);

		// Failed job result should not be overwritten
		const fetched = jobMgr.getJob(job.id)!;
		expect(fetched.status).toBe("failed");
		expect(fetched.result!.stderr).toBe("Process exited with code 1");
	});

	test("updatePartialResult replaces result with latest snapshot (accumulated state)", () => {
		const jobMgr = new JobManager();
		const job = jobMgr.createJob("reviewer", "Review auth module");

		// spawnSubagentProcess sends accumulated snapshots (not deltas),
		// so updatePartialResult simply replaces the result.
		const firstUsage = fakeUsageStats();
		const firstPartial = fakeSingleResult({ usage: firstUsage });
		jobMgr.updatePartialResult(job.id, firstPartial);

		const secondUsage: SingleResult["usage"] = { ...firstUsage, input: firstUsage.input * 2, output: firstUsage.output * 2, turns: firstUsage.turns + 1 };
		const secondPartial = fakeSingleResult({ usage: secondUsage });
		jobMgr.updatePartialResult(job.id, secondPartial);

		const result = jobMgr.getJob(job.id)!.result!;
		// Replacement behavior: result is the second snapshot
		expect(result).toBe(secondPartial);
		expect(result.usage.input).toBe(secondUsage.input);
		expect(result.usage.output).toBe(secondUsage.output);
		expect(result.usage.turns).toBe(secondUsage.turns);
	});

	test("updatePartialResult replaces messages with latest snapshot (accumulated state)", () => {
		const jobMgr = new JobManager();
		const job = jobMgr.createJob("reviewer", "Review auth module");

		const msg1 = { role: "assistant" as const, content: [{ type: "text" as const, text: "First message" }] } as Message;
		const firstPartial = fakeSingleResult({ messages: [msg1] });
		jobMgr.updatePartialResult(job.id, firstPartial);

		// Second snapshot includes both messages (accumulated)
		const msg2 = { role: "assistant" as const, content: [{ type: "text" as const, text: "Second message" }] } as Message;
		const secondPartial = fakeSingleResult({ messages: [msg1, msg2] });
		jobMgr.updatePartialResult(job.id, secondPartial);

		const result = jobMgr.getJob(job.id)!.result!;
		// Replacement behavior: result is the second snapshot
		expect(result).toBe(secondPartial);
		expect(result.messages).toHaveLength(2);
		expect(result.messages[0]).toEqual(msg1);
		expect(result.messages[1]).toEqual(msg2);
	});

	test("updatePartialResult for a cancelled job does not update (frozen state)", () => {
		const jobMgr = new JobManager();
		const mockProc = fakeChildProcess();
		const job = jobMgr.createJob("reviewer", "Review auth module");
		jobMgr.setProcess(job.id, mockProc);

		// Put some partial result before cancellation
		const firstPartial = fakeSingleResult();
		jobMgr.updatePartialResult(job.id, firstPartial);

		jobMgr.cancelJob(job.id);

		const latePartial = fakeSingleResult({ stderr: "should not appear" });
		jobMgr.updatePartialResult(job.id, latePartial);

		const fetched = jobMgr.getJob(job.id)!;
		expect(fetched.status).toBe("cancelled");
		// The partial result from before cancellation should still be there
		expect(fetched.result).toBe(firstPartial);
	});
});