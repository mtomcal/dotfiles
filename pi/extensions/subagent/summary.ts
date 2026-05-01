/**
 * Summary extraction and widget truncation utilities.
 *
 * Provides constants for summary thresholds / widget timing and
 * functions to extract a substantive summary from a message array
 * and truncate it for display in a TUI widget.
 */

import type { Message } from "@mariozechner/pi-ai";
import { getDisplayItems } from "./renderers.js";

/** Minimum character length for a text block to be considered a substantive summary. */
export const SUBAGENT_SUMMARY_MIN_LENGTH = 50;

/** Debounce interval (ms) for widget update events. */
export const SUBAGENT_WIDGET_DEBOUNCE_MS = 1000;

/** Delay (ms) before auto-dismissing the widget after completion. */
export const SUBAGENT_WIDGET_DISMISS_DELAY_MS = 5000;

/**
 * Extract a summary from a message array by scanning backward through
 * assistant display items (as produced by getDisplayItems).
 *
 * Returns the first text block with length ≥ SUBAGENT_SUMMARY_MIN_LENGTH
 * encountered while scanning backward. Falls back to the last text block
 * (the one closest to the end) if none meet the threshold, or an empty
 * string if there are no text blocks at all.
 */
export function extractSummary(messages: Message[]): string {
	const items = getDisplayItems(messages);
	let lastTextBlock = "";
	for (let i = items.length - 1; i >= 0; i--) {
		if (items[i].type === "text") {
			if (items[i].text.length >= SUBAGENT_SUMMARY_MIN_LENGTH) {
				return items[i].text;
			}
			if (!lastTextBlock) {
				lastTextBlock = items[i].text;
			}
		}
	}
	return lastTextBlock;
}

/**
 * Truncate text for display in a TUI widget.
 *
 * 1. Truncates at the first newline boundary.
 * 2. Clips to (maxWidth − 2) characters, where the 2-char reduction
 *    accounts for the "  " indent prefix used in widget rendering.
 *
 * If maxWidth is 0, undefined, or less than 4, defaults to 80.
 * Returns an empty string when given empty text.
 */
export function truncateForWidget(text: string, maxWidth: number): string {
	const effectiveWidth = !maxWidth || maxWidth < 4 ? 80 : maxWidth;
	const maxChars = effectiveWidth - 2;

	if (!text) return "";

	// Truncate at first newline
	const newlineIdx = text.indexOf("\n");
	if (newlineIdx >= 0) {
		text = text.slice(0, newlineIdx);
	}

	// Clip to max chars
	if (text.length > maxChars) {
		text = text.slice(0, maxChars);
	}

	return text;
}