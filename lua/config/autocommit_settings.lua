-- :AutoCommitSettings window, laid out like :Lazy. j/k move, Enter changes the item under the cursor, q closes.
local autocommit = require("config.autocommit")
local M = {}

local items = {
  { section = "General" },
  { key = "enabled", label = "Automatic commits", kind = "bool" },
  { key = "interval", label = "Interval (minutes)", kind = "number" },
  { key = "push", label = "Push after commit", kind = "bool" },
  { key = "include_untracked", label = "Include new files", kind = "bool" },
  { key = "min_lines", label = "Minimum changed lines", kind = "number" },
  { section = "Model" },
  { key = "provider", label = "Provider", kind = "choice", choices = { "ollama", "openai" } },
  { hint = "The diff is sent to the chosen URL. Keep it on localhost to keep code on this machine." },
  { section = "Ollama" },
  { key = "ollama_url", label = "URL", kind = "text" },
  { key = "ollama_model", label = "Model", kind = "text" },
  { section = "OpenAI-compatible" },
  { key = "openai_url", label = "Base URL", kind = "text" },
  { key = "openai_model", label = "Model", kind = "text" },
  { key = "openai_key_env", label = "API key variable", kind = "text" },
}

local buf, win
local line_items = {} -- buffer line number -> item

local function display(item)
  local value = autocommit.settings[item.key]
  if item.kind == "bool" then
    return value and "on" or "off"
  end
  return tostring(value)
end

local function render()
  local lines = { "  AutoCommit", "  Enter change   q close", "" }
  line_items = {}
  for _, item in ipairs(items) do
    if item.section then
      table.insert(lines, "")
      table.insert(lines, "  " .. item.section)
    elseif item.hint then
      table.insert(lines, "    " .. item.hint)
    else
      table.insert(lines, ("    %-24s %s"):format(item.label, display(item)))
      line_items[#lines] = item
    end
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

local function save_and_refresh()
  autocommit.save()
  autocommit.restart_timer()
  render()
end

local function edit_current()
  local item = line_items[vim.api.nvim_win_get_cursor(win)[1]]
  if not item then
    return
  end
  local s = autocommit.settings

  if item.kind == "bool" then
    s[item.key] = not s[item.key]
    return save_and_refresh()
  end

  if item.kind == "choice" then
    local current = 1
    for i, choice in ipairs(item.choices) do
      if choice == s[item.key] then
        current = i
      end
    end
    s[item.key] = item.choices[current % #item.choices + 1]
    return save_and_refresh()
  end

  vim.ui.input({ prompt = item.label .. ": ", default = tostring(s[item.key]) }, function(input)
    if input == nil or input == "" then
      return
    end
    if item.kind == "number" then
      local n = tonumber(input)
      if not n or n <= 0 then
        vim.notify("[AutoCommit] Enter a positive number", vim.log.levels.WARN)
        return
      end
      s[item.key] = n
    else
      s[item.key] = input
    end
    save_and_refresh()
  end)
end

local function close()
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

  local width = 64
  local height = math.min(#items + 6, vim.o.lines - 6)
  win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " AutoCommit ",
    title_pos = "center",
  })
  vim.wo[win].cursorline = true
  vim.wo[win].wrap = false

  render()
  -- Start on the first setting, not on a section header
  local first = math.huge
  for line in pairs(line_items) do
    first = math.min(first, line)
  end
  vim.api.nvim_win_set_cursor(win, { first, 0 })

  local map = function(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true })
  end
  map("q", close)
  map("<Esc>", close)
  map("<CR>", edit_current)
end

return M
