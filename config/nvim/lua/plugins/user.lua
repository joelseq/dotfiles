return {
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = { style = "moon" },
  },
  {
    "kylechui/nvim-surround",
    event = "InsertEnter",
    config = function()
      require("nvim-surround").setup()
    end,
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
