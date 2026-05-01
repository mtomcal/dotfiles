/**
 * Subagent Extension — Six-Tool Async Subagent Architecture
 *
 * Tools:
 *   subagent_run    - Blocking single, parallel, chain
 *   subagent_fork   - Async background job(s)
 *   subagent_status - Check job status / list all
 *   subagent_results- Get full output of a job
 *   subagent_wait   - Block until job completes
 *   subagent_cancel - Cancel one or all jobs
 *
 * Key invariants:
 * - Max 8 concurrent async jobs
 * - Job ID format: {agentName}-{shortRandom}
 * - Fork always returns immediately
 * - Completion notifications via pi.sendMessage() with deliverAs: "steer"
 * - Running jobs killed on session_shutdown
 */

import { spawn, type ChildProcess } from "node:child_process";
import { randomBytes } from "node:crypto";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ThinkingLevel } from "@mariozechner/pi-agent-core";
import type { Message } from "@mariozechner/pi-ai";
import { StringEnum } from "@mariozechner/pi-ai";
import {
	type ExtensionAPI,
	getMarkdownTheme,
	withFileMutationQueue,
} from "@mariozechner/pi-coding-agent";
import { Container, Markdown, Spacer, Text } from "@mariozechner/pi-tui";
import { Type } from "typebox";
import { type AgentConfig, type AgentScope, discoverAgents, normalizeOptional } from "./agents.js";
import { JobManager, type AsyncJob, type SingleResult, MAX_RUNNING_JOBS } from "./job-manager.js";
import {
	type SubagentDetails,
	aggregateUsage,
	COLLAPSED_ITEM_COUNT,
	formatToolCall,
	formatUsageStats,
	getDisplayItems,
	getFinalOutput,
	MAX_CONCURRENCY,
	MAX_PARALLEL_TASKS,
	renderJobStatusLine,
	renderSingleResult,
} from "./renderers.js";

// ─── Schema Definitions ───────────────────────────────────────────────

const ProviderSchema = Type.Optional(
	Type.String({
		description: "Provider override. Prevents accidental routing to expensive providers.",
	}),
);

const ThinkingSchema = Type.Optional(
	StringEnum(["off", "minimal", "low", "medium", "high", "xhigh"] as const, {
		description: "Thinking level override. Overrides agent definition default.",
	}),
);

const TaskItem = Type.Object({
	agent: Type.String({ description: "Name of the agent to invoke" }),
	task: Type.String({ description: "Task to delegate to the agent" }),
	cwd: Type.Optional(Type.String({ description: "Working directory for the agent process" })),
	provider: ProviderSchema,
	thinking: ThinkingSchema,
});

const ChainItem = Type.Object({
	agent: Type.String({ description: "Name of the agent to invoke" }),
	task: Type.String({ description: "Task with optional {previous} placeholder for prior output" }),
	cwd: Type.Optional(Type.String({ description: "Working directory for the agent process" })),
	provider: ProviderSchema,
	thinking: ThinkingSchema,
});

const AgentScopeSchema = StringEnum(["user", "project", "both"] as const, {
	description: 'Which agent directories to use. Default: "user". Use "both" to include project-local agents.',
	default: "user",
});

const ForkItem = Type.Object({
	agent: Type.String({ description: "Name of the agent to invoke" }),
	task: Type.String({ description: "Task to delegate to the agent" }),
	cwd: Type.Optional(Type.String({ description: "Working directory for the agent process" })),
	provider: ProviderSchema,
	thinking: ThinkingSchema,
});

// ─── Helpers ──────────────────────────────────────────────────────────

const nullProc = { kill: () => {}, killed: true } as ChildProcess;

function getPiInvocation(args: string[]): { command: string; args: string[] } {
	const currentScript = process.argv[1];
	const isBunVirtualScript = currentScript?.startsWith("/$bunfs/root/");
	if (currentScript && !isBunVirtualScript && fs.existsSync(currentScript)) {
		return { command: process.execPath, args: [currentScript, ...args] };
	}

	const execName = path.basename(process.execPath).toLowerCase();
	const isGenericRuntime = /^(node|bun)(\.exe)?$/.test(execName);
	if (!isGenericRuntime) {
		return { command: process.execPath, args };
	}

	return { command: "pi", args };
}

async function writePromptToTempFile(
	agentName: string,
	prompt: string,
): Promise<{ dir: string; filePath: string }> {
	const tmpDir = await fs.promises.mkdtemp(path.join(os.tmpdir(), "pi-subagent-"));
	const safeName = agentName.replace(/[^\w.-]+/g, "_");
	const filePath = path.join(tmpDir, `prompt-${safeName}.md`);
	await withFileMutationQueue(filePath, async () => {
		await fs.promises.writeFile(filePath, prompt, { encoding: "utf-8", mode: 0o600 });
	});
	return { dir: tmpDir, filePath };
}

function cleanupTempFiles(files: { dir: string | null; filePath: string | null }[]): void {
	for (const f of files) {
		if (f.filePath)
			try { fs.unlinkSync(f.filePath); } catch { /* ignore */ }
		if (f.dir)
			try { fs.rmdirSync(f.dir); } catch { /* ignore */ }
	}
}

async function mapWithConcurrencyLimit<TIn, TOut>(
	items: TIn[],
	concurrency: number,
	fn: (item: TIn, index: number) => Promise<TOut>,
): Promise<TOut[]> {
	if (items.length === 0) return [];
	const limit = Math.max(1, Math.min(concurrency, items.length));
	const results: TOut[] = new Array(items.length);
	let nextIndex = 0;
	const workers = new Array(limit).fill(null).map(async () => {
		while (true) {
			const current = nextIndex++;
			if (current >= items.length) return;
			results[current] = await fn(items[current], current);
		}
	});
	await Promise.all(workers);
	return results;
}

function resolveEffectiveConfig(options: {
	agent: AgentConfig | undefined;
	topLevelProvider?: string;
	topLevelThinking?: ThinkingLevel;
	perTaskProvider?: string;
	perTaskThinking?: ThinkingLevel;
}): { provider?: string; model?: string; thinking: ThinkingLevel } {
	return {
		provider:
			normalizeOptional(options.perTaskProvider) ??
			normalizeOptional(options.topLevelProvider) ??
			options.agent?.provider,
		model: options.agent?.model,
		thinking: options.perTaskThinking ?? options.topLevelThinking ?? options.agent?.thinking ?? "medium",
	};
}

function findAgent(agents: AgentConfig[], name: string): AgentConfig | undefined {
	return agents.find((a) => a.name === name);
}

function agentToTaskError(agentName: string, agents: AgentConfig[]): SingleResult {
	const available = agents.map((a) => `"${a.name}"`).join(", ") || "none";
	return {
		agent: agentName,
		agentSource: "unknown",
		task: "",
		exitCode: 1,
		messages: [],
		stderr: `Unknown agent: "${agentName}". Available agents: ${available}.`,
		usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
		errorMessage: `Unknown agent: "${agentName}". Available agents: ${available}.`,
	};
}

