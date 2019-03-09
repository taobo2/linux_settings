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
set backup



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
    let strLen = strlen(a:str)
    if strLen <= a:len
        return a:str
    endif
    return '<' . strpart(a:str, strLen - a:len)
endfunction

function FileName()
    let currentfile = expand('%')
    let fileNameLen = strlen(currentfile)
    let status = TruncateStr(currentfile, winwidth(0)/3)
    return status
endfunction

function WorkingDir()
    let workingdir = getcwd()
    let leftSpaces = winwidth(0) * 2 / 3 - strlen(FileName())
    let status = TruncateStr(workingdir, leftSpaces)
    return status
endfunction

"set statusline=%.40F

"set statusline+=\ %1*%.40{getcwd()}%0* "set working directory

set statusline=%1*%{FileName()}%0*%2*\ %{WorkingDir()}
"Terminate User2 at the beginning of right-align status, so that User2 
"can be applied emptiness between this and right-align status.
"l means current line number; L means max line number.
set statusline+=%=%0*%1*%P%0*%2*[%l\ %c]%0*
"statusline shouldnot contain spaces, if spaces are required, a \ should
"before the space
"set spell
function SetBackupdir(dir)
    let l:backup = a:dir . "/vimbackup"
    if !isdirectory(l:backup)
        call mkdir(l:backup, "p")
    endif
    let &backupdir = l:backup . "//"

    let l:directory = a:dir . "/vimswp"
    if !isdirectory(l:directory)
        call mkdir(l:directory, "p")
    endif
    "The 'directory' option controls where swap files go
    let &directory = l:directory . "//"

    let l:undodir = a:dir . "/vimundo"
    if !isdirectory(l:undodir)
        call mkdir(l:undodir, "p")
    endif
    let &undodir = l:undodir . "//"
endfunction

if strlen($TEMP) > 0 
    call SetBackupdir($TEMP)
elseif strlen($TMPDIR) > 0
    call SetBackupdir($TMPDIR)
else
    call SetBackupdir("/tmp")
endif


filetype plugin indent on

"rename backupfile to contain full path info
autocmd BufWritePre * let &backupext = substitute(expand('%:p:h'), '/', '%', 'g')

command Wa :wa|!ant

"pathogen
"call pathogen#infect()



"autocmd FileType javascript set makeprg=jsl\ -nologo\ -nofilelisting\ -nosummary\ -nocontext\ -conf\ '/cygwin64/etc/jsl.conf'\ -process\ %
"autocmd FileType javascript set errorformat=%f(%l):\ %m
