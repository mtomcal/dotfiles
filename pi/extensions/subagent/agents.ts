/**
 * Agent discovery and configuration
 */

import * as fs from "node:fs";
import * as path from "node:path";
import { getAgentDir, parseFrontmatter } from "@mariozechner/pi-coding-agent";
import type { ThinkingLevel } from "@mariozechner/pi-agent-core";

export type AgentScope = "user" | "project" | "both";

const VALID_THINKING_LEVELS = ["off", "minimal", "low", "medium", "high", "xhigh"] as const;

export function isThinkingLevel(s: string): s is ThinkingLevel {
	return VALID_THINKING_LEVELS.includes(s as ThinkingLevel);
}

/**
 * Normalize empty strings to undefined for config fields.
 * Prevents empty-string overrides from silently winning in priority chains.
 */
export function normalizeOptional(s: string | undefined): string | undefined {
	return s && s.trim() !== "" ? s.trim() : undefined;
}

export interface AgentConfig {
	name: string;
	description: string;
	tools?: string[];
	provider?: string;
	model?: string;
	thinking?: ThinkingLevel;
	systemPrompt: string;
	source: "user" | "project";
	filePath: string;
}

export function parseModelField(modelStr: string): {
	provider?: string;
	model: string;
	thinking?: ThinkingLevel;
} {
	let remaining = modelStr;
	let provider: string | undefined;
	let thinking: ThinkingLevel | undefined;

	// Extract provider prefix: "provider/model" -> provider="provider", model="model"
	const slashIndex = remaining.indexOf("/");
	if (slashIndex > 0) {
		provider = remaining.substring(0, slashIndex);
		remaining = remaining.substring(slashIndex + 1);
	}

	// Extract thinking suffix: "model:high" -> thinking="high", model="model"
	const colonIndex = remaining.lastIndexOf(":");
	if (colonIndex > 0) {
		const possibleThinking = remaining.substring(colonIndex + 1);
		if (VALID_THINKING_LEVELS.includes(possibleThinking as ThinkingLevel)) {
			thinking = possibleThinking as ThinkingLevel;
			remaining = remaining.substring(0, colonIndex);
		}
	}

	return { provider, model: remaining, thinking };
}

export interface AgentDiscoveryResult {
	agents: AgentConfig[];
	projectAgentsDir: string | null;
}

function loadAgentsFromDir(dir: string, source: "user" | "project"): AgentConfig[] {
	const agents: AgentConfig[] = [];

	if (!fs.existsSync(dir)) {
		return agents;
	}

	let entries: fs.Dirent[];
	try {
		entries = fs.readdirSync(dir, { withFileTypes: true });
	} catch {
		return agents;
	}

	for (const entry of entries) {
		if (!entry.name.endsWith(".md")) continue;
		if (!entry.isFile() && !entry.isSymbolicLink()) continue;

		const filePath = path.join(dir, entry.name);
		let content: string;
		try {
			content = fs.readFileSync(filePath, "utf-8");
		} catch {
			continue;
		}

		const { frontmatter, body } = parseFrontmatter<Record<string, string>>(content);

		if (!frontmatter.name || !frontmatter.description) {
			continue;
		}

		const tools = frontmatter.tools
			?.split(",")
			.map((t: string) => t.trim())
			.filter(Boolean);

		// Parse model field (handles "provider/id:thinking" shorthand)
		let provider = frontmatter.provider;
		let model = frontmatter.model;
		let thinking: ThinkingLevel | undefined;

		if (model) {
			const parsed = parseModelField(model);
			// Shorthand components only apply if explicit fields aren't set
			if (!provider && parsed.provider) provider = parsed.provider;
			if (!frontmatter.thinking && parsed.thinking) thinking = parsed.thinking;
			model = parsed.model;
		}

		// Normalize empty strings to undefined (prevents "" from winning over real values in priority chains)
		provider = normalizeOptional(provider);

		// Explicit thinking field overrides shorthand
		if (frontmatter.thinking) {
			if (isThinkingLevel(frontmatter.thinking)) {
				thinking = frontmatter.thinking;
			} else {
				console.warn(`Skipping agent "${frontmatter.name}" in ${filePath}: invalid thinking level "${frontmatter.thinking}". Valid levels: ${VALID_THINKING_LEVELS.join(", ")}`);
				continue;
			}
		}

		agents.push({
			name: frontmatter.name,
			description: frontmatter.description,
			tools: tools && tools.length > 0 ? tools : undefined,
			provider,
			model,
			thinking,
			systemPrompt: body,
			source,
			filePath,
		});
	}

	return agents;
}

function isDirectory(p: string): boolean {
	try {
		return fs.statSync(p).isDirectory();
	} catch {
		return false;
	}
}

function findNearestProjectAgentsDir(cwd: string): string | null {
	let currentDir = cwd;
	while (true) {
		const candidate = path.join(currentDir, ".pi", "agents");
		if (isDirectory(candidate)) return candidate;

		const parentDir = path.dirname(currentDir);
		if (parentDir === currentDir) return null;
		currentDir = parentDir;
	}
}

export function discoverAgents(cwd: string, scope: AgentScope): AgentDiscoveryResult {
	const userDir = path.join(getAgentDir(), "agents");
	const projectAgentsDir = findNearestProjectAgentsDir(cwd);

	const userAgents = scope === "project" ? [] : loadAgentsFromDir(userDir, "user");
	const projectAgents = scope === "user" || !projectAgentsDir ? [] : loadAgentsFromDir(projectAgentsDir, "project");

	const agentMap = new Map<string, AgentConfig>();

	if (scope === "both") {
		for (const agent of userAgents) agentMap.set(agent.name, agent);
		for (const agent of projectAgents) agentMap.set(agent.name, agent);
	} else if (scope === "user") {
		for (const agent of userAgents) agentMap.set(agent.name, agent);
	} else {
		for (const agent of projectAgents) agentMap.set(agent.name, agent);
	}

	return { agents: Array.from(agentMap.values()), projectAgentsDir };
}

export function formatAgentList(agents: AgentConfig[], maxItems: number): { text: string; remaining: number } {
	if (agents.length === 0) return { text: "none", remaining: 0 };
	const listed = agents.slice(0, maxItems);
	const remaining = agents.length - listed.length;
	return {
		text: listed.map((a) => `${a.name} (${a.source}): ${a.description}`).join("; "),
		remaining,
	};
}
