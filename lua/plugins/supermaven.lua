return {
  'supermaven-inc/supermaven-nvim',
  config = function()
    require('supermaven-nvim').setup {
      keymaps = {
        accept_suggestion = '<S-Tab>',
        clear_suggestion = '<C-S-h>',
        accept_word = '<C-S-j>',
      },
      ignore_filetypes = { cpp = true }, -- or { "cpp", }
      log_level = 'info', -- set to "off" to disable logging completely
      disable_inline_completion = false, -- disables inline completion for use with cmp
      disable_keymaps = false, -- disables built in keymaps for more manual control
    }
  end,
}
