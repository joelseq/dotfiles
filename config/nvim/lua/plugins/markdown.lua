vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("markdown_wrap", { clear = true }),
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
  end,
})

return {}
