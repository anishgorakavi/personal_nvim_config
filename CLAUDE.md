@AGENTS.md

# Claude Code notes

The shared rules for this repo are in `AGENTS.md`, imported above. This file adds what applies only to Claude Code.

- Use the `personal-code-hygiene` skill for code changes here.
- For Neovim behavior you cannot check headlessly, use the `run` skill to launch Neovim in a real session, or say that the change is unverified.
- `:Claude` and `:RecentClaude` in this config start Claude Code in a terminal split. That is how the user usually opens an agent in this repo. Don't change those commands unless asked.
- Before editing, run `git status`. Several files in this repo may already have uncommitted changes from the user. Work around them.
