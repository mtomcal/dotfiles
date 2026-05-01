/**
 * Subagent Model Routing — Read settings.json and build routing tables
 * for injection into subagent tool descriptions.
 *
 * The subagent extension reads a `subagentModelRouting` table from Pi's
 * settings.json and injects it as a markdown table into subagent_run and
 * subagent_fork tool descriptions. The LLM classifies tasks into one of
 * five intent categories (scout, planner, reviewer, implementer, specialist)
 * and uses the prescribed model/provider/thinking values.
 *
 * Spec: ai-agent-config.md v1.2.0 (B5.1 rules 10-13)
 */

import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";

// ─── Types ────────────────────────────────────────────────────────────

export interface RoutingEntry {
	category: string;
	description: string;
	model: string;
	provider: string;
	thinking: string;
	rationale: string;
}

export type RoutingTable = RoutingEntry[];

// ─── State (mutable — updated by reloadRoutingTable) ────────────────

/** Current routing table, read at extension load or after a /reload-routing call. */
export let routingTable: RoutingEntry[] | null = null;

/** Settings path (resolved once at load, used for reloads). */
let _settingsPath: string | null = null;

// ─── Constants ────────────────────────────────────────────────────────

const VALID_THINKING_LEVELS = ["off", "minimal", "low", "medium", "high", "xhigh"];

/** Known routing category names. Unknown categories are accepted but logged. */
const KNOWN_CATEGORIES = new Set(["scout", "planner", "reviewer", "implementer", "specialist"]);

const WARNING_PREFIX = "[subagent-routing]";

// ─── Reading ──────────────────────────────────────────────────────────

interface RawRoutingEntry {
	description?: string;
	model?: string;
	provider?: string;
	thinking?: string;
	rationale?: string;
}

interface RawSettings {
	subagentModelRouting?: Record<string, RawRoutingEntry>;
}

/**
 * Read `subagentModelRouting` from a settings.json file.
 *
 * Returns a sorted array of RoutingEntry objects, or null if:
 * - The file does not exist
 * - The file is not valid JSON
 * - The `subagentModelRouting` key is absent or empty
 *
 * Logs a warning to stderr when the key is absent or empty.
 */
export function readRoutingTable(settingsPath: string): RoutingEntry[] | null {
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

	const routing = parsed.subagentModelRouting;

	// Distinguish absent vs empty for accurate warning messages
	if (routing === undefined || routing === null) {
		console.warn(`${WARNING_PREFIX} subagentModelRouting is absent from settings.json — falling back to defaults`);
		return null;
	}
	if (typeof routing !== "object" || Array.isArray(routing) || Object.keys(routing).length === 0) {
		console.warn(`${WARNING_PREFIX} subagentModelRouting is present but empty — falling back to defaults`);
		return null;
	}

	const entries: RoutingEntry[] = [];

	for (const [category, entry] of Object.entries(routing)) {
		// Skip non-object entries (null, string, array)
		if (!entry || typeof entry !== "object" || Array.isArray(entry)) continue;

		// Skip empty category names
		if (!category) continue;

		const description = typeof entry.description === "string" ? entry.description : "";
		const model = typeof entry.model === "string" ? entry.model : "";
		const provider = typeof entry.provider === "string" ? entry.provider : "";
		const thinking = typeof entry.thinking === "string" ? entry.thinking : "medium";
		const rationale = typeof entry.rationale === "string" ? entry.rationale : "";

		// Warn on unknown category names (but still accept them)
		if (!KNOWN_CATEGORIES.has(category)) {
			console.warn(`${WARNING_PREFIX} unknown routing category "${category}" — did you mean scout, planner, reviewer, implementer, or specialist?`);
		}

		// Skip entries without both model and provider
		if (!model || !provider) continue;

		// Warn on invalid thinking levels before defaulting
		if (!VALID_THINKING_LEVELS.includes(thinking)) {
			console.warn(`${WARNING_PREFIX} invalid thinking level "${thinking}" for category "${category}" — defaulting to "medium"`);
		}

		entries.push({
			category,
			description,
			model,
			provider,
			thinking: VALID_THINKING_LEVELS.includes(thinking) ? thinking : "medium",
			rationale,
		});
	}

	if (entries.length === 0) {
		console.warn(`${WARNING_PREFIX} subagentModelRouting is present but empty — falling back to defaults`);
		return null;
	}

	// Sort alphabetically by category for consistent display
	entries.sort((a, b) => a.category.localeCompare(b.category));

	return entries;
}

