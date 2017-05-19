" Folds
nnoremap <Space> za
nnoremap <Space> zf

" Accelerated travel
nmap <Up> 5k
nmap <Down> 5j

" Navigate between open buffers in normal mode
nnoremap <Right> :bnext <Enter>
nnoremap <Enter> :bnext <Enter>
nnoremap <Left> :bprev <Enter>

" Disable arrow keys in insert mode
inoremap <Up> <NOP>
inoremap <Right> <NOP>
inoremap <Down> <NOP>
inoremap <Left> <NOP>

" Global format settings
set nu
set expandtab
set tabstop=2
set shiftwidth=2

" Highlight all search matches (:nohlsearch to turn off)
set hlsearch

" prevent auto commenting
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

" Set markdown syntax highlighting for *.md files
au BufNewFile,BufFilePre,BufRead *.md set filetype=markdown " TODO: Come up with a way to conditionally load plugins

" Python file format settings
autocmd BufRead *.py set smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class
autocmd BufRead *.py set nocindent
autocmd BufWritePre *.py normal m`:%s/\s\+$//e ``
au BufNewFile,BufRead *.py 
    \ set tabstop=2
"    \ set softtabstop=2
    \ set shiftwidth=2
    \ set textwidth=79
    \ set expandtab
    \ set autoindent
    \ set fileformat=unix
"au BufRead,BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/
autocmd BufNewFile,BufRead *.py 
    \ set foldmethod=indent

" Include plugins
source ~/.vim/plugins.vim

" Include config required by eclim
"source ~/.vim/eclim.vim
