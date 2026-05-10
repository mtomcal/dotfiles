/**
 * TUI Status Widget — renders async job state into lines for Pi's status bar.
 */

import type { AsyncJob } from "./job-manager.js";
import {
	extractSummary,
	truncateForWidget,
	SUBAGENT_SUMMARY_MIN_LENGTH,
	SUBAGENT_WIDGET_DEBOUNCE_MS,
	SUBAGENT_WIDGET_DISMISS_DELAY_MS,
} from "./summary.js";
import { formatUsageStats, getDisplayItems, formatToolCall, formatToolsBracket } from "./renderers.js";
import { formatGuardrailProgress } from "./guardrails.js";

/** Plain-text theme function: strips color, returns text as-is. */
const plainTheme = (_color: any, text: string): string => text;

/** Format elapsed milliseconds as a human-readable string. */
function formatElapsed(ms: number): string {
	if (ms < 1000) return `${ms}ms`;
	if (ms < 60000) return `${Math.round(ms / 1000)}s`;
	return `${Math.floor(ms / 60000)}m ${Math.round((ms % 60000) / 1000)}s`;
}

/** Sort priority: running → failed → completed → cancelled. */
const STATUS_SORT_ORDER: Record<string, number> = {
	running: 0,
	failed: 1,
	completed: 2,
	cancelled: 3,
};

/** Sort jobs: running first, then failed, then completed, then cancelled. Within each group, oldest start time first. */
function sortJobs(jobs: AsyncJob[]): AsyncJob[] {
	return [...jobs].sort((a, b) => {
		const orderA = STATUS_SORT_ORDER[a.status] ?? 99;
		const orderB = STATUS_SORT_ORDER[b.status] ?? 99;
		if (orderA !== orderB) return orderA - orderB;
		return a.startedAt - b.startedAt;
	});
}

/**
 * Render widget content from the current set of async jobs.
 *
 * Returns an array of lines for the TUI status bar, or `undefined`
 * when there are no jobs (signals widget removal).
 */
export function renderWidgetContent(jobs: AsyncJob[], terminalWidth?: number): string[] | undefined {
	try {
		if (!jobs || jobs.length === 0) return undefined;

		const width = terminalWidth && !Number.isNaN(terminalWidth) ? terminalWidth : 80;

		const sorted = sortJobs(jobs);

		const runningCount = sorted.filter((j) => j.status === "running").length;
		const doneCount = sorted.filter(
			(j) => j.status === "completed" || j.status === "failed" || j.status === "cancelled",
		).length;

		const lines: string[] = [];

		// Header line
		lines.push(`⏳ Subagents: ${runningCount} running, ${doneCount} done`);

		for (const job of sorted) {
			const elapsed = formatElapsed((job.completedAt ?? Date.now()) - job.startedAt);

			if (job.status === "running") {
				// Line 1: status, name, tools bracket, elapsed, usage (which includes turns)
				const toolsBracket = formatToolsBracket(job.tools);
				let line1 = `⏳ ${job.name}${toolsBracket ? ` ${toolsBracket}` : ""} (${elapsed})`;
				if (job.result) {
					const usage = formatUsageStats(
						job.result.usage,
						job.result.model,
						job.result.provider,
						job.result.thinking,
					);
					if (usage) line1 += ` ${usage}`;
				} else {
					line1 += ` 0 turns`;
				}

				// Add guardrail progress if job has guardrails
				if (job.guardrails && job.result) {
					const progress = formatGuardrailProgress(job.result.usage, job.guardrails, Date.now() - job.startedAt);
					if (progress) line1 += ` ${progress}`;
				}

				if (line1.length > width) line1 = line1.slice(0, width);
				lines.push(line1);

				// Line 2: snippet + last tool call
				let snippet = '""';
				let toolCallStr = "";
				if (job.result) {
					const summary = truncateForWidget(extractSummary(job.result.messages), width);
					snippet = `"${summary}"`;

					const items = getDisplayItems(job.result.messages).filter(
						(i: any) => i.type === "toolCall",
					);
					if (items.length > 0) {
						const last = items[items.length - 1];
						if (last.type === "toolCall") {
							toolCallStr = formatToolCall(last.name, last.args, plainTheme);
						}
					}
				}

				let line2 = `  ${snippet}`;
				if (toolCallStr) line2 += ` → ${toolCallStr}`;
				if (line2.length > width) line2 = line2.slice(0, width);
				lines.push(line2);
			} else if (job.status === "completed") {
				let summary = "";
				let usageStr = "";
				if (job.result) {
					summary = truncateForWidget(extractSummary(job.result.messages), width);
					usageStr = formatUsageStats(
						job.result.usage,
						job.result.model,
						job.result.provider,
						job.result.thinking,
					);
				}

				const completedToolsBracket = formatToolsBracket(job.tools);
				let line = `✓ ${job.name}${completedToolsBracket ? ` ${completedToolsBracket}` : ""} (${elapsed})`;
				if (usageStr) line += ` ${usageStr}`;
				line += ` "${summary}"`;
				if (line.length > width) line = line.slice(0, width);
				lines.push(line);
			} else if (job.status === "failed") {
				let errorText = "(failed)";
				if (job.result && job.result.errorMessage) {
					errorText = job.result.errorMessage;
				}
				const truncated = truncateForWidget(errorText, width);
				const failedToolsBracket = formatToolsBracket(job.tools);
				let line = `✗ ${job.name}${failedToolsBracket ? ` ${failedToolsBracket}` : ""} (${elapsed}) ${truncated}`;
				if (line.length > width) line = line.slice(0, width);
				lines.push(line);
			} else if (job.status === "cancelled") {
				let line = `⊘ ${job.name} (${elapsed})`;
				if (line.length > width) line = line.slice(0, width);
				lines.push(line);
			}
		}

		return lines;
	} catch (err) {
		console.error("renderWidgetContent error:", err);
		return undefined;
	}
}