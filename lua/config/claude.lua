-- :Claude [prompt] starts Claude Code in a split on the right.
-- :RecentClaude [prompt] resumes the most recent conversation in this directory.
-- Any text after the command is sent to Claude as the first message.
local M = {}

local function launch(continue, prompt)
  local cmd = { "claude" }
  if continue then
    table.insert(cmd, "--continue")
  end
  if prompt ~= "" then
    table.insert(cmd, vim.fn.shellescape(prompt))
  end
  Snacks.terminal.toggle(table.concat(cmd, " "), { win = { position = "right", width = 0.4 } })
end

function M.setup()
  vim.api.nvim_create_user_command("Claude", function(opts)
    launch(false, opts.args)
  end, { nargs = "*", desc = "Start Claude Code, optionally with a prompt" })

  vim.api.nvim_create_user_command("RecentClaude", function(opts)
    launch(true, opts.args)
  end, { nargs = "*", desc = "Resume the recent Claude Code conversation here" })
end

return M
