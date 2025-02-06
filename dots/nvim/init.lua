local vim = vim or {}
local loadPlugins = function()
  local Plug = vim.fn['plug#']

  vim.call('plug#begin')

  Plug 'vimwiki/vimwiki'
  Plug('junegunn/fzf', {['do'] = vim.fn['fzf#install']})
  Plug 'junegunn/fzf.vim'
  Plug('earthly/earthly.vim', { branch= 'main' })

  Plug 'ziglang/zig.vim'
  Plug 'DingDean/wgsl.vim'
  Plug 'VaiN474/vim-etlua'

  Plug 'evanleck/vim-svelte'

  Plug 'pangloss/vim-javascript'
  Plug 'HerringtonDarkholme/yats.vim'
  Plug 'mattn/emmet-vim'

  Plug 'habamax/vim-godot'
  Plug('neoclide/coc.nvim', { branch= 'release' })

  --Plug 'williamboman/mason.nvim'
  --Plug 'williamboman/mason-lspconfig.nvim'
  --Plug 'neovim/nvim-lspconfig'
  Plug 'dense-analysis/ale'

  Plug('dracula/vim', { as= 'dracula' })
  Plug('folke/tokyonight.nvim', { as= 'tokyonight' })

  Plug 'preservim/nerdtree'

  Plug 'tpope/vim-fugitive'

  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'

  Plug 'tpope/vim-repeat'
  Plug 'ggandor/leap.nvim'

  vim.call('plug#end')

  vim.cmd([[
  let b:ale_fixers = {'javascript': ['prettier', 'eslint'], 'typescript': ['prettier', 'eslint']}
  let g:ale_fix_on_save = 1

  runtime ./plugins/vim-airline.rc.vim
  runtime ./plugins/vimwiki.rc.vim
  "runtime ./plugins/mason.rc.lua
  runtime ./plugins/emmet-vim.rc.vim
  runtime ./plugins/nerdtree.rc.vim
  runtime ./plugins/leap.rc.lua
  runtime ./plugins/coc.rc.vim
  "runtime ./plugins/lspconfig.rc.lua
  ]])
end

local loadMaps = function()
  vim.cmd([[
    " shift + arrow keys move between tabs
    nnoremap <S-up> <C-w><up>
    nnoremap <S-right> <C-w><right>
    nnoremap <S-down> <C-w><down>
    nnoremap <S-left> <C-w><left>

    " arrow key left and right moves between buffers
    nnoremap <right> :bnext<CR>
    nnoremap <left> :bprev<CR>

    " arrow key up and down leaps in the current buffer
    nnoremap <up> 10k<CR>
    nnoremap <down> 10j<CR>

    " Open fzf search, acknowledging .gitignore entries
    nnoremap ; :GFiles?<CR>
    " Use ? key to invoke a text search across files
    nnoremap ? :Rg<CR>

    " kyazdani42/nvim-tree.lua
    " https://github.com/kyazdani42/nvim-tree.lua

    nnoremap <C-n> :NERDTree<CR>
    nnoremap <C-t> :NERDTreeToggle<CR>
    nnoremap <leader>r :NERDTreeRefreshRoot<CR>
    nnoremap <leader>n :NERDTreeFocus<CR>
  ]])

  -- Make space more useful
  vim.keymap.set('n', '<space>', 'za')
  vim.keymap.set('n', 'R', '<cmd>source $MYVIMRC<cr>')
end

local loadLocals = function()
  vim.cmd.runtime('./locals/locals.vim')
end

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


loadPlugins()
loadMaps()
loadLocals()

vim.cmd.colorscheme('dracula')
