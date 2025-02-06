local vim = vim or {}
local Plug = require 'usermod.vimplug'

local loadPlugins = function()
  Plug.begin()

  Plug('vimwiki/vimwiki', {
    config = function()
      vim.cmd([[
      let g:vimwiki_list = [{'path': '~/vimwiki', 'path_html': '~/vimwiki_html'}]
      ]])
    end,
  })
  Plug('junegunn/fzf', {['do'] = vim.fn['fzf#install']})
  Plug 'junegunn/fzf.vim'
  Plug('earthly/earthly.vim', { branch= 'main' })

  Plug 'ziglang/zig.vim'
  Plug 'DingDean/wgsl.vim'
  Plug 'VaiN474/vim-etlua'

  Plug 'evanleck/vim-svelte'

  Plug 'pangloss/vim-javascript'
  Plug 'HerringtonDarkholme/yats.vim'
  Plug( 'mattn/emmet-vim', {
    config = function()
      vim.cmd.runtime('./plugins/emmet-vim.rc.vim')
    end,
  })

  Plug 'habamax/vim-godot'
  Plug('neoclide/coc.nvim', {
    branch= 'release',
    config = function()
      vim.cmd.runtime('./plugins/coc.rc.vim')
    end
  })

  --Plug 'williamboman/mason.nvim'
  --Plug 'williamboman/mason-lspconfig.nvim'
  --Plug 'neovim/nvim-lspconfig'
  Plug('dense-analysis/ale', {
    config = function()
      vim.cmd([[
      let b:ale_fixers = {'javascript': ['prettier', 'eslint'], 'typescript': ['prettier', 'eslint']}
      let g:ale_fix_on_save = 1
      ]])
    end,
  })

  Plug('dracula/vim', { as= 'dracula' })
  Plug('folke/tokyonight.nvim', { as= 'tokyonight' })

  Plug('preservim/nerdtree', {
    config = function()
      vim.cmd.runtime('./plugins/nerdtree.rc.vim')
    end,
  })

  Plug 'tpope/vim-fugitive'

  Plug('vim-airline/vim-airline', {
    config = function()
      vim.cmd([[
      let g:airline_theme='lucius'
      let g:airline#extensions#wordcount#filetypes = '\vwiki|md|txt'
      set laststatus=2 " enables vim-airline
      ]])
    end,
  })
  Plug 'vim-airline/vim-airline-themes'

  Plug 'tpope/vim-repeat'
  Plug('ggandor/leap.nvim', {
    config = function()
      vim.cmd.runtime('./plugins/leap.rc.lua')
    end,
  })

  Plug.ends()
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
