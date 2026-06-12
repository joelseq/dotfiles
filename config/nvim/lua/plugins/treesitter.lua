-- Customize Treesitter

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = function(_, opts)
    opts.treesitter = opts.treesitter or {}
    opts.treesitter.highlight = true
    opts.treesitter.indent = true
    opts.treesitter.auto_install = true
    opts.treesitter.ensure_installed = require("astrocore").list_insert_unique(opts.treesitter.ensure_installed or {}, {
      "lua",
      "vim",
      -- add more arguments for adding more treesitter parsers
      "bash",
      "go",
      "html",
      "javascript",
      "json",
      "luadoc",
      "luap",
      "markdown",
      "markdown_inline",
      "python",
      "query",
      "regex",
      "ruby",
      "rust",
      "svelte",
      "toml",
      "tsx",
      "typescript",
      "yaml",
    })
  end,
}
