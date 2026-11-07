-- Hovering the mouse over a symbol shows its documentation from the language
-- server, for Rust, Python and Java. The popup closes when the mouse moves.
-- The cursor doesn't move, so this doesn't disturb editing.
local M = {}

local filetypes = { rust = true, python = true, java = true }
local delay_ms = 400

local timer = vim.uv.new_timer()
local popup_win = nil

local function close_popup()
  if popup_win and vim.api.nvim_win_is_valid(popup_win) then
    vim.api.nvim_win_close(popup_win, true)
  end
  popup_win = nil
end

-- Ask the language server for hover documentation at a buffer position and
-- show it in a floating window.
function M.hover_at(bufnr, line, col)
  local params = {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position = { line = line, character = col },
  }
  vim.lsp.buf_request(bufnr, "textDocument/hover", params, function(err, result)
    if err or not result or not result.contents then
      return
    end
    local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
    lines = vim.lsp.util.trim_empty_lines(lines)
    if vim.tbl_isempty(lines) then
      return
    end
    close_popup()
    local _, win = vim.lsp.util.open_floating_preview(lines, "markdown", {
      border = "rounded",
      focusable = false,
      max_width = 80,
    })
    popup_win = win
  end)
end

local function on_mouse_move()
  close_popup()
  timer:stop()
  timer:start(delay_ms, 0, vim.schedule_wrap(function()
    local winid = vim.v.mouse_winid
    if winid == 0 or not vim.api.nvim_win_is_valid(winid) then
      return
    end
    local bufnr = vim.api.nvim_win_get_buf(winid)
    if not filetypes[vim.bo[bufnr].filetype] then
      return
    end
    if #vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/hover" }) == 0 then
      return
    end
    M.hover_at(bufnr, vim.v.mouse_lnum - 1, vim.v.mouse_col - 1)
  end))
end

function M.setup()
  vim.o.mousemoveevent = true
  vim.keymap.set({ "n", "i", "v" }, "<MouseMove>", on_mouse_move, { desc = "Hover docs under mouse" })
end

return M
