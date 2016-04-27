set nocompatible
set nu
"set autoindent
set ignorecase smartcase
syntax on
set fileencoding=utf-8
set fileencodings=ucs-bom,utf-8,chinese,cp936
set ruler
colorscheme darkblue
set tabstop=4
set shiftwidth=4 "length for (auto)indent
set expandtab
"set omnifunc=syntaxcomplete#Complete
set backspace=2
set hlsearch
set incsearch
"autocmd InsertEnter * set cursorline cursorcolumn
"autocmd InsertLeave * set nocursorline nocursorcolumn
set cursorline cursorcolumn
set wildmenu
set history=1000
set ls=2
"path define where command (such as find) goes to find files, ** means all sub
"directories
set path+=./**



"curdir means save current dir in this session
"sesdir means when open the session, set current dir to session file's dir
set sessionoptions-=curdir
set sessionoptions+=sesdir


"expand('%') displays the relative path of the file being edit.
"":h means remove the last file name and file path separator.

" %t means File name(tail) of file in the buffer.
"
" The statusline syntax allows the use of 9 different hights in the statusline
" and ruler. The names are User1 to User9. %1* to switch to User1.%0* to
" switch to default
" %1*in%0* means use user1 color to word "in", then switch to the default color
"
" ctermfg is the front color for terminal vim.
highlight User1 ctermfg=green
"set statusline+=%t\ %1*in%0*\ %.10{fnamemodify(expand('%'),':h')}
".80 means the max length of %F (full path), truncate if needed
set statusline=%.40F

set statusline+=\ %1*%.40{getcwd()}%0* "set working directory
"l means current line number; L means max line number.
set statusline+=%=Col:%c
"set spell


set backupdir=/tmp
"The 'directory' option controls where swap files go
set directory=/tmp


filetype plugin indent on

"pathogen
"call pathogen#infect()



"autocmd FileType javascript set makeprg=jsl\ -nologo\ -nofilelisting\ -nosummary\ -nocontext\ -conf\ '/cygwin64/etc/jsl.conf'\ -process\ %
"autocmd FileType javascript set errorformat=%f(%l):\ %m
