/**
 * Smoke tests — verify agent MD files load correctly with the real filesystem.
 * Run after /reload to confirm the extension works with actual agent files.
 */

import { describe, test, expect } from "vitest";
import { loadAgentFile, listAgentFiles, getDefaultAgentsDir } from "../agent-loading.js";
import { resolveConfig } from "../subagent-config.js";
import * as path from "node:path";
import * as os from "node:os";
import * as fs from "node:fs";

// Use the repo's pi/agents/ dir directly (where we created the files)
const agentsDir = path.join(os.homedir(), "dotfiles", "pi", "agents");

describe("smoke: agent file loading from disk", () => {
	test("agents dir exists", () => {
		expect(fs.existsSync(agentsDir)).toBe(true);
	});

	test("lists all 4 agents", () => {
		const agents = listAgentFiles(agentsDir);
		const names = agents.map((a) => a.name).sort();
		expect(names).toEqual([
			"implementer",
			"quality-reviewer",
			"security-reviewer",
			"test-reviewer",
		]);
	});

	test("loads implementer agent correctly", () => {
		const agent = loadAgentFile("implementer", agentsDir);
		expect(agent).not.toBeNull();
		expect(agent!.name).toBe("implementer");
		expect(agent!.description).toContain("TDD");
		expect(agent!.tools).toBe("read, write, bash, edit");
		expect(agent!.systemPrompt).toContain("implementation agent");
		expect(agent!.systemPrompt).toContain("RED");
		expect(agent!.systemPrompt).toContain("GREEN");
		expect(agent!.systemPrompt).toContain("REFACTOR");
		// No model/provider/thinking/guardrails — these come from the manifest
		expect(agent!.model).toBeUndefined();
		expect(agent!.provider).toBeUndefined();
	});

	test("loads test-reviewer agent correctly", () => {
		const agent = loadAgentFile("test-reviewer", agentsDir);
		expect(agent).not.toBeNull();
		expect(agent!.name).toBe("test-reviewer");
		expect(agent!.tools).toBe("read, bash");
		expect(agent!.systemPrompt).toContain("test reviewer");
		expect(agent!.systemPrompt).toContain("vague");
	});

	test("loads quality-reviewer agent correctly", () => {
		const agent = loadAgentFile("quality-reviewer", agentsDir);
		expect(agent).not.toBeNull();
		expect(agent!.name).toBe("quality-reviewer");
		expect(agent!.tools).toBe("read, bash");
		expect(agent!.systemPrompt).toContain("code quality");
	});

	test("loads security-reviewer agent correctly", () => {
		const agent = loadAgentFile("security-reviewer", agentsDir);
		expect(agent).not.toBeNull();
		expect(agent!.name).toBe("security-reviewer");
		expect(agent!.tools).toBe("read, bash");
		expect(agent!.systemPrompt).toContain("security reviewer");
	});
});

describe("smoke: config resolution with real agent files", () => {
	test("implementer agent provides system prompt and tools as defaults", () => {
		const agent = loadAgentFile("implementer", agentsDir);
		const config = resolveConfig(
			{ task: "Fix login bug" },
			undefined, undefined, null,
			agent,
		);
		expect(config.systemPrompt).toContain("implementation agent");
		expect(config.tools).toEqual(["read", "write", "bash", "edit"]);
		expect(config.thinking).toBe("medium"); // default
		expect(config.model).toBeUndefined(); // no model in agent file
	});

	test("per-call model overrides when using implementer agent", () => {
		const agent = loadAgentFile("implementer", agentsDir);
		const config = resolveConfig(
			{ task: "Fix login bug", model: "glm-5.1", provider: "ollama-cloud" },
			undefined, undefined, null,
			agent,
		);
		expect(config.model).toBe("glm-5.1");
		expect(config.provider).toBe("ollama-cloud");
		expect(config.tools).toEqual(["read", "write", "bash", "edit"]); // still from agent
	});

	test("reviewer agents have read-only tools", () => {
		for (const name of ["test-reviewer", "quality-reviewer", "security-reviewer"]) {
			const agent = loadAgentFile(name, agentsDir);
			const config = resolveConfig(
				{ task: "Review slice 1" },
				undefined, undefined, null,
				agent,
			);
			expect(config.tools).toEqual(["read", "bash"]);
			// No write or edit tools for reviewers
			expect(config.tools).not.toContain("write");
			expect(config.tools).not.toContain("edit");
		}
	});

	test("per-call guardrails override empty agent guardrails", () => {
		const agent = loadAgentFile("implementer", agentsDir);
		expect(agent!.maxTurns).toBeUndefined(); // not in agent file

		const config = resolveConfig(
			{ task: "Fix bug", maxTurns: 50, maxCost: 1.0 },
			undefined, undefined, null,
			agent,
		);
		expect(config.guardrails.maxTurns).toBe(50);
		expect(config.guardrails.maxCost).toBe(1.0);
	});

	test("null agent falls through to bare-task injection", () => {
		const config = resolveConfig(
			{ task: "Quick check" },
			undefined, undefined, null,
			null,
		);
		expect(config.systemPrompt).toContain("subagent operating in an isolated context");
		expect(config.tools).toBeUndefined(); // all tools
	});
});

describe("smoke: agents directory symlink target", () => {
	test("getDefaultAgentsDir points to ~/.pi/agent/agents", () => {
		const dir = getDefaultAgentsDir();
		expect(dir).toContain(".pi/agent/agents");
	});

	test("can load from default agents dir if symlinked", () => {
		// Only works if the symlink exists, otherwise skip
		const defaultDir = getDefaultAgentsDir();
		if (fs.existsSync(defaultDir)) {
			const agent = loadAgentFile("implementer", defaultDir);
			expect(agent).not.toBeNull();
			expect(agent!.name).toBe("implementer");
		} else {
			console.warn(`Skipped: ${defaultDir} not found (run install.sh to create symlink)`);
		}
	});
});
