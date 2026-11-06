-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Run the current Python or Java file (F5 works too, like most IDEs)
vim.keymap.set("n", "<leader>rr", function()
  require("config.run").run_file()
end, { desc = "Run current file" })
vim.keymap.set("n", "<F5>", function()
  require("config.run").run_file()
end, { desc = "Run current file" })

-- :Claude and :RecentClaude commands, see lua/config/claude.lua
require("config.claude").setup()
-- :AutoCommit and :AutoCommitSettings, see lua/config/autocommit.lua
require("config.autocommit").setup()
-- :HotReload, see lua/config/reload.lua
require("config.reload").setup()
