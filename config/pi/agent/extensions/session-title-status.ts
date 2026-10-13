import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

const WIDGET_KEY = "session-title";

export default function sessionTitleStatus(pi: ExtensionAPI): void {
  function showTitle(ctx: ExtensionContext, title = pi.getSessionName()): void {
    if (!ctx.hasUI || !title) {
      ctx.ui.setWidget(WIDGET_KEY, undefined);
      return;
    }

    ctx.ui.setWidget(
      WIDGET_KEY,
      (_tui, theme) => ({
        invalidate() {},
        render(width: number): string[] {
          const line = theme.fg("muted", `session · ${title}`);
          return [truncateToWidth(line, width)];
        },
      }),
      { placement: "belowEditor" },
    );
  }

  pi.on("session_start", (_event, ctx) => {
    showTitle(ctx);
  });

  pi.on("session_info_changed", (event, ctx) => {
    showTitle(ctx, event.name);
  });

  pi.on("session_shutdown", (_event, ctx) => {
    ctx.ui.setWidget(WIDGET_KEY, undefined);
  });
}
