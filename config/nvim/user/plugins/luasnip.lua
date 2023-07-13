-- customize luasnip
return {
  {
    "L3MON4D3/LuaSnip",
    config = function(plugin, opts)
      require "plugins.configs.luasnip"(plugin, opts) -- include the default astronvim config that calls the setup call
      -- add more custom luasnip configuration such as filetype extend or custom snippets
      local ls = require "luasnip"
      ls.filetype_extend("javascript", { "javascriptreact", "typescript", "typescriptreact" })

      -- <c-k> to expand a snippet or go to the next jump spot
      vim.keymap.set({ "i", "s" }, "<c-k>", function()
        if ls.expand_or_jump() then ls.expand_or_jump() end
      end, { silent = true })

      -- <c-j> go to previous jump spot
      vim.keymap.set({ "i", "s" }, "<c-j>", function()
        if ls.jumpable(-1) then ls.jump(-1) end
      end, { silent = true })

      -- <c-l> is selecting within a list of options.
      vim.keymap.set("i", "<c-l>", function()
        if ls.choice_active() then ls.change_choice(1) end
      end)

      -- shortcut to source luasnip file again
      vim.keymap.set("n", "<leader><leader>s", "<cmd>source ~/.config/nvim/lua/user/plugins/luasnip.lua<CR>")

      require("luasnip.loaders.from_vscode").lazy_load {
        paths = { "~/.config/nvim/lua/user/snippets" },
      }
    end,
  },
}
