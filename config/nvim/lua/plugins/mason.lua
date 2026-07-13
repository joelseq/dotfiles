-- Install Mason-managed tools (LSP servers, formatters, linters, debuggers).
--
-- IMPORTANT: these are mason-tool-installer entries and use *mason package names*
-- (e.g. "ruby-lsp"), NOT lspconfig/null-ls/dap source names (e.g. "ruby_lsp").
-- AstroNvim nulls out the `ensure_installed` of mason-lspconfig / mason-null-ls /
-- mason-nvim-dap whenever mason-tool-installer is present (it is — community packs
-- like go/svelte pull it in), so mason-tool-installer is the ONLY list that
-- actually installs anything. Server enabling still happens via mason-lspconfig's
-- auto-enable of installed packages.
---@type LazySpec
return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  opts = function(_, opts)
    opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
      -- LSP servers
      "lua-language-server",
      "astro-language-server",
      "bash-language-server",
      "eslint-lsp",
      "gopls",
      "ruby-lsp",
      "rust-analyzer",
      "sorbet",
      "svelte-language-server",
      -- "tailwindcss-language-server",
      "tsgo",
      "yaml-language-server",
      "zls",
      -- formatters / linters
      "stylua",
      -- debuggers
      "debugpy",
    })
  end,
}
