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
    event = "InsertEnter",
    config = function() require("nvim-surround").setup {} end,
  },
  {
    "mg979/vim-visual-multi",
    event = "InsertEnter",
  },
  {
    "mattn/emmet-vim",
    event = "InsertEnter",
  },
  {
    "folke/todo-comments.nvim",
    event = "BufRead",
    config = function() require("todo-comments").setup {} end,
  },
  {
    "vimwiki/vimwiki",
    event = "InsertEnter",
  },
  {
    "Wansmer/treesj",
    keys = {
      {
        "<leader>m",
        "<CMD>TSJToggle<CR>",
        desc = "Toggle Treesitter Join",
      },
    },
    cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
    opts = { use_default_keymaps = false },
  },
  {
    "f-person/git-blame.nvim",
    event = "VeryLazy",
  },
}
