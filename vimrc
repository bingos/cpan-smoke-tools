set number
syntax on
set statusline=%t\ %y\ format:\ %{&ff};\ [%c,%l]
set laststatus=2
au BufNewFile,BufRead *.t                     setf perl
highlight perlComment ctermfg=Green guifg=Green
highlight confComment ctermfg=Green guifg=Green
highlight ExtraWhitespace ctermbg=red guibg=red
set expandtab
set tabstop=2
autocmd Syntax * syn match ExtraWhitespace /\s\+$\| \+\ze\t/ containedin=ALL

" autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
" autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
" autocmd InsertLeave * match ExtraWhitespace /\s\+$/
