-- Mapping data with "desc" stored directly by vim.keymap.set().
--
-- Please use this mappings table to set keyboard mapping since this is the
-- lower level configuration and more robust one. (which-key will
-- automatically pick-up stored data by this setting.)
return {
  -- first key is the mode
  n = {
    -- second key is the lefthand side of the map
    -- mappings seen under group name "Buffer"
    ["<leader>bn"] = { "<cmd>tabnew<cr>", desc = "New tab" },
    ["<leader>bD"] = {
      function()
        require("astronvim.utils.status").heirline.buffer_picker(
          function(bufnr) require("astronvim.utils.buffer").close(bufnr) end
        )
      end,
      desc = "Pick to close",
    },
    -- tables with the `name` key will be registered with which-key if it's installed
    -- this is useful for naming menus
    ["<leader>b"] = { name = "Buffers" },
    -- quick save
    -- ["<C-s>"] = { ":w!<cr>", desc = "Save File" },  -- change description but the same command

    -- Save without formatting
    ["<leader>n"] = { ":noa w<cr>", desc = "Save File without formatting" },

    -- Yank file paths
    ["<leader>y"] = { name = "Yank File Path" },
    ["<leader>ya"] = { ":let @+ = expand('%:p')<cr>", desc = "[Y]ank [A]bsolute file path in current buffer" },
    ["<leader>yr"] = { ":let @+ = expand('%')<cr>", desc = "[Y]ank [R]elative file path in current buffer" },

    -- Git Blame
    ["<leader>gf"] = { ":GitBlameOpenFileURL<cr>", desc = "GitBlame Open [F]ile URL" },

    -- Snippets
    ["<leader>s"] = { name = "Snippets" },
    ["<leader>ss"] = {
      "<cmd>source ~/.config/nvim/lua/user/plugins/luasnip.lua<cr>",
      desc = "Source luasnip file",
    },
  },
  t = {
    -- setting a mapping to false will disable it
    -- ["<esc>"] = false,
  },
}
