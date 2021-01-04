set guioptions -=m "menu 
set guioptions -=T "toolbar
language en_US.utf8

if has("gui_win32")
    set guifont=Consolas:h11:cANSI "use this font to ANSI chars
endif

highlight StatusLine guifg=#545454 guibg=#66d9ef
highlight StatusLineNC gui=NONE guifg=white guibg=#545454
highlight StatusLineTermNC cterm=NONE guifg=white guibg=#545454

nmap <C-F2> <F21>
nmap <M-F2> <F22>
imap <M-F2> <F22>
tmap <M-F2> <F22>
nmap <C-F3> <F31>
imap <C-F3> <F31>
nmap <C-F5> <F15>
imap <C-F5> <F15>
"set pastetoggle=<M-F5>

"paste from clipboard with set paste mode, before current column
nnoremap <C-S-F5> :set paste<cr>"+P:set nopaste<cr>
