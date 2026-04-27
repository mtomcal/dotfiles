/**
 * Ollama Cloud Web Search & Fetch — Pi extension
 *
 * Registers two tools:
 *   - web_search: Search the web via Ollama Cloud
 *   - web_fetch:  Fetch and extract content from a URL
 *
 * Requires OLLAMA_API_KEY environment variable.
 *
 * Content is truncated to stay within safe context limits.
 */

import { Type } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const OLLAMA_API = "https://ollama.com/api";

// ~1 token ≈ 4 chars. 30K chars ≈ 7.5K tokens — safe headroom for any model.
const MAX_CONTENT_CHARS = 30000;
const MAX_SNIPPET_CHARS = 500;

function getApiKey(): string {
	const key = process.env.OLLAMA_API_KEY;
	if (!key) throw new Error("OLLAMA_API_KEY environment variable is not set");
	return key;
}

async function ollamaPost(endpoint: string, body: Record<string, unknown>): Promise<any> {
	const res = await fetch(`${OLLAMA_API}/${endpoint}`, {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
			Authorization: `Bearer ${getApiKey()}`,
		},
		body: JSON.stringify(body),
	});
	if (!res.ok) {
		const text = await res.text();
		throw new Error(`Ollama API ${endpoint} failed (${res.status}): ${text}`);
	}
	return res.json();
}

function truncate(text: string, maxChars: number): string {
	if (text.length <= maxChars) return text;
	return text.slice(0, maxChars) + `\n\n[... truncated ${text.length - maxChars} chars]`;
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "web_search",
		label: "Web Search",
		description:
			"Search the web using Ollama Cloud. Returns titles, URLs, and content snippets for the top results. Each snippet is truncated to stay context-safe.",
		parameters: Type.Object({
			query: Type.String({ description: "Search query" }),
			max_results: Type.Optional(
				Type.Integer({ description: "Number of results (1-10, default 5)", minimum: 1, maximum: 10 }),
			),
		}),

		async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
			try {
				const data = await ollamaPost("web_search", {
					query: params.query,
					max_results: params.max_results ?? 5,
				});

				const results = data.results ?? [];
				if (results.length === 0) {
					return { content: [{ type: "text", text: `No results found for: ${params.query}` }] };
				}

				const formatted = results
					.map(
						(r: { title: string; url: string; content: string }, i: number) =>
							`${i + 1}. **${r.title}**\n   ${r.url}\n   ${truncate(r.content ?? "", MAX_SNIPPET_CHARS)}`,
					)
					.join("\n\n");

				return {
					content: [{ type: "text", text: truncate(formatted, MAX_CONTENT_CHARS) }],
					details: { query: params.query, resultCount: results.length },
				};
			} catch (err: any) {
				return {
					content: [{ type: "text", text: `Web search error: ${err.message}` }],
					isError: true,
				};
			}
		},
	});

	pi.registerTool({
		name: "web_fetch",
		label: "Web Fetch",
		description:
			"Fetch and extract the main content from a URL using Ollama Cloud. Content is truncated to ~30K chars to stay context-safe. For large pages, use web_search first to find the specific section you need.",
		parameters: Type.Object({
			url: Type.String({ description: "URL to fetch" }),
		}),

		async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
			try {
				const data = await ollamaPost("web_fetch", { url: params.url });

				const title = data.title ?? "(no title)";
				const rawContent = data.content ?? "(no content)";
				const links = data.links ?? [];
				const content = truncate(rawContent, MAX_CONTENT_CHARS);

				let text = `# ${title}\n\n${content}`;
				if (links.length > 0) {
					text += `\n\n## Links (first 10 of ${links.length})\n${links.slice(0, 10).map((l: string) => `- ${l}`).join("\n")}`;
				}

				return {
					content: [{ type: "text", text }],
					details: {
						url: params.url,
						title,
						linkCount: links.length,
						truncated: rawContent.length > MAX_CONTENT_CHARS,
						originalChars: rawContent.length,
					},
				};
			} catch (err: any) {
				return {
					content: [{ type: "text", text: `Web fetch error: ${err.message}` }],
					isError: true,
				};
			}
		},
	});
}
