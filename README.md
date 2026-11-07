# My Neovim setup

LazyVim-based config with Java and Python support and a one-key "run this file".

## First steps

1. Open `nvim` and wait for plugins to install (a minute or two on first launch).
2. Open a `.py` or `.java` file. The language server (pyright / jdtls) starts on its own.
3. Press `<Space>` and wait: a menu of every key you can press appears. This is the best way to discover things.
4. Run `:Tutor` once for the basics of Vim movement.

## Running code

| Key            | Does                                  |
|----------------|---------------------------------------|
| `F5`           | Save and run the current file         |
| `<Space>rr`    | Same as F5                            |

Output appears in a terminal split at the bottom. To leave terminal mode press `<Ctrl>\` then `<Ctrl>n`, then `:q` to close the split.

- Python runs with `python3`.
- Java compiles every `.java` file in the same folder with `javac`, then runs the class. Files under `src/main/java` compile the whole source root. Libraries from Maven or Gradle are not on the classpath, so use the build tool in the terminal (`<Ctrl>/`) for those projects.
- Rust runs `cargo run` inside a Cargo project, and `rustc` on a standalone file.

## Claude Code

| Command                 | Does                                                          |
|-------------------------|---------------------------------------------------------------|
| `:Claude`               | Start Claude Code in a split on the right                     |
| `:Claude <prompt>`      | Start Claude Code and send `<prompt>` as the first message    |
| `:RecentClaude`         | Resume the most recent conversation in this directory         |
| `:RecentClaude <prompt>`| Resume that conversation and send `<prompt>`                  |

Neovim requires command names to start with a capital letter, so type `:Claude`, not `:claude`. Open Neovim in the project you are working on first. Each directory keeps its own terminal, and running the command again toggles the split without ending the session.

To add another language, add an entry to `lua/config/run.lua`.

## Codex and Antigravity

| Command                 | Does                                                          |
|-------------------------|---------------------------------------------------------------|
| `:Codex`                | Start OpenAI Codex CLI in a split on the right                |
| `:Codex <prompt>`       | Start Codex CLI and send `<prompt>` as the first message      |
| `:AGY`                  | Start Antigravity (`agy`) in a split on the right             |
| `:AGY <prompt>`         | Start Antigravity and send `<prompt>` as the first message    |

These run the `codex` and `agy` binaries from your PATH, so they must be installed. The commands are defined in `lua/config/agents.lua`.

## Automatic commits

| Command                 | Does                                                              |
|-------------------------|-------------------------------------------------------------------|
| `:AutoCommit`           | Commit and push the current repo now                              |
| `:AutoCommit!`          | Same, but commit even when the change looks trivial               |
| `:AutoCommitSettings`   | Open the settings window (interval, provider, model, URL, ...)    |
| `:AutoCommitStatus`     | Show the current phase, the model's output as it streams, and what Ollama has loaded |

Every 30 minutes (configurable), Neovim checks the repo of the current directory. It stages the tracked changes (plus new files if you enable that), then skips the run if the change is under the minimum line count, ignoring whitespace. Otherwise it sends the staged diff to the model, which returns a one-line commit subject, and then runs a plain `git push`. The model never sees the rest of the repo and is never asked to write code.

- Ollama is the default and keeps the diff on your machine. The default model is `qwen3.5:2b-mlx`.
- The OpenAI-compatible option sends the diff to the server you configure. Check your course policy first. The API key is read from the environment variable you name in the settings, so the key itself is never saved to disk.
- Settings are saved to `~/.local/state/nvim/autocommit.json`.
- Nothing is force-pushed. If the branch has no upstream, the commit is made and the push is skipped.
- While a run is in progress, a spinner labelled `AutoCommit` appears in the statusline.

## Reloading the config

`:HotReload` re-runs the Lua config in `lua/config/` without quitting Neovim. Changes to plugin specs in `lua/plugins/` still need a restart, because lazy.nvim reads them only once.

## Everyday keys

| Key              | Does                                    |
|------------------|-----------------------------------------|
| `<Space>e`       | File explorer                           |
| `<Space>ff`      | Find file by name                       |
| `<Space>/`       | Search text in project                  |
| `<Space>cf`      | Format the file                         |
| `<Space>xx`      | List all errors and warnings            |
| `<Space>ca`      | Code actions (fix imports, quick fixes) |
| `<Space>cr`      | Rename symbol everywhere                |
| `gd`             | Go to definition                        |
| `K`              | Show docs for the thing under cursor    |
| Mouse hover      | Rest the mouse on a symbol to show its docs (Rust, Python, Java) |
| `<Ctrl>/`        | Toggle a terminal                       |
| `<Space>cm`      | Mason: install/update language tools    |
| `<Space>l`       | Lazy: plugin manager                    |
| `<Space>sk`      | Search all keymaps                      |
| `<Space>qq`      | Quit everything                         |

## Vim basics

- `i` enters insert mode, `<Esc>` leaves it.
- `:w` saves, `:q` quits, `:wq` saves and quits. `:q!` quits without saving.
- Movement: `h j k l` (or arrow keys), `w`/`b` by word, `0`/`$` start/end of line, `gg`/`G` top/bottom.
- Option+Left and Option+Right move by word in normal and insert mode. Option+Backspace deletes the previous word in insert mode.
- `u` undo, `<Ctrl>r` redo.

## Layout

- `init.lua`: entry point.
- `lazyvim.json`: which LazyVim extras are enabled (Java and Python). Use `:LazyExtras` to add more.
- `lua/config/`: options, keymaps, autocmds, and the run command. Also the Codex/AGY commands (`agents.lua`) and mouse hover (`hover.lua`).
- `lua/plugins/`: put your own plugins here (empty for now).
