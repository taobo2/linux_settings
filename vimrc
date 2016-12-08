set nocompatible
"set nu
"set autoindent
set ignorecase smartcase
syntax on
set fileencoding=utf-8
set fileencodings=ucs-bom,utf-8,chinese,cp936
set ruler
colorscheme elflord
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
set history=10000
set ls=2
"path define where command (such as find) goes to find files, ** means all sub
"directories
set path+=./**
set relativenumber
set autoread



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
highlight StatusLine ctermbg=black guibg=black
highlight User1 ctermfg=white ctermbg=blue guifg=white guibg=blue
highlight User2 ctermfg=black ctermbg=yellow guifg=black guibg=yellow
"set statusline+=%t\ %1*in%0*\ %.10{fnamemodify(expand('%'),':h')}
".80 means the max length of %F (full path), truncate if needed
function TruncateStr(str, len)
    let a:strLen = strlen(a:str)
    if a:strLen <= a:len
        return a:str
    endif
    return '<' . strpart(a:str, a:strLen - a:len)
endfunction

function FileName()
    let a:currentfile = expand('%')
    let a:fileNameLen = strlen(a:currentfile)
    let a:status = TruncateStr(a:currentfile, winwidth(0)/3)
    return a:status
endfunction

function WorkingDir()
    let a:workingdir = getcwd()
    let a:leftSpaces = winwidth(0) * 2 / 3 - strlen(FileName())
    let a:status = TruncateStr(a:workingdir, a:leftSpaces)
    return a:status
endfunction

"set statusline=%.40F

"set statusline+=\ %1*%.40{getcwd()}%0* "set working directory

set statusline=%1*%{FileName()}%0*%2*\ %{WorkingDir()}%0*
"l means current line number; L means max line number.
set statusline+=%=%1*%P%0*%2*[%l\ %c]%0*
"statusline shouldnot contain spaces, if spaces are required, a \ should
"before the space
"set spell

if strlen($TEMP) > 0 
    set backupdir=$TEMP
    set directory=$TEMP
elseif strlen($TMPDIR) > 0
    set backupdir=$TMPDIR
    set directory=$TMPDIR
else
    set backupdir=/tmp
    "The 'directory' option controls where swap files go
    set directory=/tmp
endif


filetype plugin indent on


command Wa :w|!an

"pathogen
"call pathogen#infect()



"autocmd FileType javascript set makeprg=jsl\ -nologo\ -nofilelisting\ -nosummary\ -nocontext\ -conf\ '/cygwin64/etc/jsl.conf'\ -process\ %
"autocmd FileType javascript set errorformat=%f(%l):\ %m
