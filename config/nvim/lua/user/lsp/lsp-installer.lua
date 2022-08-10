local status_ok, mason = pcall(require, "mason")
if not status_ok then
	return
end

local servers = {
	"bashls",
	"eslint",
	"gopls",
	"jsonls",
	"rust_analyzer",
	"solargraph",
	"sorbet",
	"sumneko_lua",
	"taplo",
	"terraformls",
	"tsserver",
	"yamlls",
}

mason.setup()

local lspconfig_status_ok, lspconfig = pcall(require, "lspconfig")
if not lspconfig_status_ok then
	return
end

local opts = {}

for _, server in pairs(servers) do
	opts = {
		on_attach = require("user.lsp.handlers").on_attach,
		capabilities = require("user.lsp.handlers").capabilities,
	}

	if server == "jsonls" then
		local jsonls_opts = require("user.lsp.settings.jsonls")
		opts = vim.tbl_deep_extend("force", jsonls_opts, opts)
	end

	if server == "sumneko_lua" then
		local sumneko_opts = require("user.lsp.settings.sumneko_lua")
		opts = vim.tbl_deep_extend("force", sumneko_opts, opts)
	end

	if server == "sorbet" then
		local sorbet_opts = require("user.lsp.settings.sorbet")
		opts = vim.tbl_deep_extend("force", sorbet_opts, opts)
	end

	if server == "solargraph" then
		local solargraph_opts = require("user.lsp.settings.solargraph")
		opts = vim.tbl_deep_extend("force", solargraph_opts, opts)
	end

	if server == "rust_analyzer" then
		require("rust-tools").setup({
			tools = {
				on_initialized = function()
					vim.cmd([[
            autocmd BufEnter,CursorHold,InsertLeave,BufWritePost *.rs silent! lua vim.lsp.codelens.refresh()
          ]])
				end,
			},
			server = {
				on_attach = require("user.lsp.handlers").on_attach,
				capabilities = require("user.lsp.handlers").capabilities,
				settings = {
					["rust-analyzer"] = {
						lens = {
							enable = true,
						},
						checkOnSave = {
							command = "clippy",
						},
					},
				},
			},
		})

		goto continue
	end

	lspconfig[server].setup(opts)
	::continue::
end
