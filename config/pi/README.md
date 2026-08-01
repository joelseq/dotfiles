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

After changing extensions/prompts/skills in a running Pi session, use `/reload`.

Custom themes hot reload when the active theme file changes.
