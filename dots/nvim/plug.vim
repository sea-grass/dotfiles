call plug#begin()

Plug 'vimwiki/vimwiki'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'earthly/earthly.vim', { 'branch': 'main' }

Plug 'ziglang/zig.vim'
Plug 'DingDean/wgsl.vim'

Plug 'evanleck/vim-svelte'

Plug 'pangloss/vim-javascript'
Plug 'HerringtonDarkholme/yats.vim'
Plug 'mattn/emmet-vim'

Plug 'habamax/vim-godot'

"Plug 'williamboman/mason.nvim'
"Plug 'williamboman/mason-lspconfig.nvim'
"Plug 'neovim/nvim-lspconfig'
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug 'dense-analysis/ale'

Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'folke/tokyonight.nvim', { 'as': 'tokyonight' }

Plug 'preservim/nerdtree'

Plug 'tpope/vim-fugitive'

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'tpope/vim-repeat'
Plug 'ggandor/leap.nvim'

call plug#end()

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
