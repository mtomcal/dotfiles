import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

function contextLine(percent: number | null | undefined): string {
  return percent === null || percent === undefined
    ? "Context: unavailable"
    : `Context: ${percent.toFixed(1)}% used`;
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") {
      return;
    }

    ctx.ui.setFooter((tui, theme, footerData) => {
      const unsubscribe = footerData.onBranchChange(() => tui.requestRender());

      return {
        dispose: unsubscribe,
        invalidate() {},
        render(width: number): string[] {
          const usage = ctx.getContextUsage();
          const branch = footerData.getGitBranch();
          const details = [branch, ctx.model?.id].filter(Boolean).join(" · ");
          const lines = [theme.fg("dim", contextLine(usage?.percent))];
          if (details) {
            lines.push(theme.fg("dim", details));
          }
          return lines.map((line) => truncateToWidth(line, width));
        },
      };
    });
  });
}
