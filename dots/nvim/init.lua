local vim = vim or {}

-- :h vim.opt
-- • |vim.opt|:        behaves like |:set|
vim.opt.compatible = false
vim.opt.nu = true
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.mouse = ""
vim.opt.colorcolumn= "80"

local timer = vim.uv.new_timer()
timer:start(1000, 0, vim.schedule_wrap(function()
  vim.cmd.echo('">^.^<"')
end))

vim.cmd([[

runtime ./plug.vim
runtime ./maps.vim
runtime ./locals/locals.vim
]])

-- Make space more useful
vim.keymap.set('n', '<space>', 'za')
vim.keymap.set('n', 'R', '<cmd>source $MYVIMRC<cr>')

vim.cmd([[
" keeps the terminal opacity of ghostty,
" but gets rid of all syntax highlighting...
" set notgc
]])
