"====================== Jdb ========================
"
function! Jdb()
    tabnew /tmp/db/Test.java
    let JavacExit = function('s:JavacExit')
    let t:javacBuf = term_start('javac -g /tmp/db/Test.java', { 'term_name' : 'javac db.Test', 'exit_cb' : JavacExit  })
endfunction

function! Jdb1()
    call term_start('jdb -sourcepath /tmp/ -classpath /tmp/ Add', { 'out_io' : 'buffer', 'out_name' : 'mybuffer' })
endfunction

let s:jWord = '[^ .(;$]\+'
let s:package = 'package'
let s:packagePart = '\(' . s:jWord . '\|\.\)'
let s:oneLineComment = '//.*'
let s:mlCommentHead = '/\*'
let s:mlCommentTail = '.\{-}\*/'
let s:colon = ';'
let s:lambdaMethod = 'lambda[$]' . s:jWord . '$' . s:jWord
let s:prompt = '\(>\|[^[ ]\+\[\d\+\]\)'

function! s:JavacExit(job, status)
    if a:status 
        return
    endif
    
    let winnr = range(1, winnr('$'))->map('winbufnr(v:val)')->index(t:javacBuf) + 1
    exe 'noautocmd ' . winnr . 'wincmd c'
    
    let t:javaBuf = term_start('java -agentlib:jdwp=transport=dt_socket,address=8000,server=y -classpath /tmp/ db.Test', { 'term_name' : 'db.Test' })
    sleep 2
    let t:jdbBuf = term_start('jdb -sourcepath /tmp/ -attach 8000', { 'term_name' : 'JDB', 'out_cb' : function('s:Output') })
endfunction

function! s:MatchOutput(lines, stats)
    let row = 0
    while row < a:lines.len()
        let beforeRow = row

        for s in a:stats
            let row = s:MatchLines(a:lines, row, s)
            if s:isMatchSucceed(s)
                break
            endif
        endfor
        
        if beforeRow == row
            let row = row + 1
        endif
    endwhile
endfunction

function! s:MatchLines(lines, start, stat)
    let row = a:start
    while row < a:lines.len()
        let line = a:lines.get(row)
        echom 'match lines '. line
        let matchToCol = a:stat.match(line)
        if s:isMatchSucceed(a:stat)
            if exists('a:stat.onSucceed')
                call a:stat['onSucceed']()
            endif
            if matchToCol == 0
                return row
            else
                return row + 1
            endif
        elseif s:isMatchFail(a:stat)
            if exists('a:stat.onFail')
                call a:stat['onFail']()
            endif
            return a:start
        endif
        let row = row + 1
    endwhile

    if s:isMatching(a:stat)
        if exists('a:stat.onFail')
            call a:stat.onFail()
        endif
        return a:start
    endif

    return row
endfunction

function s:newLines(start, end)
    let lines = {}
    function! lines.len() closure
        return a:end - a:start + 1    
    endfunction

    function! lines.get(row) closure
        return s:GetOutputLine(a:row + a:start)
    endfunction

    function! lines.toString()
        let list = []
        let row = 0
        while row < self.len()
            call add(list, self.get(row))
            let row = row + 1
        endwhile
        return string(list)
    endfunction

    return lines
endfunction

function! s:Output(chan, msg)
    let promptReg = '^' . s:prompt . '\(\s' . s:prompt . '\)*'
    if term_getline(t:jdbBuf, '.') !~ promptReg . '\s*$' 
        return
    endif
    if exists('t:lastCursorRow')
        let start = t:lastCursorRow + 1
    else
        let start = 0
    endif

    let end = term_getcursor(t:jdbBuf)[0] - 1 + term_getscrolled(t:jdbBuf)
    echom "===================== Output:". start . "," . end." =================="
    let lines = s:newLines(start, end)
    if exists('t:executionMatch')
        let stats = [ t:executionMatch, s:newStopStat(function('s:ProcessStop')), s:newWhereStat()]
        unlet t:executionMatch
    else
        let stats = [ s:newStopStat(function('s:ProcessStop')), s:newWhereStat()]
    endif

    call s:MatchOutput(lines, stats)

    "echom "============================================================"
    "echom lines.toString()
    "echom term_getline(t:jdbBuf, '.')
    "echom string(t:executionMatch)
    "echom "============================================================"
    if !empty(get(t:, 'execution', {}))
        let executeCommand = t:execution.command . "\<cr>"
        if exists('t:execution.matchStat')
            let t:executionMatch = t:execution.matchStat
        endif
        let t:execution = {}
        call term_sendkeys(t:jdbBuf, executeCommand)
    endif

    let t:lastCursorRow = end
