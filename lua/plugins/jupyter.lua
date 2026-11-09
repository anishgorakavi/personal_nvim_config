-- Open .ipynb notebooks as readable Markdown and write edits back to the
-- original notebook format. Requires the `jupytext` CLI on PATH.
return {
  {
    "goerz/jupytext.nvim",
    version = "0.2.0",
    lazy = false,
    opts = {
      format = "markdown",
      update = true,
    },
  },
}
