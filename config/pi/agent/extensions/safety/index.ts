import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"
import { existsSync, readFileSync } from "node:fs"

export type Settings = {
  safety?: {
    enabled?: boolean
  }
}

type Decision = {
  kind: "block" | "confirm"
  reason: string
}

function isSafetyEnabled(): boolean {
  const envValue = process.env.PI_SAFETY_ENABLED?.toLowerCase()
  if (["0", "false", "no", "off"].includes(envValue ?? "")) return false
  if (["1", "true", "yes", "on"].includes(envValue ?? "")) return true

  try {
    const settingsPath = `${process.env.HOME}/.pi/agent/settings.json`
    const settings = existsSync(settingsPath)
      ? (JSON.parse(readFileSync(settingsPath, "utf8")) as Settings)
      : {}
    return settings.safety?.enabled !== false
  } catch {
    return true
  }
}

const SECRET_FILE_PATTERNS = [
  /(^|\/)\.env($|\.)/,
  /(^|\/)\.npmrc$/,
  /(^|\/)\.pypirc$/,
  /(^|\/)id_(rsa|dsa|ecdsa|ed25519)$/,
  /(^|\/).*\.(pem|key|p12|pfx)$/,
]

const PROTECTED_DIR_PATTERNS = [/(^|\/)\.git($|\/)/, /(^|\/)node_modules($|\/)/]

const LOCKFILE_PATTERNS = [
  /(^|\/)package-lock\.json$/,
  /(^|\/)pnpm-lock\.yaml$/,
  /(^|\/)yarn\.lock$/,
  /(^|\/)bun\.lockb?$/,
  /(^|\/)Cargo\.lock$/,
  /(^|\/)Gemfile\.lock$/,
  /(^|\/)poetry\.lock$/,
]

const DANGEROUS_BASH_PATTERNS: Array<[RegExp, string]> = [
  [
    /\brm\s+[^\n;]*(?:-[^\n;]*r[^\n;]*f|-[^\n;]*f[^\n;]*r|--recursive[^\n;]*--force|--force[^\n;]*--recursive)/,
    "recursive forced delete",
  ],
  [/\bgit\s+reset\s+--hard\b/, "git reset --hard discards work"],
  [
    /\bgit\s+clean\s+[^\n;]*(?:-[^\n;]*f|--force)/,
    "git clean --force deletes untracked files",
  ],
  [
    /\bgit\s+(?:checkout|restore)\s+(?:--\s+)?\.(?:\s|;|$)/,
    "checkout/restore of entire working tree",
  ],
  [/\bsudo\b/, "sudo command"],
  [/\bchmod\s+-R\s+(?:777|\+w)\b/, "recursive broad chmod"],
  [/\bchown\s+-R\b/, "recursive chown"],
  [/\bdd\s+[^\n;]*\bof=/, "dd writing to a device/file"],
  [/\bmkfs(?:\.[a-z0-9]+)?\b/, "filesystem formatting command"],
  [/\btruncate\s+[^\n;]*\s-s\s*0\b/, "truncate to zero bytes"],
]

function normalizedPath(input: unknown): string {
  return String(input ?? "").replaceAll("\\", "/")
}

function pathDecision(filePath: unknown): Decision | undefined {
  const p = normalizedPath(filePath)

  if (SECRET_FILE_PATTERNS.some((pattern) => pattern.test(p))) {
    return { kind: "block", reason: `Protected secret file: ${filePath}` }
  }

  if (PROTECTED_DIR_PATTERNS.some((pattern) => pattern.test(p))) {
    return { kind: "block", reason: `Protected directory: ${filePath}` }
  }

  if (LOCKFILE_PATTERNS.some((pattern) => pattern.test(p))) {
    return { kind: "confirm", reason: `Lockfile modification: ${filePath}` }
  }

  return undefined
}

function bashDecision(command: string): Decision | undefined {
  for (const [pattern, reason] of DANGEROUS_BASH_PATTERNS) {
    if (pattern.test(command)) return { kind: "confirm", reason }
  }

  if (/\b(?:>|>>|tee\s+)(?:\S*\/)?\.env(?:\s|$|\.)/.test(command)) {
    return { kind: "block", reason: "attempt to write .env from shell" }
  }

  return undefined
}

async function handleDecision(
  decision: Decision,
  ctx: any,
): Promise<{ block: true; reason: string } | undefined> {
  if (decision.kind === "block") {
    if (ctx.hasUI)
      ctx.ui.notify(`Safety blocked: ${decision.reason}`, "warning")
    return { block: true, reason: decision.reason }
  }

  if (!ctx.hasUI) {
    return {
      block: true,
      reason: `${decision.reason}; confirmation required but no UI is available`,
    }
  }

  const allowed = await ctx.ui.confirm(
    "Safety confirmation",
    `Allow ${decision.reason}?`,
  )
  if (!allowed) {
    ctx.ui.notify(`Safety blocked: ${decision.reason}`, "warning")
    return { block: true, reason: decision.reason }
  }

  ctx.ui.notify(`Safety allowed: ${decision.reason}`, "info")
  return undefined
}

export default function safety(pi: ExtensionAPI) {
  pi.registerCommand("safety-status", {
    description: "Show the active safety extension rules",
    handler: async (_args, ctx) => {
      const message = [
        `Safety extension is ${isSafetyEnabled() ? "active" : "disabled"}.`,
        "Set safety.enabled=false or PI_SAFETY_ENABLED=false to disable it.",
        "",
        "Blocks writes/edits to secret files and protected directories:",
        "- .env*, .npmrc, .pypirc, private keys/certs",
        "- .git/, node_modules/",
        "",
        "Confirms lockfile writes/edits and dangerous shell commands:",
        "- rm -rf, git reset --hard, git clean -f, sudo, chmod/chown -R, dd, mkfs, truncate",
      ].join("\n")
      if (ctx.hasUI) ctx.ui.notify(message, "info")
      else console.log(message)
    },
  })

  pi.on("session_start", async (_event, ctx) => {
    if (ctx.hasUI)
      ctx.ui.setStatus("safety", isSafetyEnabled() ? "safety:on" : "safety:off")
  })

  pi.on("tool_call", async (event, ctx) => {
    if (!isSafetyEnabled()) return undefined

    if (event.toolName === "write" || event.toolName === "edit") {
      const decision = pathDecision((event.input as { path?: unknown }).path)
      if (decision) return handleDecision(decision, ctx)
    }

    if (event.toolName === "bash") {
      const command = String(
        (event.input as { command?: unknown }).command ?? "",
      )
      const decision = bashDecision(command)
      if (decision) return handleDecision(decision, ctx)
    }

    return undefined
  })
}