endfunction

function! s:newConditionStat(conditionStr, outClass, line)
    let progresses = [ { 'type' : 'consume', 'consume' : a:conditionStr } ]
    let stat = { 'progresses' : progresses , 'meetSucceed' : 0 }

    function stat.onFail() 
        if !self.meetSucceed
            let t:execution = { 'command' : 'cont' }
        endif
    endfunction

    function stat.onSuccess() closure
        let self.meetSucceed = 1
        if exists('t:execution')
            let t:execution = {}
        endif
        call s:ChangeCurrentLine(a:line)    
    endfunction

    function stat.match(line) 
        echom 'meet ' . a:line 
        echom 'expect ' . string(self.progresses[0])
        return s:Match(a:line, self)
    endfunction
    return stat
endfunction

function! s:newStopStat(...)
    let ProcessStop = get(a:, 1, 0)
    let stat = {}
    function stat.match(line) 
        return s:MatchStop(a:line, self)
    endfunction
    
    function stat.onSucceed() closure
        if !empty(ProcessStop)
            call ProcessStop(self)
        endif
    endfunction
    
    return stat
endfunction

function! s:newWhereStat()
    let stat = {}
    function stat.match(line)
        return s:MatchWhere(a:line, self)
    endfunction

    function stat.onSucceed()
        if get(self, 'topWhere', 1)
            call s:ChangeCurrentLine(self.line)
            let self.topWhere = 0
        endif
    endfunction

    function stat.onFail()
        if exists('self.topWhere')
            unlet self.topWhere
        endif
    endfunction

    return stat
endfunction

function! s:isComplete(progress)
    if exists('a:progress["complete"]') 
        return a:progress['complete'] == 1
    endif
endfunction

function! s:isFail(progress)
    if exists('a:progress["complete"]')
        return a:progress['complete'] == 0
    endif
endfunction

function! s:isWorking(progress)
    return !exists('a:progress.complete')
endfunction

function! s:isMatchSucceed(stat)
    if exists('a:stat["succeed"]')
        return a:stat["succeed"] == 1
    endif
endfunction

function! s:isMatchFail(stat)
    if exists('a:stat["succeed"]')
        return a:stat["succeed"] == 0
    endif
endfunction

function! s:isMatching(stat)
    return !exists('a:stat.succeed')
endfunction

function! s:dispatchProgress(line, col, progress)
    let type = a:progress['type']
    if type == 'consume'
        return s:ProcessConsume(a:line, a:col, a:progress)
    elseif type == 'number'
        return  s:ProcessNumber(a:line, a:col, a:progress)
    elseif type == 'method'
        return  s:ProcessMethod(a:line, a:col, a:progress)
    elseif type == 'between'
        return  s:ProcessBetween(a:line, a:col, a:progress)
    elseif type == 'any'
        return s:ProcessAny(a:line, a:col, a:progress)
    endif
    return -1
endfunction

function! s:Match(...)
    let line = a:1
    let stat = a:2
    let col = get(a:, 3, 0)

    let progresses = stat['progresses']
    while col < len(line)
        let current = get(stat, 'current', 0)
        let progress = progresses[current]
        let matchStartCol = col
        let col = s:dispatchProgress(line, col, progress)
        if col == -1
            break
        endif

        if s:isFail(progress)
            let stat['succeed'] = 0
            return get(a:, 3, 0)
        endif

        if matchStartCol < col
            let progress['match'] = get(progress, 'match', '') . line[matchStartCol : col - 1]
        endif

        if s:isComplete(progress)
            if progress.type == 'method'
                call s:ProcessMethodComplete(progress)
            endif

            if len(progresses) <= current + 1
                let stat['succeed'] = 1
                return col
            endif
            let stat['current'] = current + 1
        endif
    endwhile

    if col == get(a:, 3, 0)
        let stat['succeed'] = 0
    endif

    return col
