/**
 * JobManager — In-memory async job tracker for background subagent jobs.
 *
 * Manages job lifecycle (create, complete, fail, cancel) with a max concurrency
 * cap of 8 running jobs. Supports serialization for session persistence.
 */

import { randomBytes } from "node:crypto";
import type { ChildProcess } from "node:child_process";
import type { Message } from "@earendil-works/pi-ai";
import type { ThinkingLevel } from "@earendil-works/pi-agent-core";
import type { Guardrails } from "./guardrails.js";
import type { SubagentConfig } from "./subagent-config.js";

export interface UsageStats {
	input: number;
	output: number;
	cacheRead: number;
	cacheWrite: number;
	cost: number;
	contextTokens: number;
	turns: number;
}

export interface SingleResult {
	name: string;
	task: string;
	exitCode: number;
	messages: Message[];
	stderr: string;
	usage: UsageStats;
	provider?: string;
	model?: string;
	thinking?: ThinkingLevel;
	tools?: string[];
	stopReason?: string;
	errorMessage?: string;
	step?: number;
}

export interface OriginalInvocation {
	config: SubagentConfig;
	task: string;
	cwd?: string;
	guardrails: Guardrails;
	resumedFrom?: string;
}

export type JobStatus = "running" | "completed" | "failed" | "cancelled";

export interface AsyncJob {
	id: string;
	name: string;
	task: string;
	status: JobStatus;
	process: ChildProcess | null;
	result: SingleResult | null;
	startedAt: number;
	completedAt: number | null;
	tools?: string[];
	guardrails?: Guardrails;
	original?: OriginalInvocation;
}

export interface SerializedJob {
	id: string;
	name: string;
	task: string;
	status: JobStatus;
	result: SingleResult | null;
	startedAt: number;
	completedAt: number | null;
	tools?: string[];
	guardrails?: Guardrails;
	original?: OriginalInvocation;
}

export const MAX_RUNNING_JOBS = 8;

/**
 * terminateProcess — shared SIGTERM/SIGKILL logic.
 *
 * Sends SIGTERM, waits up to 5s, sends SIGKILL if process hasn't exited.
 * Resolves immediately if the process is already killed.
 */
export function terminateProcess(proc: ChildProcess): Promise<void> {
	return new Promise((resolve) => {
		if (proc.killed) { resolve(); return; }
		proc.kill("SIGTERM");
		const timeout = setTimeout(() => {
			if (!proc.killed) proc.kill("SIGKILL");
		}, 5000);
		proc.on("close", () => {
			clearTimeout(timeout);
			resolve();
		});
	});
}

export class JobManager {
	private jobs = new Map<string, AsyncJob>();
	private onCancel: ((job: AsyncJob) => void) | null = null;
	private onPartialResult: ((jobId: string, partial: SingleResult) => void) | null = null;

	createJob(name: string, task: string, guardrails?: Guardrails, original?: OriginalInvocation): AsyncJob {
		const running = this.listRunning();
		if (running.length >= MAX_RUNNING_JOBS) {
			throw new Error(
				`Maximum ${MAX_RUNNING_JOBS} concurrent async jobs. Cancel a job or wait for one to complete.`,
			);
		}
		// 3 bytes = 6 hex chars = 16M values per name prefix (safe from birthday collisions)
		let id: string;
		let attempts = 0;
		do {
			id = `${name}-${randomBytes(3).toString("hex")}`;
			attempts++;
		} while (this.jobs.has(id) && attempts < 10);
		const job: AsyncJob = {
			id,
			name,
			task,
			status: "running",
			process: null,
			result: null,
			startedAt: Date.now(),
			completedAt: null,
			guardrails,
			original,
		};
		this.jobs.set(id, job);
		return job;
	}

	setOnCancel(callback: (job: AsyncJob) => void): void {
		this.onCancel = callback;
	}

	setOnPartialResult(callback: (jobId: string, partial: SingleResult) => void): void {
		this.onPartialResult = callback;
	}

	setProcess(jobId: string, proc: ChildProcess): void {
		const job = this.jobs.get(jobId);
		if (job) job.process = proc;
	}

	updatePartialResult(jobId: string, partial: SingleResult): void {
		const job = this.jobs.get(jobId);
		if (!job || job.status !== "running") return;

		// spawnSubagentProcess sends accumulated snapshots (not deltas),
		// so we simply replace the result with the latest state.
		job.result = partial;
		this.onPartialResult?.(jobId, partial);
	}

	completeJob(jobId: string, result: SingleResult): void {
		const job = this.jobs.get(jobId);
		if (job && job.status === "running") {
			job.status = "completed";
			job.result = result;
			job.completedAt = Date.now();
			job.process = null;
		}
	}

	failJob(jobId: string, error: string): void {
		const job = this.jobs.get(jobId);
		if (job && job.status === "running") {
			job.status = "failed";
			job.result = job.result ?? {
				name: job.name,
				task: job.task,
				exitCode: 1,
				messages: [],
				stderr: error,
				usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
				errorMessage: error,
			};
			job.completedAt = Date.now();
			job.process = null;
		}
	}

	cancelJob(jobId: string): void {
		const job = this.jobs.get(jobId);
		if (job && job.status === "running") {
			// Capture process reference BEFORE nullifying job.process,
			// so the SIGKILL timeout closure can still access it.
			const proc = job.process;
			if (proc) {
				terminateProcess(proc); // fire and forget — don't await
			}
			job.status = "cancelled";
			job.completedAt = Date.now();
			this.onCancel?.(job);
			job.process = null;
		}
	}

	cancelAll(): void {
		const cancelledJobs: AsyncJob[] = [];
		for (const job of this.jobs.values()) {
			if (job.status === "running") {
				const proc = job.process;
				if (proc) {
					terminateProcess(proc); // fire and forget — don't await
				}
				job.status = "cancelled";
				job.completedAt = Date.now();
				job.process = null;
				cancelledJobs.push(job);
			}
		}
		// Notify after all cancellations to avoid concurrent modification
		for (const job of cancelledJobs) {
			this.onCancel?.(job);
		}
	}

	getJob(id: string): AsyncJob | undefined {
		return this.jobs.get(id);
	}

	listJobs(): AsyncJob[] {
		return Array.from(this.jobs.values());
	}

	listRunning(): AsyncJob[] {
		return Array.from(this.jobs.values()).filter((j) => j.status === "running");
	}

	serialize(): SerializedJob[] {
		return Array.from(this.jobs.values()).map((j) => ({
			id: j.id,
			name: j.name,
			task: j.task,
			status: j.status,
			result: j.result,
			startedAt: j.startedAt,
			completedAt: j.completedAt,
			tools: j.tools,
			guardrails: j.guardrails,
			original: j.original,
		}));
	}

	deserialize(data: SerializedJob[]): void {
		this.jobs.clear();
		for (const d of data) {
			// After session restore, "running" jobs have no process — mark as cancelled
			const status: JobStatus = d.status === "running" ? "cancelled" : d.status;
			// Backward-compat: legacy data may use 'agent' instead of 'name'
			const name = d.name ?? (d as any).agent ?? "unknown";
			const result = d.result
				? { ...d.result, name: d.result.name ?? (d.result as any).agent ?? name }
				: null;
			const job: AsyncJob = {
				id: d.id,
				name,
				task: d.task,
				status,
				process: null,
				result,
				startedAt: d.startedAt,
				completedAt: d.completedAt,
				tools: d.tools,
				guardrails: d.guardrails,
				original: d.original,
			};
			this.jobs.set(d.id, job);
		}
	}

	runningCount(): number {
		return this.listRunning().length;
	}
}