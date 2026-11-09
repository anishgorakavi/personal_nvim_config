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

-- Dependency JARs cached by javadeps.lua, as a classpath string ("" when absent).
local function dependency_classpath(build_root)
  local path = build_root .. "/.ferrisjdt/classpath.txt"
  if vim.uv.fs_stat(path) == nil then
    return ""
  end
  return table.concat(vim.fn.readfile(path), ":")
end

local function is_spring_boot_app(file)
  for line in io.lines(file) do
    if line:find("@SpringBootApplication", 1, true) then
      return true
    end
  end
  return false
end

local runners = {
  python = function(file)
    return { "python3", "-u", file }
  end,
  -- Compile every sibling .java file first, so classes that reference each other resolve.
  -- Maven/Gradle layouts (src/main/java) compile the whole source root so packages work too.
  -- Inside a Maven/Gradle project the cached dependency JARs go on the classpath, and a Spring
  -- Boot app in the standard layout is started by the build tool so runtime-only JARs are included.
  java = function(file)
    local build_root = vim.fs.root(file, { "pom.xml", "build.gradle", "build.gradle.kts" })
    if build_root and file:find(build_root .. "/src/main/java/", 1, true) and is_spring_boot_app(file) then
      local goal = vim.uv.fs_stat(build_root .. "/pom.xml")
          and (vim.uv.fs_stat(build_root .. "/mvnw") and "./mvnw" or "mvn") .. " spring-boot:run"
        or (vim.uv.fs_stat(build_root .. "/gradlew") and "./gradlew" or "gradle") .. " bootRun"
      return { "sh", "-c", "cd " .. vim.fn.shellescape(build_root) .. " && " .. goal }
    end
    local deps = build_root and dependency_classpath(build_root) or ""
    local javac_cp = deps ~= "" and (" -cp " .. vim.fn.shellescape(deps)) or ""
    local resources = build_root and (build_root .. "/src/main/resources") or ""
    local out = vim.fn.tempname()
    local name = vim.fn.fnamemodify(file, ":t:r")
    local pkg = package_of(file)
    local main_class = pkg and (pkg .. "." .. name) or name
    local source_root = file:match("^(.*/src/[^/]+/java)/")
    local find = source_root and "find . -name '*.java'" or "find . -maxdepth 1 -name '*.java'"
    local runtime = out .. (resources ~= "" and (":" .. resources) or "") .. (deps ~= "" and (":" .. deps) or "")
    local script = table.concat({
      "cd " .. vim.fn.shellescape(source_root or vim.fs.dirname(file)),
      "mkdir -p " .. out,
      find .. " -print0 | xargs -0 javac" .. javac_cp .. " -d " .. out,
      "java -cp " .. vim.fn.shellescape(runtime) .. " " .. main_class,
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
