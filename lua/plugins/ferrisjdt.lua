-- FerrisJDT: a lightweight Java language server, used instead of JDTLS. It
-- speaks plain LSP over stdio and needs no JVM of its own.
--
-- To go back to JDTLS, delete this file: LazyVim's `lang.java` extra then
-- takes over again on its own.

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

return {
  -- JDTLS starts a JVM per project and is what this replaces, so its plugin
  -- is turned off rather than left to attach a second client to every buffer.
  { "mfussenegger/nvim-jdtls", enabled = false },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- `false` stops LazyVim from installing or enabling JDTLS.
        jdtls = false,

        ferrisjdt = binary and {
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
  binary == nil and {
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
