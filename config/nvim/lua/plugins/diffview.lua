---@type LazySpec
return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      {
        "<leader>gv",
        function()
          if next(require("diffview.lib").views) == nil then
            vim.cmd "DiffviewOpen"
          else
            vim.cmd "DiffviewClose"
          end
        end,
        desc = "Toggle Diffview",
      },
    },
  },
}
