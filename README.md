# My Neovim setup

LazyVim-based config with Java, Python and Rust support, Jupyter notebooks, and a one-key "run this file".

## First steps

1. Open `nvim` and wait for plugins to install (a minute or two on first launch).
2. Open a `.py`, `.java` or `.rs` file. The language server (pyright, FerrisJDT, or rust-analyzer) starts on its own.
3. Press `<Space>` and wait: a menu of every key you can press appears. This is the best way to discover things.
4. Run `:Tutor` once for the basics of Vim movement.

## Running code

| Key            | Does                                  |
|----------------|---------------------------------------|
| `F5`           | Save and run the current file         |
| `<Space>rr`    | Same as F5                            |

In a Maven or Gradle project the dependency JARs cached by `:JavaDepsSync` are on the classpath. A Spring Boot app under `src/main/java` is started with `bootRun` or `spring-boot:run` instead, so runtime-only JARs are included.

Output appears in a terminal split at the bottom. To leave terminal mode press `<Ctrl>\` then `<Ctrl>n`, then `:q` to close the split.

- Python runs with `python3`.
- Java compiles every `.java` file in the same folder with `javac`, then runs the class. Files under `src/main/java` compile the whole source root. Libraries from Maven or Gradle are not on the classpath, so use the build tool in the terminal (`<Ctrl>/`) for those projects.
- Rust runs `cargo run` inside a Cargo project, and `rustc` on a standalone file.

## Java

Java uses FerrisJDT, a lightweight Java language server, instead of JDTLS. It needs no JVM of its own. The server is set up in `lua/plugins/ferrisjdt.lua`. It looks for the `ferrisjdt` binary on PATH, then in `~/.local/bin`, then in a local release build. To build and install it, run `cargo build --release` and then `make install`. If the binary is missing, Neovim shows a warning and Java language support is off.

- The source level is Java 8. To change it, set `sourceLevel` in `ferrisjdt.lua`, or commit a `ferrisjdt.json` to the project.
- Completion for `variable.` lists members, and the highlighted item shows its documentation beside the menu (`lua/plugins/java-completion.lua`).
- Java buffers use 4-space indentation (`lua/config/autocmds.lua`).
- Rename a variable, method or class with `<F2>`. The prompt starts with the current name, and FerrisJDT updates every use in the project. It refuses invalid names and library symbols, and shows why.
- `:SwitchJavaLSP` asks which Java server to use, FerrisJDT or JDTLS. The choice is saved and applies after you restart Neovim. The code is in `lua/config/java_lsp.lua`.

## Jupyter notebooks

Opening a `.ipynb` file shows it as readable Markdown, and saving writes the edits back to the notebook format. This needs the `jupytext` command on your PATH. The plugin is set up in `lua/plugins/jupyter.lua`.

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

## Expo

| Command                 | Key           | Does                                                          |
|-------------------------|---------------|---------------------------------------------------------------|
| `:ExpoStart`            | `<Space>ex`   | Run `npx expo start` (dev server)                             |
| `:ExpoIOS`              | `<Space>edi`  | Run `npx expo run:ios --device`                               |
| `:ExpoAndroid`          | `<Space>eda`  | Run `npx expo run:android --device`                           |
| `:ExpoAndroidEmulator`  | `<Space>ea`   | Run `npx expo start --android` (opens the Android emulator)    |

Each one opens in a small floating window in the bottom right quarter of the screen, in the project root found from the current directory. The commands are defined in `lua/config/expo.lua`.

- **Resize:** drag the bottom right corner of the window with the mouse.
- **Minimize:** click `_` in the title bar to shrink the window to that bar. Click `□` in the bar to restore it. The process keeps running while minimized.

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

## Maven and Gradle projects

Open a Java file in a project with a `pom.xml` or `build.gradle` and FerrisJDT gets its dependencies without you doing anything. The first time a file attaches, and again whenever the build file is newer than the cache, Neovim runs `mvn dependency:build-classpath` (or `./mvnw`) or Gradle (`./gradlew`, else `gradle`) in the background, saves the JAR list to `.ferrisjdt/classpath.txt` in the project, and restarts the server. The first run downloads plugins and can take a minute. FerrisJDT also reads the Java level from the build file; plain directories keep `sourceLevel = 8`.

| Command           | Does                                                      |
| ----------------- | --------------------------------------------------------- |
| `:JavaDepsSync`   | Resolve dependencies again, for example after editing the build file or when the first attempt failed |
| `:JavaDepsStatus` | Show how many JARs are cached and whether the cache is stale |

For Gradle, every module (and source set) is resolved by its own task, so a module cannot silently lose its dependencies; the Java level, source and generated-source directories, and files a source set excludes are reported too, and a sync that resolves no JARs is an error instead of an empty cache. Set `vim.g.javadeps_gradle` to a Gradle binary to use instead of the project's `gradlew`, for example when its wrapper has not been verified. Annotation-processor output (MapStruct, QueryDSL, a JPA metamodel, Micronaut) is indexed only after you have compiled the project once, because the server never runs the build.

For a multi-module Maven project, every module's dependencies are collected into one cache in the project root, and FerrisJDT treats the parent project as the workspace even when you open a single module, so sibling modules' classes resolve. The code is in `lua/config/javadeps.lua`.

## Reloading the config

`:HotReload` re-runs the Lua config in `lua/config/` without quitting Neovim. Changes to plugin specs in `lua/plugins/` still need a restart, because lazy.nvim reads them only once.

## Autosave

| Command                 | Does                                                          |
|-------------------------|---------------------------------------------------------------|
| `:AutoSave`             | Turn automatic saving on or off                               |
| `:AutoSaveSettings`     | Choose what triggers a save, a delay, and filetypes to skip   |

Autosave is on by default. A named file is saved when you leave insert mode, after you pause editing in normal mode, and when Neovim loses focus. Terminal and help buffers are never saved. `:AutoSaveSettings` lists each trigger (leaving insert mode, normal-mode edits, focus loss), a delay in milliseconds before saving after edits, a periodic save every N seconds (0 turns it off, and it saves every modified buffer), and a comma-separated list of filetypes never saved (default `gitcommit`). Settings are kept across `:HotReload` and restarts, in `autosave.json` under `:echo stdpath('data')`. The code is in `lua/config/autosave.lua`.

## CS314 hygiene checks

| Command                 | Does                                                          |
|-------------------------|---------------------------------------------------------------|
| `:CS314ON`              | Check Java files with `eclipse_config/cs314-checkstyle.xml`   |
| `:CS314OFF`             | Stop the checks and clear the findings                        |

Findings appear as errors in the diagnostics list, so `<Space>xx` lists them and `]d` / `[d` jump between them. Checks run when a Java file opens and each time it is saved. Unsaved edits are not checked, because Checkstyle reads the file from disk. The checks are off when Neovim starts, and `:CS314ON` turns them on for that session only.

The checks need the `checkstyle` command: `brew install checkstyle`. The config path is set in `lua/config/cs314.lua`. The commands are defined there too.

## Agent control socket

Neovim listens on `~/.local/state/nvim/agent.sock` so that an agent can run commands in your editor. The directory is readable only by you. Anyone who can connect to the socket can run any command as you, including shell commands, so do not copy the socket path anywhere shared.

```sh
nvim --server ~/.local/state/nvim/agent.sock --remote-send ':CS314ON<CR>'
nvim --server ~/.local/state/nvim/agent.sock --remote-expr 'getline(1)'
```

The first Neovim started owns the socket. Other instances log a warning and leave it alone. The socket file is removed when Neovim exits. If Neovim crashed and left a stale file, the next start removes it. The setup is in `lua/config/agent_rpc.lua`.

## Other commands

| Command                 | Does                                                          |
|-------------------------|---------------------------------------------------------------|
| `:Central`              | Open the `central` command in a terminal buffer               |

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
| `<F2>`           | Rename symbol under the cursor          |
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
- `lazyvim.json`: which LazyVim extras are enabled (Java, Python and Rust). Use `:LazyExtras` to add more.
- `lua/config/`: options, keymaps, autocmds, and the run command. Also the Claude, Codex and AGY commands (`claude.lua`, `agents.lua`), AutoCommit (`autocommit.lua`), mouse hover (`hover.lua`), Maven/Gradle dependencies (`javadeps.lua`), the Java server switch (`java_lsp.lua`), and `:HotReload` (`reload.lua`), CS314 checks (`cs314.lua`), and the agent socket (`agent_rpc.lua`).
- `lua/plugins/`: your own plugin specs, one file per plugin or group. Current files: `ferrisjdt.lua` (Java language server), `java-completion.lua`, `jupyter.lua`, and `autocommit.lua` (statusline spinner).
- `snippets/`: custom snippets, such as `java.json`.
- `AGENTS.md` and `CLAUDE.md`: notes for AI coding agents working in this repo.
