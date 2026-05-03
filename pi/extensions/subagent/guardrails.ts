/**
 * Guardrails — Threshold enforcement and formatting for subagent runs.
 *
 * Provides pure functions for:
 * - `Guardrails` interface: four optional threshold fields
 * - `resolveGuardrails`: merge per-call config with global defaults
 * - `checkGuardrails`: detect threshold breaches (maxTurns → maxCost → maxTokens → maxTime)
 * - `formatGuardrailProgress`: usage vs limits string (e.g. "18/25T $0.32/$0.50 84K/200K 2m30s/5m")
 * - `formatGuardrailLine`: single guardrail line (e.g. "25 turns, $0.50, 200K tokens, 5m")
 * - `readGuardrailDefaults`: read subagentGuardrails from settings.json
 *
 * Spec: specs/subagent-guardrails.md (Slice 1)
 */

import * as fs from "node:fs";
import type { UsageStats } from "./job-manager.js";

export { type UsageStats } from "./job-manager.js";

// ─── Types ────────────────────────────────────────────────────────────

export interface Guardrails {
	maxTurns?: number;
	maxCost?: number;
	maxTokens?: number;
	maxTime?: number;
}

// ─── Constants ────────────────────────────────────────────────────────

const WARNING_PREFIX = "[subagent-routing]";

// ─── Pure Functions ───────────────────────────────────────────────────

/**
 * resolveGuardrails — per-call field wins over global default.
 *
 * Undefined `perCall` param is treated as `{}` (per-call config is always
 * a Guardrails object, not undefined — Grill Q10).
 * Undefined per-call field falls back to global default if present.
 * If both are undefined, the field is undefined (= unlimited).
 *
 * @param perCall - Per-call guardrails (may be undefined, treated as {})
 * @param globalDefaults - Global defaults from settings.json (may be null)
 */
export function resolveGuardrails(
	perCall: Guardrails | undefined,
	globalDefaults: Guardrails | null,
): Guardrails {
	const pc = perCall ?? {};
	const gd = globalDefaults ?? {};
	return {
		maxTurns: pc.maxTurns !== undefined ? pc.maxTurns : gd.maxTurns,
		maxCost: pc.maxCost !== undefined ? pc.maxCost : gd.maxCost,
		maxTokens: pc.maxTokens !== undefined ? pc.maxTokens : gd.maxTokens,
		maxTime: pc.maxTime !== undefined ? pc.maxTime : gd.maxTime,
	};
}

/**
 * checkGuardrails — check for threshold breaches.
 *
 * Check order: maxTurns → maxCost → maxTokens → maxTime.
 * Returns immediately on first breach found.
 * null return means all thresholds are within bounds.
 *
 * @param usage - Current usage statistics
 * @param guardrails - Resolved guardrails thresholds
 * @param elapsedMs - Elapsed time in milliseconds (not part of UsageStats)
 */
export function checkGuardrails(
	usage: UsageStats,
	guardrails: Guardrails,
	elapsedMs: number,
): { breached: true; reason: string } | null {
	const { maxTurns, maxCost, maxTokens, maxTime } = guardrails;

	if (maxTurns !== undefined && usage.turns > maxTurns) {
		return { breached: true, reason: `exceeded maxTurns (${maxTurns})` };
	}

	if (maxCost !== undefined && usage.cost > maxCost) {
		return { breached: true, reason: `exceeded maxCost ($${maxCost.toFixed(2)})` };
	}

	if (maxTokens !== undefined && usage.contextTokens > maxTokens) {
		return { breached: true, reason: `exceeded maxTokens (${maxTokens})` };
	}

	if (maxTime !== undefined && elapsedMs > maxTime * 1000) {
		return { breached: true, reason: `exceeded maxTime (${maxTime}s)` };
	}

	return null;
}

// ─── Formatting Helpers ───────────────────────────────────────────────

/** Format tokens: <1000 → raw number, 1k–<10k → X.Xk, 10k–<1M → Xk, ≥1M → X.XM */
function formatTokens(count: number): string {
	if (count <= 1000) return count.toString();
	if (count <= 10000) return `${(count / 1000).toFixed(1)}k`;
	if (count < 1000000) return `${Math.round(count / 1000)}k`;
	return `${(count / 1000000).toFixed(1)}M`;
}

/** Format elapsed milliseconds as "Xs" or "Xm" or "Xm Ys" */
function formatElapsed(ms: number): string {
	const totalSecs = Math.round(ms / 1000);
	if (totalSecs < 60) return `${totalSecs}s`;
	const mins = Math.floor(totalSecs / 60);
	const secs = totalSecs % 60;
	return secs === 0 ? `${mins}m` : `${mins}m ${secs}s`;
}

/**
 * formatGuardrailProgress — usage vs limits string.
 *
 * Format: "18/25T $0.32/$0.50 84K/200K 2m30s/5m"
 * Only dimensions with a threshold set are shown.
 * Returns empty string if guardrails is undefined or has no thresholds.
 *
 * @param usage - Current usage statistics
 * @param guardrails - Resolved guardrails thresholds (may be undefined)
 * @param elapsedMs - Elapsed time in milliseconds
 */
