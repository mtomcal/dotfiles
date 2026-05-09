/**
 * Agent MD File Loading — read and parse agent configuration from .md files.
 *
 * Agent MD files use YAML frontmatter (between --- delimiters) with:
 *   Required: name, description, tools
 *   Optional:  model, provider, thinking, maxTurns, maxCost, maxTokens, maxTime
 *
 * The body after the frontmatter is used as the system prompt.
 */

import * as fs from "node:fs";
import * as path from "node:path";

// ─── Types ────────────────────────────────────────────────────────────

export interface AgentFileConfig {
	name: string;
	description: string;
	tools?: string;
	model?: string;
	provider?: string;
	thinking?: string;
	maxTurns?: number;
	maxCost?: number;
	maxTokens?: number;
	maxTime?: number;
	systemPrompt: string;
}

export interface AgentListing {
	name: string;
	description: string;
}

// ─── Constants ────────────────────────────────────────────────────────

const NUMBER_FIELDS = new Set(["maxTurns", "maxCost", "maxTokens", "maxTime"]);

// ─── Frontmatter Parsing ──────────────────────────────────────────────

/**
 * Parse YAML-like frontmatter from markdown content.
 *
 * Looks for content between opening and closing `---` delimiters.
 * Each line within is parsed as `key: value`.
 * Returns null if no frontmatter is found or if it's empty.
 *
 * @param content - Raw file content
 * @returns Record of key-value pairs, or null
 */
export function parseAgentFrontmatter(content: string): Record<string, string> | null {
	if (!content) return null;

	const lines = content.split(/\r?\n/);

	// Find opening ---
	if (lines[0]?.trim() !== "---") return null;

	// Find closing ---
	const closingIdx = lines.findIndex((l, i) => i > 0 && l.trim() === "---");
	if (closingIdx === -1) return null;

	// Extract frontmatter lines (between the two --- markers)
	const fmLines = lines.slice(1, closingIdx);

	const result: Record<string, string> = {};

	for (const line of fmLines) {
		const colonIdx = line.indexOf(":");
		if (colonIdx === -1) continue; // skip lines without key:value

		const key = line.slice(0, colonIdx).trim();
		let value = line.slice(colonIdx + 1).trim();

		// Strip trailing whitespace and quotes
		value = value.replace(/^["']|["']$/g, "");

		if (key) {
			result[key] = value;
		}
	}

	// Return null if no fields were parsed (empty frontmatter)
	if (Object.keys(result).length === 0) return null;

	return result;
}

// ─── Agent Loading ────────────────────────────────────────────────────

/**
 * Parse a string value into the appropriate type for agent config fields.
 * Number fields (maxTurns, maxCost, maxTokens, maxTime) are parsed as numbers;
 * all others remain strings.
 */
function coerceValue(key: string, value: string): string | number {
	if (NUMBER_FIELDS.has(key)) {
		const num = Number(value);
		if (!Number.isNaN(num)) return num;
	}
	return value;
}

/**
 * Load an agent configuration from a markdown file.
 *
 * Reads `{agentsDir}/{agentName}.md`, parses the frontmatter, and extracts
 * the body as the system prompt.
 *
 * Returns null if:
 * - The file does not exist
 * - The file has no valid frontmatter
 * - The frontmatter lacks a `name` field
 *
 * @param agentName - Name of the agent (without .md extension)
 * @param agentsDir - Directory containing agent .md files
 * @returns AgentFileConfig or null
 */
export function loadAgentFile(agentName: string, agentsDir: string): AgentFileConfig | null {
	const filePath = path.join(agentsDir, `${agentName}.md`);

	let raw: string;
	try {
		raw = fs.readFileSync(filePath, { encoding: "utf-8" });
	} catch {
		return null;
	}

	const frontmatter = parseAgentFrontmatter(raw);
	if (!frontmatter || !frontmatter["name"]) return null;

	// Extract body: everything after the closing ---
	const lines = raw.split(/\r?\n/);
	const closingIdx = lines.findIndex((l, i) => i > 0 && l.trim() === "---");
	const body =
		closingIdx >= 0
			? lines
					.slice(closingIdx + 1)
					.join("\n")
					.trim()
			: "";

	// Build config with type coercion for number fields
	const config: Record<string, any> = {};

	for (const [key, value] of Object.entries(frontmatter)) {
		config[key] = coerceValue(key, value);
	}

	// Ensure systemPrompt is always set (body may be empty string)
	config.systemPrompt = body;

	return config as AgentFileConfig;
}

// ─── Agent Listing ────────────────────────────────────────────────────

/**
 * List all available agent files in a directory.
 *
 * Reads all .md files, parses their frontmatter, and returns name + description
 * for each file with valid frontmatter containing at least a `name` field.
 *
 * Returns an empty array if:
 * - The directory does not exist
 * - The directory is empty
 * - No .md files have valid frontmatter
 *
 * @param agentsDir - Directory containing agent .md files
 * @returns Array of { name, description } for each valid agent
 */
export function listAgentFiles(agentsDir: string): AgentListing[] {
	let files: string[];
	try {
		files = fs.readdirSync(agentsDir, { encoding: "utf-8" });
	} catch {
		return [];
	}

	const agents: AgentListing[] = [];

	for (const file of files) {
		if (!file.endsWith(".md")) continue;

		const filePath = path.join(agentsDir, file);
		let raw: string;
		try {
			raw = fs.readFileSync(filePath, { encoding: "utf-8" });
		} catch {
			continue;
		}

		const frontmatter = parseAgentFrontmatter(raw);
		if (!frontmatter || !frontmatter["name"]) {
			// Skip files without name in frontmatter — they're not valid agents
			continue;
		}

		agents.push({
			name: frontmatter["name"],
			description: frontmatter["description"] || "",
		});
	}

	return agents;
}

// ─── Default Agents Directory ─────────────────────────────────────────

/**
 * Get the default agents directory path.
 *
 * Uses `PI_AGENTS_DIR` env var if set, otherwise `~/.pi/agent/agents/`.
 */
export function getDefaultAgentsDir(): string {
	if (process.env.PI_AGENTS_DIR) return process.env.PI_AGENTS_DIR;
	return path.join(
		process.env.HOME ?? process.env.USERPROFILE ?? "/tmp",
		".pi",
		"agent",
		"agents",
	);
}
