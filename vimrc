set nocompatible
"set nu
"set autoindent
set ignorecase smartcase
syntax on
set fileencoding=utf-8
set fileencodings=ucs-bom,utf-8,chinese,cp936
set ruler
colorscheme koehler
set tabstop=4
set shiftwidth=4 "length for (auto)indent
set expandtab
"set omnifunc=syntaxcomplete#Complete
set backspace=2
set hlsearch
set incsearch
"autocmd InsertEnter * set cursorline cursorcolumn
"autocmd InsertLeave * set nocursorline nocursorcolumn
"set cursorline cursorcolumn
set wildmenu
set history=10000
set ls=2
"path define where command (such as find) goes to find files, ** means all sub
"directories
set path+=./**
set relativenumber
set autoread
set backup
"./ is replaced with the path of the current file
set tags+=./.tags;
set pastetoggle=<F6>
"allow hide modified buffer
set hidden

set guioptions-=L "turn off left scroll bar
set guioptions-=r "turn off right scroll bar


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
" cterm is for the terminal with color; bold atrribute may be removed by
" ctermfg in some terminal, put it at the end
highlight StatusLine ctermfg=Black ctermbg=yellow guifg=Black guibg=yellow cterm=bold 
highlight User1 ctermfg=DarkRed guifg=DarkRed ctermbg=yellow guibg=yellow cterm=bold gui=bold
highlight User2 ctermfg=darkblue guifg=darkblue ctermbg=yellow guibg=yellow cterm=bold gui=bold
"for non current window statusline
"Differences in User1/User2 with StatusLine overwrites corresponding settings
"in StatusLineNC
highlight StatusLineNC ctermfg=white ctermbg=grey cterm=bold guifg=white guibg=grey gui=NONE

"for terminal window
highlight StatusLineTerm ctermfg=Black ctermbg=yellow guibg=yellow cterm=bold 
highlight StatusLineTermNC ctermbg=240 cterm=bold 

"for wildmenu
highlight WildMenu ctermfg=White ctermbg=Black

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

"set statusline=%1*%{FileName()}%0*%2*\ %{WorkingDir()}
"%t means name of the current file
"set statusline=%1*%t%0*%2*\ %{getcwd()}
set statusline=%t\ \ %{getcwd()}

"Terminate User2 at the beginning of right-align status, so that User2 
"can be applied emptiness between this and right-align status.
"l means current line number; L means max line number.
"set statusline+=%=%0*%1*%P%0*%2*[%l\ %c]%0*
set statusline+=%=\ \ %P[%l\ %c]%m
"statusline shouldnot contain spaces, if spaces are required, a \ should
"before the space
"
"add current split window index
"set statusline+=%1*win\ %{winnr()}%0* 
"add modified flag
"set statusline+=%1*%m%0*
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
augroup backup
    autocmd!
    autocmd BufWritePre * let &backupext = substitute(expand('%:p:h'), '/', '%', 'g')
augroup END

"command Wa :wa|!ant

function CC(...)
    if a:0 > 0
        let l:shift = a:1
    else
        let l:shift = 0
    endif
    let l:current = getline(".")[ col(".") - 1 + l:shift ]
    return l:current
endfunction

augroup autocode
    autocmd!
    autocmd FileType javascript,java inoremap <buffer> <expr> ( CC() == "" \|\| stridx("}]);", CC()) >= 0 ? "()<left>" : "("
    autocmd FileType javascript,java inoremap <buffer> <expr> [ CC() == "" \|\| stridx("}]);", CC()) >= 0 ? "[]<left>" : "["
    autocmd FileType javascript,java inoremap <buffer> <expr> { CC() == "" \|\| stridx("}]);", CC()) >= 0 ? "{}<left>" : "{"
    autocmd FileType javascript,java inoremap <buffer> <expr> ' CC() == "" \|\| stridx("}]);\"", CC()) >= 0 ? "''<left>" : CC() == "'" ? "<right>" : "'"
    autocmd FileType javascript,java inoremap <buffer> <expr> " CC() == "" \|\| stridx("}]);'", CC()) >= 0 ? "\"\"<left>" : CC() == "\"" ? "<right>" : "\""
    autocmd FileType javascript,java inoremap <buffer> <expr> <cr> CC() == "}" ? "<cr><esc><S-O>" : "<cr>"

    autocmd FileType javascript,java inoremap <buffer> <expr> ) CC() == ")" ? "<right>" : ")"
    autocmd FileType javascript,java inoremap <buffer> <expr> ] CC() == "]" ? "<right>" : "]"
    autocmd FileType javascript,java inoremap <buffer> <expr> } CC() == "}" ? "<right>" : "}"
augroup END

"update all windows' statuslines when creating a new window
augroup statusupdate
    autocmd!
    autocmd WinEnter * :redraws!
augroup END


"function OnWinEnter()
"    if exists("t:jumping") && t:jumping
"        unlet t:jumping 
"        if exists("w:jumpmode") && w:jumpmode == "i"
"            startinsert
"        endif
"    endif
"
"    if exists("w:jumpmode")
"        unlet w:jumpmode
"    endif
"endfunction
"
""toggle between current/last-accessed windows
"tnoremap <silent> <F3> <c-w>:let t:jumping=1<cr><c-w>p
"nnoremap <silent> <F3> :let t:jumping=1<cr><c-w>p
"inoremap <silent> <F3> <esc>:let t:jumping=1<cr>:let w:jumpmode='i'<cr><c-w>p
"augroup windowjump
"    autocmd!
"    autocmd WinEnter * :call OnWinEnter()
"augroup END

"toggle between current/last-accessed tabs
if !exists('g:lasttab')
  let g:lasttab = 1
endif

nnoremap <silent> <F2> :exe "tabn ".g:lasttab<CR>
inoremap <silent> <F2> <esc>:exe "tabn ".g:lasttab<CR>
tnoremap <silent> <F2> <c-w>:exe "tabn ".g:lasttab<CR>
augroup tabjump
    autocmd!
    au TabLeave * let g:lasttab = tabpagenr()
augroup END

if $TERM_PROGRAM == "Apple_Terminal"
    set <S-F5>=[25~
endif
" map <F5> and <S-F5> to jump between locations in a quickfix list, or
" differences if in window in diff mode
nnoremap <expr> <silent> <F5>   (&diff ? "]c" : ":cnext\<CR>")
nnoremap <expr>  <silent> <S-F5> (&diff ? "[c" : ":cprev\<CR>")

""""""""""Bind Function Keys""""""""""
"F2
"operations about jump 
"
"C-F2
"max a window(jump to a new tab which only contains current window content)

function ToggleWin()
    if exists("b:originWin")
        execute "tabc"
        let success = win_gotoid(b:originWin)
        unlet b:originWin
    else
        let b:originWin = win_getid()
        execute "tab split"
    endif
endfunction

if $TERM_PROGRAM == 'Windows_Terminal' || !empty($WSLENV)
    set <F22>=[1;5Q
else
    set <F22>=<C-F2>
endif 

nnoremap <silent> <F22> :call ToggleWin()<cr>

"S-F2
"toggle between current/last-accessed windows

function OnWinEnter()
    if exists("t:jumping") && t:jumping
        unlet t:jumping 
        if exists("w:jumpmode") && w:jumpmode == "i"
            startinsert
        endif
    endif

    if exists("w:jumpmode")
        unlet w:jumpmode
    endif
endfunction

if $TERM_PROGRAM == 'Windows_Terminal' || !empty($WSLENV)
    set <F32>=[1;2Q
else
    set <F32>=<S-F2>
endif 

tnoremap <silent> <F32> <c-w>:let t:jumping=1<cr><c-w>p
nnoremap <silent> <F32> :let t:jumping=1<cr><c-w>p
inoremap <silent> <F32> <esc>:let t:jumping=1<cr>:let w:jumpmode='i'<cr><c-w>p
augroup windowjump
    autocmd!
    autocmd WinEnter * :call OnWinEnter()
augroup END

"F4
"operations about fold
"
"F4
"fold contents in { .. }
set foldmethod=manual

"| needs to be transformed by \, <cr> is importatnt to trigger the command"
function ToggleFold()
    let l:currentLine = line('.')

    let w:folded = 0
    execute "folddoclosed let w:folded = 1"

	if w:folded == 0
        execute "normal vi{\<esc>\<cr>"
        execute "'<,'>g/{/exe \"if foldclosed(line('.')) == -1 \| normal! f{zf% \| endif\""
	else
		normal! zR
    endif

    execute l:currentLine
endfunction
nnoremap <silent> <F4> :call ToggleFold()<cr>

"F3
"operation about format code
"
"F3
"align code according to some letter
vnoremap <silent> <F3>= :!column -t -s '=' -o '='<cr>
vnoremap <silent> <F3>: :!column -t -s ':' -o ':'<cr>
vnoremap <silent> <F3><Space> :!column -t -s ' ' -o ' '<cr>

"********************* make ******************
augroup makeconfig
    autocmd!
    autocmd Filetype javascript setlocal makeprg=jshint\ --verbose\ %\\\|grep\ '(E'
    autocmd Filetype javascript setlocal errorformat=%f:\ line\ %l\\,\ col\ %c\\,\ %m
    autocmd BufWritePost *.js silent make | redraw! | if ! empty(getqflist()) | copen | else | cclose | endif
augroup END

