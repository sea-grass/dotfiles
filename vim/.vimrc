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

" prevent auto commenting
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

" navigate between open buffers in normal mode
nmap <Up> :bfirst <Enter>
nmap <Right> :bnext <Enter>
nmap <Down> :blast <Enter>
nmap <Left> :bprev <Enter>
