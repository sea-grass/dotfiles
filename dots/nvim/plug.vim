call plug#begin()

Plug 'vimwiki/vimwiki'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'earthly/earthly.vim', { 'branch': 'main' }

Plug 'ziglang/zig.vim'

Plug 'dense-analysis/ale'
Plug 'neoclide/coc.nvim', { 'branch': 'release' }

Plug 'dracula/vim', { 'as': 'dracula' }

Plug 'kyazdani42/nvim-web-devicons'
Plug 'kyazdani42/nvim-tree.lua'

Plug 'tpope/vim-fugitive'

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

call plug#end()

runtime ./plugins/devicons.rc.vim
runtime ./plugins/nvim-tree.rc.vim
runtime ./plugins/vim-airline.rc.vim
runtime ./plugins/vimwiki.rc.vim