export function formatGuardrailProgress(
	usage: UsageStats,
	guardrails: Guardrails | undefined,
	elapsedMs: number,
): string {
	if (!guardrails) return "";

	const parts: string[] = [];
	const { maxTurns, maxCost, maxTokens, maxTime } = guardrails;

	if (maxTurns !== undefined) {
		parts.push(`${usage.turns}/${maxTurns}T`);
	}

	if (maxCost !== undefined) {
		parts.push(`$${usage.cost.toFixed(2)}/$${maxCost.toFixed(2)}`);
	}

	if (maxTokens !== undefined) {
		parts.push(`${formatTokens(usage.contextTokens)}/${formatTokens(maxTokens)}`);
	}

	if (maxTime !== undefined) {
		// Elapsed: compact "XmYs" with no space between m and s
		const elapsedTotalSecs = Math.round(elapsedMs / 1000);
		let elapsedStr: string;
		if (elapsedTotalSecs < 60) {
			elapsedStr = `${elapsedTotalSecs}s`;
		} else {
			const elapsedMins = Math.floor(elapsedTotalSecs / 60);
			const elapsedSecs = elapsedTotalSecs % 60;
			elapsedStr = elapsedSecs === 0 ? `${elapsedMins}m` : `${elapsedMins}m${elapsedSecs}s`;
		}
		// Max time limit: uses "Xs" for < 60s, "Xm" for ≥ 60s
		const maxTimeStr = maxTime <= 60 ? `${maxTime}s` : `${Math.floor(maxTime / 60)}m`;
		parts.push(`${elapsedStr}/${maxTimeStr}`);
	}

	return parts.join(" ");
}

/**
 * formatGuardrailLine — single guardrail line.
 *
 * Format: "25 turns, $0.50, 200K tokens, 5m"
 * Comma-separated, no trailing comma.
 * Returns empty string if guardrails is undefined or has no thresholds.
 *
 * @param guardrails - Guardrails thresholds (may be undefined)
 */
export function formatGuardrailLine(guardrails: Guardrails | undefined): string {
	if (!guardrails) return "";

	const parts: string[] = [];
	const { maxTurns, maxCost, maxTokens, maxTime } = guardrails;

	if (maxTurns !== undefined) {
		parts.push(`${maxTurns} turns`);
	}

	if (maxCost !== undefined) {
		parts.push(`$${maxCost.toFixed(2)}`);
	}

	if (maxTokens !== undefined) {
		parts.push(`${formatTokens(maxTokens)} tokens`);
	}

	if (maxTime !== undefined) {
		const totalSecs = maxTime;
		if (totalSecs < 60) {
			parts.push(`${totalSecs}s`);
		} else {
			const mins = Math.floor(totalSecs / 60);
			const secs = totalSecs % 60;
			parts.push(secs === 0 ? `${mins}m` : `${mins}m ${secs}s`);
		}
	}

	return parts.join(", ");
}

// ─── Settings Reader ───────────────────────────────────────────────────

interface RawSettings {
	subagentGuardrails?: Record<string, unknown>;
}

/**
 * readGuardrailDefaults — read subagentGuardrails from a settings.json file.
 *
 * Returns null if:
 * - The file does not exist
 * - The file is not valid JSON
 * - The `subagentGuardrails` key is absent or empty
 * - The section has no valid number fields
 *
 * Logs a warning to stderr for absent/empty/invalid sections.
 *
 * @param settingsPath - Path to settings.json
 */
export function readGuardrailDefaults(settingsPath: string): Guardrails | null {
	let raw: string;
	try {
		raw = fs.readFileSync(settingsPath, { encoding: "utf-8" });
	} catch (err) {
		const nodeErr = err as NodeJS.ErrnoException;
		if (nodeErr.code === "ENOENT") {
			console.warn(`${WARNING_PREFIX} settings.json not found at "${settingsPath}"`);
		} else {
			console.warn(`${WARNING_PREFIX} cannot read settings.json: ${nodeErr.message}`);
		}
		return null;
	}

	let parsed: RawSettings;
	try {
		parsed = JSON.parse(raw) as RawSettings;
	} catch {
		console.warn(`${WARNING_PREFIX} settings.json is not valid JSON`);
		return null;
	}

	const section = parsed.subagentGuardrails;

	// Distinguish absent vs empty for accurate warning messages
	if (section === undefined || section === null) {
		return null;
	}

	if (typeof section !== "object" || Array.isArray(section)) {
		console.warn(`${WARNING_PREFIX} subagentGuardrails is not a valid object`);
		return null;
	}

	const entries = Object.entries(section);

	if (entries.length === 0) {
		return null;
	}

	const guardrails: Guardrails = {};

	for (const [key, value] of entries) {
		if (typeof value === "number") {
			(guardrails as Record<string, unknown>)[key] = value;
		} else {
			console.warn(
				`${WARNING_PREFIX} invalid field type for "${key}" in subagentGuardrails — ignoring`,
			);
		}
	}

	// Return null if no valid number fields were found
	if (Object.keys(guardrails).length === 0) {
		return null;
	}

	return guardrails;
}
