-- :SwitchJavaLSP chooses the Java language server, FerrisJDT or JDTLS.
--
-- The choice is saved in the state directory. lazy.nvim reads the plugin specs
-- only once, so the new server takes effect on the next start of Neovim.
-- ferrisjdt.lua and the LazyVim java extra both read current() at startup.

local M = {}

local options = {
  { key = "ferrisjdt", label = "FerrisJDT" },
  { key = "jdtls", label = "JDTLS" },
}

local path = vim.fn.stdpath("state") .. "/java_lsp"

function M.current()
  local ok, lines = pcall(vim.fn.readfile, path)
  if ok and lines[1] == "jdtls" then
    return "jdtls"
  end
  return "ferrisjdt"
end

function M.setup()
  vim.api.nvim_create_user_command("SwitchJavaLSP", function()
    local current = M.current()
    vim.ui.select(options, {
      prompt = "Java language server (applies after restart):",
      format_item = function(option)
        return option.label .. (option.key == current and " (current)" or "")
      end,
    }, function(choice)
      if not choice or choice.key == current then
        return
      end
      vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
      vim.fn.writefile({ choice.key }, path)
      vim.notify(choice.label .. " is set for Java. Restart Neovim to apply it.", vim.log.levels.INFO, {
        title = "Java LSP",
      })
    end)
  end, { desc = "Switch the Java language server between FerrisJDT and JDTLS" })
end

return M
