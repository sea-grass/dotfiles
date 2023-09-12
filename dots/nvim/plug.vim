call plug#begin()

Plug 'vimwiki/vimwiki'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'earthly/earthly.vim', { 'branch': 'main' }

Plug 'ziglang/zig.vim'

Plug 'evanleck/vim-svelte'

Plug 'pangloss/vim-javascript'
Plug 'HerringtonDarkholme/yats.vim'
Plug 'mattn/emmet-vim'

Plug 'habamax/vim-godot'

Plug 'dense-analysis/ale'
Plug 'neoclide/coc.nvim', { 'branch': 'release' }

Plug 'dracula/vim', { 'as': 'dracula' }

Plug 'preservim/nerdtree'

Plug 'tpope/vim-fugitive'

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'tpope/vim-repeat'
Plug 'ggandor/leap.nvim'

call plug#end()

runtime ./plugins/vim-airline.rc.vim
runtime ./plugins/vimwiki.rc.vim
runtime ./plugins/coc.rc.vim
runtime ./plugins/emmet-vim.rc.vim
runtime ./plugins/nerdtree.rc.vim
runtime ./plugins/leap.rc.lua
