set guioptions -=m "menu 
set guioptions -=T "toolbar
language en_US.utf8

if has("gui_win32")
    set guifont=Consolas:h11:cANSI "use this font to ANSI chars
endif

highlight StatusLine guifg=#545454 guibg=#66d9ef
highlight StatusLineNC gui=NONE guifg=white guibg=#545454
highlight StatusLineTermNC cterm=NONE guifg=white guibg=#545454
