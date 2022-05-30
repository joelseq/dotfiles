local null_ls_status_ok, null_ls = pcall(require, "null-ls")
if not null_ls_status_ok then
	return
end

local code_actions = null_ls.builtins.code_actions
-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
local formatting = null_ls.builtins.formatting
-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
local diagnostics = null_ls.builtins.diagnostics

null_ls.setup({
	debug = true,
	sources = {
		code_actions.eslint_d.with({
			env = {
				ESLINT_D_LOCAL_ESLINT_ONLY = 1,
			},
		}),
		diagnostics.eslint_d.with({
			env = {
				ESLINT_D_LOCAL_ESLINT_ONLY = 1,
			},
		}),
		formatting.eslint_d.with({
			env = {
				ESLINT_D_LOCAL_ESLINT_ONLY = 1,
			},
		}),
		formatting.prettierd.with({
			env = {
				PRETTIERD_LOCAL_PRETTIER_ONLY = 1,
			},
		}),
		formatting.black.with({ extra_args = { "--fast" } }),
		formatting.stylua,
		code_actions.gitsigns,
	},
	on_attach = function(client)
		if client.resolved_capabilities.document_formatting then
			vim.cmd([[
      augroup LspFormatting
          autocmd! * <buffer>
          autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()
      augroup END
      ]])
		end
	end,
})
