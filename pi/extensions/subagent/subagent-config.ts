/**
 * Subagent Config — Types, resolution, and utilities for ad-hoc subagent configuration.
 *
 * Ad-hoc subagent configuration resolution.
 * Pure config resolution: per-item > top-level > default.
 */

import type { ThinkingLevel } from "@mariozechner/pi-agent-core";

// ─── Types ──────────────────────────────────────────────────────────

export interface SubagentConfig {
	name: string;
	systemPrompt: string | undefined;
	tools: string[] | undefined;
	model: string | undefined;
	provider: string | undefined;
	thinking: ThinkingLevel;
	contextFiles: boolean;
	extensions: boolean;
}

export interface ResolvableFields {
	name?: string;
	task: string;
	systemPrompt?: string;
	tools?: string;
	model?: string;
	provider?: string;
	thinking?: ThinkingLevel;
	cwd?: string;
	contextFiles?: boolean;
	extensions?: boolean;
}

// ─── Constants ───────────────────────────────────────────────────────

export const BARE_TASK_INJECTION =
	"You are a subagent operating in an isolated context. Complete your task " +
	"autonomously. Return a clear, self-contained result. Your output will be " +
	"read by another agent — be concise and structured. If you encounter " +
	"ambiguity, make your best judgment rather than asking questions.";

const VALID_THINKING_LEVELS = ["off", "minimal", "low", "medium", "high", "xhigh"] as const;

// ─── Utility Functions ───────────────────────────────────────────────

export function isThinkingLevel(s: string): s is ThinkingLevel {
	return VALID_THINKING_LEVELS.includes(s as ThinkingLevel);
}

export function normalizeOptional(s: string | undefined): string | undefined {
	return s && s.trim() !== "" ? s.trim() : undefined;
}

export function deriveName(task: string): string {
	const trimmed = task.trim();
	if (!trimmed) return "task";
	// Take first word, lowercase, strip non-word chars except hyphens
	let firstWord = trimmed.split(/\s+/)[0].toLowerCase().replace(/[^\w-]/g, "");
	// Strip leading non-alpha chars (prevents "-fix" → job ID "-fix-xxx")
	firstWord = firstWord.replace(/^[^a-z]+/, "");
	// Must be at least 3 chars to be meaningful
	if (firstWord.length < 3) return "task";
	// Truncate long names
	return firstWord.slice(0, 20);
}

export function parseModelField(modelStr: string): {
	provider?: string;
	model: string;
	thinking?: ThinkingLevel;
} {
	let remaining = modelStr;
	let provider: string | undefined;
	let thinking: ThinkingLevel | undefined;

	const slashIndex = remaining.indexOf("/");
	if (slashIndex > 0) {
		provider = remaining.substring(0, slashIndex);
		remaining = remaining.substring(slashIndex + 1);
	}

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

export function parseTools(toolsStr: string): string[] {
	return toolsStr
		.split(",")
		.map((t) => t.trim())
		.filter(Boolean);
}

// ─── Config Resolution ───────────────────────────────────────────────

export function resolveConfig(
	perItem: ResolvableFields,
	topLevel?: ResolvableFields,
): SubagentConfig {
	const task = perItem.task;
	const name = perItem.name ?? deriveName(task);

	// System prompt: per-item > top-level > bare-task injection
	const systemPrompt = perItem.systemPrompt ?? topLevel?.systemPrompt ?? undefined;
	const effectiveSystemPrompt = systemPrompt ?? BARE_TASK_INJECTION;

	// Tools: per-item > top-level > undefined (all tools)
	const toolsStr = perItem.tools ?? topLevel?.tools;
	const tools = toolsStr ? parseTools(toolsStr) : undefined;

	// Model: per-item > top-level. Parse shorthand.
	const rawModel = perItem.model ?? topLevel?.model;
	let model: string | undefined;
	let shorthandProvider: string | undefined;
	let shorthandThinking: ThinkingLevel | undefined;
	if (rawModel) {
		const parsed = parseModelField(rawModel);
		model = parsed.model;
		shorthandProvider = parsed.provider;
		shorthandThinking = parsed.thinking;
	}

	// Provider: explicit > shorthand from model > top-level explicit > top-level shorthand
	// Note: shorthand components from per-item model replace top-level entirely.
	// If per-item model lacks a shorthand provider, the top-level model's shorthand
	// provider is NOT automatically inherited — use top-level `provider` param instead.
	const topLevelParsed = topLevel?.model ? parseModelField(topLevel.model) : undefined;
	const provider =
		normalizeOptional(perItem.provider) ??
		(shorthandProvider ? shorthandProvider : undefined) ??
		normalizeOptional(topLevel?.provider) ??
		(topLevelParsed?.provider ? topLevelParsed.provider : undefined) ??
		undefined;

	// Thinking: explicit > shorthand from model > top-level > top-level shorthand > default "medium"
	const thinking =
		perItem.thinking ??
		shorthandThinking ??
		topLevel?.thinking ??
		(topLevelParsed?.thinking ? topLevelParsed.thinking : undefined) ??
		"medium";

	// Context files: per-item > top-level > default true
	const contextFiles = perItem.contextFiles ?? topLevel?.contextFiles ?? true;

	// Extensions: per-item > top-level > default false
	const extensions = perItem.extensions ?? topLevel?.extensions ?? false;

	return {
		name,
		systemPrompt: effectiveSystemPrompt,
		tools,
		model,
		provider,
		thinking,
		contextFiles,
		extensions,
	};
}

// ─── CLI Arg Builder ──────────────────────────────────────────────────

export function buildSpawnArgs(config: SubagentConfig, task: string): string[] {
	const args: string[] = ["--mode", "json", "-p", "--no-session", "--no-skills"];

	if (config.provider) args.push("--provider", config.provider);
	if (config.model) args.push("--model", config.model);
	// Suppress --thinking for "medium" (Pi default)
	if (config.thinking && config.thinking !== "medium") {
		args.push("--thinking", config.thinking);
	}
	if (config.tools && config.tools.length > 0) {
		args.push("--tools", config.tools.join(","));
	}
	if (!config.contextFiles) args.push("--no-context-files");
	if (!config.extensions) args.push("--no-extensions");

	// Task text is appended at the end
	args.push(`Task: ${task}`);

	return args;
}