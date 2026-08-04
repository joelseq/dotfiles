import type { AssistantMessage } from "@earendil-works/pi-ai"
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui"
import path from "node:path"

type UsageTotals = {
  input: number
  output: number
  cost: number
}

function fmtCount(value: number): string {
  if (!Number.isFinite(value) || value <= 0) return "0"
  if (value < 1000) return String(Math.round(value))
  if (value < 1_000_000)
    return `${(value / 1000).toFixed(value < 10_000 ? 1 : 0)}k`
  return `${(value / 1_000_000).toFixed(1)}m`
}

function fmtCost(value: number): string {
  if (!Number.isFinite(value) || value <= 0) return "$0"
  if (value < 0.01) return `$${value.toFixed(4)}`
  if (value < 1) return `$${value.toFixed(3)}`
  return `$${value.toFixed(2)}`
}

function compactModel(modelId: string): string {
  return modelId
    .replace(/^claude-/, "")
    .replace(/^gpt-/, "g")
    .replace(/-20\d{6}$/, "")
    .replace(/-latest$/, "")
}

function totalsFromBranch(ctx: any): UsageTotals {
  const totals = { input: 0, output: 0, cost: 0 }
  for (const entry of ctx.sessionManager.getBranch()) {
    if (entry.type !== "message" || entry.message.role !== "assistant") continue
    const message = entry.message as AssistantMessage
    totals.input += message.usage?.input ?? 0
    totals.output += message.usage?.output ?? 0
    totals.cost += message.usage?.cost?.total ?? 0
  }
  return totals
}

function contextPart(ctx: any): string | null {
  const usage = ctx.getContextUsage?.()
  if (!usage?.tokens) return null

  const window = ctx.model?.contextWindow ?? ctx.model?.context_window
  if (!window) return `ctx ${fmtCount(usage.tokens)}`

  const percent = Math.min(999, Math.round((usage.tokens / window) * 100))
  return `ctx ${percent}%`
}

function statusParts(statuses: ReadonlyMap<string, string>): string[] {
  return [...statuses.entries()]
    .filter(([key, value]) => key !== "better-statusline" && value)
    .map(([_key, value]) => value.replace(/\x1b\[[0-9;]*m/g, ""))
}

export default function betterStatusline(pi: ExtensionAPI) {
  let enabled = true
  let renderRequest: (() => void) | undefined

  function installFooter(ctx: any) {
    if (!enabled || !ctx.hasUI) return

    ctx.ui.setFooter((tui: any, theme: any, footerData: any) => {
      renderRequest = () => tui.requestRender()
      const unsubBranch = footerData.onBranchChange(() => tui.requestRender())

      return {
        dispose() {
          unsubBranch()
          if (renderRequest) renderRequest = undefined
        },
        invalidate() {},
        render(width: number): string[] {
          const cwd = truncateToWidth(
            path.basename(ctx.cwd) || ctx.cwd,
            24,
            "…",
          )
          const branch = footerData.getGitBranch?.()
          const branchPart = branch
            ? ` ${truncateToWidth(branch, 28, "…")}`
            : "no-git"
          const provider = ctx.model?.provider ?? "no-provider"
          const model = compactModel(ctx.model?.id ?? "no-model")
          const thinking = ctx.thinkingLevel ? `:${ctx.thinkingLevel}` : ""
          const modelPart = `${provider}/${model}${thinking}`
          const usage = totalsFromBranch(ctx)
          const usagePart = `↑${fmtCount(usage.input)} ↓${fmtCount(usage.output)} ${fmtCost(usage.cost)}`
          const ctxPart = contextPart(ctx)
          const extParts = statusParts(
            footerData.getExtensionStatuses?.() ?? new Map(),
          )

          const leftItems = ["π", cwd, branchPart]
          const rightItems = [
            modelPart,
            ctxPart,
            usagePart,
            ...extParts,
          ].filter(Boolean) as string[]

          const sep = theme.fg("borderMuted", "  │  ")
          const left = [
            theme.fg("accent", leftItems[0]),
            theme.fg("text", cwd),
            theme.fg(branch ? "mdLink" : "dim", branchPart),
          ].join(sep)
          const right = [
            theme.fg("toolTitle", modelPart),
            ctxPart ? theme.fg("warning", ctxPart) : undefined,
            theme.fg("success", usagePart),
            ...extParts.map((part) => theme.fg("muted", part)),
          ]
            .filter(Boolean)
            .join(sep)
          const gap = width - visibleWidth(left) - visibleWidth(right)

          if (gap >= 1) return [left + " ".repeat(gap) + right]

          const compactRight = [
            theme.fg("toolTitle", modelPart),
            ctxPart ? theme.fg("warning", ctxPart) : undefined,
            theme.fg("success", usagePart),
          ]
            .filter(Boolean)
            .join(theme.fg("borderMuted", " │ "))
          const compactRightRaw = [modelPart, ctxPart, usagePart]
            .filter(Boolean)
            .join(" │ ")
          const compactGap =
            width - visibleWidth(left) - visibleWidth(compactRight)
          if (compactGap >= 1)
            return [left + " ".repeat(compactGap) + compactRight]

          return [
            truncateToWidth(
              `${leftItems.join(" ")} ${compactRightRaw}`,
              width,
              "…",
            ),
          ]
        },
      }
    })
  }

  pi.registerCommand("statusline", {
    description: "Toggle the better custom statusline",
    handler: async (_args, ctx) => {
      enabled = !enabled
      if (enabled) {
        installFooter(ctx)
        ctx.ui.notify("Better statusline enabled", "info")
      } else {
        ctx.ui.setFooter(undefined)
        ctx.ui.notify("Better statusline disabled", "info")
      }
    },
  })

  pi.on("session_start", async (_event, ctx) => {
    installFooter(ctx)
  })

  pi.on("model_select", async () => renderRequest?.())
  pi.on("thinking_level_select", async () => renderRequest?.())
  pi.on("agent_settled", async () => renderRequest?.())
}
