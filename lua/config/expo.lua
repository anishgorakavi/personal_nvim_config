-- :ExpoStart runs the Expo dev server. :ExpoIOS builds and runs on an iPhone, :ExpoAndroid on an
-- Android device, and :ExpoAndroidEmulator starts the dev server and opens the Android emulator.
-- Each one opens in a small floating window in the bottom right quarter of the screen. Drag its
-- bottom right corner with the mouse to resize it. The _ button in its title bar minimizes it to
-- that bar, and the same button restores it.
local M = {}

local MIN_WIDTH, MIN_HEIGHT = 20, 4

local function winbar(minimized)
  local button = minimized and "□" or "_"
  return "%#Title# Expo %=%0@v:lua.require'config.expo'.toggle_minimize@ " .. button .. " %X"
end

local function launch(args)
  local cwd = vim.fs.root(vim.fn.getcwd(), "package.json") or vim.fn.getcwd()
  local cmd = { "npx", "expo" }
  vim.list_extend(cmd, args)
  Snacks.terminal.toggle(cmd, {
    cwd = cwd,
    win = {
      position = "float",
      row = 0.5,
      col = 0.5,
      width = 0.5,
      height = 0.5,
      border = "rounded",
      backdrop = false,
      enter = true,
      wo = { winbar = winbar(false) },
      w = { expo_float = true },
    },
  })
end

-- Clicking the title bar button flips the window between full size and a one-line bar at the
-- bottom of the editor. With its border the bar is 3 rows tall, so it sits just above the statusline.
function M.toggle_minimize()
  local win = vim.fn.getmousepos().winid
  if not vim.w[win].expo_float then
    return
  end
  local minimized = not vim.w[win].expo_minimized
  local cfg = vim.api.nvim_win_get_config(win)
  if minimized then
    vim.w[win].expo_restore = { height = cfg.height, row = cfg.row }
    local statusline = vim.o.laststatus > 0 and 1 or 0
    local bottom = vim.o.lines - vim.o.cmdheight - statusline
    vim.api.nvim_win_set_config(win, { relative = "editor", row = bottom - 2, col = cfg.col, height = 1 })
  else
    local restore = vim.w[win].expo_restore
    vim.api.nvim_win_set_config(win, { relative = "editor", row = restore.row, col = cfg.col, height = restore.height })
  end
  vim.w[win].expo_minimized = minimized
  vim.wo[win].winbar = winbar(minimized)
end

-- The window whose bottom right corner is under the mouse, if any. The corner is the border cell
-- or the last content cell, so a click one cell off still grabs it.
local function corner_under_mouse(pos)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.w[win].expo_float and not vim.w[win].expo_minimized then
      local cfg = vim.api.nvim_win_get_config(win)
      local right, bottom = cfg.col + cfg.width, cfg.row + cfg.height
      if math.abs(pos.screencol - 1 - right) <= 1 and math.abs(pos.screenrow - 1 - bottom) <= 1 then
        return win
      end
    end
  end
end

local drag_win = nil

local function set_mouse_maps()
  vim.keymap.set({ "n", "t" }, "<LeftMouse>", function()
    drag_win = corner_under_mouse(vim.fn.getmousepos())
    return drag_win and "" or "<LeftMouse>"
  end, { expr = true, desc = "Start resizing an Expo window from its corner" })

  vim.keymap.set({ "n", "t" }, "<LeftDrag>", function()
    if not drag_win then
      return "<LeftDrag>"
    end
    local cfg = vim.api.nvim_win_get_config(drag_win)
    local pos = vim.fn.getmousepos()
    local width = math.max(pos.screencol - 1 - cfg.col, MIN_WIDTH)
    local height = math.max(pos.screenrow - 1 - cfg.row, MIN_HEIGHT)
    vim.api.nvim_win_set_config(drag_win, {
      relative = "editor",
      row = cfg.row,
      col = cfg.col,
      width = width,
      height = height,
    })
    return ""
  end, { expr = true, desc = "Resize the Expo window" })

  vim.keymap.set({ "n", "t" }, "<LeftRelease>", function()
    drag_win = nil
    return "<LeftRelease>"
  end, { expr = true, desc = "Stop resizing an Expo window" })
end

function M.start()
  launch({ "start" })
end

function M.ios()
  launch({ "run:ios", "--device" })
end

function M.android()
  launch({ "run:android", "--device" })
end

function M.android_emulator()
  launch({ "start", "--android" })
end

function M.setup()
  vim.api.nvim_create_user_command("ExpoStart", M.start, { desc = "Start the Expo dev server" })
  vim.api.nvim_create_user_command("ExpoIOS", M.ios, { desc = "Build and run the Expo app on an iOS device" })
  vim.api.nvim_create_user_command("ExpoAndroid", M.android, {
    desc = "Build and run the Expo app on an Android device",
  })
  vim.api.nvim_create_user_command("ExpoAndroidEmulator", M.android_emulator, {
    desc = "Start the Expo dev server and open the Android emulator",
  })
  set_mouse_maps()
end

return M
