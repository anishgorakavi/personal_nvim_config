# AGENTS.md

Guidance for AI coding agents working in this repo. It is a personal Neovim config on macOS, built on LazyVim and lazy.nvim. There is no build step and no test suite. To verify a change, start Neovim headless and check for errors, as described below.

## Layout

- `init.lua`: entry point. It requires `config.lazy` and defines `:Central`.
- `lua/config/lazy.lua`: bootstraps lazy.nvim, then loads LazyVim, then every spec in `lua/plugins/`.
- `lua/config/options.lua`, `autocmds.lua`, `keymaps.lua`: loaded on the VeryLazy event. `keymaps.lua` wires up every feature module.
- `lua/config/<feature>.lua`: one module per feature. Each returns `M` with a `setup()` that registers user commands. Current modules: `run`, `claude`, `agents`, `hover`, `autocommit`, `autocommit_settings`, `autocommit_status`, `reload`, `cs314`, `agent_rpc`, `autosave`, `javadeps`, `java_lsp`.
- `lua/plugins/*.lua`: lazy.nvim plugin specs. Each file returns a table of specs. These are read once at startup.
- `lazyvim.json`: enabled LazyVim extras (java, python, rust).
- `lazy-lock.json`: plugin versions. Lazy.nvim writes it. Don't edit it by hand.
- `snippets/java.json`: custom Java snippets.
- `README.md`: the user-facing manual. It lists every command and key.
- `stylua.toml`: 2-space indent, Unix-style spaces, 120-column width.

## Verifying changes

- Format Lua with `stylua <changed files>` if stylua is installed. Check with `stylua --check`.
- Check that a changed module loads: `nvim --headless -c "lua require('config.run')" -c "qa"`. Use the module's name in place of `config.run`. Errors go to stderr.
- Check startup: `nvim --headless -c "qa"`. Plugins must already be installed, or this will try to fetch them.
- For `lua/config/` changes, `:HotReload` re-runs the config without a restart. Changes under `lua/plugins/` need a full restart.
- You cannot see the editor UI from here. If you change behavior the user would see, say that it is unverified in the real editor.

## Conventions

- Match the code around you. Comments explain why something is done, not what the code does. Each feature module opens with a short header comment that lists the user commands it defines. Keep that pattern for new modules.
- Keep changes small and in the existing style. Don't add abstractions, helper layers, or dependencies unless the change needs them.
- Register user commands with `nvim_create_user_command`, give each a `desc`, and start the name with a capital letter. Neovim requires that.
- Use `Snacks.terminal.toggle` for terminal splits, as `claude.lua` and `agents.lua` do. Pass user-supplied text through `vim.fn.shellescape`.
- When you add or change a command, a key, or a feature, update the matching table in `README.md` in the same change.
- Paths in this config are machine-specific on purpose, for example `~/.local/bin/ferrisjdt` and `~/Desktop/newjdtls/...` in `ferrisjdt.lua`. Don't generalize them.

## Gotchas

- **AutoCommit acts on the repo under you.** `lua/config/autocommit.lua` runs on a timer, every 30 minutes by default. It stages tracked changes, skips the run if the diff is under `min_lines`, and otherwise commits and runs a plain `git push`. If Neovim is open in a git repo while you work, it may commit and push your edits or the user's in-progress edits. Don't assume the working tree stays as you left it. Check `git status` before and after your changes.
- **The working tree may already hold the user's unfinished work.** `init.lua`, `lazy-lock.json`, `lua/config/autocmds.lua`, `lua/plugins/java-completion.lua`, `lua/plugins/jupyter.lua`, and `snippets/` may have uncommitted changes. Don't revert or overwrite them unless the user asks. Keep your edits separate from theirs.
- **Keep the AutoCommit defaults.** The default provider is `ollama`, which keeps diffs local. The `openai` provider sends diffs to a remote server. Don't change the default to `openai`. API keys are read from the environment variable named in the settings, and are never written to disk.
- **Java buffers use 4-space indent.** The override is in `autocmds.lua`. It overrides `stylua.toml` for Java files only, so don't "fix" it to 2 spaces.
- **Java LSP is FerrisJDT by default, not JDTLS.** `:SwitchJavaLSP` (`java_lsp.lua`) saves a choice of JDTLS in the state directory, and `ferrisjdt.lua` reads it at startup to turn FerrisJDT off and `nvim-jdtls` on. The choice applies only after a restart. While the choice is FerrisJDT, `nvim-jdtls` is disabled in `ferrisjdt.lua`. The server sets `sourceLevel = 8` because the user's Java course targets Java 8. Keep that for plain directories. For a Maven or Gradle project, `before_init` drops it so the server reads the Java level from the build file, and `javadeps.lua` caches the dependency classpath in `.ferrisjdt/classpath.txt`.
- **Plugin specs are read once.** Adding or changing a file in `lua/plugins/` has no effect until Neovim restarts.
- **Headless runs don't fire VeryLazy.** `keymaps.lua` loads on VeryLazy, so `nvim --headless -c "qa"` never registers `:CS314ON`, `:Claude`, or the agent socket. To test those, add `-c "doautocmd User VeryLazy"`.
- **The agent socket gives full control.** `lua/config/agent_rpc.lua` serves `~/.local/state/nvim/agent.sock`, and anyone who connects can run any command as the user. Don't print the socket path into logs, commits, or shared output. To test the socket, use `nvim --server <sock> --remote-send` and `--remote-expr`.
- **CS314 checks need the `checkstyle` command.** `lua/config/cs314.lua` reads `~/Desktop/cs314/eclipse_config/cs314-checkstyle.xml`. Install the command with `brew install checkstyle`. The checks run only when `:CS314ON` is active, so a headless run does not start them.

## Git

- The branch is `main`. Look at `git log` for the message style: a short imperative subject.
- Don't commit unless the user asks. Don't push, and never force-push.
- Don't commit the user's unrelated uncommitted changes as part of your own work. Stage only the files you changed.
- Never write secrets, API keys, or tokens into any file in this repo.