endfunction

function! s:ProcessAny(line, col, progress)
    for p in a:progress['candidates']
        if s:isFail(p)
            continue
        endif

        let stat = { 'progresses' : [ p ] }
        let col = s:Match(a:line, stat, a:col)
        if s:isMatchSucceed(stat)
            let a:progress['complete'] = 1
            return col
        elseif s:isMatching(stat)
            return col
        endif
    endfor

    for p in a:progress.candidates
        if s:isWorking(p)
            return len(a:line)
        endif
    endfor

    let a:progress.complete = 0
    return a:col
endfunction

function! s:ProcessBetween(line, col, progress)
    if empty(get(a:progress, 'startProgress', {}))
        let startProgress =  { 'consume' : a:progress['start'] }
        let a:progress['startProgress'] = startProgress
    else
        let startProgress = a:progress['startProgress']
    endif

    if s:isComplete(startProgress)
        let endProgress = a:progress['endProgress']
        let col = s:ProcessConsume(a:line, a:col, endProgress)
        if s:isComplete(endProgress)
            let a:progress['complete'] = 1
            return col
        elseif s:isFail(endProgress)
            let a:progress['endProgress'] = { 'consume' : a:progress['end'] }
            return col + 1
        else
            return col
        endif
    else
       let col = s:ProcessConsume(a:line, a:col, startProgress) 
       if s:isComplete(startProgress)
           let a:progress['endProgress'] = { 'consume' : a:progress['end'] }
       elseif s:isFail(startProgress)
           let a:progress['complete'] = 0
       endif
       return col
   endif
endfunction

function! s:MatchWhere(line, stat)
    if !s:isMatching(a:stat) || empty(get(a:stat, 'progresses', []))
        let a:stat['progresses'] = [ 
                    \{ 'type' : 'consume', 'consume' : '  [' }, 
                    \{ 'type' : 'number' }, 
                    \{ 'type' : 'consume', 'consume' : '] ' }, 
                    \{ 'type' : 'method' }, 
                    \{ 'type' : 'between', 'start' : ' (', 'end' : ':' },
                    \{ 'type' : 'number' } , 
                    \{ 'type' : 'consume', 'consume' : ')' } 
                    \]
        if exists('a:stat.succeed')
            unlet a:stat.succeed
        endif
    endif
    
    let col = s:Match(a:line, a:stat)
    if s:isMatchSucceed(a:stat)
        let methodProgress = a:stat['progresses'][3]
        let a:stat['outClass'] = methodProgress['outClass']
        let lineProgress = a:stat['progresses'][5]
        let a:stat['line'] = lineProgress['match']
    endif
    return col
endfunction

function! s:ProcessNumber(line, col, progress)
    let matches = matchlist(a:line, '^\d\+', a:col)
    if len(matches) > 0
        return a:col + len(matches[0])
    else
        if get(a:progress, 'match', '') == ''
            let a:progress['complete'] = 0
        else
            let a:progress['complete'] = 1
        endif
        return a:col
    endif
endfunction

