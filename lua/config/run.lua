-- Run the current file in a small terminal split at the bottom of the screen.
-- Add a language by giving its filetype a function that returns the command as a list.
local M = {}

-- Read the `package x.y;` line so the class can be launched by its full name
local function package_of(file)
  for line in io.lines(file) do
    local pkg = line:match("^%s*package%s+([%w_%.]+)%s*;")
    if pkg then
      return pkg
    end
  end
end

local runners = {
  python = function(file)
    return { "python3", "-u", file }
  end,
  -- Compile every sibling .java file first, so classes that reference each other resolve.
  -- Maven/Gradle layouts (src/main/java) compile the whole source root so packages work too.
  java = function(file)
    local name = vim.fn.fnamemodify(file, ":t:r")
    local pkg = package_of(file)
    local main_class = pkg and (pkg .. "." .. name) or name
    local source_root = file:match("^(.*/src/[^/]+/java)/")
    local find = source_root and "find . -name '*.java'" or "find . -maxdepth 1 -name '*.java'"
    local out = vim.fn.tempname()
    local script = table.concat({
      "cd " .. vim.fn.shellescape(source_root or vim.fs.dirname(file)),
      "mkdir -p " .. out,
      find .. " -print0 | xargs -0 javac -d " .. out,
      "java -cp " .. out .. " " .. main_class,
    }, " && ")
    return { "sh", "-c", script }
  end,
  rust = function(file)
    -- Inside a Cargo project, let cargo find the crate and binary
    if vim.fs.root(file, "Cargo.toml") then
      return { "cargo", "run" }
    end
    local out = vim.fn.tempname()
    return { "sh", "-c", "rustc -o " .. out .. " " .. vim.fn.shellescape(file) .. " && " .. out }
  end,
}

local output_win = nil

function M.run_file()
  local runner = runners[vim.bo.filetype]
  if not runner then
    vim.notify("Don't know how to run a '" .. vim.bo.filetype .. "' file yet", vim.log.levels.WARN)
    return
  end

  vim.cmd("write")
  local file = vim.api.nvim_buf_get_name(0)

  -- Reuse one output window instead of stacking a new split on every run
  if output_win and vim.api.nvim_win_is_valid(output_win) then
    vim.api.nvim_win_close(output_win, true)
  end

  vim.cmd("botright 12new")
  output_win = vim.api.nvim_get_current_win()
  vim.fn.jobstart(runner(file), { term = true, cwd = vim.fs.dirname(file) })
  -- Wait until the new window has focus, otherwise startinsert does nothing and keys go to normal mode
  vim.schedule(function()
    if vim.api.nvim_get_current_win() == output_win then
      vim.cmd("startinsert")
    end
  end)
end

return M