function spawnSubagentProcess(
	agents: AgentConfig[],
	agentName: string,
	task: string,
	cwd: string | undefined,
	defaultCwd: string,
	signal: AbortSignal | undefined,
	topLevelProvider: string | undefined,
	topLevelThinking: ThinkingLevel | undefined,
	perTaskProvider: string | undefined,
	perTaskThinking: ThinkingLevel | undefined,
	step: number | undefined,
	onMessage?: (result: SingleResult) => void,
): { proc: ChildProcess; resultPromise: Promise<SingleResult> } {
	const agent = findAgent(agents, agentName);
	if (!agent) {
		const errorResult = agentToTaskError(agentName, agents);
		return { proc: nullProc, resultPromise: Promise.resolve(errorResult) };
	}

	const effective = resolveEffectiveConfig({ agent, topLevelProvider, topLevelThinking, perTaskProvider, perTaskThinking });

	const args: string[] = ["--mode", "json", "-p", "--no-session"];
	if (effective.provider) args.push("--provider", effective.provider);
	if (effective.model) args.push("--model", effective.model);
	if (effective.thinking !== "medium") args.push("--thinking", effective.thinking);
	if (agent.tools && agent.tools.length > 0) args.push("--tools", agent.tools.join(","));

	let tmpPromptDir: string | null = null;
	let tmpPromptPath: string | null = null;

	const currentResult: SingleResult = {
		agent: agentName,
		agentSource: agent.source,
		task,
		exitCode: 0,
		messages: [],
		stderr: "",
		usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
		provider: effective.provider,
		model: effective.model,
		thinking: effective.thinking,
		step,
	};

	const emitUpdate = () => { if (onMessage) onMessage({ ...currentResult }); };

	let proc: ChildProcess = nullProc;
	const resultPromise = new Promise<SingleResult>(async (resolve) => {
		try {
			if (agent.systemPrompt.trim()) {
				const tmp = await writePromptToTempFile(agent.name, agent.systemPrompt);
				tmpPromptDir = tmp.dir;
				tmpPromptPath = tmp.filePath;
				args.push("--append-system-prompt", tmpPromptPath);
			}
			args.push(`Task: ${task}`);
		} catch (err) {
			cleanupTempFiles([{ dir: tmpPromptDir, filePath: tmpPromptPath }]);
			currentResult.exitCode = 1;
			currentResult.stderr = `Failed to prepare prompt: ${(err as Error).message}`;
			currentResult.errorMessage = (err as Error).message;
			resolve(currentResult);
			return;
		}

		const invocation = getPiInvocation(args);

		proc = spawn(invocation.command, invocation.args, {
			cwd: cwd ?? defaultCwd,
			shell: false,
			stdio: ["ignore", "pipe", "pipe"],
		});
		let buffer = "";
		let wasAborted = false;

		const processLine = (line: string) => {
			if (!line.trim()) return;
			let event: any;
			try { event = JSON.parse(line); } catch { return; }

			if (event.type === "message_end" && event.message) {
				const msg = event.message as Message;
				currentResult.messages.push(msg);
				if (msg.role === "assistant") {
					currentResult.usage.turns++;
					const usage = msg.usage;
					if (usage) {
						currentResult.usage.input += usage.input || 0;
						currentResult.usage.output += usage.output || 0;
						currentResult.usage.cacheRead += usage.cacheRead || 0;
						currentResult.usage.cacheWrite += usage.cacheWrite || 0;
						currentResult.usage.cost += usage.cost?.total || 0;
						currentResult.usage.contextTokens = usage.totalTokens || 0;
					}
					if (!currentResult.model && msg.model) currentResult.model = msg.model;
					if (msg.stopReason) currentResult.stopReason = msg.stopReason;
					if (msg.errorMessage) currentResult.errorMessage = msg.errorMessage;
				}
				emitUpdate();
			}
			if (event.type === "tool_result_end" && event.message) {
				currentResult.messages.push(event.message as Message);
				emitUpdate();
			}
		};

		proc.stdout.on("data", (data) => {
			buffer += data.toString();
			const lines = buffer.split("\n");
			buffer = lines.pop() || "";
			for (const line of lines) processLine(line);
		});
		proc.stderr.on("data", (data) => { currentResult.stderr += data.toString(); });

		proc.on("close", (code) => {
			if (buffer.trim()) processLine(buffer);
			cleanupTempFiles([{ dir: tmpPromptDir, filePath: tmpPromptPath }]);
			currentResult.exitCode = code ?? 0;
			if (wasAborted) {
				currentResult.exitCode = 1;
				currentResult.errorMessage = "Subagent was aborted";
			}
			emitUpdate();
			resolve(currentResult);
		});
		proc.on("error", () => {
			cleanupTempFiles([{ dir: tmpPromptDir, filePath: tmpPromptPath }]);
			currentResult.exitCode = 1;
			currentResult.errorMessage = "Failed to spawn subagent process";
			resolve(currentResult);
		});

		if (signal) {
			const killProc = () => {
				wasAborted = true;
				proc.kill("SIGTERM");
				setTimeout(() => { if (!proc.killed) proc.kill("SIGKILL"); }, 5000);
			};
			if (signal.aborted) killProc();
			else signal.addEventListener("abort", killProc, { once: true });
		}
	});

	return { proc, resultPromise };
}

// ─── Notification ─────────────────────────────────────────────────────

function emitCompletionNotification(pi: ExtensionAPI, job: AsyncJob): void {
	if (job.status === "cancelled" || !job.result) return;
	const result = job.result;
	const finalOutput = getFinalOutput(result.messages);

	const displayItems = getDisplayItems(result.messages);
	let smartContent = "";
	for (let i = displayItems.length - 1; i >= 0; i--) {
		if (displayItems[i].type === "text") { smartContent = displayItems[i].text; break; }
	}
	if (!smartContent) smartContent = finalOutput || "(no output)";

	const usageLine = formatUsageStats(result.usage, result.model, result.provider, result.thinking);
	const statusEmoji = job.status === "completed" ? "✓" : "✗";

	const notificationContent = [
		`**Subagent ${statusEmoji}: \`${job.agent}\` — ${job.status}**`,
		`**Job:** \`${job.id}\``,
		`**Task:** ${job.task}`,
		``,
		smartContent,
		``,
		usageLine ? `**Usage:** ${usageLine}` : "",
	].join("\n");

	pi.sendMessage(
		{
			customType: "subagent-result",
			content: notificationContent,
			display: true,
			details: {
				jobId: job.id,
				status: job.status,
				agent: job.agent,
				task: job.task,
				mode: "single",
				summary: smartContent,
				usage: result.usage,
				result,
			},
		},
		{ triggerTurn: true, deliverAs: "steer" },
	);
}

// ─── Serialization Helper ──────────────────────────────────────────────

function serializeJobForDetails(job: AsyncJob) {
	return {
		id: job.id,
		agent: job.agent,
		task: job.task,
		status: job.status,
		startedAt: job.startedAt,
		completedAt: job.completedAt,
		result: job.result
			? { agent: job.result.agent, task: job.result.task, exitCode: job.result.exitCode, usage: job.result.usage, errorMessage: job.result.errorMessage }
			: null,
	};
}

