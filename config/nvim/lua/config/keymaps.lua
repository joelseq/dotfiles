-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set(
  "n",
  "<leader>sx",
  require("telescope.builtin").resume,
  { noremap = true, silent = true, desc = "Resume" }
)

vim.keymap.set("n", "<leader>/", "gcc", { remap = true, desc = "Toggle comment line" })
vim.keymap.set("x", "<leader>/", "gc", { remap = true, desc = "Toggle comment" })
vim.keymap.set("n", "gl", function()
  vim.diagnostic.open_float()
end, { desc = "Hover diagnostics" })

-- Git Blame
vim.keymap.set("n", "<leader>gf", ":GitBlameOpenFileURL<cr>", { desc = "GitBlame Open [F]ile URL" })
