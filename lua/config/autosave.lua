-- :AutoSave toggles automatic saving; :AutoSaveSettings changes what triggers it. Named files are
-- written when you leave insert mode, after a pause in normal-mode edits, when Neovim loses
-- focus, and, if an interval is set, every N seconds. Settings live in vim.g, so :HotReload keeps them, and are saved to
-- stdpath("data")/autosave.json so they survive a restart. setup() rebuilds its autocommands
-- without duplicating them.
local M = {}

local GROUP = "AutoSave"
local FILE = vim.fn.stdpath("data") .. "/autosave.json"

local defaults = {
  enabled = true,
  on_insert_leave = true,
  on_text_changed = true,
  on_focus_lost = true,
  delay_ms = 0,
  interval_sec = 0,
  exclude_filetypes = "gitcommit",
}

local timer = vim.uv.new_timer()
local interval_timer = vim.uv.new_timer()

-- Reads saved settings over the defaults. A missing or unreadable file leaves the defaults.
local function load_settings()
  local settings = vim.deepcopy(defaults)
  local ok, lines = pcall(vim.fn.readfile, FILE)
  if ok then
    local decoded_ok, saved = pcall(vim.json.decode, table.concat(lines, "\n"))
    if decoded_ok and type(saved) == "table" then
      for key in pairs(defaults) do
        if type(saved[key]) == type(defaults[key]) then
          settings[key] = saved[key]
        end
      end
    end
  end
  return settings
end

local function persist()
  pcall(vim.fn.writefile, { vim.json.encode(vim.g.autosave_settings) }, FILE)
end

-- True when the buffer's filetype is in the comma-separated exclude list.
local function excluded(buf)
  for name in vim.gsplit(vim.g.autosave_settings.exclude_filetypes, ",", { trimempty = true }) do
    if vim.trim(name) == vim.bo[buf].filetype then
      return true
    end
  end
  return false
end

-- Writes the current buffer if it is a named, editable file with unsaved changes.
-- Other buffers, such as terminals and help pages, are never written.
local function save(buf)
  buf = type(buf) == "number" and buf or vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_get_name(buf) == "" or vim.bo[buf].buftype ~= "" or excluded(buf) then
    return
  end
  vim.api.nvim_buf_call(buf, function()
    vim.cmd("silent! update")
  end)
end

-- Writes every modified buffer; the periodic timer uses this so background buffers are saved too.
local function save_all()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
      save(buf)
    end
  end
end

-- Saves now, or after delay_ms of no further edits when a delay is set.
local function save_after_delay()
  local delay = vim.g.autosave_settings.delay_ms
  if delay <= 0 then
    save()
    return
  end
  timer:stop()
  timer:start(delay, 0, vim.schedule_wrap(save))
end

-- Rebuilds the autosave autocommands to match vim.g.autosave_settings.
local function apply()
  local group = vim.api.nvim_create_augroup(GROUP, { clear = true })
  local settings = vim.g.autosave_settings
  interval_timer:stop()
  if not settings.enabled then
    return
  end
  if settings.interval_sec > 0 then
    local ms = settings.interval_sec * 1000
    interval_timer:start(ms, ms, vim.schedule_wrap(save_all))
  end
  local function on(event, callback)
    vim.api.nvim_create_autocmd(event, {
      group = group,
      callback = callback,
      desc = "Save the buffer automatically",
    })
  end
  if settings.on_insert_leave then
    on("InsertLeave", save)
  end
  if settings.on_text_changed then
    on("TextChanged", save_after_delay)
  end
  if settings.on_focus_lost then
    on("FocusLost", save)
  end
end

local function update(key, value)
  local settings = vim.deepcopy(vim.g.autosave_settings)
  settings[key] = value
  vim.g.autosave_settings = settings
  persist()
  apply()
end

-- :AutoSave. Flips the master switch and reports the new state.
function M.toggle()
  update("enabled", not vim.g.autosave_settings.enabled)
  vim.notify("AutoSave " .. (vim.g.autosave_settings.enabled and "on" or "off"), vim.log.levels.INFO)
end

local items = {
  { key = "enabled", label = "Autosave" },
  { key = "on_insert_leave", label = "Save when leaving insert mode" },
  { key = "on_text_changed", label = "Save after normal-mode edits" },
  { key = "on_focus_lost", label = "Save when Neovim loses focus" },
  { key = "interval_sec", label = "Save every N seconds (0 = off)", number = true },
  { key = "delay_ms", label = "Delay after edits (ms, 0 = none)", number = true },
  { key = "exclude_filetypes", label = "Never save filetypes (comma-separated)", text = true },
}

-- :AutoSaveSettings. Lists each setting with its value; choosing one flips or edits it, then reopens.
function M.settings()
  local settings = vim.g.autosave_settings
  vim.ui.select(items, {
    prompt = "AutoSave settings",
    format_item = function(item)
      local value = settings[item.key]
      if type(value) == "boolean" then
        value = value and "on" or "off"
      end
      return ("%-40s %s"):format(item.label, value)
    end,
  }, function(item)
    if not item then
      return
    end
    local value = settings[item.key]
    if type(value) == "boolean" then
      update(item.key, not value)
      return M.settings()
    end
    vim.ui.input({ prompt = item.label .. ": ", default = tostring(value) }, function(input)
      if input == nil then
        return
      end
      if item.number then
        local number = tonumber(input)
        if not number or number < 0 then
          vim.notify("Enter a number, 0 or more", vim.log.levels.WARN)
          return M.settings()
        end
        update(item.key, math.floor(number))
      else
        update(item.key, input)
      end
      M.settings()
    end)
  end)
end

-- Loads saved settings the first time, then applies whatever is already in place.
function M.setup()
  if vim.g.autosave_settings == nil then
    vim.g.autosave_settings = load_settings()
  end
  apply()
  vim.api.nvim_create_user_command("AutoSave", M.toggle, {
    desc = "Toggle automatic saving of files",
  })
  vim.api.nvim_create_user_command("AutoSaveSettings", M.settings, {
    desc = "Choose when files are saved automatically",
  })
end

return M
