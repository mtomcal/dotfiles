/**
 * Subagent Extension — Six-Tool Async Subagent Architecture (Ad-Hoc Config)
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
 * - Job ID format: {name}-{6hex}
 * - Fork always returns immediately
 * - Completion notifications via pi.sendMessage() with deliverAs: "steer"
 * - Running jobs killed on session_shutdown
 * - Ad-hoc configuration: task + systemPrompt + params, with optional named agent .md file lookup
 */

import { spawn, type ChildProcess } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ThinkingLevel } from "@earendil-works/pi-agent-core";
import type { Message } from "@earendil-works/pi-ai";
import { StringEnum } from "@earendil-works/pi-ai";
import {
	type ExtensionAPI,
	type ExtensionCommandContext,
	getMarkdownTheme,
	withFileMutationQueue,
} from "@earendil-works/pi-coding-agent";
import { Container, Markdown, Spacer, Text, type Component } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import {
	type SubagentConfig,
	type ResolvableFields,
	buildSpawnArgs,
	deriveName,
	parseTools,
	resolveConfig,
	BARE_TASK_INJECTION,
} from "./subagent-config.js";
import { JobManager, type AsyncJob, type SingleResult, MAX_RUNNING_JOBS, terminateProcess } from "./job-manager.js";
import { checkGuardrails, formatGuardrailLine, formatGuardrailProgress, type Guardrails } from "./guardrails.js";
import {
	type SubagentDetails,
	aggregateUsage,
	COLLAPSED_ITEM_COUNT,
	formatToolCall,
	formatToolsBracket,
	formatToolsLabel,
	formatUsageStats,
	getDisplayItems,
	getFinalOutput,
	MAX_CONCURRENCY,
	MAX_PARALLEL_TASKS,
	renderJobStatusLine,
	renderSingleResult,
} from "./renderers.js";
import { extractSummary, truncateForWidget } from "./summary.js";
import { readRoutingTable, buildToolDescription } from "./routing.js";
import { loadAgentFile, listAgentFiles, getDefaultAgentsDir } from "./agent-loading.js";
import { renderWidgetContent } from "./widget.js";
import { SUBAGENT_WIDGET_DEBOUNCE_MS, SUBAGENT_WIDGET_DISMISS_DELAY_MS } from "./summary.js";

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

