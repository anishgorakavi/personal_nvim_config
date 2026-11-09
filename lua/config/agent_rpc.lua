-- Listens on a fixed Unix socket so agents can control this Neovim with `nvim --server`.
-- Example: nvim --server ~/.local/state/nvim/agent.sock --remote-send ':CS314ON<CR>'
-- Anyone who can connect runs commands as you, so the state directory stays private (0700).
local M = {}

local SOCKET_DIR = vim.fn.stdpath("state")
local SOCKET = SOCKET_DIR .. "/agent.sock"

-- Returns true when this Neovim already serves the socket, for example after :HotReload.
local function listening()
  return vim.tbl_contains(vim.fn.serverlist(), SOCKET)
end

-- Returns true when another live Neovim answers on the socket.
-- A socket file left behind by a crash does not answer.
local function socket_alive()
  local ok, chan = pcall(vim.fn.sockconnect, "pipe", SOCKET, { rpc = true })
  if ok and chan > 0 then
    vim.fn.chanclose(chan)
    return true
  end
  return false
end

-- Starts the agent socket. Skips quietly if this instance already runs it,
-- and warns instead of taking over a socket that another Neovim still uses.
function M.setup()
  if listening() then
    return
  end

  vim.fn.mkdir(SOCKET_DIR, "p", 448)
  if vim.uv.fs_stat(SOCKET) then
    if socket_alive() then
      vim.notify("Agent socket is used by another Neovim: " .. SOCKET, vim.log.levels.WARN)
      return
    end
    -- serverstart refuses a path that exists, so clear the stale file first
    vim.uv.fs_unlink(SOCKET)
  end

  local ok, err = pcall(vim.fn.serverstart, SOCKET)
  if not ok then
    vim.notify("Could not start agent socket: " .. err, vim.log.levels.ERROR)
  end
end

return M
