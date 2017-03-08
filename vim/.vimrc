nnoremap <Space> za
nnoremap <Space> zf

nmap <Up> 5k
nmap <Down> 5j

nnoremap <Right> :bnext <Enter>
nnoremap <Enter> :bnext <Enter>
nnoremap <Left> :bprev <Enter>

set nu
set expandtab
set tabstop=2
set shiftwidth=2

" Highlight all search matches (:nohlsearch to turn off)
set hlsearch

" Set markdown syntax highlighting for *.md files
au BufNewFile,BufFilePre,BufRead *.md set filetype=markdown

" TODO: Come up with a way to conditionally load plugins
source ~/.vim/plugins
" Include config required by eclim
"source ~/.vim/eclim

" prevent auto commenting
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

" navigate between open buffers in normal mode

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
