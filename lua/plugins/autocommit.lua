-- Shows a spinner in the statusline while AutoCommit is running. Hidden otherwise.
return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, 1, {
        function()
          return require("config.autocommit").status()
        end,
        cond = function()
          return require("config.autocommit").is_busy()
        end,
        color = { fg = "#e0af68" },
      })
    end,
  },
}