// ─── Markdown Formatting ──────────────────────────────────────────────

/**
 * Format routing entries as a markdown table.
 *
 * Columns: Category | Description | Model | Provider | Thinking | Rationale
 *
 * Returns empty string when entries array is empty.
 */
export function formatRoutingTable(entries: RoutingEntry[]): string {
	if (entries.length === 0) return "";

	const lines: string[] = [];
	lines.push("| Category | Description | Model | Provider | Thinking | Rationale |");
	lines.push("|----------|-------------|-------|----------|----------|-----------|");

	for (const entry of entries) {
		const cat = escapeMarkdownCell(entry.category);
		const desc = escapeMarkdownCell(entry.description);
		const rat = escapeMarkdownCell(entry.rationale);
		const mdl = escapeMarkdownCell(entry.model);
		const prv = escapeMarkdownCell(entry.provider);
		lines.push(`| ${cat} | ${desc} | ${mdl} | ${prv} | ${entry.thinking} | ${rat} |`);
	}

	return lines.join("\n");
}

/**
 * Escape markdown-sensitive characters in table cell content.
 * Escapes: | (table delimiter), * _ (bold/italic), ` (code), [ ] (links).
 * Also replaces newlines with spaces to prevent row splitting.
 */
function escapeMarkdownCell(text: string): string {
	return text
		.replace(/\r?\n/g, " ")
		.replace(/[|*_`\[\]]/g, (c) => `\\${c}`);
}

// ─── Tool Description Builder ─────────────────────────────────────────

const ROUTING_TABLE_HEADER =
	"\n\n### Subagent Model Routing\n\n" +
	"The following routing table prescribes model/provider/thinking per intent category. " +
	"Select a routing category and use the prescribed values. Deviation requires explicit justification.\n\n";

const ROUTING_TABLE_FOOTER =
	"\n\n*Select a routing category and use the prescribed model, provider, and thinking values. " +
	"Deviation requires explicit justification in the call.*\n\n" +
	"> ⚠️ **Deviating from the routing table without strong justification will degrade output quality.**";

/**
 * Reload the routing table from the settings file.
 * Call this from a `/reload-routing` command to hot-reload without restarting pi.
 *
 * @param settingsPath - Path to settings.json (falls back to env or home dir if omitted)
 * @returns The new routing table (or null if not configured)
 */
export function reloadRoutingTable(settingsPath?: string): RoutingEntry[] | null {
	_settingsPath =
		settingsPath ??
		_settingsPath ??
		process.env.PI_SUBAGENT_SETTINGS_PATH ??
		path.join(os.homedir(), ".pi", "agent", "settings.json");
	routingTable = readRoutingTable(_settingsPath);
	return routingTable;
}

const FALLBACK_NOTE =
	"\n\n> **Note**: No subagent model routing configured. Using default model and thinking level for all subagent calls.";

/**
 * Build a tool description with optional routing table markdown appended.
 *
 * - If `routingTable` is non-null and non-empty: appends the routing table
 *   with instructions for the LLM to select a category.
 * - If `routingTable` is null: appends a fallback note about using defaults.
 *
 * @param baseDescription - The base tool description text
 * @param routingTable - Routing entries (null if not configured)
 * @returns The full description string
 */
export function buildToolDescription(
	baseDescription: string,
	routingTable: RoutingEntry[] | null,
): string {
	if (routingTable && routingTable.length > 0) {
		const tableMd = formatRoutingTable(routingTable);
		return baseDescription + ROUTING_TABLE_HEADER + tableMd + ROUTING_TABLE_FOOTER;
	}

	return baseDescription + FALLBACK_NOTE;
}