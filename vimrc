set nocompatible
"set nu
"set autoindent
set ignorecase smartcase
syntax on
set fileencoding=utf-8
set fileencodings=ucs-bom,utf-8,chinese,cp936
set ruler
colorscheme koehler
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

filetype on "auto check file type
filetype plugin on 
filetype plugin indent on


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
"highlight StatusLine ctermfg=Black ctermbg=yellow guifg=Black guibg=yellow cterm=bold 
"highlight User1 ctermfg=DarkRed guifg=DarkRed ctermbg=yellow guibg=yellow cterm=bold gui=bold
"highlight User2 ctermfg=darkblue guifg=darkblue ctermbg=yellow guibg=yellow cterm=bold gui=bold
"for non current window statusline
"Differences in User1/User2 with StatusLine overwrites corresponding settings
"in StatusLineNC
"highlight StatusLineNC ctermfg=white ctermbg=grey cterm=bold guifg=white guibg=grey gui=NONE

"for terminal window
"highlight StatusLineTerm ctermfg=Black ctermbg=yellow guibg=yellow cterm=bold 
"highlight StatusLineTermNC ctermbg=240 cterm=bold 

"for wildmenu
"highlight WildMenu ctermfg=White ctermbg=Black

"set statusline+=%t\ %1*in%0*\ %.10{fnamemodify(expand('%'),':h')}
".80 means the max length of %F (full path), truncate if needed
function TruncateStr(str, len)
    let strLen = strlen(a:str)
    if strLen <= a:len
        return a:str
    endif
    return '<' . strpart(a:str, strLen - a:len)
endfunction

"function FileName()
"    let currentfile = expand('%')
"    let fileNameLen = strlen(currentfile)
"    let status = TruncateStr(currentfile, winwidth(0)/3)
"    return status
"endfunction

function WorkingDir()
    let workingdir = getcwd()
    let leftSpaces = winwidth(0) * 2 / 3 - strlen(FileName())
    let status = TruncateStr(workingdir, leftSpaces)
    return status
endfunction

"set statusline=%.40F

"set statusline+=\ %1*%.40{getcwd()}%0* "set working directory

"set statusline=%1*%{FileName()}%0*%2*\ %{WorkingDir()}
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
"**************************** operations about jump ******************
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

augroup navigateCode 
    autocmd!
    autocmd Filetype javascript setlocal suffixesadd=.js "for gf
augroup END

"F4
"*********************** operations about fold ******************
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


"********************** Indention and tabs *****************
set tabstop=4 "the length of a tab char
set softtabstop=4 "affects what happens when you press the <TAB> or <BS> keys. 
set shiftwidth=4 "affects what happens when you press >>, << or ==. It also affects how automatic indentation works.
set expandtab

augroup set_indention
    autocmd!
    autocmd Filetype javascript setlocal tabstop=2 | setlocal softtabstop=2 | setlocal shiftwidth=2
augroup END

"********************** set status bar *****************
function FileName()
    let infoes = systemlist('svn info ' . expand('%'))

    if v:shell_error == 1
        return expand('%:t') "t means tail, which is filename
    endif

    return strpart(infoes[4], stridx(infoes[4], '^'))
endfunction

let g:statusFileNames = {}

function StatusLeftPart()
    if !has_key(g:statusFileNames, expand('%:p'))
        let g:statusFileNames[expand('%:p')] = FileName() "cache, FileName is slow
    endif
    
    let name = g:statusFileNames[expand('%:p')]
    if len(name) + 30 > winwidth(0)
        return strpart(name, 0, winwidth(0) - 30 - 4 - len(expand('%:t'))) . '.../' . expand('%:t')
    elseif len(name) + len(getcwd()) + 30 > winwidth(0) 
        return name
    endif

    return name . '  ' . getcwd()
endfunction

highlight StatusLine cterm=bold ctermfg=240 ctermbg=81
highlight StatusLineNC cterm=bold ctermfg=white ctermbg=240
"%t means name of the current file
"set statusline=%1*%t%0*%2*\ %{getcwd()}
set statusline=%{StatusLeftPart()}

"Terminate User2 at the beginning of right-align status, so that User2 
"can be applied emptiness between this and right-align status.
"l means current line number; L means max line number.
"set statusline+=%=%0*%1*%P%0*%2*[%l\ %c]%0*
set statusline+=%=\ \ %P[%l\ %c]%m
"statusline shouldnot contain spaces, if spaces are required, a \ should
"before the space

augroup statusBar
    autocmd!
    autocmd BufReadPre * silent! unlet g:statusFileNames[expand('%:p')]
    autocmd BufDelete * silent! unlet g:statusFileNames[expand('%:p')]
    autocmd InsertEnter * silent! lcd %:h    " when new empty file, there are errors to silent
    autocmd InsertLeave * silent! lcd -
