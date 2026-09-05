return {
  "nvim-lualine/lualine.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "bwpge/lualine-pretty-path",
  },
  opts = {
    options = {
      component_separators = "",
      always_divide_middle = true,
      globalstatus = vim.o.laststatus == 3,
      disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter", "snacks_dashboard" } },
    },
    sections = {
      lualine_a = {
        { "mode" },
      },
      lualine_b = {
        { "branch" },
        { "diff", symbols = { added = " ", modified = " ", removed = " " } },
        { "diagnostics", symbols = { error = " ", warn = " ", info = " ", hint = "" } },
      },
      lualine_c = {
        {
          "pretty_path",
          directories = {
            max_depth = 4,
          },
          highlights = {
            newfile = "LazyProgressDone",
          },
          separator = "",
        },
        { "navic", color_correction = "dynamic" },
      },
      lualine_x = {
        -- stylua: ignore
        {
          function() return require("noice").api.status.command.get() end,
          cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
          color = function() return { fg = Snacks.util.color("Statement") } end,
        },
        -- stylua: ignore
        {
          function() return require("noice").api.status.mode.get() end,
          cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
          color = function() return { fg = Snacks.util.color("Constant") } end,
        },
        -- stylua: ignore
        {
          function() return "  " .. require("dap").status() end,
          cond = function() return package.loaded["dap"] and require("dap").status() ~= "" end,
          color = function() return { fg = Snacks.util.color("Debug") } end,
        },
        -- stylua: ignore
        {
          require("lazy.status").updates,
          cond = require("lazy.status").has_updates,
          color = function() return { fg = Snacks.util.color("Special") } end,
        },
      },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
    extensions = { "nvim-dap-ui", "trouble" },
  },
}
