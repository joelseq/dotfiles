-- customize luasnip
return {
  {
    "L3MON4D3/LuaSnip",
    config = function(plugin, opts)
      require "astronvim.plugins.configs.luasnip"(plugin, opts) -- include the default astronvim config that calls the setup call
      -- add more custom luasnip configuration such as filetype extend or custom snippets
      local ls = require "luasnip"
      ls.filetype_extend("javascriptreact", { "javascript" })
      ls.filetype_extend("typescript", { "javascript" })
      ls.filetype_extend("typescriptreact", { "javascriptreact", "javascript", "typescript" })

      -- <c-l> to expand a snippet or go to the next jump spot
      vim.keymap.set({ "i", "s" }, "<c-l>", function()
        if ls.expand_or_jumpable() then ls.expand_or_jump() end
      end, { silent = true })

      -- <c-h> go to previous jump spot
      vim.keymap.set({ "i", "s" }, "<c-h>", function()
        if ls.jumpable(-1) then ls.jump(-1) end
      end, { silent = true })

      -- <c-l> is selecting within a list of options.
      -- vim.keymap.set("i", "<c-l>", function()
      --   if ls.choice_active() then ls.change_choice(1) end
      -- end)

      -- shortcut to source luasnip file again
      vim.keymap.set("n", "<leader><leader>s", "<cmd>source ~/.config/nvim/lua/user/plugins/luasnip.lua<CR>")

      require("luasnip.loaders.from_vscode").lazy_load {
        paths = { "~/.config/nvim/lua/snippets" },
      }
    end,
  },
}