augroup end



"********************** Recent Tabs *****************
function CreateRecentWindow()
    if !exists("t:recentBufs") || t:recentBufs != 1
        let buffers = tabpagebuflist()->filter('index(g:recentBufs_visitBufList, v:val)<0') + g:recentBufs_visitBufList
        exe "tabnew %" 
        let g:recentBufs_visitBufList = buffers
        let t:recentBufs = 1
    endif

    let winNr = winnr()

    if winnr('$') % (&columns / 80) == 0
        exe "noautocmd botright split"
    else
        exe "noautocmd ". winnr('$') . "wincmd w"
        exe "noautocmd vsplit"
    endif
    
    exe "noautocmd ". winNr ."wincmd w"

    call UpdateRecentLayout()
endfunction

function DeleteRencentWindow()
    if gettabvar(tabpagenr(), 'recentBufs', '') != 1
        return
    endif
    let winNr = winnr()

    exe "noautocmd ". winnr('$') . "wincmd w"
    exe "noautocmd close"

    exe "noautocmd ". winNr ."wincmd w"

    call UpdateRecentLayout()
endfunction

function RecordBufVisit()
    let existIdx = index(g:recentBufs_visitBufList, bufnr('%'))
    if existIdx > -1
        call remove(g:recentBufs_visitBufList, existIdx) "If a function is used alone, prefix it with call. It is to distinguish with ex-command introduced by vi and ed
    endif

    call add(g:recentBufs_visitBufList, bufnr('%'))
endfunction

function UpdateRecentLayout()
    let buf2Open = Buf2Open()

    let winNr = winnr()


    for buf in buf2Open
        exe 'noautocmd ' . WinNr2Replace() . 'wincmd w'
        exe 'noautocmd b' . buf
    endfor
    exe "noautocmd ". winNr . "wincmd w"
endfunction

function Buf2Open()
    return g:recentBufs_visitBufList[ max([-len(g:recentBufs_visitBufList), -winnr('$')]):-1 ]
                \->filter('tabpagebuflist()->index(v:val) < 0')
                \->reverse()
endfunction

function WinNr2Replace()

    let wins = range(1, winnr('$'))->sort("RecentVisitLast")

    return wins[0]
endfunction

function RecentVisitLast(a, b)
    if winnr() == a:a
        return 1
    elseif winnr() == a:b
        return -1
    endif

    if winbufnr(a:a) == winbufnr(a:b)
        return a:b - a:a
    endif

    let aIsEdit = winbufnr(winnr()) == winbufnr(a:a)
    let aRepeat = aIsEdit || range(1, a:a - 1)->map('winbufnr(v:val)')->index(winbufnr(a:a)) >= 0
    let bIsEdit = winbufnr(winnr()) == winbufnr(a:b)
    let bRepeat = bIsEdit || range(1, a:b - 1)->map('winbufnr(v:val)')->index(winbufnr(a:b)) >= 0
    if aRepeat != bRepeat
        return bRepeat - aRepeat
    endif

    let result = index(g:recentBufs_visitBufList, winbufnr(a:a)) - index(g:recentBufs_visitBufList, winbufnr(a:b))
    return result
endfunction

function RemoveDeleteBuf(buf)
    return g:recentBufs_visitBufList->filter('v:val!=' . a:buf)
endfunction

nnoremap <F6> :call CreateRecentWindow()<cr>
nnoremap <S-F6> :call DeleteRencentWindow()<cr>

let g:recentBufs_visitBufList = []

augroup recentBufsGroup
    autocmd!

    autocmd BufEnter *  call RecordBufVisit() 

    "Called when a buffer is shown in a window
    autocmd BufWinEnter *  call RecordBufVisit() | if gettabvar(tabpagenr(), 'recentBufs', '') == 1 | call UpdateRecentLayout() | endif

    autocmd BufDelete * call RemoveDeleteBuf(expand('<abuf>'))

augroup end

"====================== Jdb ========================
"
function Jdb()
    tabnew /tmp/db/Test.java
    let g:javacBuf = term_start('javac -g /tmp/db/Test.java', { 'term_name' : 'javac db.Test', 'exit_cb' : 'JavacExit' })
endfunction

function Jdb1()
    call term_start('jdb -sourcepath /tmp/ -classpath /tmp/ Add', { 'out_io' : 'buffer', 'out_name' : 'mybuffer' })
endfunction

let g:lastCursorRow = 0
let g:lastCommand = ''
let g:executeCommand = ''
let g:inWhereOutput = 0
let g:jdbBuf = 0
let g:javacBuf = 0
let g:jWord = '[^ .(;]\+'
let g:package = 'package'
let g:packagePart = '\(' . jWord . '\|\.\)'
let g:oneLineComment = '//.*'
let g:mlCommentHead = '/\*'
let g:mlCommentTail = '.\{-}\*/'
let g:colon = ';'

