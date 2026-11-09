-- Completion behaviour for Java. The language server itself is configured in
-- ferrisjdt.lua; this only tunes how its results are shown.
--
-- `variable.` lists members; the highlighted item shows its documentation
-- beside the menu.
return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "enter",
        ["<CR>"] = {
          function(cmp)
            if not cmp.is_menu_visible() then
              return false
            end

            cmp.accept({
              callback = function()
                -- Snippet acceptance can enter Select mode after Blink's
                -- callback runs, so leave it on the next short timer tick.
                vim.defer_fn(function()
                  if vim.fn.mode():match("^[sS]") then
                    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
                  end
                  vim.cmd("startinsert")
                end, 20)
              end,
            })
            return true
          end,
          "fallback",
        },
      },
      completion = {
        trigger = { show_on_trigger_character = true },
        documentation = { auto_show = true, auto_show_delay_ms = 150, window = { border = "rounded" } },
        menu = { border = "rounded" },
      },
      signature = { enabled = true },
    },
  },
}
