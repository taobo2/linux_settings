command! -nargs=? -complete=file Jdebug call <SID>Jdebug(<f-args>)
command! -nargs=+ -complete=file JdebugSource call <SID>SetSourcepath(<f-args>)
command! -nargs=+ -complete=file JdebugAddSource call <SID>addSourcepath(<f-args>)
command! -nargs=+ JdebugRemote call <SID>JdebugRemote(<f-args>)
command! -nargs=* JdebugStop call <SID>toggleBreakpoint(<f-args>)
command! -nargs=* JdebugConditionStop call <SID>SetConditionBreakpoint(<f-args>)
command! -nargs=+ JdebugRun call <SID>runCommand(<f-args>)

augroup JdebugAutocmd
    autocmd!
    autocmd CursorMoved *.java call <SID>popCondition()
augroup END

highlight! JdebugBreakpoint ctermbg=green
highlight! JdebugStop ctermbg=red

function! <SID>popCondition()
    if col('.') > 1
        return
    endif

    let key = s:outClass(bufnr()) . ':' . line('.')
    if exists('t:breakpoints["' . key .'"].javaExp')
        let bp = t:breakpoints[key]
        call popup_atcursor(bp.javaExp . ' = ' . bp.expectValue, #{ pos : 'botleft'})
    endif
endfunction

function! <SID>runCommand(...)
   if s:waitInput() 
       call term_sendkeys(t:jdbBuf, a:000->join(' '))
   else
       echom 'Jdb is busy, ignore this command.'
   endif
endfunction

function! s:waitInput()
    if !exists('t:jdbBuf')
        return 
    endif

    let promptReg = '^' . s:prompt . '\(\s' . s:prompt . '\)*'
    return term_getline(t:jdbBuf, '.') =~ promptReg . '\s*' 
endfunction

function! s:srcWin()
    return range(1, winnr('$'))->filter('winbufnr(v:val)!=t:jdbBuf && winbufnr(v:val)!=t:javaBuf')[0]
endfunction

function! s:jdbExitCb(a1, a2)
    if exists('t:stopMatchId')
        call matchdelete(t:stopMatchId, s:srcWin())
        unlet t:stopMatchId
    endif
endfunction

function! <SID>JdebugRemote(host, port)
    call s:beforeDebug('')
    let t:jdbBuf = term_start('jdb -sourcepath '. s:getSourcepathArg() . ' -attach '. a:host .':' . a:port, 
                \{ 
                \'term_name' : 'JDB', 
                \'vertical' : 1,  
                \'out_cb' : function('s:Output')
                \})
endfunction

function! s:getSourcepathArg()
    if exists('t:sourcepaths') && !empty('t:sourcepaths')
        return t:sourcepaths->join(':')
    else
        return  getcwd() 
    endif
endfunction

function! <SID>addSourcepath(...)
    call <SID>SetSourcepath(get(t:, 'sourcepaths', []) + a:000)
endfunction

function! <SID>SetSourcepath(...)
    let t:sourcepaths = a:000
    if exists('t:jdbBuf') && term_getstatus(t:jdbBuf) == 'running'
        call term_sendkeys(t:jdbBuf, 'use ' . s:getSourcepathArg() . "\<cr>")
    endif
endfunction

function! s:beforeDebug(filePath)
    let breakpoints = get(t:, 'breakpoints', {})
    if exists('t:javaBuf')
        call term_getjob(t:javaBuf)->job_stop('kill')
        exe 'noautocmd ' . bufwinnr(t:javaBuf) . 'wincmd c'
        unlet t:javaBuf
    endif
    if exists('t:jdbBuf') 
        call term_getjob(t:jdbBuf)->job_stop('kill')    
        exe 'noautocmd ' . bufwinnr(t:jdbBuf) . 'wincmd c'
        unlet t:jdbBuf
    elseif !empty(a:filePath)
        exe 'tabnew ' . a:filePath
    else
        exe 'tabnew '
    endif
    let t:breakpoints = deepcopy(breakpoints)
    call s:addBreakpoints()
endfunction

function! <SID>Jdebug(...)
    let filePath = get(a:, 1, expand('%:p'))
    if filePath =~ '[.]java$'
        let buf = bufnr(filePath)
        if buf == -1
            exe 'e ' . filePath
            let buf = bufnr(filePath)
        endif
        let tailNum = split(s:Package(buf), '[.]')->len() + 1
        let sourcepath = fnamemodify(filePath, repeat(':h', tailNum))
        let sourcepaths = get(t:, 'sourcepaths', []) + [ sourcepath ]
    endif
    
    call s:beforeDebug(filePath)
    let t:sourcepaths = sourcepaths
    let compileCommand = 'javac -g -sourcepath '. s:getSourcepathArg() . ' ' .  filePath
    let JavacExit = function('s:JavacExit')
    let t:javacBuf = term_start(compileCommand, { 'exit_cb' : JavacExit  })
endfunction

let s:jWord = '[^ .(;$><]\+'
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
    
    let t:javaBuf = term_start('java -agentlib:jdwp=transport=dt_socket,server=y -classpath /tmp/ db.Test', { 'term_name' : 'db.Test', 'vertical' : 1, 'out_cb' : function('s:JavaOutput') })
endfunction

function! s:addBreakpoints()
    let t:executions = get(t:, 'executions', [])
    for b in get(t:, 'breakpoints', {})->keys()
        call add(t:executions, #{ command : 'stop at ' . b })
    endfor
endfunction

function! s:JavaOutput(chan, msg)
    if exists('t:jdbBuf')
        return
    endif

    let progresses = [
                \{ 'type' : 'consume', 'consume' : 'Listening for transport dt_socket at address: ' },
                \{ 'type' : 'number' }
                \]
    let lineMatcher = { 'progresses' : progresses }
    function! lineMatcher.match(line)
        if !s:isMatching(self)
            let self.progresses = [
                        \{ 'type' : 'consume', 'consume' : 'Listening for transport dt_socket at address:' },
                        \{ 'type' : 'number' }
                        \]
            if exists('self.succeed')
                unlet self.succeed
            endif
        endif
        return s:Match(a:line, self)
    endfunction

    function! lineMatcher.onSucceed()
        let port = self.progresses[1]['match']
        let t:jdbBuf = term_start('jdb -sourcepath '.s:getSourcepathArg().' -attach '. port, 
                    \{ 
                    \'term_name' : 'JDB',
                    \ 'out_cb' : function('s:Output'),
                    \ 'exit_cb' : function('s:jdbExitCb')
                    \})
    endfunction

    let lines = s:newLines(1, 2, t:javaBuf)
    call s:MatchOutput(lines, [lineMatcher])
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

    for s in a:stats
        if exists('s.onOutputEnd')
            call s.onOutputEnd()
        endif
    endfor
endfunction

function! s:MatchLines(lines, start, stat)
    let row = a:start
    while row < a:lines.len()
        let line = a:lines.get(row)
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

function s:newLines(start, end, buf)
    let lines = {}
    function! lines.len() closure
        return a:end - a:start + 1    
    endfunction

    function! lines.get(row) closure
        return s:GetOutputLine(a:row + a:start, a:buf)
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

    let end = term_getcursor(t:jdbBuf)[0]  + term_getscrolled(t:jdbBuf)
    let lines = s:newLines(start, end, t:jdbBuf)
    if exists('t:executionMatch')
        let stats = [ t:executionMatch, s:newStopStat(function('s:ProcessStop')), s:newWhereStat(), s:newSetBreakpointStat(), s:newClearBreakpointStat()]
        unlet t:executionMatch
    else
        let stats = [ s:newStopStat(function('s:ProcessStop')), s:newWhereStat(), s:newSetBreakpointStat(), s:newClearBreakpointStat()]
    endif

    call s:MatchOutput(lines, stats)

    let t:lastCursorRow = end
    if get(t:, 'executions', [])->empty()
        return
    endif

    let execution = t:executions->remove(0)
    let executeCommand = execution.command . "\<cr>"
    if exists('execution.matchStat')
        let t:executionMatch = execution.matchStat
    endif
    call term_sendkeys(t:jdbBuf, executeCommand)
endfunction

function! s:newSetBreakpointStat()
    let candidates = [
                \{ 'type' : 'consume', 'consume' : 'Set breakpoint' },
                \{ 'type' : 'consume', 'consume' : 'Deferring breakpoint' }
                \]
    let progresses = [ 
                \{ 'type' : 'any', 'candidates' : candidates  },
                \{ 'type' : 'between', 'start' : ' ', 'end' : ':' },
                \{ 'type' : 'number' }
                \]
    let stat = s:newStat(progresses)

    function! stat.onSucceed()
        if !exists('t:breakpoints')
            let t:breakpoints = {}
        endif
        let outClass = self.progresses[1].match[1:-2]
        let line = self.progresses[2].match
        let key = outClass . ':' . line
        if !has_key(t:breakpoints, key)
            let t:breakpoints[outClass . ':' . line] = {}
        endif
        call s:updateBreakpoints()
    endfunction

    retur stat
endfunction

function! s:newClearBreakpointStat()
    let progresses = [ 
                \{ 'type' : 'consume', 'consume' : 'Removed: breakpoint' },
				\{ 'type' : 'between', 'start' : ' ', 'end' : ':' },
                \{ 'type' : 'number' }
                \]
    let stat = s:newStat(progresses)
    function! stat.onSucceed()
        let outClass = self.progresses[1].match[1:-2]
        let line = self.progresses[2].match
        if exists('t:breakpoints["' . outClass . ':' . line . '"]')
            unlet t:breakpoints[outClass . ':' . line] 
            call s:updateBreakpoints()
        endif
    endfunction
    return stat
endfunction

function! s:updateBreakpoints()
    if exists('t:matchIds')
        call matchdelete(t:matchIds, s:srcWin())
    endif
    let prefix = s:outClass(s:srcWin()->winbufnr())
    let lines = get(t:, 'breakpoints', {})
                \->keys()
                \->filter('v:val->stridx(prefix) == 0')
                \->map('v:val->split(":")[1]')
                \->map('[v:val, 1]')
    let t:matchIds = matchaddpos('JdebugBreakpoint', lines, 10, -1, {'window' :  s:srcWin()})
endfunction

function! s:newStat(progresses)
    let stat = {}
    function stat.match(line) closure
        if !s:isMatching(self) || !exists('stat.progresses')
            let stat.progresses = a:progresses->deepcopy()
            if exists('self.succeed')
                unlet self.succeed
            endif
            if exists('self.current')
                unlet self.current
            endif
        endif

        return s:Match(a:line, self)
    endfunction
    return stat
endfunction

function! s:newConditionStat(conditionStr, outClass, line)
    let progresses = [ { 'type' : 'consume', 'consume' : a:conditionStr } ]
    let stat = s:newStat(progresses)
    let stat.meetSucceed = 0

    function stat.onSucceed() closure
        let self.meetSucceed = 1
        call s:ChangeCurrentLine(a:outClass, a:line)    
    endfunction

    function stat.onOutputEnd()
        if !self.meetSucceed
            let t:executions = get(t:, 'executions', [])->add({ 'command' : 'cont' })
        endif
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
            call s:ChangeCurrentLine(self.outClass, self.line)
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
    while 1
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

        if col >= len(line)
            break
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
    if has_key(a:progress, 'initConsume')
        let col = s:ProcessConsume(a:line, a:col, a:progress.initConsume)
        if s:isComplete(a:progress.initConsume)
            let a:progress['complete'] = 1
            return col
        elseif s:isFail(a:progress.initConsume)
            let a:progress['complete'] = 0
            return a:col
        else
            return col
        endif
    endif

    let firstMatch = matchlist(a:line, '^' . s:jWord, a:col)
    if firstMatch->len() > 0
        return a:col + len(firstMatch[0])
    endif


    let matchStr = a:progress['match']
    if matchStr[len(matchStr) - 1] == '.' && a:line[a:col] != '<'
        let a:progress['complete'] = 0
        return a:col
    endif

    if a:line[a:col] == '.' || a:line[a:col] == '$'
        return a:col + 1
    elseif a:line[a:col] == '<'
        let a:progress.initConsume = { 'type' : 'consume', 'consume' : 'init>' }
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
    endif
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
            let t:executions = get(t:, 'executions', [])->add(s:CreateConditionCommand(conditionBreakpoint))
            return
        endif
    endif
    "echom stopType . ' ' . class . ':' . line
    call s:ChangeCurrentLine(class, line)
endfunction

function! s:GetOutputLine(row, buf)
    if term_getcursor(a:buf)[0] - a:row < term_getsize(a:buf)[0] 
        let l = term_getline(a:buf, a:row - term_getscrolled(a:buf)) "can only get last term_size rows
    else
        let l = getbufline(a:buf, a:row) "cursor row may not be in buffer at this time
    endif
    return l
endfunction

function! s:CreateConditionCommand(breakpoint)
    let command = 'print ' . (a:breakpoint.javaExp)
    let conditionStr = ' '.(a:breakpoint.javaExp) . ' = ' . a:breakpoint.expectValue  
    return { 'command' : command, 'matchStat' : s:newConditionStat(conditionStr, a:breakpoint.outClass, a:breakpoint.line ) }
endfunction

function! s:GetConditionBreakpoint(class, line)
    if exists('t:breakpoints')
        let bp = get(t:breakpoints, a:class . ':'.  a:line, {})
        if has_key(bp, 'javaExp')
            return bp
        endif
    endif
endfunction

function! <SID>SetConditionBreakpoint(...)
    let expectValue = a:1
    if exists('a:2')
        let exp = a:2
    elseif line("'>") && line("'>") == line("'<")
        let selectLine = line("'>")
        let exp = getline(selectLine)[col("'<") : col("'>")]
    else
        let exp = expand('<cexpr>')
    endif
    
    let buf = get(a:, '4', bufnr())
    let class = get(a:, '4', buf)->bufname()->fnamemodify(':t:r')
    let outClass = s:Package(buf) . '.' . class
    let line = get(a:, '3', line('.'))
    "echom 'To set a breakpoint with condition : ' . exp . ' = ' . expectValue
    call s:setBreakpoint(line, outClass)

    if !exists('t:breakpoints')
        let t:breakpoints = {}
    endif
    let t:breakpoints[outClass .':'. line] = {
                \'javaExp' : exp, 
                \'line' : line, 
                \'outClass' : outClass, 
                \'expectValue' : expectValue 
                \}
    
endfunction

function! s:ChangeCurrentLine(outClass, line)
    let javaFile = ''
    let qualifyNames = a:outClass->split('[.]')
    let qualifyNames[-1] = qualifyNames[-1] . '.java'

    for srcPath in s:getSourcepathArg()->split(':')
        let path = srcPath
        for name in qualifyNames
            let path = globpath(path, name)
            if empty(path)
                break
            endif
        endfor

        if !empty(path)
            let javaFile = path
            break
        endif
    endfor

    if empty(javaFile)
        echom 'Can not find ' . a:outClass
        return
    endif
    
    let curWin = winnr()
    exec 'silent ' . s:srcWin() .'wincmd w '
    if bufexists(javaFile)
        exec 'silent b ' . javaFile
    else
        exec 'silent e ' .javaFile
    endif
    exec 'silent ' . a:line
    if exists('t:stopMatchId')
        call matchdelete(t:stopMatchId)
    endif
    let t:stopMatchId = matchaddpos('JdebugStop', [[a:line, 1]])
    exec 'silent ' . curWin.'wincmd w'
    exec 'redraw!'
endfunction

function! s:outClass(buf)
    let class = bufname(a:buf)->fnamemodify(':t:r')
    return s:Package(a:buf) . '.' . class
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

function! <SID>toggleBreakpoint(...)
    let buf = get(a:, 1, '')->bufnr()
    if get(a:, 2, 0) > 0
        let line = a:2
    else
        let line = line('.', win_getid(s:srcWin()))
    endif

    if !exists('t:breakpoints')
        let t:breakpoints = {}
    endif

    let class = bufname(buf)->fnamemodify(':t:r')
    let qualifiedClass = s:Package(buf) . '.' . class
    if get(t:, 'breakpoints', {})->has_key(qualifiedClass . ':' . line)
        call s:clearBreakpoint(line, qualifiedClass)
    else
        call s:setBreakpoint(line, qualifiedClass)
    endif
endfunction

function! s:clearBreakpoint(line, qualifiedClass)
    call term_sendkeys(t:jdbBuf, 'clear '. a:qualifiedClass . ':'.a:line."\<cr>")
endfunction

function! s:setBreakpoint(line, qualifiedClass)
    call term_sendkeys(t:jdbBuf, 'stop at '.a:qualifiedClass.':'.a:line."\<cr>")
endfunction

function! s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun

function! Jdb_SID()
    return s:SID()
endfunction

echom Jdb_SID()