function! s:MatchStop(line,  stat)
    if !s:isMatching(a:stat) || empty(get(a:stat, 'progresses', []))
        let a:stat['progresses'] = [ 
                    \{ 'type' : 'between', 'start' : '"', 'end' : '"' }, 
                    \{ 'type' : 'consume', 'consume' : ', '}, 
                    \{ 'type' : 'method' }, 
                    \{ 'type' : 'consume', 'consume' : '(), line='}, 
                    \{ 'type' : 'number' }, 
                    \{ 'type' : 'consume', 'consume' : ' bci=' } 
                    \]
        let firstProgress = { 'type' : 'any', 'candidates' : [] }
        call insert(firstProgress.candidates, { 'type' : 'consume', 'consume' : 'Breakpoint hit: ' }, 0)
                    \->insert({ 'type' : 'consume', 'consume' : 'Step completed: ' }, 1)
        let a:stat['progresses'] =  [firstProgress]  + a:stat['progresses']
        if exists('a:stat.succeed')
            unlet a:stat.succeed
        endif
    endif
    let col = s:Match(a:line, a:stat)
    if s:isMatchSucceed(a:stat)
        let methodProgress = a:stat['progresses']
                    \->copy()
                    \->filter('v:val["type"] == "method"')[0]
        let a:stat['outClass'] = methodProgress['outClass']
        let lineProgress = a:stat['progresses']
                    \->copy()
                    \->filter('v:val["type"] == "number"')[0]
        let a:stat['line'] = lineProgress['match']
        if a:stat['progresses'][0].match == 'Breakpoint hit: '
            let a:stat['type'] = 'Breakpoint hit'
        else
            let a:stat['type'] = 'Step completed'
        endif
    endif
    return col
endfunction

function! s:ProcessMethodComplete(stat)
    let lastDot = strridx(a:stat['match'], '.')
    let a:stat['class'] = a:stat['match'][0:lastDot-1]
    let firstDollar = a:stat['class']->stridx('$')
    if firstDollar >= 0
        let a:stat['outClass'] = a:stat['class'][0:firstDollar-1]
    else
        let a:stat['outClass'] = a:stat['class']
    endif
endfunction

function! s:ProcessConsume(line, col,  progress)
    let nextMatchCol = get(a:progress, 'nextMatchCol', 0)
    let consume = a:progress['consume']
    let i = 0
    while i < min([len(a:line) - a:col, len(consume) - nextMatchCol])
        if a:line[a:col + i] != consume[nextMatchCol + i]
            let a:progress['complete'] = 0
            return a:col 
        endif
        let i = i + 1
    endwhile
    
    if nextMatchCol + i == len(consume)
        let a:progress['complete'] = 1
        return a:col + i
    else
        let a:progress['nextMatchCol'] = nextMatchCol + i
        return len(a:line)
    endif
endfunction

function! s:ProcessMethod(line, col, progress)
    let matchStr = get(a:progress, 'match', '') 
    if matchStr->stridx('$') > 0 || a:line[a:col] == '$'
        return s:ProcessInnerMethod(a:line, a:col, a:progress)
    elseif matchStr->stridx('.') > 0 || a:line[a:col] == '.'
        return s:ProcessMethodTail(a:line, a:col, a:progress)
    else
        return s:ProcessMethodHead(a:line, a:col, a:progress)
    endif
endfunction

function! s:ProcessMethodTail(line, col, progress)
    let firstMatch = matchlist(a:line, '^' . s:jWord, a:col)
    if firstMatch->len() > 0
        return a:col + len(firstMatch[0])
    endif

    let matchStr = a:progress['match']
    if matchStr[len(matchStr) - 1] == '.'
        let a:progress['complete'] = 0
        return a:col
    endif

    if a:line[a:col] == '.' || a:line[a:col] == '$'
        return a:col + 1
    endif
    
    let a:progress['complete'] = 1
    return a:col
endfunction
    
"a.
"a$
"$
function! s:ProcessMethodHead(line, col, progress)
    let match = matchlist(a:line, '^' . s:jWord, a:col)
    if len(match) > 0
        return a:col + len(match[0])
    endif
    let a:progress['complete'] = 0
    return a:col
endfunction

function! s:ProcessInnerMethod(line, col, progress)
    let matchStr = get(a:progress, 'match', '')
    let lastDot = matchStr->strridx('.')
    let innerClassDollar = matchStr->strridx('$', lastDot)
    if innerClassDollar > -1 
        let stage = get(a:progress, 'stage', '')
        if stage == 'lambda_method_name' || stage == 'lambda_tail'
            return s:ProcessLambdaMethodName()
        else
            return s:ProcessInnerMethodName(a:line, a:col, a:progress)
        endif
    else
        return s:ProcessInnerClassName(a:line, a:col, a:progress)
