return {
	root_dir = function()
		local cwd = vim.fn.getcwd()

		if string.find(cwd, "figma/figma") then
			return vim.fn.getcwd() .. "/sinatra"
		else
			return cwd
		end
	end,
}
