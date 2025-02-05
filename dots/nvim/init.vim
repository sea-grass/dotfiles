set nocompatible
set nu expandtab tabstop=2 shiftwidth=2
set mouse=
set colorcolumn=81

runtime ./plug.vim
runtime ./maps.vim
runtime ./locals/locals.vim

echom ">^.^<"

" Make space more useful
nnoremap <space> za

let curt = strftime("%H:%M")
let nighttime = curt > "18:00" || curt < "6:00"

if nighttime
  colorscheme tokyonight-night
else
  colorscheme tokyonight-day
endif

" keeps the terminal opacity of ghostty,
" but gets rid of all syntax highlighting...
" set notgc