const ItemConfig = Type.Object({
	name: Type.Optional(Type.String({ description: "Display label for this subagent. Auto-derived from task text if omitted." })),
	task: Type.String({ description: "Task to delegate to the subagent" }),
	systemPrompt: Type.Optional(Type.String({ description: "System prompt — defines the subagent's role and behavior" })),
	tools: Type.Optional(Type.String({ description: "Comma-separated tool allowlist (e.g. 'read,write,bash'). Omit for all default tools." })),
	model: Type.Optional(Type.String({ description: "Model ID or pattern (e.g. 'claude-sonnet-4-5', 'anthropic/claude-sonnet-4-5')" })),
	provider: ProviderSchema,
	thinking: ThinkingSchema,
	cwd: Type.Optional(Type.String({ description: "Working directory for the subagent process" })),
	contextFiles: Type.Optional(Type.Boolean({ description: "Load project context files (AGENTS.md etc). Default: true." })),
	extensions: Type.Optional(Type.Boolean({ description: "Load extensions in subagent. Default: false." })),
	maxTurns: Type.Optional(Type.Number({ description: "Maximum conversation turns before guardrail kill" })),
	maxCost: Type.Optional(Type.Number({ description: "Maximum cost in dollars before guardrail kill" })),
	maxTokens: Type.Optional(Type.Number({ description: "Maximum context tokens before guardrail kill" })),
	maxTime: Type.Optional(Type.Number({ description: "Maximum wall-clock time in seconds before guardrail kill" })),
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
	subagentName: string,
	prompt: string,
): Promise<{ dir: string; filePath: string }> {
	const tmpDir = await fs.promises.mkdtemp(path.join(os.tmpdir(), "pi-subagent-"));
	const safeName = subagentName.replace(/[^\w.-]+/g, "_");
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

// ─── Agent Catalog Helpers ─────────────────────────────────────────

/**
 * Build a markdown catalog of all available agents for system prompt injection.
 * Discovers agents from ~/.pi/agent/agents/*.md, loads full frontmatter config
 * for each, and formats as a bulleted list with model, provider, thinking, tools,
 * and default guardrails.
 */
function buildAgentCatalog(): string {
	const agentsDir = getDefaultAgentsDir();
	const listings = listAgentFiles(agentsDir);
	if (listings.length === 0) return "";

	const lines: string[] = [];
	lines.push("## Available Subagents");
	lines.push("");

	for (const listing of listings) {
		const agent = loadAgentFile(listing.name, agentsDir);
		const toolsLabel = agent?.tools || "(all default)";

		const guardrailParts: string[] = [];
		if (agent?.maxTurns) guardrailParts.push(`${agent.maxTurns} turns`);
		if (agent?.maxCost) guardrailParts.push(`$${agent.maxCost.toFixed(2)}`);
		if (agent?.maxTokens) guardrailParts.push(`${agent.maxTokens.toLocaleString()} tokens`);
		if (agent?.maxTime) guardrailParts.push(`${agent.maxTime}s`);
		const guardrailStr = guardrailParts.length > 0 ? guardrailParts.join(", ") : "none";

		lines.push(`- **\`${listing.name}\`** (user): ${listing.description}`);

		const metaParts: string[] = [];
		if (agent?.model && agent?.provider) {
			metaParts.push(`Model: ${agent.model} @ ${agent.provider}`);
		} else if (agent?.model) {
			metaParts.push(`Model: ${agent.model}`);
		}
		if (agent?.thinking) metaParts.push(`Thinking: ${agent.thinking}`);
		metaParts.push(`Tools: ${toolsLabel}`);
		lines.push(`  ${metaParts.join(" | ")}`);

		lines.push(`  Default guardrails: ${guardrailStr}`);
		lines.push("");
	}

	return lines.join("\n");
}

/**
 * Build a compact agent list for the `agent` parameter description
 * on subagent_run / subagent_fork tools.
 */
function buildAgentParamDescription(): string {
	const agentsDir = getDefaultAgentsDir();
	const listings = listAgentFiles(agentsDir);
	if (listings.length === 0) {
		return "Named agent to use from ~/.pi/agent/agents/. Loads .md file with frontmatter defaults. Per-call params override agent defaults.";
	}
	const compact = listings
		.map((a) => {
			// Take first clause before em-dash, comma, period, or colon
			const raw = a.description.split(/[—–,:.]/)[0].trim();
			// Truncate to ~40 chars at word boundary
			const short = raw.length > 40
				? raw.slice(0, 40).replace(/\s+\S*$/, "") + "..."
				: raw;
			return `${a.name} (${short})`;
		})
		.join(", ");
	return `Named agent to use from ~/.pi/agent/agents/. Available: ${compact}. Loads .md file with frontmatter defaults. Per-call params override agent defaults.`;
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

function spawnSubagentProcess(
	config: SubagentConfig,
	task: string,
	cwd: string | undefined,
	defaultCwd: string,
	signal: AbortSignal | undefined,
	step: number | undefined,
	onMessage?: (result: SingleResult) => void,
): { proc: ChildProcess; resultPromise: Promise<SingleResult> } {
	const args = buildSpawnArgs(config, task);
	// Remove the "Task: ..." from args since we'll construct it separately
	const taskIdx = args.findIndex((a) => a.startsWith("Task: "));
	if (taskIdx >= 0) args.splice(taskIdx, 1);

	// Add flags that are handled externally
	const allArgs = ["--mode", "json", "-p", "--no-session", "--no-skills"];
	// Rebuild args from config
	if (config.provider) allArgs.push("--provider", config.provider);
	if (config.model) allArgs.push("--model", config.model);
	if (config.thinking && config.thinking !== "medium") allArgs.push("--thinking", config.thinking);
	if (config.tools && config.tools.length > 0) allArgs.push("--tools", config.tools.join(","));
	if (!config.contextFiles) allArgs.push("--no-context-files");
	if (!config.extensions) allArgs.push("--no-extensions");

	// System prompt via temp file
	let tmpPromptDir: string | null = null;
	let tmpPromptPath: string | null = null;

	// Current result being built
	const currentResult: SingleResult = {
		name: config.name,
		task,
		exitCode: 0,
		messages: [],
		stderr: "",
		usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 },
		provider: config.provider,
		model: config.model,
		thinking: config.thinking,
		tools: config.tools,
		step,
	};

	const emitUpdate = () => { if (onMessage) onMessage({ ...currentResult }); };

	// Guardrail enforcement
	const startTime = Date.now();
	let maxTimeTimer: ReturnType<typeof setTimeout> | null = null;
	const effectiveGuardrails = config.guardrails;

	let proc: ChildProcess = nullProc;
	const resultPromise = new Promise<SingleResult>(async (resolve) => {
		try {
			if (config.systemPrompt && config.systemPrompt.trim()) {
				const tmp = await writePromptToTempFile(config.name, config.systemPrompt);
				tmpPromptDir = tmp.dir;
				tmpPromptPath = tmp.filePath;
				allArgs.push("--append-system-prompt", tmpPromptPath);
			}
			allArgs.push(`Task: ${task}`);
		} catch (err) {
			cleanupTempFiles([{ dir: tmpPromptDir, filePath: tmpPromptPath }]);
			currentResult.exitCode = 1;
			currentResult.stderr = `Failed to prepare prompt: ${(err as Error).message}`;
			currentResult.errorMessage = (err as Error).message;
			resolve(currentResult);
			return;
		}

		const invocation = getPiInvocation(allArgs);

		proc = spawn(invocation.command, invocation.args, {
			cwd: cwd ?? defaultCwd,
			shell: false,
			stdio: ["ignore", "pipe", "pipe"],
		});

		// Set maxTime timeout if configured
		if (effectiveGuardrails.maxTime) {
			maxTimeTimer = setTimeout(() => {
				currentResult.stopReason = "guardrail";
				currentResult.errorMessage = `Subagent killed: exceeded maxTime (${effectiveGuardrails.maxTime}s)`;
				terminateProcess(proc);
			}, effectiveGuardrails.maxTime * 1000);
		}

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

					// Guardrail check after usage accumulation
					const breach = checkGuardrails(currentResult.usage, effectiveGuardrails, Date.now() - startTime);
					if (breach) {
						if (maxTimeTimer) clearTimeout(maxTimeTimer);
						currentResult.stopReason = "guardrail";
						currentResult.errorMessage = `Subagent killed: ${breach.reason}`;
						terminateProcess(proc);
					}
				}
				emitUpdate();
			}
			if (event.type === "tool_result_end" && event.message) {
				currentResult.messages.push(event.message as Message);
				emitUpdate();
			}
		};

		proc.stdout!.on("data", (data) => {
			buffer += data.toString();
			const lines = buffer.split("\n");
			buffer = lines.pop() || "";
			for (const line of lines) processLine(line);
		});
		proc.stderr!.on("data", (data) => { currentResult.stderr += data.toString(); });

		proc.on("close", (code) => {
			if (maxTimeTimer) clearTimeout(maxTimeTimer);
			if (buffer.trim()) processLine(buffer);
			cleanupTempFiles([{ dir: tmpPromptDir, filePath: tmpPromptPath }]);
			currentResult.exitCode = code ?? 0;
			if (currentResult.stopReason === "guardrail") {
				currentResult.exitCode = 1;
			} else if (wasAborted) {
				currentResult.exitCode = 1;
				currentResult.errorMessage = "Subagent was aborted";
			}
			emitUpdate();
			resolve(currentResult);
		});
		proc.on("error", () => {
			if (maxTimeTimer) clearTimeout(maxTimeTimer);
			cleanupTempFiles([{ dir: tmpPromptDir, filePath: tmpPromptPath }]);
			currentResult.exitCode = 1;
			currentResult.errorMessage = "Failed to spawn subagent process";
			resolve(currentResult);
		});

		if (signal) {
			const killProc = () => {
				wasAborted = true;
				if (maxTimeTimer) clearTimeout(maxTimeTimer);
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

	// Use extractSummary for content selection (≥50 char threshold, backward scan)
	const smartContent = extractSummary(result.messages) || getFinalOutput(result.messages) || "(no output)";
	const truncatedContent = truncateForWidget(smartContent, 200);

	const usageLine = formatUsageStats(result.usage, result.model, result.provider, result.thinking);
	const statusEmoji = job.status === "completed" ? "✓" : "✗";

	let notificationContent: string[];
	if (result.stopReason === "guardrail") {
		// Guardrail kill notification with specific reason and usage
		const guardrailReason = result.errorMessage || "Subagent killed by guardrail";
		notificationContent = [
			`**Subagent ${statusEmoji}: \`${job.name}\` — ${job.status}**`,
			`**Job:** \`${job.id}\``,
			`**Task:** ${job.task}`,
			`**Error:** ${guardrailReason}`,
			"",
			truncatedContent,
			"",
			usageLine ? `**Usage:** ${usageLine}` : "",
		].filter(Boolean);
	} else {
		notificationContent = [
			`**Subagent ${statusEmoji}: \`${job.name}\` — ${job.status}**`,
			`**Job:** \`${job.id}\``,
			`**Task:** ${job.task}`,
			"",
			truncatedContent,
			"",
			usageLine ? `**Usage:** ${usageLine}` : "",
		].filter(Boolean);
	}

	pi.sendMessage(
		{
			customType: "subagent-result",
			content: notificationContent.join("\n"),
			display: true,
			details: {
				jobId: job.id,
				status: job.status,
				name: job.name,
				task: job.task,
				mode: "single",
				summary: truncatedContent,
				usage: result.usage,
				result,
			},
		},
		{ triggerTurn: true, deliverAs: "steer" },
	);
}

function emitCancellationNotification(pi: ExtensionAPI, job: AsyncJob): void {
	const summary = job.result ? extractSummary(job.result.messages) : "";
	const displayItems = job.result ? getDisplayItems(job.result.messages).filter(i => i.type === "toolCall") : [];
	const lastToolCall = displayItems.length > 0 ? displayItems[displayItems.length - 1] : null;

	const now = Date.now();
	const elapsedMs = (job.completedAt ?? now) - job.startedAt;
	const elapsed = elapsedMs < 1000 ? `${elapsedMs}ms`
		: elapsedMs < 60000 ? `${Math.round(elapsedMs / 1000)}s`
		: `${Math.floor(elapsedMs / 60000)}m ${Math.round((elapsedMs % 60000) / 1000)}s`;

	let toolCallLine = "";
	if (lastToolCall) {
		toolCallLine = `\n→ ${formatToolCall(lastToolCall.name, lastToolCall.args, (_c: any, t: string) => t)}`;
	}

	const usageLine = job.result ? formatUsageStats(job.result.usage, job.result.model, job.result.provider, job.result.thinking) : "";

	const notificationContent = [
		`**⊘ Subagent Cancelled: \`${job.name}\`**`,
		`**Job:** \`${job.id}\``,
		`**Task:** ${job.task}`,
		`**Elapsed:** ${elapsed}`,
		usageLine ? `**Usage:** ${usageLine}` : "",
		summary ? `\n${summary}${toolCallLine}` : "",
	].filter(Boolean).join("\n");

	pi.sendMessage(
		{
			customType: "subagent-result",
			content: notificationContent,
			display: true,
			details: {
				jobId: job.id,
				status: "cancelled",
				name: job.name,
				task: job.task,
				summary: summary || "(cancelled)",
				usage: job.result?.usage,
				result: job.result,
			},
		},
		{ triggerTurn: true, deliverAs: "steer" },
	);
}

// ─── Serialization Helper ──────────────────────────────────────────────

function serializeJobForDetails(job: AsyncJob) {
	return {
		id: job.id,
		name: job.name,
		task: job.task,
		status: job.status,
		startedAt: job.startedAt,
		completedAt: job.completedAt,
		tools: job.tools ?? job.result?.tools,
		result: job.result
			? { name: job.result.name, task: job.result.task, exitCode: job.result.exitCode, usage: job.result.usage, errorMessage: job.result.errorMessage }
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
				container.addChild(new Text(`${theme.fg("muted", `─── Step ${r.step}: `) + theme.fg("accent", r.name)} ${rIcon}`, 0, 0));
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
			text += `\n\n${theme.fg("muted", `─── Step ${r.step}: `)}${theme.fg("accent", r.name)} ${rIcon}`;
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
				container.addChild(new Text(`${theme.fg("muted", "─── ") + theme.fg("accent", r.name)} ${rIcon}`, 0, 0));
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
			text += `\n\n${theme.fg("muted", "─── ")}${theme.fg("accent", r.name)} ${rIcon}`;
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
	const jobMgr: JobManager = (pi as any).jobMgr ?? new JobManager();
	if (!(pi as any).jobMgr) (pi as any).jobMgr = jobMgr;

	// ── Agent catalog injection tracking ───────────────────────────
	let _catalogInjectedThisSession = false;

	// Wire up cancellation notification callback so cancelJob/cancelAll
	// automatically send steer notifications when jobs are cancelled.
	jobMgr.setOnCancel((job: AsyncJob) => {
		try {
			emitCancellationNotification(pi, job);
		} catch { /* notification best-effort */ }
	});

	// Wire up partial result callback for live progress widget updates.
	jobMgr.setOnPartialResult((_jobId: string, _partial: SingleResult) => {
		scheduleWidgetUpdate(widgetCtx);
	});
	function persist() {
		pi.appendEntry("subagent-job-state", jobMgr.serialize());
	}

	// ── Context reference for widget updates ─────────────────────────────
	let widgetCtx: any = null;

	// ── Widget management ────────────────────────────────────────────────
	let widgetDebounceTimer: ReturnType<typeof setTimeout> | null = null;
	let widgetDismissTimer: ReturnType<typeof setTimeout> | null = null;

	function updateWidget(ctx: any): void {
		try {
			const terminalWidth = process.stdout.columns || 80;
			const jobs = jobMgr.listJobs();
			const content = renderWidgetContent(jobs, terminalWidth);
			if (ctx?.ui?.setWidget) {
				ctx.ui.setWidget("subagent-jobs", content, { placement: "aboveEditor" });
			}
		} catch (err) {
			// Widget render failure → log error, skip re-render (AIAGT-014)
			console.error("[subagent-widget] render error:", err);
		}
	}

	function scheduleWidgetUpdate(ctx: any): void {
		if (widgetDebounceTimer) clearTimeout(widgetDebounceTimer);
		widgetDebounceTimer = setTimeout(() => {
			widgetDebounceTimer = null;
			updateWidget(ctx);
		}, SUBAGENT_WIDGET_DEBOUNCE_MS);
	}

	function scheduleWidgetDismiss(ctx: any): void {
		if (widgetDismissTimer) clearTimeout(widgetDismissTimer);
		widgetDismissTimer = setTimeout(() => {
			widgetDismissTimer = null;
			try {
				if (ctx?.ui?.setWidget) {
					ctx.ui.setWidget("subagent-jobs", undefined, { placement: "aboveEditor" });
			}
			} catch { /* best-effort */ }
		}, SUBAGENT_WIDGET_DISMISS_DELAY_MS);
	}

	function cancelWidgetTimers(): void {
		if (widgetDebounceTimer) { clearTimeout(widgetDebounceTimer); widgetDebounceTimer = null; }
		if (widgetDismissTimer) { clearTimeout(widgetDismissTimer); widgetDismissTimer = null; }
	}

		// ── Read subagent model routing from settings ────────────────────
	const settingsPath =
		process.env.PI_SUBAGENT_SETTINGS_PATH ??
		path.join(os.homedir(), ".pi", "agent", "settings.json");
	const routingTable = readRoutingTable(settingsPath);

	// ── Register /reload-agents command ────────────────────────────
	// Allows hot-reload of agent catalog without restarting pi.
	// Refreshes the agent listing injected into the system prompt.
	// NOTE: tool parameter descriptions are baked at registration time.
	// Run /reload after /reload-agents to update tool descriptions too.
	pi.registerCommand("reload-agents", {
		description: "Reload agent catalog from ~/.pi/agent/agents/ into system prompt (use /reload after to update tool descriptions)",
		handler: async (_args: string, _ctx: ExtensionCommandContext) => {
			_catalogInjectedThisSession = false;
			const agentsDir = getDefaultAgentsDir();
			const listings = listAgentFiles(agentsDir);
			if (listings.length === 0) {
				console.warn("[subagent] No agents found in " + agentsDir);
			} else {
				console.warn(
					`[subagent] Reloaded — ${listings.length} agents discovered. ` +
					"Run /reload to apply changes to subagent_run and subagent_fork tool descriptions.",
				);
			}
		},
	});

	// ── Register /reload-routing command ───────────────────────────
	// Allows hot-reload of routing table without restarting pi.
	// Useful after editing settings.json during a session.
	//
	// NOTE: tool descriptions are baked in at registration time (lines 522, 703 below).
	// Mutating the module-level `routingTable` variable does NOT update already-registered
	// tool descriptions. To apply routing changes to tool descriptions, run `/reload`
	// (full pi extension reload) after `/reload-routing`.
	pi.registerCommand("reload-routing", {
		description: "Reload the subagent model routing table from settings.json (use /reload after to update tool descriptions)",
		handler: async (_args: string, _ctx: ExtensionCommandContext) => {
			const { reloadRoutingTable } = await import("./routing.js");
			const updated = reloadRoutingTable(settingsPath);
			const count = updated ? updated.length : 0;
			console.warn(
				`[subagent-routing] Reloaded — ${count} categories active. ` +
				"Run /reload to apply changes to subagent_run and subagent_fork tool descriptions.",
			);
		},
	});

	// ── Lifecycle ────────────────────────────────────────────────────
	pi.on("session_shutdown", async () => { cancelWidgetTimers(); widgetCtx = null; jobMgr.cancelAll(); persist(); });
	pi.on("session_start", async (_event, ctx) => {
		_catalogInjectedThisSession = false;
		widgetCtx = ctx;
		for (const entry of ctx.sessionManager.getEntries()) {
			if (entry.type === "custom" && entry.customType === "subagent-job-state") {
				jobMgr.deserialize(entry.data as any);
			}
		}
	});

	// ── Inject agent catalog into system prompt once per session ───
	pi.on("before_agent_start", async (event, _ctx) => {
		if (_catalogInjectedThisSession) return;
		_catalogInjectedThisSession = true;

		const catalog = buildAgentCatalog();
		if (!catalog) return;

		return {
			systemPrompt: event.systemPrompt + "\n\n" + catalog,
		};
	});

	// ── Tool: subagent_run (Blocking) ────────────────────────────────
	pi.registerTool({
		name: "subagent_run",
		label: "Subagent Run",
		description: buildToolDescription([
			"Run a subagent synchronously. Modes: single (task), parallel (tasks array), chain (sequential with {previous} placeholder).",
			"Blocks until completion. Provide `systemPrompt` to define the subagent's role, or omit for a default assistant with isolated context.",
			"ad-hoc subagents: each call configures the subagent inline.",
		].join(" "), routingTable),
		parameters: Type.Object({
			agent: Type.Optional(Type.String({ description: buildAgentParamDescription() })),
			name: Type.Optional(Type.String({ description: "Display label. Auto-derived from task text if omitted." })),
			task: Type.Optional(Type.String({ description: "Task to delegate (single mode)" })),
			systemPrompt: Type.Optional(Type.String({ description: "System prompt — defines the subagent's role and behavior" })),
			tools: Type.Optional(Type.String({ description: "Comma-separated tool allowlist (e.g. 'read,write,bash'). Omit for all default tools." })),
			model: Type.Optional(Type.String({ description: "Model ID or pattern" })),
			provider: ProviderSchema,
			thinking: ThinkingSchema,
			cwd: Type.Optional(Type.String({ description: "Working directory for the subagent process" })),
			contextFiles: Type.Optional(Type.Boolean({ description: "Load project context files (AGENTS.md etc). Default: true.", default: true })),
			extensions: Type.Optional(Type.Boolean({ description: "Load extensions in subagent. Default: false.", default: false })),
			maxTurns: Type.Optional(Type.Number({ description: "Maximum conversation turns before guardrail kill" })),
			maxCost: Type.Optional(Type.Number({ description: "Maximum cost in dollars before guardrail kill" })),
			maxTokens: Type.Optional(Type.Number({ description: "Maximum context tokens before guardrail kill" })),
			maxTime: Type.Optional(Type.Number({ description: "Maximum wall-clock time in seconds before guardrail kill" })),
			tasks: Type.Optional(Type.Array(ItemConfig, { description: "Array of items for parallel execution" })),
			chain: Type.Optional(Type.Array(ItemConfig, { description: "Array of items for sequential execution with {previous}" })),
		}),
		promptSnippet: "Run subagent tasks and get results immediately",
		promptGuidelines: [
			"Use the `agent` parameter to reference a named agent definition from the Available Subagents catalog in the system prompt. The agent .md file provides defaults for system prompt, tools, model, and guardrails.",
			"Provide `systemPrompt` to define the subagent's behavior, and `name` for a readable job label.",
			"For the best results, scope `tools` to what the subagent needs (e.g. 'read,grep' for review, 'read,write,bash,edit' for implementation).",
			"Omit `systemPrompt` and `name` for a bare-task pattern: a default assistant in an isolated context. Useful for running a task in a fresh context window.",
			"Use `model` and `thinking` to control the subagent's capability: fast models for lookup, powerful models for complex tasks.",
			"Use subagent_fork for background execution. Use subagent_run when you need the result before continuing.",
			"Set guardrails (maxTurns, maxCost, maxTokens, maxTime) to limit subagent resource usage. The subagent is killed with stopReason=guardrail if any threshold is exceeded.",
		],

		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			// Load agent file if agent param is specified
			const agentsDir = getDefaultAgentsDir();
			const agentFile = params.agent ? loadAgentFile(params.agent, agentsDir) : null;

			const hasChain = (params.chain?.length ?? 0) > 0;
			const hasTasks = (params.tasks?.length ?? 0) > 0;
			const hasSingle = Boolean(params.task && params.task.trim());
			const modeCount = Number(hasChain) + Number(hasTasks) + Number(hasSingle);

			const makeDetails = (mode: "single" | "parallel" | "chain") => (results: SingleResult[]): SubagentDetails => ({
				mode, results,
			});

			if (modeCount !== 1) {
				return { content: [{ type: "text", text: "Invalid parameters. Provide exactly one of: task, tasks[], or chain[]." }], details: makeDetails("single")([]), isError: true };
			}

			// Build top-level resolvable fields for inheritance
			const topLevel: ResolvableFields | undefined = (params.provider || params.thinking || params.model || params.systemPrompt || params.tools || params.contextFiles !== undefined || params.extensions !== undefined || params.maxTurns !== undefined || params.maxCost !== undefined || params.maxTokens !== undefined || params.maxTime !== undefined)
				? { task: params.task ?? "", provider: params.provider, thinking: params.thinking as ThinkingLevel | undefined, model: params.model, systemPrompt: params.systemPrompt, tools: params.tools, contextFiles: params.contextFiles, extensions: params.extensions, maxTurns: params.maxTurns, maxCost: params.maxCost, maxTokens: params.maxTokens, maxTime: params.maxTime }
				: undefined;

			if (params.chain && params.chain.length > 0) {
				const results: SingleResult[] = [];
				let previousOutput = "";
				for (let i = 0; i < params.chain.length; i++) {
					const step = params.chain[i];
					const taskWithContext = step.task.replace(/\{previous\}/g, previousOutput);
					const config = resolveConfig(
						{ task: taskWithContext, name: step.name, systemPrompt: step.systemPrompt, tools: step.tools, model: step.model, provider: step.provider, thinking: step.thinking as ThinkingLevel | undefined, cwd: step.cwd, contextFiles: step.contextFiles, extensions: step.extensions, maxTurns: step.maxTurns, maxCost: step.maxCost, maxTokens: step.maxTokens, maxTime: step.maxTime },
						topLevel,
					);
					const { resultPromise } = spawnSubagentProcess(
						config, taskWithContext, step.cwd ?? params.cwd, ctx.cwd, signal, i + 1,
						onUpdate ? (cr: SingleResult) => { onUpdate({ content: [{ type: "text", text: getFinalOutput(cr.messages) || "(running...)" }], details: makeDetails("chain")([...results, cr]) }); } : undefined,
					);
					const result = await resultPromise;
					results.push(result);
					const isError = result.exitCode !== 0 || result.stopReason === "error" || result.stopReason === "aborted";
					if (isError) {
						const errorMsg = result.errorMessage || result.stderr || getFinalOutput(result.messages) || "(no output)";
						return { content: [{ type: "text", text: `Chain stopped at step ${i + 1} (${step.name || deriveName(step.task)}): ${errorMsg}` }], details: makeDetails("chain")(results), isError: true };
					}
					previousOutput = getFinalOutput(result.messages);
				}
				return { content: [{ type: "text", text: getFinalOutput(results[results.length - 1].messages) || "(no output)" }], details: makeDetails("chain")(results) };
			}

			if (params.tasks && params.tasks.length > 0) {
				if (params.tasks.length > MAX_PARALLEL_TASKS) return { content: [{ type: "text", text: `Too many parallel tasks (${params.tasks.length}). Max is ${MAX_PARALLEL_TASKS}.` }], details: makeDetails("parallel")([]) };
				const allResults: SingleResult[] = new Array(params.tasks.length);
				for (let i = 0; i < params.tasks.length; i++) {
					allResults[i] = { name: deriveName(params.tasks[i].task), task: params.tasks[i].task, exitCode: -1, messages: [], stderr: "", usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 } };
				}
				const emitParallelUpdate = () => { if (onUpdate) { onUpdate({ content: [{ type: "text", text: `Parallel: ${allResults.filter((r) => r.exitCode !== -1).length}/${allResults.length} done...` }], details: makeDetails("parallel")([...allResults]) }); } };
				const results = await mapWithConcurrencyLimit(params.tasks, MAX_CONCURRENCY, async (t, index) => {
					const config = resolveConfig(
						{ task: t.task, name: t.name, systemPrompt: t.systemPrompt, tools: t.tools, model: t.model, provider: t.provider, thinking: t.thinking as ThinkingLevel | undefined, cwd: t.cwd, contextFiles: t.contextFiles, extensions: t.extensions, maxTurns: t.maxTurns, maxCost: t.maxCost, maxTokens: t.maxTokens, maxTime: t.maxTime },
						topLevel,
					);
					const { resultPromise } = spawnSubagentProcess(config, t.task, t.cwd ?? params.cwd, ctx.cwd, signal, undefined, (partial) => { allResults[index] = partial; emitParallelUpdate(); });
					const result = await resultPromise;
					allResults[index] = result;
					emitParallelUpdate();
					return result;
				});
				const successCount = results.filter((r) => r.exitCode === 0).length;
				const summaries = results.map((r) => {
					const output = getFinalOutput(r.messages);
					const truncated = output.length > 500 ? output.slice(0, 500) + "\n\n*(...truncated, full output in details)*" : output;
					const toolsBracket = formatToolsBracket(r.tools);
					const bracketStr = toolsBracket ? ` ${toolsBracket}` : "";
					return `## ${r.name}${bracketStr} (${r.exitCode === 0 ? "completed" : "failed"})\n\n${truncated || "(no output)"}`;
				});
				return { content: [{ type: "text", text: `Parallel: ${successCount}/${results.length} succeeded\n\n${summaries.join("\n\n---\n\n")}` }], details: makeDetails("parallel")(results) };
			}

			if (params.task && params.task.trim()) {
				const config = resolveConfig(
					{ task: params.task.trim(), name: params.name, systemPrompt: params.systemPrompt, tools: params.tools, model: params.model, provider: params.provider, thinking: params.thinking as ThinkingLevel | undefined, cwd: params.cwd, contextFiles: params.contextFiles, extensions: params.extensions, maxTurns: params.maxTurns, maxCost: params.maxCost, maxTokens: params.maxTokens, maxTime: params.maxTime },
					undefined,
					undefined,
					null,
					agentFile,
				);
				const { resultPromise } = spawnSubagentProcess(
					config, params.task.trim(), params.cwd, ctx.cwd, signal, undefined,
					onUpdate ? (cr: SingleResult) => { onUpdate({ content: [{ type: "text", text: getFinalOutput(cr.messages) || "(running...)" }], details: makeDetails("single")([cr]) }); } : undefined,
				);
				const result = await resultPromise;
				const isError = result.exitCode !== 0 || result.stopReason === "error" || result.stopReason === "aborted";
				if (isError) {
					const errorMsg = result.errorMessage || result.stderr || getFinalOutput(result.messages) || "(no output)";
					return { content: [{ type: "text", text: `Agent ${result.stopReason || "failed"}: ${errorMsg}` }], details: makeDetails("single")([result]), isError: true };
				}
				return { content: [{ type: "text", text: getFinalOutput(result.messages) || "(no output)" }], details: makeDetails("single")([result]) };
			}

			return { content: [{ type: "text", text: "Invalid parameters. Provide task, tasks[], or chain[]." }], details: makeDetails("single")([]) };
		},

		renderCall(args, theme, _context) {
			if (args.chain && args.chain.length > 0) {
				let text = theme.fg("toolTitle", theme.bold("subagent_run ")) + theme.fg("accent", `chain (${args.chain.length} steps)`);
				for (let i = 0; i < Math.min(args.chain.length, 3); i++) {
					const step = args.chain[i];
					const cleanTask = step.task.replace(/\{previous\}/g, "").trim();
					const displayName = step.name || deriveName(step.task);
					text += "\n  " + theme.fg("muted", `${i + 1}.`) + " " + theme.fg("accent", displayName);
					const meta: string[] = [];
					if (step.provider) meta.push(step.provider);
					if (step.model) meta.push(step.model);
					if (step.thinking && step.thinking !== "medium") meta.push(`think:${step.thinking}`);
					if (meta.length > 0) text += theme.fg("muted", ` (${meta.join(", ")})`);
					const chainToolsBracket = step.tools ? formatToolsBracket(parseTools(step.tools)) : "";
					if (chainToolsBracket) text += theme.fg("dim", ` ${chainToolsBracket}`);
					text += theme.fg("dim", ` ${cleanTask.length > 40 ? cleanTask.slice(0, 40) + "..." : cleanTask}`);
				}
				if (args.chain.length > 3) text += `\n  ${theme.fg("muted", `... +${args.chain.length - 3} more`)}`;
				return new Text(text, 0, 0);
			}
			if (args.tasks && args.tasks.length > 0) {
				let text = theme.fg("toolTitle", theme.bold("subagent_run ")) + theme.fg("accent", `parallel (${args.tasks.length} tasks)`);
				for (const t of args.tasks.slice(0, 3)) {
					const displayName = t.name || deriveName(t.task);
					text += `\n  ${theme.fg("accent", displayName)}`;
					const meta: string[] = [];
					if (t.provider) meta.push(t.provider);
					if (t.model) meta.push(t.model);
					if (t.thinking && t.thinking !== "medium") meta.push(`think:${t.thinking}`);
					if (meta.length > 0) text += theme.fg("muted", ` (${meta.join(", ")})`);
					const taskToolsBracket = t.tools ? formatToolsBracket(parseTools(t.tools)) : "";
					if (taskToolsBracket) text += theme.fg("dim", ` ${taskToolsBracket}`);
					text += theme.fg("dim", ` ${t.task.length > 40 ? t.task.slice(0, 40) + "..." : t.task}`);
				}
				if (args.tasks.length > 3) text += `\n  ${theme.fg("muted", `... +${args.tasks.length - 3} more`)}`;
				return new Text(text, 0, 0);
			}
			const displayName = args.name || (args.task ? deriveName(args.task) : "...");
			const preview = args.task ? (args.task.length > 60 ? `${args.task.slice(0, 60)}...` : args.task) : "...";
			let text = theme.fg("toolTitle", theme.bold("subagent_run ")) + theme.fg("accent", displayName);
			if (args.provider || args.model || args.thinking) {
				const meta: string[] = [];
				if (args.provider) meta.push(args.provider);
				if (args.model) meta.push(args.model);
				if (args.thinking && args.thinking !== "medium") meta.push(`think:${args.thinking}`);
				if (meta.length > 0) text += theme.fg("muted", ` (${meta.join(", ")})`);
			}
			const singleToolsBracket = args.tools ? formatToolsBracket(parseTools(args.tools)) : "";
			if (singleToolsBracket) text += theme.fg("dim", ` ${singleToolsBracket}`);
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
		description: buildToolDescription([
			"Start one or more background subagent jobs. Returns immediately with job IDs.",
			"You receive a completion notification when each job finishes. Max 8 concurrent jobs.",
			"Provide `systemPrompt` to define the subagent's role, or omit for a default assistant with isolated context.",
			"ad-hoc subagents: each call configures the subagent inline.",
		].join(" "), routingTable),
		parameters: Type.Object({
			agent: Type.Optional(Type.String({ description: buildAgentParamDescription() })),
			name: Type.Optional(Type.String({ description: "Display label. Auto-derived from task text if omitted." })),
			task: Type.Optional(Type.String({ description: "Task to delegate (for single mode)" })),
			systemPrompt: Type.Optional(Type.String({ description: "System prompt — defines the subagent's role and behavior" })),
			tools: Type.Optional(Type.String({ description: "Comma-separated tool allowlist (e.g. 'read,write,bash'). Omit for all default tools." })),
			model: Type.Optional(Type.String({ description: "Model ID or pattern" })),
			provider: ProviderSchema,
			thinking: ThinkingSchema,
			cwd: Type.Optional(Type.String({ description: "Working directory for the subagent process (single mode)" })),
			contextFiles: Type.Optional(Type.Boolean({ description: "Load project context files. Default: true.", default: true })),
			extensions: Type.Optional(Type.Boolean({ description: "Load extensions in subagent. Default: false.", default: false })),
			maxTurns: Type.Optional(Type.Number({ description: "Maximum conversation turns before guardrail kill" })),
			maxCost: Type.Optional(Type.Number({ description: "Maximum cost in dollars before guardrail kill" })),
			maxTokens: Type.Optional(Type.Number({ description: "Maximum context tokens before guardrail kill" })),
			maxTime: Type.Optional(Type.Number({ description: "Maximum wall-clock time in seconds before guardrail kill" })),
			tasks: Type.Optional(Type.Array(ItemConfig, { description: "Array of items for parallel fork" })),
		}),
		promptSnippet: "Fork background subagent jobs, continue working while they run",
		promptGuidelines: [
			"Use the `agent` parameter to reference a named agent definition from the Available Subagents catalog in the system prompt. The agent .md file provides defaults for system prompt, tools, model, and guardrails.",
			"Provide `systemPrompt` to define the subagent's behavior, and `name` for a readable job label.",
			"After forking, continue your work. You'll receive a completion notification with a summary and usage stats.",
			"When you receive a notification, call subagent_results with the jobId only if you need more detail.",
			"Max 8 concurrent background jobs. Check with subagent_status before forking more.",
			"Omit `systemPrompt` for the bare-task pattern: a default assistant in isolated context.",
			"Use subagent_run when you need the result immediately. Use subagent_fork when you can work in parallel.",
			"A TUI status widget is displayed above the editor while jobs are running, showing live progress. You'll also receive a completion notification when each job finishes.",
			"Set guardrails (maxTurns, maxCost, maxTokens, maxTime) to limit subagent resource usage. The subagent is killed with stopReason=guardrail if any threshold is exceeded.",
		],

		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			// Load agent file if agent param is specified
			const agentsDir = getDefaultAgentsDir();
			const agentFile = params.agent ? loadAgentFile(params.agent, agentsDir) : null;

			const tasks: Array<{ config: SubagentConfig; task: string; cwd?: string }> = [];

			if (params.task && params.task.trim()) {
				const config = resolveConfig(
					{ task: params.task.trim(), name: params.name, systemPrompt: params.systemPrompt, tools: params.tools, model: params.model, provider: params.provider, thinking: params.thinking as ThinkingLevel | undefined, cwd: params.cwd, contextFiles: params.contextFiles, extensions: params.extensions, maxTurns: params.maxTurns, maxCost: params.maxCost, maxTokens: params.maxTokens, maxTime: params.maxTime },
					undefined,
					undefined,
					null,
					agentFile,
				);
				tasks.push({ config, task: params.task.trim(), cwd: params.cwd });
			} else if (params.tasks && params.tasks.length > 0) {
				for (const t of params.tasks) {
					if (!t.task || !t.task.trim()) {
						return { content: [{ type: "text", text: `Task for "${t.name || deriveName(t.task)}" must not be empty.` }], details: { jobs: [] }, isError: true };
					}
					const config = resolveConfig(
						{ task: t.task.trim(), name: t.name, systemPrompt: t.systemPrompt, tools: t.tools, model: t.model, provider: t.provider, thinking: t.thinking as ThinkingLevel | undefined, cwd: t.cwd, contextFiles: t.contextFiles, extensions: t.extensions, maxTurns: t.maxTurns, maxCost: t.maxCost, maxTokens: t.maxTokens, maxTime: t.maxTime },
						{ task: params.task ?? "", provider: params.provider, thinking: params.thinking as ThinkingLevel | undefined, model: params.model, systemPrompt: params.systemPrompt, tools: params.tools, contextFiles: params.contextFiles, extensions: params.extensions, maxTurns: params.maxTurns, maxCost: params.maxCost, maxTokens: params.maxTokens, maxTime: params.maxTime },
						undefined,
						null,
						agentFile,
					);
					tasks.push({ config, task: t.task.trim(), cwd: t.cwd ?? params.cwd });
				}
			} else {
				return { content: [{ type: "text", text: "Provide task or tasks[] to fork." }], details: { jobs: [] }, isError: true };
			}

			// Check cap before spawning
			const available = MAX_RUNNING_JOBS - jobMgr.runningCount();
			if (tasks.length > available) {
				return { content: [{ type: "text", text: `Maximum ${MAX_RUNNING_JOBS} concurrent async jobs (${jobMgr.runningCount()} running). Cancel a job or wait for one to complete.` }], details: { jobs: [] }, isError: true };
			}

			const spawnedJobs: Array<{ id: string; name: string; task: string; status: string; provider?: string; thinking?: string; tools?: string[]; guardrails?: import("./guardrails.js").Guardrails }> = [];

			for (const t of tasks) {
				// Always create job entry first so it counts against the cap.
				let job;
				try { job = jobMgr.createJob(t.config.name, t.task, t.config.guardrails); }
				catch (err) {
					// Cap hit mid-batch
					return { content: [{ type: "text", text: `Maximum ${MAX_RUNNING_JOBS} concurrent async jobs (${jobMgr.runningCount()} running). Cancel a job or wait for one to complete.` }], details: { jobs: spawnedJobs }, isError: true };
				}
				job.tools = t.config.tools;

				const taskPreview = t.task.length > 60 ? `${t.task.slice(0, 60)}...` : t.task;
				spawnedJobs.push({ id: job.id, name: t.config.name, task: taskPreview, status: "running", provider: t.config.provider, thinking: t.config.thinking as string | undefined, tools: t.config.tools, guardrails: t.config.guardrails });

				const { proc, resultPromise } = spawnSubagentProcess(
					t.config, t.task, t.cwd, ctx.cwd, undefined, undefined,
					(partial: SingleResult) => { jobMgr.updatePartialResult(job.id, partial); },
				);
				jobMgr.setProcess(job.id, proc);

				// Handle completion asynchronously
				resultPromise.then((result) => {
					if (result.exitCode === 0 && !result.errorMessage) jobMgr.completeJob(job.id, result);
					else jobMgr.failJob(job.id, result.errorMessage || result.stderr || "Process failed");
					persist();
					try { emitCompletionNotification(pi, jobMgr.getJob(job.id)!); } catch { /* notification best-effort */ }
					// Immediate widget update on state transition (bypasses debounce)
					updateWidget(ctx);
					if (jobMgr.listRunning().length === 0) scheduleWidgetDismiss(ctx);
				}).catch((err) => {
					jobMgr.failJob(job.id, (err as Error).message);
					persist();
					try { emitCompletionNotification(pi, jobMgr.getJob(job.id)!); } catch { /* notification best-effort */ }
					// Immediate widget update on state transition (bypasses debounce)
					updateWidget(ctx);
					if (jobMgr.listRunning().length === 0) scheduleWidgetDismiss(ctx);
				});
			}

			persist();

			const running = jobMgr.runningCount();
			const jobLines = spawnedJobs.map((j) => {
				const bracket = j.tools ? formatToolsBracket(j.tools) : "";
				const bracketStr = bracket ? ` ${bracket}` : "";
				let line = `- \`${j.id}\`: **${j.name}**${bracketStr} — ${j.task} (${j.status})`;
				if (j.guardrails) {
					const guardrailLine = formatGuardrailLine(j.guardrails);
					if (guardrailLine) line += `\n  Guardrails: ${guardrailLine}`;
				}
				return line;
			}).join("\n");
			return {
				content: [{ type: "text", text: `Forked ${spawnedJobs.length} job${spawnedJobs.length > 1 ? "s" : ""} (${running}/${MAX_RUNNING_JOBS} running)\n\n${jobLines}` }],
				details: { jobs: spawnedJobs },
			};
		},

		renderCall(args, theme, _context) {
			if (args.tasks && args.tasks.length > 0) {
				let text = theme.fg("toolTitle", theme.bold("subagent_fork ")) + theme.fg("accent", `${args.tasks.length} jobs`);
				for (const t of args.tasks.slice(0, 3)) {
					const displayName = t.name || deriveName(t.task);
					const forkToolsBracket = t.tools ? formatToolsBracket(parseTools(t.tools)) : "";
					const bracketStr = forkToolsBracket ? `${forkToolsBracket} ` : "";
					text += `\n  ${theme.fg("accent", displayName)} ${theme.fg("dim", `${bracketStr}${t.task.length > 40 ? t.task.slice(0, 40) + "..." : t.task}`)}`;
				}
				if (args.tasks.length > 3) text += `\n  ${theme.fg("muted", `... +${args.tasks.length - 3} more`)}`;
				return new Text(text, 0, 0);
			}
			const displayName = args.name || (args.task ? deriveName(args.task) : "...");
			const preview = args.task ? (args.task.length > 60 ? `${args.task.slice(0, 60)}...` : args.task) : "...";
			const forkSingleBracket = args.tools ? formatToolsBracket(parseTools(args.tools)) : "";
			const bracketStr = forkSingleBracket ? ` ${forkSingleBracket}` : "";
			return new Text(theme.fg("toolTitle", theme.bold("subagent_fork ")) + theme.fg("accent", displayName) + theme.fg("dim", `${bracketStr} ${preview}`), 0, 0);
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
				if (!job) return { content: [{ type: "text", text: `Job "${params.jobId}" not found.` }], details: {} as any, isError: true };

				const statusIcons: Record<string, string> = { running: "⏳", completed: "✓", failed: "✗", cancelled: "⊘" };
				const icon = statusIcons[job.status] || "?";
				const now = Date.now();
				const elapsedMs = (job.completedAt ?? now) - job.startedAt;
				const elapsed = elapsedMs < 1000 ? `${elapsedMs}ms` : elapsedMs < 60000 ? `${Math.round(elapsedMs / 1000)}s` : `${Math.floor(elapsedMs / 60000)}m ${Math.round((elapsedMs % 60000) / 1000)}s`;

				let text = `**${icon} ${job.name}** — ${job.status}\n\n**Job ID:** \`${job.id}\`\n**Task:** ${job.task}`;
				const toolsLabel = formatToolsLabel(job.tools ?? job.result?.tools);
				if (toolsLabel) text += `\n${toolsLabel}`;
				text += `\n**Elapsed:** ${elapsed}`;
				if (job.status === "running" && job.result) {
					// Progress section for running jobs with partial result data
					const progressItems = getDisplayItems(job.result.messages);
					const lastToolCall = progressItems.filter(i => i.type === "toolCall").pop();
					const progressSummary = extractSummary(job.result.messages);
					const progressUsage = formatUsageStats(job.result.usage, job.result.model, job.result.provider, job.result.thinking);
					text += `\n\n**Progress:**`;
					// Show guardrail-specific progress if guardrails are set
					if (job.guardrails) {
						const guardrailProgress = formatGuardrailProgress(job.result.usage, job.guardrails, elapsedMs);
						if (guardrailProgress) {
							// Parse the progress string to format individual lines
							const parts = guardrailProgress.split(" ");
							if (job.guardrails.maxTurns) {
								const turnPart = parts.find(p => p.includes("/T"));
								if (turnPart) text += `\n- **Turns:** ${turnPart}`;
							}
							const costPart = parts.find(p => p.startsWith("$"));
							if (costPart) text += `\n- **Cost:** ${costPart}`;
							const tokenPart = parts.find(p => p.match(/^\d+/));
							if (tokenPart && !tokenPart.includes("/T") && !tokenPart.startsWith("$")) {
								text += `\n- **Tokens:** ${tokenPart}`;
							}
							const timePart = parts.find(p => p.includes("/"));
							if (timePart && timePart.includes("m") || timePart?.includes("s")) {
								text += `\n- **Time:** ${timePart}`;
							}
						}
						} else {
							// No guardrails: show turns and full usage stats
							if (job.result.usage.turns) text += `\n- **Turns:** ${job.result.usage.turns}`;
							if (progressUsage) text += `\n- **Usage:** ${progressUsage}`;
						}
						if (progressSummary) text += `\n- **Last text:** ${truncateForWidget(progressSummary, 120)}`;
						if (lastToolCall) text += `\n- **Last tool call:** ${formatToolCall(lastToolCall.name, lastToolCall.args, (_c: any, t: string) => t)}`;
				} else if (job.status === "running" && !job.result) {
					text += `\n\n**Progress:** No progress data available yet`;
				}
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
			"The completion notification already includes a summary. Only use subagent_results when you need more detail.",
			"subagent_results returns an error if the job is still running. Use subagent_wait to block until completion.",
		],

		async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
			const job = jobMgr.getJob(params.jobId);
			if (!job) return { content: [{ type: "text", text: `Job "${params.jobId}" not found.` }], details: {} as any, isError: true };
			if (job.status === "running") return { content: [{ type: "text", text: `Job "${params.jobId}" is still running. Use subagent_wait to wait for completion, or subagent_status to check progress.` }], details: {} as any, isError: true };
			if (!job.result) return { content: [{ type: "text", text: `Job "${params.jobId}" has no result data.` }], details: {} as any, isError: true };

			const displayItems = getDisplayItems(job.result.messages);
			const finalOutput = getFinalOutput(job.result.messages);
			const usage = formatUsageStats(job.result.usage, job.result.model, job.result.provider, job.result.thinking);

			let text = `**Results for \`${params.jobId}\` (${job.name} — ${job.status})**\n\n**Task:** ${job.task}\n`;
			const toolsLabel = formatToolsLabel(job.result.tools ?? job.tools);
			if (toolsLabel) text += `${toolsLabel}\n`;
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

		async execute(_toolCallId, params, signal, onUpdate, _ctx) {
			const job = jobMgr.getJob(params.jobId);
			if (!job) return { content: [{ type: "text", text: `Job "${params.jobId}" not found.` }], details: {} as any, isError: true };

			if (job.status !== "running") {
				const result = job.result;
				const finalOutput = result ? getFinalOutput(result.messages) : "(no output)";
				const usage = result ? formatUsageStats(result.usage, result.model, result.provider, result.thinking) : "";
				return { content: [{ type: "text", text: `Job \`${params.jobId}\` (${job.name}) already ${job.status}.\n${finalOutput ? `\n${finalOutput}\n` : ""}${usage ? `\n**Usage:** ${usage}` : ""}` }], details: { results: result ? [result] : [] } };
			}

			const timeoutMs = (params.timeout ?? 300) * 1000;
			const startTime = Date.now();

			while (Date.now() - startTime < timeoutMs) {
				const current = jobMgr.getJob(params.jobId);
				if (!current) return { content: [{ type: "text", text: `Job "${params.jobId}" was removed.` }], details: {} as any, isError: true };
				if (current.status !== "running") {
					const result = current.result;
					const finalOutput = result ? getFinalOutput(result.messages) : "(no output)";
					const usage = result ? formatUsageStats(result.usage, result.model, result.provider, result.thinking) : "";
					return { content: [{ type: "text", text: `Job \`${params.jobId}\` (${current.name}) ${current.status}.\n${finalOutput ? `\n${finalOutput}\n` : ""}${usage ? `\n**Usage:** ${usage}` : ""}` }], details: { results: result ? [result] : [] } };
				}
				if (signal?.aborted) return { content: [{ type: "text", text: `Wait for job "${params.jobId}" was aborted.` }], details: {} as any, isError: true };

				// Stream progress if partial result is available
				if (onUpdate && current.result) {
					const progressItems = getDisplayItems(current.result.messages);
					const lastToolCall = progressItems.filter(i => i.type === "toolCall").pop();
					const summary = extractSummary(current.result.messages);
					const now = Date.now();
					const elapsedMs = now - current.startedAt;
					const elapsed = elapsedMs < 1000 ? `${elapsedMs}ms` : elapsedMs < 60000 ? `${Math.round(elapsedMs / 1000)}s` : `${Math.floor(elapsedMs / 60000)}m ${Math.round((elapsedMs % 60000) / 1000)}`;
					const usageLine = formatUsageStats(current.result.usage, current.result.model, current.result.provider, current.result.thinking);
					let progressText = `\u23F3 ${current.name}${formatToolsBracket(current.tools ?? current.result?.tools)} (${elapsed})`;
					if (usageLine) progressText += ` ${usageLine}`;
					if (current.result.usage.turns) progressText += ` ${current.result.usage.turns} turns`;
					let detailLine = "";
					if (summary) detailLine = `\n  "${truncateForWidget(summary, 80)}"`;
					if (lastToolCall) detailLine += ` \u2192 ${formatToolCall(lastToolCall.name, lastToolCall.args, (_c: any, t: string) => t)}`;
					onUpdate({
						content: [{ type: "text", text: progressText + detailLine }],
						details: { results: [current.result] },
					});
				}

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

		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			if (params.all) {
				const running = jobMgr.listRunning();
				const count = running.length;

				if (count === 0) return { content: [{ type: "text", text: "No running jobs to cancel." }], details: { cancelled: 0 } };
				jobMgr.cancelAll();
				persist();
				// Immediate widget update on cancellation (state transition)
				updateWidget(ctx);
				if (jobMgr.listRunning().length === 0) scheduleWidgetDismiss(ctx);
				return { content: [{ type: "text", text: `Cancelled ${count} job${count > 1 ? "s" : ""}.` }], details: { cancelled: count } };
			}

			if (params.jobId) {
				const job = jobMgr.getJob(params.jobId);
				if (!job) return { content: [{ type: "text", text: `Job "${params.jobId}" not found.` }], details: {} as any, isError: true };
				if (job.status !== "running") return { content: [{ type: "text", text: `Job "${params.jobId}" is not running (status: ${job.status}). Only running jobs can be cancelled.` }], details: {} as any, isError: true };
				jobMgr.cancelJob(params.jobId);
				persist();
				// Immediate widget update on cancellation (state transition)
				updateWidget(ctx);
				if (jobMgr.listRunning().length === 0) scheduleWidgetDismiss(ctx);
				return { content: [{ type: "text", text: `Cancelled job "${params.jobId}" (${job.name}).` }], details: { cancelled: 1, jobId: params.jobId } };
			}

			return { content: [{ type: "text", text: "Provide jobId to cancel a specific job, or all: true to cancel all running jobs." }], details: {} as any, isError: true };
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
		const details = message.details as { jobId: string; status: string; name: string; task: string; summary?: string; usage?: any; result?: SingleResult } | undefined;
		if (!details) return undefined;

		const statusIcon = details.status === "completed" ? theme.fg("success", "✓") : details.status === "failed" ? theme.fg("error", "✗") : theme.fg("warning", "⏳");
		const header = `${statusIcon} ${theme.fg("toolTitle", theme.bold(details.name))} ${theme.fg("muted", `(${details.status})`)}`;

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