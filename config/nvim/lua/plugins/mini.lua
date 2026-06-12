---@type LazySpec
return {
  { "nvim-mini/mini.ai", event = "BufEnter", config = function() require("mini.ai").setup() end },
  -- { "nvim-mini/mini.animate", event = "BufEnter", config = function() require("mini.animate").setup() end },
  { "nvim-mini/mini.icons", version = false },
  { "nvim-mini/mini.hipatterns", version = false },
}
