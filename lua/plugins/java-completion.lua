-- Completion behaviour for Java. The language server itself is configured in
-- ferrisjdt.lua; this only tunes how its results are shown.
--
-- `variable.` lists members; the highlighted item shows its documentation
-- beside the menu.
return {
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        trigger = { show_on_trigger_character = true },
        documentation = { auto_show = true, auto_show_delay_ms = 150, window = { border = "rounded" } },
        menu = { border = "rounded" },
      },
      signature = { enabled = true },
    },
  },
}
