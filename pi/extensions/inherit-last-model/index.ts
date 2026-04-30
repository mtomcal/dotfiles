/**
 * Inherit Last Model Extension
 *
 * When `/new` is used to start a fresh session, this extension carries over
 * the provider and model from the previous session instead of falling back
 * to the configured default (settings.defaultProvider/defaultModel).
 *
 * How it works:
 * - On every model change (`model_select`), writes `{ provider, modelId }`
 *   to a temp file at `~/.pi/agent/last-model.json`.
 * - Also writes on `session_before_switch` as a safety net (fires during
 *   `/new` before the old extension instance is torn down).
 * - On `session_start` with reason "new", reads the temp file and calls
 *   `pi.setModel()` to restore. Silent if the file is missing, corrupt,
 *   the model was removed from config, or auth is unavailable.
 *
 * The temp file is necessary because the old extension instance is fully
 * disposed (with all in-memory state) before the new instance starts.
 *
 * Edge cases handled:
 * - No model selected yet → skip write, pi defaults apply
 * - Model removed from models.json → skip restore (find returns undefined)
 * - Auth lost for the model → pi.setModel() returns false, skip silently
 * - First run / no prior session → temp file missing, skip restore
 * - Corrupt temp file → JSON parse fails, skip restore
 * - Crash before `/new` → model_select already wrote the file, still works
 */

import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { getAgentDir } from "@mariozechner/pi-coding-agent";

/**
 * @returns Path to the temp file that holds the last selected model.
 */
function getLastModelPath(): string {
	return join(getAgentDir(), "last-model.json");
}

/**
 * Persist the current model to the temp file.
 * Only writes if both provider and modelId are present.
 */
function writeLastModel(model: { provider: string; id: string } | undefined): void {
	if (!model?.provider || !model?.id) return;

	try {
		writeFileSync(getLastModelPath(), JSON.stringify({ provider: model.provider, modelId: model.id }), "utf-8");
	} catch {
		// Silent — temp file writes are best-effort
	}
}

/**
 * Read and parse the persisted model from the temp file.
 * @returns `{ provider, modelId }` or undefined if file is missing/corrupt.
 */
function readLastModel(): { provider: string; modelId: string } | undefined {
	const path = getLastModelPath();
	if (!existsSync(path)) return undefined;

	try {
		const raw = readFileSync(path, "utf-8");
		const parsed = JSON.parse(raw);
		if (parsed && typeof parsed.provider === "string" && typeof parsed.modelId === "string") {
			return { provider: parsed.provider, modelId: parsed.modelId };
		}
	} catch {
		// Silent — corrupt file is treated as "no prior model"
	}

	return undefined;
}

export default function inheritLastModelExtension(pi: ExtensionAPI) {
	// -----------------------------------------------------------------------
	// Write: every model change records the current model to the temp file.
	// This ensures the file is always up-to-date even if pi crashes before
	// a `/new` command.
	// -----------------------------------------------------------------------
	pi.on("model_select", (event) => {
		writeLastModel(event.model);
	});

	// -----------------------------------------------------------------------
	// Write: safety net that fires during `/new` before the old extension
	// instance is disposed. ctx.model is the current (soon-to-be-previous)
	// session's model. Only writes for "new" reason, not "resume".
	// -----------------------------------------------------------------------
	pi.on("session_before_switch", (_event, ctx) => {
		if (_event.reason === "new" && ctx.model) {
			writeLastModel(ctx.model);
		}
	});

	// -----------------------------------------------------------------------
	// Read: after a new session starts, try to restore the last-used model.
	// Only applies for "new" sessions — "resume" and "fork" already carry
	// the model from session context.
	// -----------------------------------------------------------------------
	pi.on("session_start", async (event, ctx) => {
		if (event.reason !== "new") return;

		const lastModel = readLastModel();
		if (!lastModel) return;

		// Look up the model in the registry — might have been removed from config
		const model = ctx.modelRegistry.find(lastModel.provider, lastModel.modelId);
		if (!model) return;

		// Attempt restore. Returns false if auth is missing or model is invalid.
		// Silent on failure — pi falls through to its own defaults.
		try {
			await pi.setModel(model);
		} catch {
			// Silent — let pi handle the fallback
		}
	});
}
