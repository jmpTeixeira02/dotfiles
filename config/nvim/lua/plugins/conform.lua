-- This is just adding more formatters. LazyVim already handles the others via LazyExtras
return {
	"stevearc/conform.nvim",
	opts = {
		formatters_by_ft = {
			kdl = { "kdlfmt" },
		},
		formatters = {
			kdlfmt = {
				command = "kdlfmt",
				args = { "format", "-" },
				stdin = true,
			},
		},
		format_on_save = {
			timeout_ms = 500,
			lsp_format = "fallback",
		},
	},
}
