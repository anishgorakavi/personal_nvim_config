# TREE

Personal Neovim configuration on LazyVim and lazy.nvim, for Java, Python, Rust and notebooks.

init.lua                    Entry point: loads the lazy.nvim setup and defines :Central.
stylua.toml                 Lua formatter settings: 2-space indent, 120 columns.
lazyvim.json                LazyVim extras that are enabled (Java, Python, Rust).
lazy-lock.json              Plugin versions pinned by lazy.nvim. Written by lazy.nvim, not by hand.
.neoconf.json               Lua language server settings for editing this config.
snippets/java.json          Custom Java snippets.
lua/config/                 One module per feature. Each exposes setup(), which registers its commands.
  lazy.nvim bootstrap       lazy.lua: installs lazy.nvim, loads LazyVim, then every spec in lua/plugins/.
  options.lua               Editor options, loaded on VeryLazy.
  autocmds.lua              Autocommands, including the Java indent override.
  keymaps.lua               Key mappings, and the setup() call for every feature module.
  run.lua                   Runs the current file in a terminal split, per filetype.
  claude.lua                :Claude and :RecentClaude, which start Claude Code in a split.
  agents.lua                :Codex and :AGY, which start those CLIs in a split.
  hover.lua                 Shows language-server docs when the mouse rests on a symbol.
  autocommit.lua            Timed commit and push of the current repo, with a model writing the subject.
  autocommit_settings.lua   :AutoCommitSettings window for the AutoCommit options.
  autocommit_status.lua     :AutoCommitStatus window showing the current phase and streamed output.
  reload.lua                :HotReload, which re-runs the lua/config modules.
  cs314.lua                 :CS314ON and :CS314OFF, Checkstyle diagnostics for Java.
  agent_rpc.lua             Serves the Neovim RPC socket that agents connect to.
  javadeps.lua              :JavaDepsSync and :JavaDepsStatus; resolves Maven/Gradle JARs for FerrisJDT.
  java_lsp.lua              :SwitchJavaLSP; saves whether FerrisJDT or JDTLS is the Java server, applied on restart.
  autosave.lua              :AutoSave and :AutoSaveSettings; saves named files on chosen triggers, with a delay and filetype exclusions.
lua/plugins/                lazy.nvim plugin specs. Read once at startup.
  init.lua                  Placeholder that returns no specs.
  ferrisjdt.lua             Sets FerrisJDT as the Java language server, unless :SwitchJavaLSP chose JDTLS.
  java-completion.lua       Java completion tuning in blink.cmp.
  jupyter.lua               Opens .ipynb files as Markdown, using jupytext.
  autocommit.lua            Statusline spinner shown while AutoCommit runs.
README.md                   User manual: every command and key.
AGENTS.md                   Guidance for AI coding agents working in this repo.
CLAUDE.md                   Claude Code notes, imported from AGENTS.md.
