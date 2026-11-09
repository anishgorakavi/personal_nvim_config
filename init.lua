-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

vim.api.nvim_create_user_command("Central", function()
  vim.cmd.enew()
  vim.fn.termopen({ "central" })
  vim.cmd.startinsert()
end, { desc = "Open Central in a terminal buffer" })
