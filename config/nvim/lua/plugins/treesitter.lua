return {
	"nvim-treesitter/nvim-treesitter",
	build = false,
	init = function()
		vim.opt.runtimepath:prepend(vim.fn.stdpath("data") .. "/site/pack/hm/start/nvim-treesitter-grammars")
	end,
	opts_extend = {},
	opts = {
		ensure_installed = {},
		auto_install = false,
	},
}
