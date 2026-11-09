-- Gives FerrisJDT the dependency JARs of Maven and Gradle projects. The server
-- never runs a build tool, so this asks mvn or gradle once for the compile
-- classpath, caches it in <root>/.ferrisjdt/classpath.txt, and restarts the
-- server to pick it up. It runs by itself when a Java file in such a project
-- attaches and the cache is missing or older than the build file.
--
-- User commands: :JavaDepsSync (re-resolve now), :JavaDepsStatus (show the cache).
local M = {}

local cache_name = ".ferrisjdt/classpath.txt"
local build_files = { "pom.xml", "build.gradle", "build.gradle.kts" }
-- Maven writes one classpath file per module, at a path relative to that module.
local maven_output = "target/ferrisjdt-classpath.txt"

local running = {}
local attempted = {}

-- A Gradle init script that prints nothing and writes every module's JARs to
-- -Dferrisjdt.out. Resolving through sourceSets honours the Spring Boot BOM.
local init_script = [[
rootProject {
  tasks.register('ferrisjdtClasspath') {
    doLast {
      def jars = new LinkedHashSet<String>()
      rootProject.allprojects.each { p ->
        def sets = p.extensions.findByName('sourceSets')
        if (sets != null) {
          sets.each { ss ->
            try {
              ss.compileClasspath.files.each { f ->
                if (f.name.endsWith('.jar') && f.exists()) { jars << f.absolutePath }
              }
            } catch (Exception e) {
              logger.warn("ferrisjdt: skipped " + p.path + ":" + ss.name + ": " + e.message)
            }
          }
        }
      }
      def out = new File(System.getProperty('ferrisjdt.out'))
      out.parentFile.mkdirs()
      out.text = jars.join('\n') + '\n'
    }
  }
}
]]

local function exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

-- The build file that makes `root` a Maven or Gradle project, if any.
function M.build_file(root)
  for _, name in ipairs(build_files) do
    if exists(root .. "/" .. name) then
      return root .. "/" .. name
    end
  end
  return nil
end

local function mtime(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.mtime.sec or 0
end

-- True when the cached classpath is missing or older than any build file.
local function stale(root)
  local cache = mtime(root .. "/" .. cache_name)
  if cache == 0 then
    return true
  end
  for _, name in ipairs(build_files) do
    if mtime(root .. "/" .. name) > cache then
      return true
    end
  end
  return false
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "FerrisJDT" })
end

-- Writes the JAR list and keeps the cache directory out of version control.
local function write_cache(root, jars)
  local dir = root .. "/.ferrisjdt"
  vim.fn.mkdir(dir, "p")
  vim.fn.writefile({ "*" }, dir .. "/.gitignore")
  vim.fn.writefile(jars, root .. "/" .. cache_name)
end

local function restart_server()
  for _, client in ipairs(vim.lsp.get_clients({ name = "ferrisjdt" })) do
    local bufs = vim.tbl_keys(client.attached_buffers)
    client:stop()
    vim.defer_fn(function()
      for _, buf in ipairs(bufs) do
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_call(buf, function()
            vim.cmd("silent! edit")
          end)
        end
      end
    end, 500)
  end
end

-- The command that resolves the classpath into `out`, or nil if no tool exists.
local function resolve_command(root, out)
  if exists(root .. "/pom.xml") then
    local mvn = exists(root .. "/mvnw") and root .. "/mvnw" or "mvn"
    if vim.fn.executable(mvn) == 1 then
      return {
        mvn, "-q", "-B", "dependency:build-classpath", "-Dmdep.outputFile=" .. maven_output,
      },
        "maven"
    end
  end
  local init = vim.fn.stdpath("data") .. "/ferrisjdt-classpath.init.gradle"
  vim.fn.writefile(vim.split(init_script, "\n"), init)
  local gradle = exists(root .. "/gradlew") and "./gradlew" or "gradle"
  if gradle == "gradle" and vim.fn.executable("gradle") ~= 1 then
    return nil
  end
  return {
    gradle, "-q", "--console=plain", "-I", init, "-Dferrisjdt.out=" .. out, "ferrisjdtClasspath",
  },
    "gradle"
end

-- The files a resolve produced: every module's Maven file, or the one Gradle file.
local function output_files(root, tool, out)
  if tool == "maven" then
    return vim.fn.glob(root .. "/**/" .. maven_output, true, true)
  end
  return exists(out) and { out } or {}
end

-- Parses Maven's colon-separated lines or Gradle's one-per-line output, across files.
local function read_jars(files)
  local seen, jars = {}, {}
  for _, file in ipairs(files) do
    for _, line in ipairs(vim.fn.readfile(file)) do
      for _, path in ipairs(vim.split(line, ":", { plain = true, trimempty = true })) do
        if path:match("%.jar$") and not seen[path] then
          seen[path] = true
          jars[#jars + 1] = path
        end
      end
    end
  end
  return jars
end

-- Resolves dependencies for the project at `root`, then restarts the server.
function M.sync(root)
  if running[root] then
    return
  end
  local out = vim.fn.tempname()
  local cmd, tool = resolve_command(root, out)
  if not cmd then
    notify("No mvn, gradle or wrapper found in " .. root, vim.log.levels.WARN)
    return
  end
  running[root] = true
  notify("Resolving " .. tool .. " dependencies...")
  vim.system(cmd, { cwd = root, text = true }, function(result)
    vim.schedule(function()
      running[root] = nil
      local files = output_files(root, tool, out)
      if result.code ~= 0 or #files == 0 then
        local tail = vim.trim((result.stderr or "") .. (result.stdout or ""))
        notify(tool .. " failed:\n" .. tail:sub(-600), vim.log.levels.ERROR)
        return
      end
      local jars = read_jars(files)
      for _, file in ipairs(files) do
        os.remove(file)
      end
      write_cache(root, jars)
      notify(("%s: %d dependency JARs cached; restarting server"):format(tool, #jars))
      restart_server()
    end)
  end)
end

-- The project root of the current buffer's FerrisJDT client, or the cwd.
local function current_root()
  local client = vim.lsp.get_clients({ bufnr = 0, name = "ferrisjdt" })[1]
  return client and client.root_dir or vim.fn.getcwd()
end

function M.setup()
  vim.api.nvim_create_user_command("JavaDepsSync", function()
    local root = current_root()
    if M.build_file(root) then
      M.sync(root)
    else
      notify("No pom.xml or build.gradle in " .. root, vim.log.levels.WARN)
    end
  end, { desc = "Resolve Maven/Gradle dependencies for FerrisJDT" })

  vim.api.nvim_create_user_command("JavaDepsStatus", function()
    local root = current_root()
    local path = root .. "/" .. cache_name
    local lines = exists(path) and vim.fn.readfile(path) or {}
    notify(("%s\n%d cached JARs%s"):format(root, #lines, stale(root) and " (stale or missing)" or ""))
  end, { desc = "Show FerrisJDT's cached dependency classpath" })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("JavaDeps", { clear = true }),
    desc = "Resolve build-tool dependencies once per project",
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local root = client and client.name == "ferrisjdt" and client.root_dir
      if root and not attempted[root] and M.build_file(root) and stale(root) then
        attempted[root] = true
        M.sync(root)
      end
    end,
  })
end

return M
