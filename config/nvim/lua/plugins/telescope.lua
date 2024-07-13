return {
  "nvim-telescope/telescope.nvim",
  -- change some telescope options and a keymap to browse plugin files
  keys = {
    -- add a keymap to browse plugin files
    -- stylua: ignore
    {
      "<C-J>",
      require("telescope.actions").move_selection_next,
      desc = "Move selection down",
    },
    {
      "<C-K>",
      require("telescope.actions").move_selection_previous,
      desc = "Move selection up",
    },
  },
}
