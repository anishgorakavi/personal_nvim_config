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
-- :Codex and :AGY, see lua/config/agents.lua
require("config.agents").setup()
-- Mouse hover docs for Rust, Python and Java, see lua/config/hover.lua
require("config.hover").setup()
-- :SwitchJavaLSP picks FerrisJDT or JDTLS, see lua/config/java_lsp.lua
require("config.java_lsp").setup()
-- :AutoCommit and :AutoCommitSettings, see lua/config/autocommit.lua
require("config.autocommit").setup()
-- :HotReload, see lua/config/reload.lua
require("config.reload").setup()
-- :CS314ON and :CS314OFF, see lua/config/cs314.lua
require("config.cs314").setup()
-- Agent control socket for `nvim --server`, see lua/config/agent_rpc.lua
require("config.agent_rpc").setup()
-- :AutoSave toggles automatic saving, see lua/config/autosave.lua
require("config.autosave").setup()

require("config.javadeps").setup()

-- Expo commands and keys, see lua/config/expo.lua
require("config.expo").setup()
local expo = require("config.expo")
vim.keymap.set("n", "<leader>ex", expo.start, { desc = "Expo start" })
vim.keymap.set("n", "<leader>edi", expo.ios, { desc = "Expo iOS device" })
vim.keymap.set("n", "<leader>eda", expo.android, { desc = "Expo Android device" })
vim.keymap.set("n", "<leader>ea", expo.android_emulator, { desc = "Expo Android emulator" })

-- F2 renames the symbol under the cursor through the language server (FerrisJDT for Java).
-- The prompt starts with the current name, so you only type the new one.
vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, { desc = "Rename symbol" })

-- Move between words, in normal and insert mode. Terminals send Option+arrow
-- either as <M-Left> or as Esc followed by b/f, so both forms are mapped.
-- <C-o> runs one normal-mode command from insert mode and returns.
vim.keymap.set("n", "<M-Left>", "<C-Left>")
vim.keymap.set("n", "<M-Right>", "<C-Right>")
vim.keymap.set("i", "<M-Left>", "<C-o>b")
vim.keymap.set("i", "<M-Right>", "<C-o>e")
vim.keymap.set("i", "<M-b>", "<C-o>b")
vim.keymap.set("i", "<M-f>", "<C-o>e")

-- Delete previous word in insert mode
vim.keymap.set("i", "<M-BS>", "<C-w>")
