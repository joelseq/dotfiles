import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

const STATUS_KEY = "pi-lens-summary";

type Severity = "error" | "warning" | "info" | "hint";

type Diagnostic = {
  severity: Severity;
};

type DiagnosticsPayload = {
  v: 1;
  source: "pi-lens";
  seq: number;
  files: Array<{
    path: string;
    diagnostics: Diagnostic[];
    truncated?: boolean;
  }>;
};

export default function piLensStatus(pi: ExtensionAPI): void {
  let currentContext: ExtensionContext | undefined;
  let lastSequence = -1;
  let hasResults = false;
  const diagnosticsByFile = new Map<string, Diagnostic[]>();
  const truncatedFiles = new Set<string>();

  function renderStatus(): void {
    const ctx = currentContext;
    if (!ctx?.hasUI) return;

    if (!hasResults) {
      ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg("muted", "Lens …"));
      return;
    }

    let errors = 0;
    let warnings = 0;
    for (const diagnostics of diagnosticsByFile.values()) {
      for (const diagnostic of diagnostics) {
        if (diagnostic.severity === "error") errors += 1;
        if (diagnostic.severity === "warning") warnings += 1;
      }
    }

    const incomplete = truncatedFiles.size > 0 ? "+" : "";
    if (errors > 0) {
      const warningsText = warnings > 0 ? ` ${warnings}W` : "";
      ctx.ui.setStatus(
        STATUS_KEY,
        ctx.ui.theme.fg("error", `Lens ${errors}E${warningsText}${incomplete}`),
      );
    } else if (warnings > 0) {
      ctx.ui.setStatus(
        STATUS_KEY,
        ctx.ui.theme.fg("warning", `Lens ${warnings}W${incomplete}`),
      );
    } else {
      ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg("success", "Lens ✓"));
    }
  }

  pi.events.on("pilens:diagnostics", (data) => {
    const payload = data as Partial<DiagnosticsPayload>;
    if (
      payload.v !== 1 ||
      payload.source !== "pi-lens" ||
      typeof payload.seq !== "number" ||
      !Array.isArray(payload.files) ||
      payload.seq <= lastSequence
    ) {
      return;
    }

    lastSequence = payload.seq;
    hasResults = true;
    for (const file of payload.files) {
      if (!file || typeof file.path !== "string" || !Array.isArray(file.diagnostics)) {
        continue;
      }
      diagnosticsByFile.set(file.path, file.diagnostics);
      if (file.truncated) {
        truncatedFiles.add(file.path);
      } else {
        truncatedFiles.delete(file.path);
      }
    }
    renderStatus();
  });

  pi.on("session_start", (_event, ctx) => {
    currentContext = ctx;
    lastSequence = -1;
    hasResults = false;
    diagnosticsByFile.clear();
    truncatedFiles.clear();
    renderStatus();
  });

  pi.on("session_shutdown", (_event, ctx) => {
    ctx.ui.setStatus(STATUS_KEY, undefined);
    currentContext = undefined;
  });
}
