return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    terminal_cmd = vim.fn.exepath("claude"),
  },
  config = true,
}