// ─── Shared Result Renderer ────────────────────────────────────────────

function renderSubagentResult(details: SubagentDetails, expanded: boolean, theme: any, result: any): any {
	if (details.mode === "single" && details.results.length === 1) {
		return renderSingleResult(details.results[0], theme, expanded);
	}

	const mdTheme = getMarkdownTheme();

	if (details.mode === "chain") {
		const successCount = details.results.filter((r) => r.exitCode === 0).length;
		const icon = successCount === details.results.length ? theme.fg("success", "✓") : theme.fg("error", "✗");

		if (expanded) {
			const container = new Container();
			container.addChild(new Text(icon + " " + theme.fg("toolTitle", theme.bold("chain ")) + theme.fg("accent", `${successCount}/${details.results.length} steps`), 0, 0));
			for (const r of details.results) {
				const rIcon = r.exitCode === 0 ? theme.fg("success", "✓") : theme.fg("error", "✗");
				const displayItems = getDisplayItems(r.messages);
				const finalOutput = getFinalOutput(r.messages);
				container.addChild(new Spacer(1));
				container.addChild(new Text(`${theme.fg("muted", `─── Step ${r.step}: `) + theme.fg("accent", r.agent)} ${rIcon}`, 0, 0));
				container.addChild(new Text(theme.fg("muted", "Task: ") + theme.fg("dim", r.task), 0, 0));
				for (const item of displayItems) {
					if (item.type === "toolCall")
						container.addChild(new Text(theme.fg("muted", "→ ") + formatToolCall(item.name, item.args, theme.fg.bind(theme)), 0, 0));
				}
				if (finalOutput) { container.addChild(new Spacer(1)); container.addChild(new Markdown(finalOutput.trim(), 0, 0, mdTheme)); }
				const stepUsage = formatUsageStats(r.usage, r.model, r.provider, r.thinking);
				if (stepUsage) container.addChild(new Text(theme.fg("dim", stepUsage), 0, 0));
			}
			const usageStr = formatUsageStats(aggregateUsage(details.results));
			if (usageStr) { container.addChild(new Spacer(1)); container.addChild(new Text(theme.fg("dim", `Total: ${usageStr}`), 0, 0)); }
			return container as unknown as Component;
		}

		let text = icon + " " + theme.fg("toolTitle", theme.bold("chain ")) + theme.fg("accent", `${successCount}/${details.results.length} steps`);
		for (const r of details.results) {
			const rIcon = r.exitCode === 0 ? theme.fg("success", "✓") : theme.fg("error", "✗");
			text += `\n\n${theme.fg("muted", `─── Step ${r.step}: `)}${theme.fg("accent", r.agent)} ${rIcon}`;
			const displayItems = getDisplayItems(r.messages);
			if (displayItems.length === 0) text += `\n${theme.fg("muted", "(no output)")}`;
			else text += `\n${renderDisplayItemsCollapsed(displayItems, 5, theme)}`;
		}
		const usageStr = formatUsageStats(aggregateUsage(details.results));
		if (usageStr) text += `\n\n${theme.fg("dim", `Total: ${usageStr}`)}`;
		text += `\n${theme.fg("muted", "(Ctrl+O to expand)")}`;
		return new Text(text, 0, 0) as any;
	}

	if (details.mode === "parallel") {
		const running = details.results.filter((r) => r.exitCode === -1).length;
		const successCount = details.results.filter((r) => r.exitCode === 0).length;
		const failCount = details.results.filter((r) => r.exitCode > 0).length;
		const isRunning = running > 0;
		const icon = isRunning ? theme.fg("warning", "⏳") : failCount > 0 ? theme.fg("warning", "◐") : theme.fg("success", "✓");
		const status = isRunning ? `${successCount + failCount}/${details.results.length} done, ${running} running` : `${successCount}/${details.results.length} tasks`;

		if (expanded && !isRunning) {
			const container = new Container();
			container.addChild(new Text(`${icon} ${theme.fg("toolTitle", theme.bold("parallel "))}${theme.fg("accent", status)}`, 0, 0));
			for (const r of details.results) {
				const rIcon = r.exitCode === 0 ? theme.fg("success", "✓") : theme.fg("error", "✗");
				const finalOutput = getFinalOutput(r.messages);
				container.addChild(new Spacer(1));
				container.addChild(new Text(`${theme.fg("muted", "─── ") + theme.fg("accent", r.agent)} ${rIcon}`, 0, 0));
				container.addChild(new Text(theme.fg("muted", "Task: ") + theme.fg("dim", r.task), 0, 0));
				const displayItems = getDisplayItems(r.messages);
				for (const item of displayItems) {
					if (item.type === "toolCall")
						container.addChild(new Text(theme.fg("muted", "→ ") + formatToolCall(item.name, item.args, theme.fg.bind(theme)), 0, 0));
				}
				if (finalOutput) { container.addChild(new Spacer(1)); container.addChild(new Markdown(finalOutput.trim(), 0, 0, mdTheme)); }
				const taskUsage = formatUsageStats(r.usage, r.model, r.provider, r.thinking);
				if (taskUsage) container.addChild(new Text(theme.fg("dim", taskUsage), 0, 0));
			}
			const usageStr = formatUsageStats(aggregateUsage(details.results));
			if (usageStr) { container.addChild(new Spacer(1)); container.addChild(new Text(theme.fg("dim", `Total: ${usageStr}`), 0, 0)); }
			return container as unknown as Component;
		}

		let text = `${icon} ${theme.fg("toolTitle", theme.bold("parallel "))}${theme.fg("accent", status)}`;
		for (const r of details.results) {
			const rIcon = r.exitCode === -1 ? theme.fg("warning", "⏳") : r.exitCode === 0 ? theme.fg("success", "✓") : theme.fg("error", "✗");
			const displayItems = getDisplayItems(r.messages);
			text += `\n\n${theme.fg("muted", "─── ")}${theme.fg("accent", r.agent)} ${rIcon}`;
			if (displayItems.length === 0) text += `\n${theme.fg("muted", r.exitCode === -1 ? "(running...)" : "(no output)")}`;
			else text += `\n${renderDisplayItemsCollapsed(displayItems, 5, theme)}`;
		}
		if (!isRunning) {
			const usageStr = formatUsageStats(aggregateUsage(details.results));
			if (usageStr) text += `\n\n${theme.fg("dim", `Total: ${usageStr}`)}`;
		}
		if (!expanded) text += `\n${theme.fg("muted", "(Ctrl+O to expand)")}`;
		return new Text(text, 0, 0) as any;
	}

	const text = result.content[0];
	return new Text(text?.type === "text" ? text.text : "(no output)", 0, 0);
}

