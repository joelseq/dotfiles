return {
  -- You can also add new plugins here as well:
  -- Add plugins, the lazy syntax
  -- "andweeb/presence.nvim",
  -- {
  --   "ray-x/lsp_signature.nvim",
  --   event = "BufRead",
  --   config = function()
  --     require("lsp_signature").setup()
  --   end,
  -- },
  "jose-elias-alvarez/typescript.nvim",
  "simrat39/rust-tools.nvim",
  {
    "kylechui/nvim-surround",
    config = function() require("nvim-surround").setup {} end,
  },
  "mg979/vim-visual-multi",
  "mattn/emmet-vim",
  {
    "folke/todo-comments.nvim",
    config = function() require("todo-comments").setup {} end,
  },
}