function JavacExit(job, status)
    if a:status 
        return
    endif
    
    let winnr = range(1, winnr('$'))->map('winbufnr(v:val)')->index(g:javacBuf) + 1
    exe 'noautocmd ' . winnr . 'wincmd c'
    
    call term_start('java -agentlib:jdwp=transport=dt_socket,address=8000,server=y -classpath /tmp/ db.Test', { 'term_name' : 'db.Test' })
    sleep 2
    let g:jdbBuf = term_start('jdb -sourcepath /tmp/ -attach 8000', { 'term_name' : 'JDB', 'out_cb' : function('Output') })
endfunction

function Output(chan, msg)
    "echom '=========================================================='
    "echom 'msg ' . a:msg
    let prompt = '\(>\|[^[ ]\+\[\d\+\]\)'
    let promptReg = '^' . prompt . '\(\s' . prompt . '\)*'

    for row in range(g:lastCursorRow + 1, term_getcursor(g:jdbBuf)[0] - 1 + term_getscrolled(g:jdbBuf))
        let g:lastCursorRow = row 
        if term_getcursor(g:jdbBuf)[0] - row < term_getsize(g:jdbBuf)[0] 
            let l = term_getline(g:jdbBuf, row - term_getscrolled(g:jdbBuf)) "can only get last term_size rows
        else
            let l = getbufline(g:jdbBuf, row) "cursor row may not be in buffer at this time
        endif

        let jWord = g:jWord
        let jClass = '\(\(' . jWord . '\.\)*'. jWord . '\)'
        let jMethod = '[^.(]\+()'
        let lineRegex = 'line=\(\d\+\)'
        let tail = 'bci='
        let hitPattern =  jClass . '\.' . jMethod . ',\s\+' . lineRegex . '\s\+' . tail
        let hitMatched = matchlist(l, hitPattern)
        if len(hitMatched)>0
            echom hitMatched
        endif

        let wherePattern = '\[\d\+\]\s\+' . jClass . '\.' . jWord . '\s\+(\([^:]\+\):\(\d\+\)'
        let whereMatched = matchlist(l, wherePattern)
        if len(whereMatched) > 0 
            if !g:inWhereOutput 
                let g:inWhereOutput = 1
                echom whereMatched
            endif
        else
            let g:inWhereOutput = 0
        endif
    endfor
    if term_getline(g:jdbBuf, '.') =~ promptReg . '\s*$' 
        echom 'wait for input...'
        if g:executeCommand == ''
            let executeCommand = g:executeCommand
            let g:executeCommand = ''
            "call term_sendkeys(g:jdbBuf, executeCommand)
        endif
    endif

endfunction

function Package(...)
    let buf = get(a:, 1, bufnr())
    if bufname(buf) !~ '\.java$'
        return -1
    endif
    
    let lines = getbufline(buf, 1, '$')
    let row = 0
    let package = ''
    while row < len(lines)
        let col = 0
        while col < len(lines[row])
            if matchlist(lines[row], '^' . g:mlCommentHead, col)->len() > 0
                let [row, col] = ProcessMultLineComment(lines, row, col + 2)
            elseif matchlist(lines[row], '^' . g:oneLineComment, col)->len() > 0 
                break
            elseif matchlist(lines[row], '^' . g:package, col)->len() > 0
                let col = col + 7
            elseif matchlist(lines[row], '^' . g:packagePart, col)->len() > 0
                let matchResult = matchlist(lines[row], g:packagePart, col)
                let package = package . matchResult[0]
                let col = col + len(matchResult[0])
            elseif matchlist(lines[row], '^' . g:colon, col)->len() > 0
                let row = len(lines)
                break
            else
                let col = col + 1
            endif
        endwhile
        let row = row + 1
    endwhile
    return package
endfunction

function ProcessMultLineComment(lines, row, col)
    let singleLineMatch = matchlist(a:lines[a:row], '^'.g:mlCommentTail, a:col)
    if len(singleLineMatch) > 0
        return [a:row, a:col + len(singleLineMatch[0])]
    endif
    
    let row = a:row + 1
    while row < len(a:lines)
        let matchResult = matchlist(a:lines[row], g:mlCommentTail)
        if len(matchResult) > 0
            return [row, matchResult[0]->len()]
        else
            let row = row + 1
        endif
    endwhile
endfunction

function FindBetween(list, startReg, endReg)
    let startMatches = range(0, len(list) - 1)->filter('list[v:val]=~startReg')
    if len(startMatches) == 0
        return ''
    endif

    let endMatches = range(startMatches[0], len(list) - 1)->filter('list[v:val]=~endReg')
    if len(endMatches) == 0
        return ''
    endif

    return list[startMatches[0]:endMatches[0]]
endfunction
