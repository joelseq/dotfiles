vim.api.nvim_create_autocmd("FileType", {
  desc = "Ensures tabs are used on Makefiles instead of spaces",
  callback = function(event)
    if event.match == "make" then vim.o.expandtab = false end
  end,
})
