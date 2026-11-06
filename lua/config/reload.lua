-- :HotReload re-runs the config modules without quitting Neovim.
-- Plugin specs in lua/plugins are read by lazy.nvim only once, so changes there still need a restart.
local M = {}

local KEEP = { ["config.reload"] = true }

function M.reload()
  -- Stop background work from the old modules first, or it keeps running after the reload
  local autocommit = package.loaded["config.autocommit"]
  if autocommit and autocommit.stop then
    autocommit.stop()
  end

  for name in pairs(package.loaded) do
    if name:match("^config%.") and not KEEP[name] then
      package.loaded[name] = nil
    end
  end

  local ok, err = pcall(function()
    require("config.options")
    require("config.autocmds")
    require("config.keymaps")
  end)
  if ok then
    vim.notify("Config reloaded", vim.log.levels.INFO)
  else
    vim.notify("Reload failed: " .. err, vim.log.levels.ERROR)
  end
end

function M.setup()
  vim.api.nvim_create_user_command("HotReload", M.reload, {
    desc = "Reload the Lua config without restarting Neovim",
  })
end

return M
