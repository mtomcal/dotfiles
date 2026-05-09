/**
 * Slice 1: Agent MD file loading and parsing
 *
 * Tests for:
 * - loadAgentFile(agentName, agentsDir) — reads MD, parses frontmatter, returns ResolvableFields
 * - listAgentFiles(agentsDir) — lists available agent names
 * - Frontmatter parsing (YAML between --- delimiters)
 * - Error handling for missing files, malformed frontmatter
 */

import { describe, test, expect, vi, beforeEach, afterEach } from "vitest";
import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";

import { loadAgentFile, listAgentFiles, parseAgentFrontmatter } from "../agent-loading.js";

describe("agent-loading", () => {
	let tmpDir: string;

	beforeEach(() => {
		tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-agent-test-"));
	});

	afterEach(() => {
		fs.rmSync(tmpDir, { recursive: true, force: true });
	});

	function writeFile(name: string, content: string): string {
		const filePath = path.join(tmpDir, name);
		fs.writeFileSync(filePath, content, "utf-8");
		return filePath;
	}

	describe("parseAgentFrontmatter", () => {
		test("parses frontmatter with name, description, tools", () => {
			const content = [
				"---",
				"name: implementer",
				"description: TDD implementation agent",
				"tools: read, write, bash, edit",
				"---",
				"",
				"You are an implementation agent.",
			].join("\n");

			const result = parseAgentFrontmatter(content);
			expect(result).not.toBeNull();
			expect(result!["name"]).toBe("implementer");
			expect(result!["description"]).toBe("TDD implementation agent");
			expect(result!["tools"]).toBe("read, write, bash, edit");
		});

		test("parses all optional fields when present", () => {
			const content = [
				"---",
				"name: implementer",
				"description: TDD implementation agent",
				"tools: read, write, bash, edit",
				"model: glm-5.1",
				"provider: ollama-cloud",
				"thinking: medium",
				"maxTurns: 30",
				"maxCost: 0.30",
				"maxTokens: 200000",
				"maxTime: 300",
				"---",
				"",
				"You are an implementation agent.",
			].join("\n");

			const result = parseAgentFrontmatter(content);
			expect(result).not.toBeNull();
			expect(result!["model"]).toBe("glm-5.1");
			expect(result!["provider"]).toBe("ollama-cloud");
			expect(result!["thinking"]).toBe("medium");
			expect(result!["maxTurns"]).toBe("30");
			expect(result!["maxCost"]).toBe("0.30");
			expect(result!["maxTokens"]).toBe("200000");
			expect(result!["maxTime"]).toBe("300");
		});

		test("returns null for content with no frontmatter", () => {
			const content = "Just a plain markdown file with no frontmatter.";
			const result = parseAgentFrontmatter(content);
			expect(result).toBeNull();
		});

		test("returns null for empty content", () => {
			const result = parseAgentFrontmatter("");
			expect(result).toBeNull();
		});

		test("handles frontmatter with only some optional fields", () => {
			const content = [
				"---",
				"name: reviewer",
				"description: Code reviewer",
				"tools: read, bash",
				"model: deepseek-v4-pro",
				"---",
				"",
				"You are a reviewer.",
			].join("\n");

			const result = parseAgentFrontmatter(content);
			expect(result).not.toBeNull();
			expect(result!["model"]).toBe("deepseek-v4-pro");
			expect(result!["provider"]).toBeUndefined(); // omitted
			expect(result!["thinking"]).toBeUndefined(); // omitted
		});

		test("extracts body text after frontmatter", () => {
			const content = [
				"---",
				"name: implementer",
				"description: Does stuff",
				"tools: read",
				"---",
				"",
				"You are an implementation agent.",
				"Follow the TDD cycle.",
				"",
				"Execute RED, GREEN, REFACTOR.",
			].join("\n");

			const result = parseAgentFrontmatter(content);
			expect(result).not.toBeNull();
			// After GREEN, we'll also test body extraction — for now just frontmatter
		});

		test("strips trailing whitespace from field values", () => {
			const content = [
				"---",
				"name: implementer  ",
				"description: TDD agent  ",
				"tools: read, write  ",
				"---",
				"",
				"Body text.",
			].join("\n");

			const result = parseAgentFrontmatter(content);
			expect(result).not.toBeNull();
			expect(result!["name"]).toBe("implementer");
			expect(result!["tools"]).toBe("read, write");
		});
	});

	describe("loadAgentFile", () => {
		test("loads a valid agent file and returns frontmatter + body", () => {
			writeFile("implementer.md", [
				"---",
				"name: implementer",
				"description: TDD implementation agent",
				"tools: read, write, bash, edit",
				"---",
				"",
				"You are an implementation agent.",
				"Follow the TDD cycle.",
			].join("\n"));

			const result = loadAgentFile("implementer", tmpDir);
			expect(result).not.toBeNull();
			expect(result!.name).toBe("implementer");
			expect(result!.description).toBe("TDD implementation agent");
			expect(result!.tools).toBe("read, write, bash, edit");
			expect(result!.systemPrompt).toContain("You are an implementation agent");
			expect(result!.systemPrompt).toContain("Follow the TDD cycle");
		});

		test("loads agent with all optional fields", () => {
			writeFile("implementer.md", [
				"---",
				"name: implementer",
				"description: TDD agent",
				"tools: read, write",
				"model: glm-5.1",
				"provider: ollama-cloud",
				"thinking: medium",
				"maxTurns: 30",
				"maxCost: 0.30",
				"maxTokens: 200000",
				"maxTime: 300",
				"---",
				"",
				"Body text.",
			].join("\n"));

			const result = loadAgentFile("implementer", tmpDir);
			expect(result).not.toBeNull();
			expect(result!.model).toBe("glm-5.1");
			expect(result!.provider).toBe("ollama-cloud");
			expect(result!.thinking).toBe("medium");
			expect(result!.maxTurns).toBe(30); // should be parsed as number
			expect(result!.maxCost).toBe(0.30);
			expect(result!.maxTokens).toBe(200000);
			expect(result!.maxTime).toBe(300);
		});

		test("returns null for non-existent agent", () => {
			const result = loadAgentFile("nonexistent", tmpDir);
			expect(result).toBeNull();
		});

		test("returns null for non-.md file (won't find it)", () => {
			writeFile("implementer.txt", "not an md file");
			const result = loadAgentFile("implementer", tmpDir);
			expect(result).toBeNull();
		});

		test("returns null for file without valid frontmatter", () => {
			writeFile("bogus.md", "Just text, no frontmatter at all.");
			const result = loadAgentFile("bogus", tmpDir);
			expect(result).toBeNull();
		});

		test("frontmatter with name but no tools still loads (tools will be undefined)", () => {
			writeFile("minimal.md", [
				"---",
				"name: minimal",
				"---",
				"",
				"Body text.",
			].join("\n"));

			const result = loadAgentFile("minimal", tmpDir);
			expect(result).not.toBeNull();
			expect(result!.name).toBe("minimal");
			expect(result!.tools).toBeUndefined();
		});
	});

	describe("listAgentFiles", () => {
		test("lists all agent files in directory", () => {
			writeFile("implementer.md", "---\nname: implementer\ndescription: A\ntools: read\n---\n\nBody.");
			writeFile("test-reviewer.md", "---\nname: test-reviewer\ndescription: B\ntools: bash\n---\n\nBody.");
			writeFile("not-an-agent.txt", "not an md file");

			const agents = listAgentFiles(tmpDir);
			expect(agents).toHaveLength(2);
			const names = agents.map((a) => a.name).sort();
			expect(names).toEqual(["implementer", "test-reviewer"]);
		});

		test("returns empty array for empty directory", () => {
			const agents = listAgentFiles(tmpDir);
			expect(agents).toEqual([]);
		});

		test("returns empty array for non-existent directory", () => {
			const agents = listAgentFiles("/nonexistent/dir/agents");
			expect(agents).toEqual([]);
		});

		test("skips .md files without valid frontmatter", () => {
			writeFile("valid.md", "---\nname: valid\ndescription: D\ntools: read\n---\n\nBody.");
			writeFile("nofm.md", "No frontmatter here.");
			writeFile("emptyfm.md", "---\n---\nBody but no fields.");

			const agents = listAgentFiles(tmpDir);
			// Only valid.md has complete frontmatter with name
			expect(agents).toHaveLength(1);
			expect(agents[0].name).toBe("valid");
		});

		test("descriptions are included in listing", () => {
			writeFile("implementer.md", "---\nname: implementer\ndescription: TDD implementation agent\ntools: read\n---\n\nBody.");
			writeFile("reviewer.md", "---\nname: reviewer\ndescription: Code quality reviewer\ntools: read, bash\n---\n\nBody.");

			const agents = listAgentFiles(tmpDir);
			const imp = agents.find((a) => a.name === "implementer");
			const rev = agents.find((a) => a.name === "reviewer");
			expect(imp!.description).toBe("TDD implementation agent");
			expect(rev!.description).toBe("Code quality reviewer");
		});
	});

	describe("resolveConfig with agent file", () => {
		// This will be tested in subagent-config once the integration is done.
		// Placeholder for Slice 2.
		test.todo("agent file provides defaults that per-call overrides can punch through");
		test.todo("agent file model overridden by per-call model");
		test.todo("agent file guardrails overridden by per-call guardrails");
		test.todo("agent file systemPrompt used when per-call systemPrompt is absent");
		test.todo("per-call tools override agent file tools");
		test.todo("agent file fields are parsed to correct types (numbers for guardrails)");
	});
});
