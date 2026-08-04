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
