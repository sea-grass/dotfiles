set nu
set expandtab
set tabstop=2
"For some reason, this let statement wasn't working.
"Maybe let sets the local value?
"let shiftwidth = &tabstop
set shiftwidth=2

" Highlight all search matches (:nohlsearch to turn off)
set hlsearch

" Enable scrolling in vim for urxvt
" Aaaaactually, don't. When you click in the terminal moves the
" cursor position, and I don't like that.
" set mouse=a

"More vim-plug tips on https://github.com/junegunn/vim-plug
call plug#begin('~/.vim/plugged')

" Make sure to use single quotes
Plug 'rosenfeld/conque-term'

" Only load vim-javascript when js or html file is opened
Plug 'pangloss/vim-javascript', { 'for': ['js', 'html'] }

Plug 'JulesWang/css.vim', { 'for': ['css', 'html', 'js'] }

" Only load vim-go when go file is opened
Plug 'fatih/vim-go', { 'for': ['go'] }

Plug 'maksimr/vim-jsbeautify', { 'do': 'git submodule update --init --recursive' }


call plug#end()

" prevent auto commenting
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o