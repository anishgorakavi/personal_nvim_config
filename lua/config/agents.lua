-- :Codex [prompt] starts OpenAI Codex CLI in a split on the right.
-- :AGY [prompt] starts Antigravity (agy) in a split on the right.
-- Any text after the command is passed to the CLI as the first message.
local M = {}

local function launch(binary, prompt)
  local cmd = { binary }
  if prompt ~= "" then
    table.insert(cmd, vim.fn.shellescape(prompt))
  end
  Snacks.terminal.toggle(table.concat(cmd, " "), { win = { position = "right", width = 0.4 } })
end

function M.setup()
  vim.api.nvim_create_user_command("Codex", function(opts)
    launch("codex", opts.args)
  end, { nargs = "*", desc = "Start Codex CLI, optionally with a prompt" })

  vim.api.nvim_create_user_command("AGY", function(opts)
    launch("agy", opts.args)
  end, { nargs = "*", desc = "Start Antigravity (agy), optionally with a prompt" })
end

return M