endfunction

function! s:ProcessLambdaMethodName(line, col, progress)
    let match = matchstr(a:line, '^' . s:jWord, a:col)
    if len(match) > 0
        return a:col + len(match)
    endif

    if a:progress.stage == 'lambda_method_name'
        if a:line[a:col] == '$'
            let a:progress.stage == 'lambda_tail'
            return a:col + 1
        else
            let a:progress.complete = 0
            return a:col
        endif
    else
        let a:progress.complete = (a:progress.match =~ '[$]$')
        return a:col
    endif
endfunction

function! s:ProcessInnerClassName(line, col, progress)
    let firstMatch = matchlist(a:line, '^' . s:jWord, a:col)
    if firstMatch->len() > 0
        return a:col + len(firstMatch[0])
    endif

    let matchStr = a:progress['match']
    if matchStr[len(matchStr) - 1] == '$'
        let a:progress['complete'] = 0
        return a:col
    endif

    if a:line[a:col] == '$' || a:line[a:col] == '.'
        return a:col + 1
    endif
    
    if matchStr =~ s:lambdaMethod + '$'
        let a:progress['complete'] = 1
    else
        let a:progress['complete'] = 0
    endif
    return a:col
endfunction

function! s:ProcessInnerMethodName(line, col, progress)
    let methodMatch = matchlist(a:line, '^' . s:jWord, a:col)
    if len(methodMatch) > 0
        return a:col + len(methodMatch[0])
    endif

    if a:col == len(a:line)
        return a:col
    endif

    let matchStr = a:progress['match']
    
    if a:line[a:col] == '$'
        if matchStr =~ '[.]lambda'
            let a:progress.part = 'lambda_method_name'
            return a:col + 1
        else
            let a:progress.complete = 0
            return a:col
        endif
    endif

    if matchStr[len(matchStr) - 1] == '.' 
        let a:progress['complete'] = 0
        return a:col
    else
        let a:progress['complete'] = 1
        return a:col
    endif
endfunction

function! s:ProcessStop(matchStat)
    let stopType = a:matchStat['type']
    let class = a:matchStat['outClass']
    let line = a:matchStat['line']
    if stopType == 'Breakpoint hit'
        let conditionBreakpoint = s:GetConditionBreakpoint(class, line) 
        if !empty(conditionBreakpoint)
            let t:execution = s:CreateConditionCommand(conditionBreakpoint)
            return
        endif
    endif
    echom stopType . ' ' . class . ':' . line
    call s:ChangeCurrentLine(line)
endfunction

function! s:GetOutputLine(row)
    if term_getcursor(t:jdbBuf)[0] - a:row < term_getsize(t:jdbBuf)[0] 
        let l = term_getline(t:jdbBuf, a:row - term_getscrolled(t:jdbBuf)) "can only get last term_size rows
    else
        let l = getbufline(t:jdbBuf, a:row) "cursor row may not be in buffer at this time
    endif
    return l
endfunction

function! s:CreateConditionCommand(breakpoint)
    let command = 'print ' . (a:breakpoint.javaExp)
    if type(a:breakpoint.expectValue) == v:t_number
        let conditionStr = ' '.(a:breakpoint.javaExp) . ' = ' . a:breakpoint.expectValue  
    else
        let conditionStr = ' '.(a:breakpoint.javaExp) . ' = "' . a:breakpoint.expectValue . '"'
    endif
    return { 'command' : command, 'matchStat' : s:newConditionStat(conditionStr, a:breakpoint.outClass, a:breakpoint.line ) }
endfunction

function! s:GetConditionBreakpoint(class, line)
    if exists('t:conditionBreakpoints')
        return get(t:conditionBreakpoints, a:class . ':'.  a:line, {})
    endif
endfunction

