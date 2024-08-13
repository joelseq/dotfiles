-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.colorscheme.catppuccin" },
  { import = "astrocommunity.colorscheme.tokyonight-nvim" },
  { import = "astrocommunity.completion.copilot-lua" },
  { import = "astrocommunity.pack.go" },
  -- { import = "astrocommunity.pack.typescript" },
  { import = "astrocommunity.pack.gleam" },
  -- { import = "astrocommunity.pack.ruby" },
  { import = "astrocommunity.pack.tailwindcss" },
  { import = "astrocommunity.pack.rainbow-delimiter-indent-blankline" },
  { import = "astrocommunity.test.neotest" },
  -- { import = "astrocommunity.utility.noice-nvim" },
  { import = "astrocommunity.editing-support.nvim-devdocs" },
  { import = "astrocommunity.editing-support.conform-nvim" },
  { import = "astrocommunity.editing-support.refactoring-nvim" },
  -- { import = "astrocommunity.bars-and-lines.bufferline-nvim" },
  { import = "astrocommunity.git.gitlinker-nvim" },
  { import = "astrocommunity.file-explorer.oil-nvim" },
  { import = "astrocommunity.pack.full-dadbod" },
  { import = "astrocommunity.search.grug-far-nvim" },
  { import = "astrocommunity.lsp.inc-rename-nvim" },
  { import = "astrocommunity.diagnostics.trouble-nvim" },
  -- import/override with your plugins folder
}
