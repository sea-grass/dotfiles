"More vim-plug tips on https://github.com/junegunn/vim-plug
call plug#begin('~/.vim/plugged')
" Make sure to use single quotes
Plug 'rosenfeld/conque-term'

" Conditional loading for specific plugins
Plug 'pangloss/vim-javascript', { 'for': ['js', 'html'] }
Plug 'JulesWang/css.vim', { 'for': ['css', 'html', 'js'] }
Plug 'fatih/vim-go', { 'for': ['go'] }
Plug 'StanAngeloff/php.vim', { 'for': ['php', 'html'] }
Plug 'lumiliet/vim-twig', { 'for': ['php', 'html'] }
Plug 'chase/vim-ansible-yaml', { 'for': ['yaml'] }

Plug 'scrooloose/syntastic'
"Plug 'starcraftman/vim-eclim'


" Syntastic suggested settings
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
Plug 'maksimr/vim-jsbeautify', { 'do': 'cd ~/.vim/bundle/vim-jsbeautify && git submodule update --init --recursive' }


call plug#end()