function! SetConditionBreakpoint(...)
    let expectValue = a:1
    if exists('a:2')
        let exp = a:2
    elseif line("'>") && line("'>") == line("'<")
        let selectLine = line("'>")
        let exp = getline(selectLine)[col("'<") : col("'>")]
    else
        let exp = expand('<cexpr>')
    endif
    
    echom 'To set a breakpoint with condition : ' . exp . ' = ' . expectValue
    let [outClass, line] = SetBreakpoint(get(a:, '3', line('.')), get(a:, '4', bufnr()))

    if !exists('t:conditionBreakpoints')
        let t:conditionBreakpoints = {}
    endif
    let t:conditionBreakpoints[outClass .':'. line] = {
                \'javaExp' : exp, 
                \'line' : line, 
                \'outClass' : outClass, 
                \'expectValue' : expectValue 
                \}
    
endfunction

function! s:ChangeCurrentLine(line)
    let curWin = winnr()
    let srcWin = range(1, winnr('$'))->filter('winbufnr(v:val)!=t:jdbBuf && winbufnr(v:val)!=t:javaBuf')[0]
    exec 'silent ' . srcWin.'wincmd w '
    exec 'silent ' . a:line
    exec 'silent ' . curWin.'wincmd w'
    exec 'redraw!'
endfunction

function! s:Package(...)
    let buf = get(a:, 1, bufnr())
    if bufname(buf) !~ '\.java$'
        return -1
    endif
    
    let lines = getbufline(buf, 1, '$')
    let row = 0
    while row < len(lines)
        let col = 0
        while col < len(lines[row])
            if matchlist(lines[row], '^' . s:mlCommentHead, col)->len() > 0
                let [row, col] = s:ProcessMultLineComment(lines, row, col + 2)
            elseif matchlist(lines[row], '^' . s:oneLineComment, col)->len() > 0 
                break
            elseif matchlist(lines[row], '^' . s:package, col)->len() > 0
                let col = col + 7
                return s:ProcessPackageDeclaration(lines, row, col)
            elseif matchlist(lines[row], '^' . s:colon, col)->len() > 0
                let row = len(lines)
                break
            else
                let col = col + 1
            endif
        endwhile
        let row = row + 1
    endwhile
    return ''
endfunction

function! s:ProcessMultLineComment(lines, row, col)
    let singleLineMatch = matchlist(a:lines[a:row], '^'.s:mlCommentTail, a:col)
    if len(singleLineMatch) > 0
        return [a:row, a:col + len(singleLineMatch[0])]
    endif
    
    let row = a:row + 1
    while row < len(a:lines)
        let matchResult = matchlist(a:lines[row], s:mlCommentTail)
        if len(matchResult) > 0
            return [row, matchResult[0]->len()]
        else
            let row = row + 1
        endif
    endwhile
endfunction

function! s:ProcessPackageDeclaration(lines, row, col)
    let row = a:row
    let package = ''
    while row < len(a:lines)

        if row == a:row
            let col = a:col
        else
            let col = 0
        endif

        while col < len(a:lines[row])
            if matchlist(a:lines[row], '^' . s:mlCommentHead, col)->len() > 0
                let [row, col] = s:ProcessMultLineComment(a:lines, row, col + 2)
            elseif matchlist(a:lines[row], '^' . s:oneLineComment, col)->len() > 0 
                break
            elseif matchlist(a:lines[row], '^' . s:packagePart, col)->len() > 0
                let matchResult = matchlist(a:lines[row], s:packagePart, col)
                let package = package . matchResult[0]
                let col = col + len(matchResult[0])
            elseif matchlist(a:lines[row], '^' . s:colon, col)->len() > 0
                return package
            else
                let col = col + 1
            endif
        endwhile
        let row = row + 1
    endwhile
endfunction

function! SetBreakpoint(...)
    let buf = get(a:, 2, bufnr())
    let line = get(a:, 1, line("."))

    let package = s:Package(buf)
    if package == -1
        echom 'Not a java file'
        return
    endif
    
    let file = bufname(buf)->fnamemodify(':t:r')

    call term_sendkeys(t:jdbBuf, 'stop at '.package.'.'.file.':'.line."\<cr>")

    echom 'Set a breakponint at ' . buf .':'. line
    return [package.'.'.file, line]
endfunction

function! s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun

function! Jdb_SID()
    return s:SID()
endfunction

echom Jdb_SID()
