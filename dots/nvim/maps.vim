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

" kyazdani42/nvim-tree.lua
" https://github.com/kyazdani42/nvim-tree.lua

nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <leader>r :NERDTreeRefreshRoot<CR>
nnoremap <leader>n :NERDTreeFocus<CR>
