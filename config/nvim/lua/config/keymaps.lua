-- VIM Default ---
--
vim.g.mapleader = " "
vim.g.last_buffer = 0

local wk = require("which-key")
wk.add({
	{ "<leader><CR>", vim.cmd.so, desc = "Reload Vim Config" },
})

vim.keymap.set({ "n", "v" }, "<leader>y", '"+y')
vim.keymap.set("n", "<leader>Y", '"+Y')

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("i", "<C-c>", "<Esc>")
