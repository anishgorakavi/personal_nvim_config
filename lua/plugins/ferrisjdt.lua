-- FerrisJDT: a lightweight Java language server, the default instead of JDTLS.
-- It speaks plain LSP over stdio and needs no JVM of its own.
--
-- :SwitchJavaLSP picks JDTLS instead; then this file enables nothing and the
-- LazyVim `lang.java` extra takes over (see config/java_lsp.lua).

-- Prefer an installed binary, then a local release build, so a freshly built
-- checkout works without installing anything.
--
-- Candidates are appended one at a time: a nil hole in a table literal would
-- make `ipairs` stop at it and silently skip the rest.
local function server_binary()
  local candidates = {}
  local function consider(path)
    if path and path ~= "" then
      candidates[#candidates + 1] = path
    end
  end
  consider(vim.g.ferrisjdt_path)
  consider(vim.fn.exepath("ferrisjdt"))
  consider(vim.fn.expand("~/.local/bin/ferrisjdt"))
  consider(vim.fn.expand("~/Desktop/newjdtls/ferrisjdt/target/release/ferrisjdt"))
  for _, path in ipairs(candidates) do
    if vim.fn.executable(path) == 1 then
      return path
    end
  end
  return nil
end

local binary = server_binary()
local ferris = require("config.java_lsp").current() == "ferrisjdt"

-- `false` stops LazyVim from installing or enabling JDTLS. It is left out
-- when JDTLS is chosen, because `nil` and `false` are not interchangeable here.
local jdtls = nil
if ferris then
  jdtls = false
end

return {
  -- JDTLS starts a JVM per project and is what this replaces, so its plugin
  -- is turned off rather than left to attach a second client to every buffer.
  { "mfussenegger/nvim-jdtls", enabled = not ferris },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        jdtls = jdtls,

        ferrisjdt = ferris and binary and {
          cmd = { binary },
          filetypes = { "java" },
          -- A plain source directory is a valid project, so `src` and a bare
          -- `.git` are markers too; a course assignment has neither Maven nor
          -- Gradle in it.
          root_markers = {
            "ferrisjdt.json",
            "pom.xml",
            "build.gradle",
            "build.gradle.kts",
            ".git",
            "src",
          },
          -- A Maven or Gradle project declares its own Java level, which the server
          -- reads from the build file, so the course default is sent only for
          -- plain directories. Dependencies come from config/javadeps.lua.
          before_init = function(params, config)
            local root = params.rootUri and vim.uri_to_fname(params.rootUri)
            if root and require("config.javadeps").build_file(root) then
              params.initializationOptions = nil
            end
          end,
          init_options = {
            -- CS 314 is a Java 8 course; raise this for a newer project, or
            -- commit a ferrisjdt.json in the project to set it per project.
            sourceLevel = 8,
            -- Left unset, the server finds a JDK itself, preferring one whose
            -- release matches sourceLevel. Set jdkHome to pin it.
          },
        } or nil,
      },
    },
  },

  -- Warn once if the binary is missing, rather than silently losing Java LSP.
  ferris and binary == nil and {
    "LazyVim/LazyVim",
    opts = function()
      vim.schedule(function()
        vim.notify(
          "ferrisjdt was not found on PATH or in ~/.local/bin; Java LSP is off.\n"
            .. "Build it with `cargo build --release` and run `make install`.",
          vim.log.levels.WARN,
          { title = "FerrisJDT" }
        )
      end)
    end,
  } or nil,
}
