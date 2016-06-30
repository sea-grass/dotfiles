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

" Conditional loading for specific plugins
Plug 'pangloss/vim-javascript', { 'for': ['js', 'html'] }
Plug 'JulesWang/css.vim', { 'for': ['css', 'html', 'js'] }
Plug 'fatih/vim-go', { 'for': ['go'] }

Plug 'scrooloose/syntastic'

" Syntastic suggested settings
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
Plug 'maksimr/vim-jsbeautify', { 'do': 'git submodule update --init --recursive' }


call plug#end()

" prevent auto commenting
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
