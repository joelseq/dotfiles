---@type LazySpec
return {
  { "echasnovski/mini.ai", event = "BufEnter", config = function() require("mini.ai").setup() end },
  { "echasnovski/mini.animate", event = "BufEnter", config = function() require("mini.animate").setup() end },
}
