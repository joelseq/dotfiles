# Pi configuration

Portable Pi resources managed by dotfiles.

Linked by `install.conf.yaml` into:

- `~/.pi/agent/settings.json`
- `~/.pi/agent/extensions/`
- `~/.pi/agent/themes/`
- `~/.pi/agent/prompts/`
- `~/.pi/agent/skills/`

Intentionally **not** tracked here:

- `~/.pi/agent/auth.json`
- `~/.pi/agent/models-store.json`
- `~/.pi/agent/sessions/`

Extensions are stored as per-extension TypeScript packages (`extensions/<name>/index.ts`) with their own `package.json` and `tsconfig.json`.

Useful commands:

```bash
npm --prefix config/pi/agent/extensions/safety run check
npm --prefix config/pi/agent/extensions/statusline run check
npm --prefix config/pi/agent/extensions/safety run format
npm --prefix config/pi/agent/extensions/statusline run format
```

After changing extensions/prompts/skills in a running Pi session, use `/reload`.

Custom themes hot reload when the active theme file changes.

## Built-in MCP

Use Pi 0.99 or later. Pi loads built-in MCP when the MCP adapter is absent.
Keep server settings in `~/.pi/agent/mcp.json`. Keep this file and
`~/.pi/agent/mcp-auth.json` outside Git; they can contain credentials.

Add a server and check its connection:

```bash
pi mcp add <name> --url <url>
pi mcp list
```

Use `.pi/mcp.json` for project servers. Built-in MCP does not read the adapter's
`.mcp.json` or `mcp-adapter.json` files. Move required entries into `mcp.json`.
If settings contain `"-builtin:mcp"` under `extensions`, remove that entry.
Restart Pi after removing the adapter. Use `/mcp` to check server state and sign in.
The adapter notification patch is no longer required.
