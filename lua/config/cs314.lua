-- :CS314ON turns on Checkstyle checks for Java buffers, using eclipse_config/cs314-checkstyle.xml,
-- and shows a bar at column 100 in Java windows.
-- :CS314OFF turns them off, hides the bar, and clears the findings. Findings are diagnostics, so <Space>xx lists
-- them and ]d / [d move between them. Needs the checkstyle command: brew install checkstyle
local M = {}

local CONFIG = vim.fn.expand("~/Desktop/cs314/eclipse_config/cs314-checkstyle.xml")
local GROUP = "CS314Hygiene"
local NS = vim.api.nvim_create_namespace("cs314-checkstyle")
-- The CS314 guide caps lines at 100 characters, so the bar marks that column
local BAR_COLUMN = "100"

-- Checkstyle plain output: [ERROR] /path/Foo.java:12:5: message [RuleName]
-- The column is optional, so "Foo.java:12: message" matches too.
local FINDING = "^%[%u+%]%s+.-:(%d+):?(%d*):?%s+(.*)$"

-- Returns true while :CS314ON is active. The autocmd group is the only state, so it
-- survives :HotReload, which reloads this module with its state cleared.
local function is_enabled()
  local ok, found = pcall(vim.api.nvim_get_autocmds, { group = GROUP })
  return ok and #found > 0
end

-- Shows or hides the 100-column bar in one window. Windows showing other files are left alone,
-- so a user's own colorcolumn setting there survives.
local function set_bar(win, visible)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
  if name:match("%.java$") then
    vim.wo[win].colorcolumn = visible and BAR_COLUMN or ""
  end
end

-- Turns Checkstyle output into diagnostic items. Every finding counts as an error,
-- as the CS314 guide treats them.
local function parse(output)
  local items = {}
  for line in output:gmatch("[^\r\n]+") do
    local lnum, col, message = line:match(FINDING)
    if lnum then
      table.insert(items, {
        lnum = tonumber(lnum) - 1,
        col = math.max(tonumber(col) or 1, 1) - 1,
        message = message,
        severity = vim.diagnostic.severity.ERROR,
        source = "checkstyle",
      })
    end
  end
  return items
end

-- Runs Checkstyle on one buffer and replaces that buffer's findings.
local function check(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local path = vim.api.nvim_buf_get_name(buf)
  -- Checkstyle reads the file from disk, so skip unsaved edits rather than show stale lines
  if not path:match("%.java$") or vim.bo[buf].modified then
    return
  end

  vim.system({ "checkstyle", "-c", CONFIG, path }, { text = true }, function(result)
    vim.schedule(function()
      -- The run can finish after :CS314OFF or after the buffer closed
      if not is_enabled() or not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      local items = parse(result.stdout or "")
      vim.diagnostic.set(NS, buf, items)
      if #items == 0 and result.code ~= 0 then
        -- No findings but a failed exit means Checkstyle itself broke, such as a bad config
        vim.notify("Checkstyle failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
      end
    end)
  end)
end

-- :CS314ON. Checks every loaded Java buffer now, then again on open and on save.
function M.on()
  if vim.fn.executable("checkstyle") == 0 then
    vim.notify("checkstyle not found. Install it with: brew install checkstyle", vim.log.levels.ERROR)
    return
  end
  if vim.fn.filereadable(CONFIG) == 0 then
    vim.notify("Checkstyle config not found: " .. CONFIG, vim.log.levels.ERROR)
    return
  end

  local group = vim.api.nvim_create_augroup(GROUP, { clear = true })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = group,
    pattern = "*.java",
    callback = function(args)
      check(args.buf)
    end,
  })
  -- Window options are per window, so the bar is set each time a Java file appears in one
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    pattern = "*.java",
    callback = function()
      set_bar(vim.api.nvim_get_current_win(), true)
    end,
  })

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    set_bar(win, true)
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      check(buf)
    end
  end
  vim.notify("CS314 hygiene checks on", vim.log.levels.INFO)
end

-- :CS314OFF. Removes the autocmds, hides the bar, and clears every finding.
function M.off()
  pcall(vim.api.nvim_del_augroup_by_name, GROUP)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    set_bar(win, false)
  end
  vim.diagnostic.reset(NS)
  vim.notify("CS314 hygiene checks off", vim.log.levels.INFO)
end

function M.setup()
  vim.api.nvim_create_user_command("CS314ON", M.on, {
    desc = "Turn on CS314 Checkstyle hygiene checks for Java",
  })
  vim.api.nvim_create_user_command("CS314OFF", M.off, {
    desc = "Turn off CS314 Checkstyle hygiene checks and clear findings",
  })
end

return M