function renderDisplayItemsCollapsed(items: ReturnType<typeof getDisplayItems>, limit: number, theme: any): string {
	const toShow = limit ? items.slice(-limit) : items;
	const skipped = limit && items.length > limit ? items.length - limit : 0;
	let text = "";
	if (skipped > 0) text += theme.fg("muted", `... ${skipped} earlier items\n`);
	for (const item of toShow) {
		if (item.type === "text") {
			text += `${theme.fg("toolOutput", item.text.split("\n").slice(0, 3).join("\n"))}\n`;
		} else {
			text += `${theme.fg("muted", "→ ") + formatToolCall(item.name, item.args, theme.fg.bind(theme))}\n`;
		}
	}
	return text.trimEnd();
}

// ═══════════════════════════════════════════════════════════════════════
// Extension Entry Point
// ═════════════════════════════════════════════════════════════════════════

export default function (pi: ExtensionAPI) {
	const jobMgr: JobManager = pi.jobMgr ?? new JobManager();
	if (!pi.jobMgr) pi.jobMgr = jobMgr;
	let agentsCache: { agents: AgentConfig[]; projectAgentsDir: string | null } | null = null;

	function getAgents(cwd: string, scope: AgentScope) {
		const discovery = discoverAgents(cwd, scope);
		agentsCache = discovery;
		return discovery;
	}

	function persist() {
		pi.appendEntry("subagent-job-state", jobMgr.serialize());
	}

	// ── Lifecycle ────────────────────────────────────────────────────
	pi.on("session_shutdown", async () => { jobMgr.cancelAll(); persist(); });
	pi.on("session_start", async (_event, ctx) => {
		for (const entry of ctx.sessionManager.getEntries()) {
			if (entry.type === "custom" && entry.customType === "subagent-job-state") {
				jobMgr.deserialize(entry.data as any);
			}
		}
	});

	// ── Tool: subagent_run (Blocking) ────────────────────────────────
	pi.registerTool({
		name: "subagent_run",
		label: "Subagent Run",
		description: [
			"Run a subagent synchronously.",
			"Modes: single (agent + task), parallel (tasks array), chain (sequential with {previous} placeholder).",
			"Blocks until completion.",
		].join(" "),
		parameters: Type.Object({
			agent: Type.Optional(Type.String({ description: "Name of the agent to invoke (for single mode)" })),
			task: Type.Optional(Type.String({ description: "Task to delegate (for single mode)" })),
			tasks: Type.Optional(Type.Array(TaskItem, { description: "Array of {agent, task} for parallel execution" })),
			chain: Type.Optional(Type.Array(ChainItem, { description: "Array of {agent, task} for sequential execution" })),
			agentScope: Type.Optional(AgentScopeSchema),
			confirmProjectAgents: Type.Optional(Type.Boolean({ description: "Prompt before running project-local agents. Default: true.", default: true })),
			cwd: Type.Optional(Type.String({ description: "Working directory for the agent process (single mode)" })),
			provider: ProviderSchema,
			thinking: ThinkingSchema,
		}),
		promptSnippet: "Run subagent tasks and get results immediately",
		promptGuidelines: [
			"Use subagent_run for blocking tasks where you need the result before continuing.",
			"Use subagent_fork instead when you want to start background work and continue your turn.",
		],

		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			const agentScope: AgentScope = params.agentScope ?? ("user" as AgentScope);
			const discovery = getAgents(ctx.cwd, agentScope);
			const agents = discovery.agents;
			const confirmProjectAgents = params.confirmProjectAgents ?? true;

			const hasChain = (params.chain?.length ?? 0) > 0;
			const hasTasks = (params.tasks?.length ?? 0) > 0;
			const hasSingle = Boolean(params.agent && params.task && params.task.trim());
			const modeCount = Number(hasChain) + Number(hasTasks) + Number(hasSingle);

			const makeDetails = (mode: "single" | "parallel" | "chain") => (results: SingleResult[]): SubagentDetails => ({
				mode, agentScope, projectAgentsDir: discovery.projectAgentsDir, results,
			});

			if (modeCount !== 1) {
				const available = agents.map((a) => `${a.name} (${a.source})`).join(", ") || "none";
				return { content: [{ type: "text", text: `Invalid parameters. Provide exactly one mode.\nAvailable agents: ${available}` }], details: makeDetails("single")([]) };
			}

			if ((agentScope === "project" || agentScope === "both") && confirmProjectAgents && ctx.hasUI) {
				const requestedAgentNames = new Set<string>();
				if (params.chain) for (const step of params.chain) requestedAgentNames.add(step.agent);
				if (params.tasks) for (const t of params.tasks) requestedAgentNames.add(t.agent);
				if (params.agent) requestedAgentNames.add(params.agent);
				const projectAgentsRequested = Array.from(requestedAgentNames)
					.map((name) => agents.find((a) => a.name === name))
					.filter((a): a is AgentConfig => a?.source === "project");
				if (projectAgentsRequested.length > 0) {
					const names = projectAgentsRequested.map((a) => a.name).join(", ");
					const dir = discovery.projectAgentsDir ?? "(unknown)";
					const ok = await ctx.ui.confirm("Run project-local agents?", `Agents: ${names}\nSource: ${dir}\n\nProject agents are repo-controlled. Only continue for trusted repositories.`);
					if (!ok) return { content: [{ type: "text", text: "Canceled: project-local agents not approved." }], details: makeDetails(hasChain ? "chain" : hasTasks ? "parallel" : "single")([]) };
				}
			}

			if (params.chain && params.chain.length > 0) {
				const results: SingleResult[] = [];
				let previousOutput = "";
				for (let i = 0; i < params.chain.length; i++) {
					const step = params.chain[i];
					const taskWithContext = step.task.replace(/\{previous\}/g, previousOutput);
					const { resultPromise } = spawnSubagentProcess(agents, step.agent, taskWithContext, step.cwd, ctx.cwd, signal, params.provider, params.thinking as ThinkingLevel | undefined, step.provider, step.thinking as ThinkingLevel | undefined, i + 1, onUpdate ? (cr) => { onUpdate({ content: [{ type: "text", text: getFinalOutput(cr.messages) || "(running...)" }], details: makeDetails("chain")([...results, cr]) }); } : undefined);
					const result = await resultPromise;
					results.push(result);
					const isError = result.exitCode !== 0 || result.stopReason === "error" || result.stopReason === "aborted";
					if (isError) {
						const errorMsg = result.errorMessage || result.stderr || getFinalOutput(result.messages) || "(no output)";
						return { content: [{ type: "text", text: `Chain stopped at step ${i + 1} (${step.agent}): ${errorMsg}` }], details: makeDetails("chain")(results), isError: true };
					}
					previousOutput = getFinalOutput(result.messages);
				}
				return { content: [{ type: "text", text: getFinalOutput(results[results.length - 1].messages) || "(no output)" }], details: makeDetails("chain")(results) };
			}

			if (params.tasks && params.tasks.length > 0) {
				if (params.tasks.length > MAX_PARALLEL_TASKS) return { content: [{ type: "text", text: `Too many parallel tasks (${params.tasks.length}). Max is ${MAX_PARALLEL_TASKS}.` }], details: makeDetails("parallel")([]) };
				const allResults: SingleResult[] = new Array(params.tasks.length);
				for (let i = 0; i < params.tasks.length; i++) {
					allResults[i] = { agent: params.tasks[i].agent, agentSource: "unknown", task: params.tasks[i].task, exitCode: -1, messages: [], stderr: "", usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 } };
				}
				const emitParallelUpdate = () => { if (onUpdate) { onUpdate({ content: [{ type: "text", text: `Parallel: ${allResults.filter((r) => r.exitCode !== -1).length}/${allResults.length} done...` }], details: makeDetails("parallel")([...allResults]) }); } };
				const results = await mapWithConcurrencyLimit(params.tasks, MAX_CONCURRENCY, async (t, index) => {
					const { resultPromise } = spawnSubagentProcess(agents, t.agent, t.task, t.cwd, ctx.cwd, signal, params.provider, params.thinking as ThinkingLevel | undefined, t.provider, t.thinking as ThinkingLevel | undefined, undefined, (partial) => { allResults[index] = partial; emitParallelUpdate(); });
					const result = await resultPromise;
					allResults[index] = result;
					emitParallelUpdate();
					return result;
				});
				const successCount = results.filter((r) => r.exitCode === 0).length;
				const summaries = results.map((r) => {
					const output = getFinalOutput(r.messages);
					const truncated = output.length > 500 ? output.slice(0, 500) + "\n\n*(...truncated, full output in details)*" : output;
					return `## ${r.agent} (${r.exitCode === 0 ? "completed" : "failed"})\n\n${truncated || "(no output)"}`;
				});
				return { content: [{ type: "text", text: `Parallel: ${successCount}/${results.length} succeeded\n\n${summaries.join("\n\n---\n\n")}` }], details: makeDetails("parallel")(results) };
			}

			if (params.agent && params.task) {
				const { resultPromise } = spawnSubagentProcess(agents, params.agent, params.task, params.cwd, ctx.cwd, signal, params.provider, params.thinking as ThinkingLevel | undefined, undefined, undefined, undefined, onUpdate ? (cr) => { onUpdate({ content: [{ type: "text", text: getFinalOutput(cr.messages) || "(running...)" }], details: makeDetails("single")([cr]) }); } : undefined);
				const result = await resultPromise;
				const isError = result.exitCode !== 0 || result.stopReason === "error" || result.stopReason === "aborted";
				if (isError) {
					const errorMsg = result.errorMessage || result.stderr || getFinalOutput(result.messages) || "(no output)";
					return { content: [{ type: "text", text: `Agent ${result.stopReason || "failed"}: ${errorMsg}` }], details: makeDetails("single")([result]), isError: true };
				}
				return { content: [{ type: "text", text: getFinalOutput(result.messages) || "(no output)" }], details: makeDetails("single")([result]) };
			}

			const available = agents.map((a) => `${a.name} (${a.source})`).join(", ") || "none";
			return { content: [{ type: "text", text: `Invalid parameters. Available agents: ${available}` }], details: makeDetails("single")([]) };
		},

		renderCall(args, theme, _context) {
			const scope: AgentScope = args.agentScope ?? "user";
			if (args.chain && args.chain.length > 0) {
				let text = theme.fg("toolTitle", theme.bold("subagent_run ")) + theme.fg("accent", `chain (${args.chain.length} steps)`) + theme.fg("muted", ` [${scope}]`);
				for (let i = 0; i < Math.min(args.chain.length, 3); i++) {
					const step = args.chain[i];
					const cleanTask = step.task.replace(/\{previous\}/g, "").trim();
					text += "\n  " + theme.fg("muted", `${i + 1}.`) + " " + theme.fg("accent", step.agent);
					const meta: string[] = [];
					if (step.provider) meta.push(step.provider);
					if (step.thinking && step.thinking !== "medium") meta.push(`think:${step.thinking}`);
					if (meta.length > 0) text += theme.fg("muted", ` (${meta.join(", ")})`);
					text += theme.fg("dim", ` ${cleanTask.length > 40 ? cleanTask.slice(0, 40) + "..." : cleanTask}`);
				}
				if (args.chain.length > 3) text += `\n  ${theme.fg("muted", `... +${args.chain.length - 3} more`)}`;
				return new Text(text, 0, 0);
			}
			if (args.tasks && args.tasks.length > 0) {
				let text = theme.fg("toolTitle", theme.bold("subagent_run ")) + theme.fg("accent", `parallel (${args.tasks.length} tasks)`) + theme.fg("muted", ` [${scope}]`);
				for (const t of args.tasks.slice(0, 3)) {
					text += `\n  ${theme.fg("accent", t.agent)}`;
					const meta: string[] = [];
					if (t.provider) meta.push(t.provider);
					if (t.thinking && t.thinking !== "medium") meta.push(`think:${t.thinking}`);
					if (meta.length > 0) text += theme.fg("muted", ` (${meta.join(", ")})`);
					text += theme.fg("dim", ` ${t.task.length > 40 ? t.task.slice(0, 40) + "..." : t.task}`);
				}
				if (args.tasks.length > 3) text += `\n  ${theme.fg("muted", `... +${args.tasks.length - 3} more`)}`;
				return new Text(text, 0, 0);
			}
			const agentName = args.agent || "...";
			const preview = args.task ? (args.task.length > 60 ? `${args.task.slice(0, 60)}...` : args.task) : "...";
			let text = theme.fg("toolTitle", theme.bold("subagent_run ")) + theme.fg("accent", agentName) + theme.fg("muted", ` [${scope}]`);
			if (args.provider || args.thinking) {
				const meta: string[] = [];
				if (args.provider) meta.push(args.provider);
				if (args.thinking && args.thinking !== "medium") meta.push(`think:${args.thinking}`);
				if (meta.length > 0) text += theme.fg("muted", ` (${meta.join(", ")})`);
			}
			text += `\n  ${theme.fg("dim", preview)}`;
			return new Text(text, 0, 0);
		},

		renderResult(result, { expanded }, theme, _context) {
			const details = result.details as SubagentDetails | undefined;
			if (!details || details.results.length === 0) {
				const text = result.content[0];
				return new Text(text?.type === "text" ? text.text : "(no output)", 0, 0);
			}
			return renderSubagentResult(details, expanded, theme, result);
		},
	});

	// ── Tool: subagent_fork (Async background) ───────────────────────
	pi.registerTool({
		name: "subagent_fork",
		label: "Subagent Fork",
		description: "Start one or more background subagent jobs. Returns immediately with job IDs. You receive a completion notification when each job finishes. Max 8 concurrent jobs.",
		parameters: Type.Object({
			agent: Type.Optional(Type.String({ description: "Name of the agent to invoke (for single mode)" })),
			task: Type.Optional(Type.String({ description: "Task to delegate (for single mode)" })),
			tasks: Type.Optional(Type.Array(ForkItem, { description: "Array of {agent, task} for parallel fork" })),
			agentScope: Type.Optional(AgentScopeSchema),
			cwd: Type.Optional(Type.String({ description: "Working directory for the agent process (single mode)" })),
			provider: ProviderSchema,
			thinking: ThinkingSchema,
		}),
		promptSnippet: "Fork background subagent jobs, continue working while they run",
		promptGuidelines: [
			"Use subagent_fork when you want to start work and continue your turn without waiting.",
			"After forking, continue your work. You will receive a completion notification for each job with a summary and usage stats.",
			"When you receive a notification, call subagent_results with the jobId only if you need the full detail beyond the summary.",
			"You may have up to 8 background jobs running at once. Check with subagent_status before forking more.",
			"Use subagent_run when you need the result immediately. Use subagent_fork when you can work on other things in parallel.",
		],

		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const agentScope: AgentScope = params.agentScope ?? ("user" as AgentScope);
			const discovery = getAgents(ctx.cwd, agentScope);
			const agents = discovery.agents;

			const tasks: Array<{ agent: string; task: string; cwd?: string; provider?: string; thinking?: ThinkingLevel }> = [];
			if (params.agent && params.task && params.task.trim()) {
				tasks.push({ agent: params.agent, task: params.task.trim(), cwd: params.cwd, provider: params.provider, thinking: params.thinking as ThinkingLevel | undefined });
			} else if (params.tasks && params.tasks.length > 0) {
				for (const t of params.tasks) {
					if (!t.task || !t.task.trim()) {
						return { content: [{ type: "text", text: `Task for agent "${t.agent}" must not be empty.` }], details: { jobs: [] }, isError: true };
					}
					tasks.push({ agent: t.agent, task: t.task.trim(), cwd: t.cwd, provider: t.provider, thinking: t.thinking as ThinkingLevel | undefined });
				}
			} else {
				return { content: [{ type: "text", text: "Provide agent+task or tasks[] to fork." }], details: { jobs: [] }, isError: true };
			}

			// Check cap before spawning
			const available = MAX_RUNNING_JOBS - jobMgr.runningCount();
			if (tasks.length > available) {
				return { content: [{ type: "text", text: `Maximum ${MAX_RUNNING_JOBS} concurrent async jobs (${jobMgr.runningCount()} running). Cancel a job or wait for one to complete.` }], details: { jobs: [] }, isError: true };
			}

			const spawnedJobs: Array<{ id: string; agent: string; task: string; status: string; provider?: string; thinking?: string }> = [];

			for (const t of tasks) {
				// Always create job entry first so it counts against the cap.
				// If createJob throws here the cap has been reached mid-batch — return an error.
				let job;
				try { job = jobMgr.createJob(t.agent, t.task); }
				catch (err) {
					// Cap hit mid-batch: don't silently skip the remaining tasks.
					return { content: [{ type: "text", text: `Maximum ${MAX_RUNNING_JOBS} concurrent async jobs (${jobMgr.runningCount()} running). Cancel a job or wait for one to complete.` }], details: { jobs: spawnedJobs }, isError: true };
				}

				const agent = findAgent(agents, t.agent);
				if (!agent) {
					// Agent not found — immediately fail the job
					const errorResult = agentToTaskError(t.agent, agents);
					jobMgr.failJob(job.id, errorResult.errorMessage!);
					spawnedJobs.push({ id: job.id, agent: t.agent, task: t.task, status: "failed", provider: t.provider || params.provider, thinking: (t.thinking ?? params.thinking) as string | undefined });
					continue;
				}
				const taskPreview = t.task.length > 60 ? `${t.task.slice(0, 60)}...` : t.task;
				spawnedJobs.push({ id: job.id, agent: t.agent, task: taskPreview, status: "running", provider: t.provider || params.provider, thinking: (t.thinking ?? params.thinking) as string | undefined });

				const { proc, resultPromise } = spawnSubagentProcess(agents, t.agent, t.task, t.cwd, ctx.cwd, undefined, t.provider || params.provider, t.thinking || (params.thinking as ThinkingLevel | undefined), undefined, undefined, undefined);
				jobMgr.setProcess(job.id, proc);

				// Handle completion asynchronously
				resultPromise.then((result) => {
					if (result.exitCode === 0 && !result.errorMessage) jobMgr.completeJob(job.id, result);
					else jobMgr.failJob(job.id, result.errorMessage || result.stderr || "Process failed");
					persist();
					try { emitCompletionNotification(pi, jobMgr.getJob(job.id)!); } catch { /* notification best-effort */ }
				}).catch((err) => {
					jobMgr.failJob(job.id, (err as Error).message);
					persist();
					try { emitCompletionNotification(pi, jobMgr.getJob(job.id)!); } catch { /* notification best-effort */ }
				});
			}

			persist();

			const running = jobMgr.runningCount();
			const jobLines = spawnedJobs.map((j) => `- \`${j.id}\`: **${j.agent}** — ${j.task} (${j.status})`).join("\n");
			return {
				content: [{ type: "text", text: `Forked ${spawnedJobs.length} job${spawnedJobs.length > 1 ? "s" : ""} (${running}/${MAX_RUNNING_JOBS} running)\n\n${jobLines}` }],
				details: { jobs: spawnedJobs },
			};
		},

		renderCall(args, theme, _context) {
			if (args.tasks && args.tasks.length > 0) {
				let text = theme.fg("toolTitle", theme.bold("subagent_fork ")) + theme.fg("accent", `${args.tasks.length} jobs`);
				for (const t of args.tasks.slice(0, 3)) {
					text += `\n  ${theme.fg("accent", t.agent)}${theme.fg("dim", ` ${t.task.length > 40 ? t.task.slice(0, 40) + "..." : t.task}`)}`;
				}
				if (args.tasks.length > 3) text += `\n  ${theme.fg("muted", `... +${args.tasks.length - 3} more`)}`;
				return new Text(text, 0, 0);
			}
			const agentName = args.agent || "...";
			const preview = args.task ? (args.task.length > 60 ? `${args.task.slice(0, 60)}...` : args.task) : "...";
			return new Text(theme.fg("toolTitle", theme.bold("subagent_fork ")) + theme.fg("accent", agentName) + theme.fg("dim", ` ${preview}`), 0, 0);
		},

		renderResult(result, _options, theme, _context) {
			const text = result.content[0];
			return new Text(`🔄 ${text?.type === "text" ? text.text : ""}`, 0, 0);
		},
	});

	// ── Tool: subagent_status ────────────────────────────────────────
	pi.registerTool({
		name: "subagent_status",
		label: "Subagent Status",
		description: "Check the status of background subagent jobs. With no arguments, lists all jobs. With a jobId, shows details for that specific job.",
		parameters: Type.Object({
			jobId: Type.Optional(Type.String({ description: "Job ID to check. Omit to list all jobs." })),
		}),
		promptSnippet: "Check subagent job status",
		promptGuidelines: [
			"Use subagent_status to check on your background jobs.",
			"Call without arguments to see an overview of all jobs (running, completed, failed).",
			"You don't need to poll — you will be notified when each job completes.",
		],

		async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
			if (params.jobId) {
				const job = jobMgr.getJob(params.jobId);
				if (!job) return { content: [{ type: "text", text: `Job "${params.jobId}" not found.` }], isError: true };

				const statusIcons: Record<string, string> = { running: "⏳", completed: "✓", failed: "✗", cancelled: "⊘" };
				const icon = statusIcons[job.status] || "?";
				const now = Date.now();
				const elapsedMs = (job.completedAt ?? now) - job.startedAt;
				const elapsed = elapsedMs < 1000 ? `${elapsedMs}ms` : elapsedMs < 60000 ? `${Math.round(elapsedMs / 1000)}s` : `${Math.floor(elapsedMs / 60000)}m ${Math.round((elapsedMs % 60000) / 1000)}s`;

				let text = `**${icon} ${job.agent}** — ${job.status}\n\n**Job ID:** \`${job.id}\`\n**Task:** ${job.task}\n**Elapsed:** ${elapsed}`;
				if (job.status === "completed" && job.result) {
					const out = getFinalOutput(job.result.messages);
					if (out) text += `\n\n**Summary:**\n${out.length > 500 ? out.slice(0, 500) + "\n\n... (truncated)" : out}`;
					const usage = formatUsageStats(job.result.usage, job.result.model, job.result.provider, job.result.thinking);
					if (usage) text += `\n\n**Usage:** ${usage}`;
				}
				if (job.status === "failed" && job.result) {
					text += `\n\n**Error:** ${job.result.errorMessage || job.result.stderr || "(no error detail)"}`;
				}
				return { content: [{ type: "text", text }], details: { job: serializeJobForDetails(job) } };
			}

			const allJobs = jobMgr.listJobs();
			if (allJobs.length === 0) return { content: [{ type: "text", text: "No subagent jobs." }], details: { jobs: [], running: 0, total: 0 } };

			const running = allJobs.filter((j) => j.status === "running").length;
			const completed = allJobs.filter((j) => j.status === "completed").length;
			const failed = allJobs.filter((j) => j.status === "failed").length;
			const cancelled = allJobs.filter((j) => j.status === "cancelled").length;

			let text = `**${allJobs.length} jobs** — ${running} running, ${completed} completed, ${failed} failed, ${cancelled} cancelled\n\n`;
			for (const job of allJobs) {
				text += renderJobStatusLine(job, { fg: (_color: any, s: string) => s, bold: (s: string) => s } as any) + "\n";
			}
			return { content: [{ type: "text", text }], details: { jobs: allJobs.map(serializeJobForDetails), running, total: allJobs.length } };
		},

		renderCall(args, _theme, _context) {
			return new Text(args.jobId ? `subagent_status: checking job ${args.jobId}` : "subagent_status: listing all jobs", 0, 0);
		},

		renderResult(result, _options, theme, _context) {
			const text = result.content[0];
			return new Text(text?.type === "text" ? text.text : "(no status)", 0, 0);
		},
	});

	// ── Tool: subagent_results ───────────────────────────────────────
	pi.registerTool({
		name: "subagent_results",
		label: "Subagent Results",
		description: "Retrieve the full output of a completed subagent job, including all messages and tool calls. The job must be completed (not running).",
		parameters: Type.Object({
			jobId: Type.String({ description: "Job ID to retrieve results for" }),
		}),
		promptSnippet: "Get full subagent job results",
		promptGuidelines: [
			"Use subagent_results when you need the complete output of a job, including intermediate tool calls and full messages.",
			"The completion notification already includes a summary. Only call subagent_results if you need more detail.",
			"subagent_results returns an error if the job is still running. Use subagent_wait to block until completion.",
		],

		async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
			const job = jobMgr.getJob(params.jobId);
			if (!job) return { content: [{ type: "text", text: `Job "${params.jobId}" not found.` }], isError: true };
			if (job.status === "running") return { content: [{ type: "text", text: `Job "${params.jobId}" is still running. Use subagent_wait to wait for completion, or subagent_status to check progress.` }], isError: true };
			if (!job.result) return { content: [{ type: "text", text: `Job "${params.jobId}" has no result data.` }], isError: true };

			const displayItems = getDisplayItems(job.result.messages);
			const finalOutput = getFinalOutput(job.result.messages);
			const usage = formatUsageStats(job.result.usage, job.result.model, job.result.provider, job.result.thinking);

			let text = `**Results for \`${params.jobId}\` (${job.agent} — ${job.status})**\n\n**Task:** ${job.task}\n`;
			if (job.result.errorMessage) text += `\n**Error:** ${job.result.errorMessage}\n`;
			if (displayItems.length > 0) {
				text += "\n**Messages:**\n\n";
				for (const item of displayItems) {
					if (item.type === "text") text += `${item.text}\n\n`;
					else {
						const argsStr = JSON.stringify(item.args);
						text += `→ *${item.name}* \`${argsStr.length > 100 ? argsStr.slice(0, 100) + "..." : argsStr}\`\n`;
					}
				}
			} else if (finalOutput) text += `\n${finalOutput}\n`;
			else text += "\n*(no output)*\n";
			if (usage) text += `\n**Usage:** ${usage}\n`;

			return { content: [{ type: "text", text }], details: { results: [job.result] } };
		},

		renderCall(args, _theme, _context) { return new Text(`subagent_results: retrieving ${args.jobId}`, 0, 0); },

		renderResult(result, { expanded }, theme, _context) {
			const details = result.details as { results?: SingleResult[] } | undefined;
			if (details?.results?.[0]) return renderSingleResult(details.results[0], theme, expanded);
			const text = result.content[0];
			return new Text(text?.type === "text" ? text.text : "(no results)", 0, 0);
		},
	});

	// ── Tool: subagent_wait ──────────────────────────────────────────
	pi.registerTool({
		name: "subagent_wait",
		label: "Subagent Wait",
		description: "Block until a specific background job completes. Default timeout is 300 seconds (5 minutes). Returns the full result when done.",
		parameters: Type.Object({
			jobId: Type.String({ description: "Job ID to wait for" }),
			timeout: Type.Optional(Type.Number({ description: "Timeout in seconds (default 300).", default: 300 })),
		}),
		promptSnippet: "Wait for a subagent job to complete",
		promptGuidelines: [
			"Use subagent_wait when you need the result of a background job and can't continue without it.",
			"Prefer waiting for the completion notification instead of calling subagent_wait — only use it when you explicitly need to block.",
			"The timeout defaults to 300 seconds. Specify a longer timeout for heavy tasks.",
		],

		async execute(_toolCallId, params, signal, _onUpdate, _ctx) {
			const job = jobMgr.getJob(params.jobId);
			if (!job) return { content: [{ type: "text", text: `Job "${params.jobId}" not found.` }], isError: true };

			if (job.status !== "running") {
				const result = job.result;
				const finalOutput = result ? getFinalOutput(result.messages) : "(no output)";
				const usage = result ? formatUsageStats(result.usage, result.model, result.provider, result.thinking) : "";
				return { content: [{ type: "text", text: `Job \`${params.jobId}\` (${job.agent}) already ${job.status}.\n${finalOutput ? `\n${finalOutput}\n` : ""}${usage ? `\n**Usage:** ${usage}` : ""}` }], details: { results: result ? [result] : [] } };
			}

			const timeoutMs = (params.timeout ?? 300) * 1000;
			const startTime = Date.now();

			while (Date.now() - startTime < timeoutMs) {
				const current = jobMgr.getJob(params.jobId);
				if (!current) return { content: [{ type: "text", text: `Job "${params.jobId}" was removed.` }], isError: true };
				if (current.status !== "running") {
					const result = current.result;
					const finalOutput = result ? getFinalOutput(result.messages) : "(no output)";
					const usage = result ? formatUsageStats(result.usage, result.model, result.provider, result.thinking) : "";
					return { content: [{ type: "text", text: `Job \`${params.jobId}\` (${current.agent}) ${current.status}.\n${finalOutput ? `\n${finalOutput}\n` : ""}${usage ? `\n**Usage:** ${usage}` : ""}` }], details: { results: result ? [result] : [] } };
				}
				if (signal?.aborted) return { content: [{ type: "text", text: `Wait for job "${params.jobId}" was aborted.` }], isError: true };
				await new Promise((resolve) => setTimeout(resolve, 500));
			}

			return { content: [{ type: "text", text: `Job "${params.jobId}" is still running after ${params.timeout ?? 300}s timeout. Check with subagent_status or extend the timeout.` }], details: { job: serializeJobForDetails(jobMgr.getJob(params.jobId)!) }, isError: true };
		},

		renderCall(args, _theme, _context) { return new Text(`subagent_wait: waiting for ${args.jobId} (timeout: ${args.timeout ?? 300}s)`, 0, 0); },

		renderResult(result, { expanded }, theme, _context) {
			const details = result.details as { results?: SingleResult[] } | undefined;
			if (details?.results?.[0]) return renderSingleResult(details.results[0], theme, expanded);
			const text = result.content[0];
			return new Text(text?.type === "text" ? text.text : "(no result)", 0, 0);
		},
	});

	// ── Tool: subagent_cancel ────────────────────────────────────────
	pi.registerTool({
		name: "subagent_cancel",
		label: "Subagent Cancel",
		description: "Cancel a running background job by ID, or cancel all running jobs with all: true.",
		parameters: Type.Object({
			jobId: Type.Optional(Type.String({ description: "Job ID to cancel. Mutually exclusive with all." })),
			all: Type.Optional(Type.Boolean({ description: "Cancel all running jobs. Mutually exclusive with jobId.", default: false })),
		}),
		promptSnippet: "Cancel subagent jobs",
		promptGuidelines: [
			"Use subagent_cancel to stop a background job you no longer need.",
			"Use all: true to cancel all running jobs at once.",
			"Completed and failed jobs cannot be cancelled.",
		],

		async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
			if (params.all) {
				const running = jobMgr.listRunning();
				const count = running.length;
				if (count === 0) return { content: [{ type: "text", text: "No running jobs to cancel." }], details: { cancelled: 0 } };
				jobMgr.cancelAll();
				persist();
				return { content: [{ type: "text", text: `Cancelled ${count} job${count > 1 ? "s" : ""}.` }], details: { cancelled: count } };
			}

			if (params.jobId) {
				const job = jobMgr.getJob(params.jobId);
				if (!job) return { content: [{ type: "text", text: `Job "${params.jobId}" not found.` }], isError: true };
				if (job.status !== "running") return { content: [{ type: "text", text: `Job "${params.jobId}" is not running (status: ${job.status}). Only running jobs can be cancelled.` }], isError: true };
				jobMgr.cancelJob(params.jobId);
				persist();
				return { content: [{ type: "text", text: `Cancelled job "${params.jobId}" (${job.agent}).` }], details: { cancelled: 1, jobId: params.jobId } };
			}

			return { content: [{ type: "text", text: "Provide jobId to cancel a specific job, or all: true to cancel all running jobs." }], isError: true };
		},

		renderCall(args, _theme, _context) {
			return new Text(args.all ? "subagent_cancel: cancelling all jobs" : `subagent_cancel: cancelling ${args.jobId}`, 0, 0);
		},

		renderResult(result, _options, theme, _context) {
			const text = result.content[0];
			return new Text(text?.type === "text" ? text.text : "(cancelled)", 0, 0);
		},
	});

	// ── Message Renderer for subagent-result ─────────────────────────
	pi.registerMessageRenderer("subagent-result", (message, options, theme) => {
		const details = message.details as { jobId: string; status: string; agent: string; task: string; summary?: string; usage?: any; result?: SingleResult } | undefined;
		if (!details) return undefined;

		const statusIcon = details.status === "completed" ? theme.fg("success", "✓") : details.status === "failed" ? theme.fg("error", "✗") : theme.fg("warning", "⏳");
		const header = `${statusIcon} ${theme.fg("toolTitle", theme.bold(details.agent))} ${theme.fg("muted", `(${details.status})`)}`;

		if (!options.expanded) {
			const usageLine = details.usage ? theme.fg("dim", formatUsageStats(details.usage, details.result?.model, details.result?.provider, details.result?.thinking)) : "";
			const taskLine = theme.fg("dim", details.task.length > 60 ? `${details.task.slice(0, 60)}...` : details.task);
			const summaryLine = details.summary ? theme.fg("toolOutput", details.summary.length > 100 ? `${details.summary.slice(0, 100)}...` : details.summary) : "";
			return new Text(`${header}\n${taskLine}${summaryLine ? `\n${summaryLine}` : ""}${usageLine ? `\n${usageLine}` : ""}`, 0, 0);
		}

		const container = new Container();
		container.addChild(new Text(header, 0, 0));
		container.addChild(new Spacer(1));
		container.addChild(new Text(theme.fg("muted", "─── Task ───"), 0, 0));
		container.addChild(new Text(theme.fg("dim", details.task), 0, 0));

		if (details.result) {
			container.addChild(new Spacer(1));
			container.addChild(new Text(theme.fg("muted", "─── Output ───"), 0, 0));
			const displayItems = getDisplayItems(details.result.messages);
			const finalOutput = getFinalOutput(details.result.messages);
			const mdTheme = getMarkdownTheme();
			for (const item of displayItems) {
				if (item.type === "toolCall")
					container.addChild(new Text(theme.fg("muted", "→ ") + formatToolCall(item.name, item.args, theme.fg.bind(theme)), 0, 0));
			}
			if (finalOutput) { container.addChild(new Spacer(1)); container.addChild(new Markdown(finalOutput.trim(), 0, 0, mdTheme)); }
			const usageStr = formatUsageStats(details.result.usage, details.result.model, details.result.provider, details.result.thinking);
			if (usageStr) { container.addChild(new Spacer(1)); container.addChild(new Text(theme.fg("dim", usageStr), 0, 0)); }
		}
		return container as unknown as Component;
	});
}
