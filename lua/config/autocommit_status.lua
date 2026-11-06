-- :AutoCommitStatus window. Shows the current phase, the model's output as it streams,
-- and what Ollama has loaded. Refreshes while it is open. q or Esc closes it.
local autocommit = require("config.autocommit")
local M = {}

local buf, win, refresh_timer
local ticks = 0
local ollama_info = "checking..."

local function format_duration(ms)
  local seconds = math.floor(ms / 1000)
  return ("%dm %02ds"):format(math.floor(seconds / 60), seconds % 60)
end

local function human_size(bytes)
  if not bytes then
    return "?"
  end
  return ("%.1f GB"):format(bytes / 1e9)
end

-- Asks Ollama which model is in memory right now. Runs in the background.
local function fetch_ollama()
  if autocommit.settings.provider ~= "ollama" then
    ollama_info = "not used (provider is " .. autocommit.settings.provider .. ")"
    return
  end
  vim.system({ "curl", "-sS", "-m", "3", autocommit.settings.ollama_url .. "/api/ps" }, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        ollama_info = "not reachable at " .. autocommit.settings.ollama_url
        return
      end
      local ok, decoded = pcall(vim.json.decode, res.stdout)
      if not ok or type(decoded) ~= "table" or not decoded.models then
        ollama_info = "unexpected response from /api/ps"
        return
      end
      if #decoded.models == 0 then
        ollama_info = "no model loaded (Ollama loads it on the next request)"
        return
      end
      local m = decoded.models[1]
      ollama_info = ("%s  %s in memory"):format(m.name or m.model or "?", human_size(m.size_vram or m.size))
    end)
  end)
end

local function render()
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end
  local s, st = autocommit.settings, autocommit.state
  local model = s.provider == "ollama" and s.ollama_model or s.openai_model
  local url = s.provider == "ollama" and s.ollama_url or s.openai_url

  local now = "    " .. ("%-12s %s"):format("Phase", st.phase)
  if autocommit.is_busy() and st.started then
    now = now .. "  (" .. format_duration(vim.uv.now() - st.started) .. ")"
  end

  local next_run = "disabled"
  local due = autocommit.next_run_in()
  if due then
    next_run = "in " .. format_duration(due)
  end

  local last = "none yet this session"
  if st.last then
    last = st.last.at .. "  " .. st.last.msg
  end

  local lines = {
    "  AutoCommit status",
    "  r refresh   q close",
    "",
    "  Now",
    now,
    "",
    "  Schedule",
    ("    %-12s %s"):format("Next run", next_run),
    ("    %-12s %s"):format("Last run", last),
    "",
    "  Model",
    ("    %-12s %s"):format("Provider", s.provider),
    ("    %-12s %s"):format("Model", model),
    ("    %-12s %s"):format("URL", url),
  }
  if s.provider == "ollama" then
    table.insert(lines, ("    %-12s %s"):format("Loaded", ollama_info))
  end

  table.insert(lines, "")
  table.insert(lines, "  Live output")
  local live = st.live ~= "" and st.live or "(nothing yet)"
  for line in (live .. "\n"):gmatch("(.-)\n") do
    table.insert(lines, "    " .. line)
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

local function stop_refresh()
  if refresh_timer then
    refresh_timer:stop()
    refresh_timer:close()
    refresh_timer = nil
  end
end

local function close()
  stop_refresh()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  win, buf = nil, nil
end

function M.open()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
    return
  end

  buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "autocommit"
  -- Stop the refresh timer when the window goes away, however that happens
  vim.api.nvim_create_autocmd("BufWipeout", { buffer = buf, once = true, callback = stop_refresh })

  local width = math.min(80, vim.o.columns - 8)
  local height = math.min(32, vim.o.lines - 6)
  win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " AutoCommit status ",
    title_pos = "center",
  })
  vim.wo[win].wrap = true

  local map = function(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true })
  end
  map("q", close)
  map("<Esc>", close)
  map("r", function()
    fetch_ollama()
    render()
  end)

  fetch_ollama()
  render()

  refresh_timer = vim.uv.new_timer()
  refresh_timer:start(500, 500, vim.schedule_wrap(function()
    ticks = ticks + 1
    if ticks % 6 == 0 then
      fetch_ollama()
    end
    render()
  end))
end

return M
