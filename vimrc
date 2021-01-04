set nocompatible
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

cabbr <expr> %% expand('%:p:h')

set number relativenumber
augroup LineNumber
    autocmd!
    autocmd WinLeave * setlocal number norelativenumber
    autocmd WinEnter * setlocal number relativenumber
augroup END

set autoread
set backup
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

""""""""""""""""""""""""""""Bind Function Keys""""""""""
"F2
"********************* operations about jump ******************
"
"
" map <F2> and <S-F2> to jump between locations in a quickfix list, or
" differences if in window in diff mode
if $TERM_PROGRAM == 'Windows_Terminal' || !empty($WSLENV)
    set <S-F2>=[1;2Q
endif 

nnoremap <expr> <silent> <F2>   (&diff ? "]c" : ":cnext\<CR>")
nnoremap <expr>  <silent> <S-F2> (&diff ? "[c" : ":cprev\<CR>")

"A-F2
"toggle between current/last-accessed tabs
if !exists('g:lasttab')
  let g:lasttab = 1
endif

if $TERM_PROGRAM == 'Windows_Terminal' || !empty($WSLENV)
    set <F22>=[1;3Q
endif

nnoremap <silent> <F22> :exe "tabn ".g:lasttab<CR>
inoremap <silent> <F22> <esc>:exe "tabn ".g:lasttab<CR>
tnoremap <silent> <F22> <c-w>:exe "tabn ".g:lasttab<CR>
augroup tabjump
    autocmd!
    au TabLeave * let g:lasttab = tabpagenr()
augroup END

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
    set <F21>=[1;5Q
endif 

nnoremap <silent> <F21> :call ToggleWin()<cr>

"<Leader>F2
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

tnoremap <silent> <Leader><F2> <c-w>:let t:jumping=1<cr><c-w>p
nnoremap <silent> <Leader><F2> :let t:jumping=1<cr><c-w>p
inoremap <silent> <Leader><F2> <esc>:let t:jumping=1<cr>:let w:jumpmode='i'<cr><c-w>p
augroup windowjump
    autocmd!
    autocmd WinEnter * :call OnWinEnter()
augroup END

augroup navigateCode 
    autocmd!
    autocmd Filetype javascript setlocal suffixesadd=.js "for gf
augroup END

"F3
"====================operation about format code==================
"
"align code according to some letter
inoremap <F3>:  <C-o><S-v>{:AlignCol:<cr>
inoremap <F3>    <C-o><S-v>{:AlignCol=<cr>
inoremap <F3>:  <S-v>{:AlignCol:<cr>
inoremap <F3>    <S-v>{:AlignCol=<cr>
vnoremap <F3>: :AlignCol:<cr>
vnoremap <F3>  :AlignCol=<cr>

if $TERM_PROGRAM == 'Windows_Terminal' || !empty($WSLENV)
    set <S-F3>=[1;2R
endif 

inoremap <S-F3>:  <C-o><S-v>}:AlignCol:<cr>
inoremap <S-F3>    <C-o><S-v>}:AlignCol=<cr>
noremap <S-F3>:  <S-v>}:AlignCol:<cr>
noremap <S-F3>    <S-v>}:AlignCol=<cr>

"compact currentline's space
if $TERM_PROGRAM == 'Windows_Terminal' || !empty($WSLENV)
    set <F31>=[1;5R
endif 
noremap <F31> :call CompactLine()<cr>

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

"F5
"*************** insert code *****************
"
"F5
"default register history
nnoremap <silent> <F5> :call PopupRegHistory()<cr>

"<C-F5>
"paste from clipboard with set paste mode, after current column
if $TERM_PROGRAM == 'Windows_Terminal' || !empty($WSLENV)
    set <F15>=[15;5~
endif 
nnoremap <F15> :set paste<cr>"+p:set nopaste<cr>
inoremap <expr> <F15> col(".") == 1 ? '<esc>:set paste<cr>"+P:set nopaste<cr>a' : '<esc>:set paste<cr>"+p:set nopaste<cr>a' 


"<A-F5>
"toggle paste
if $TERM_PROGRAM == 'Windows_Terminal' || !empty($WSLENV)
    set <F16>=[15;3~
endif 


"********************* make ******************
augroup makeconfig
    autocmd!
    if executable('jshint')
        autocmd Filetype javascript compiler jshint
    elseif executable('wsl')
        let cmd = 'wsl jshint --verbose "$(wslpath '. "'%'" . ')"'
        let grepError = 'grep "(E"'
        let prefixName = 'while IFS= read -r l;do echo ' . "'%'~~" . '${l};done'
        autocmd Filetype javascript let &l:makeprg=cmd .'^\|'. grepError .'^\|' . prefixName
        autocmd Filetype javascript setlocal errorformat=%f~~%.%#:\ line\ %l\\,\ col\ %c\\,\ %m
    endif
    autocmd BufWritePost *.js silent make | redraw! | if ! empty(getqflist()) | copen | else | cclose | endif
augroup END

"********************* tags ******************
"./ is replaced with the path of the current file
set tags=./.tags;
augroup savetags
    autocmd!
    autocmd BufWritePost *.js,*.java call SaveTags(expand('<afile>:p:h'))
augroup end

function! SaveTags(dir)
    if !exists('g:SaveTagDirs') 
        let g:SaveTagDirs=[]
    endif

    if index(g:SaveTagDirs, a:dir) >= 0
        return
    endif

    function! RemoveTagJob(...) closure
        let index = g:SaveTagDirs->index(a:dir)
        if index >= 0
            call remove(g:SaveTagDirs, index)
        endif
    endfunction

    let options = { 'close_cb' : funcref('RemoveTagJob') }

    if has("gui_win32")
        let job = job_start('wsl cd $(wslpath "' . a:dir . '");ctags -o .tags *' , options)
    else
        let job = job_start('sh -c "cd ' . a:dir . '");ctags -o .tags *', options)
    endif

    call add(g:SaveTagDirs, a:dir)
endfunction

"********************** Indention and tabs *****************
set tabstop    =4 "the length of a tab char
set softtabstop=4 "affects what happens when you press the <TAB> or <BS> keys. 
set shiftwidth =4 "affects what happens when you press >>, << or ==. It also affects how automatic indentation works.
set expandtab

augroup set_indention
    autocmd!
    "autocmd Filetype javascript setlocal tabstop=2 | setlocal softtabstop=2 | setlocal shiftwidth=2
augroup END

"********************** set status bar *****************
function FileName()
    let infoes = systemlist('svn info "' . expand('%') .'"')

    if v:shell_error == 1 || !executable('svn')
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
highlight StatusLineTermNC cterm=bold ctermfg=white ctermbg=240
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
augroup end

"========================= Auto Complete ==========================================
"== path ==
function! PopRelativePath()
    autocmd CompleteDone * ++once call RevertRelativePath()
    let b:lastCwd = getcwd()
    exe 'lcd %:h'
    return "\<C-x>\<C-f>"
endfunction

function! RevertRelativePath()
    if exists('b:lastCwd')
        exe 'lcd ' . b:lastCwd
        unlet b:lastCwd
    endif
endfunction

inoremap <expr> <C-x><C-x> PopRelativePath()

"Auto Brace
function CC(...)
    if a:0 > 0
        let l:shift = a:1
    else
        let l:shift = 0
    endif
    let l:current = getline(".")[ col(".") - 1 + l:shift ]
    return l:current
endfunction

augroup autoBrace
    autocmd!
    autocmd FileType javascript,java,autohotkey inoremap <buffer> <expr> { CC() == "" \|\| stridx("}]);", CC()) >= 0 ? "{}<left>" : "{"
    autocmd FileType javascript,java,autohotkey inoremap <buffer> <expr> <cr> CC() == "}" ? "<cr><esc><S-O>" : "<cr>"
    autocmd FileType javascript,java,autohotkey inoremap <buffer> <expr> } CC() == "}" ? "<right>" : "}"
augroup end

"== separator == 
function! GetIdx(line, char, nth)
    let start = 0
    for i in range(a:nth)
        let index = a:line->stridx(a:char, start)
        if index  == -1
            return -1
        endif
        let start = index + 1
    endfor

    return a:line->stridx(a:char, start)
endfunction

function! AlignCol(separator) range
    let separator = a:separator
    let nth = 0
    while 1
        let lines = getline(a:firstline, a:lastline)
        if lines->len() <= 1
            return
        endif

        let cols = lines->map("GetIdx(v:val,'" . separator . "'," . nth . ")")

        let maxCol = cols->max()
        if maxCol == -1
            break
        endif

        for row in range(a:firstline, a:lastline)
            let col = cols[row - a:firstline]
            if col == -1
                continue
            endif  

            let spaces = maxCol - col
            if spaces == 0
                continue
            endif

            execute "normal " . row . "G" . (col + 1) . "|" . spaces . "i "
        endfor

        let nth = nth + 1
    endwhile
endfunction

command -range -nargs=1 AlignCol <line1>,<line2>call AlignCol(<q-args>)

" Compact line
function! CompactLine()
    let col = 0
    exe 'normal 0f '
    while col < col('.')
        exe "normal dwi \<esc>l"
        let col = col('.')
        exe 'normal f '
    endwhile
endfunction

"save yank items
let g:regHistory = []
let g:regSize = 100
augroup Yank
    autocmd!
    autocmd TextYankPost * if v:event.regname == '' | call SaveDefaultRegister(v:event.regcontents, v:event.regtype) | endif
augroup end

function! SaveDefaultRegister(contents, type)
    let empty = a:contents->copy()->map('v:val->empty()')->min()
    if empty
        return
    endif

    let elem = #{ content : a:contents, type : a:type }

    let g:regHistory = ([ elem ] + g:regHistory)[0:g:regSize - 1]
endfunction

function! PopupRegHistory()
    if g:regHistory->len() == 0
        return
    endif

    let menuItems = g:regHistory->copy()
                \->map('v:val.content->len() == 1 ? v:val.content[0] : v:val.content[0] . " ..."')
    call popup_menu(menuItems, #{ callback : 'OnRegSelected' })
endfunction

function! OnRegSelected(id, result)
    if a:result == -1
        return
    endif

    let elem = g:regHistory[a:result - 1]
    call setreg('', elem.content, elem.type)
    exe 'normal p'
endfunction

