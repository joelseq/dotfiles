return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "marilari88/neotest-vitest",
      "rouge8/neotest-rust",
    },
    opts = function(_, opts)
      if not opts.adapters then opts.adapters = {} end
      table.insert(opts.adapters, require "neotest-vitest"(require("astrocore").plugin_opts "neotest-vitest"))
      table.insert(opts.adapters, require "neotest-rust"(require("astrocore").plugin_opts "neotest-rust"))
    end,
  },
}
