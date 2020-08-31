let s:m = {}
function! JdbTest()
    let targetId = Jdb_SID()
    let s:m = s:getLocalFunc(targetId)
    
    for test in s:getTests()
        let v:errors = []
        echom 'Run ' . test
        call function(test)()
        if len(v:errors) > 0
            echoerr v:errors->join("\n")
        else
            echom 'Succeed!'
        endif
    endfor
endfunction

function! s:getLocalFunc(sid)
    let funcNames = s:functions({idx, val -> val->stridx('<SNR>' . a:sid . '_') == 0 })
    let funcMap = {}
    for name in funcNames
        let funcMap[matchstr(name, '<SNR>\d\+_\zs.\+')] = function(name)
    endfor
    return funcMap
endfunction

function! s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun

function! s:isTestFunc(idx, str)
    return a:str->stridx('<SNR>' . s:SID(). '_test') == 0
endfunction

function! s:funcName(idx, str)
    return matchstr(a:str, 'function \zs[^(]\+')
endfunction

function! s:getTests()
    return s:functions(function('s:isTestFunc'))
endfunction

function! s:functions(filter)
    redir => functions
    silent function
    redir END

    return functions
                \->split('\n')
                \->map(function('s:funcName'))
                \->filter(a:filter)
endfunction

function! s:testConsume()
    let progress = { 'consume' : 'astring' }
    let col = s:m['ProcessConsume']('astring', 0, progress)
    call assert_equal(1, progress['complete'])
    call assert_equal(len('astring'), col)
endfunction

function! s:testConsumeTail()
    let progress = { 'consume' : 'astring', 'nextMatchCol' : 3 }
    let col = s:m['ProcessConsume']('ring', 0,  progress)
    call assert_equal(1, progress['complete'])
    call assert_equal(len('ring'), col)
endfunction

function! s:testConsumeNotMatch()
    let progress = { 'consume' : 'astring' }
    let col = s:m['ProcessConsume']('astrina', 0, progress)
    call assert_true(s:m.isFail(progress))
    call assert_equal(0, col)
endfunction

function! s:testConsumeHead()
    let progress = { 'consume' : 'astring' }
    let col = s:m['ProcessConsume']('as', 0, progress)
    call assert_equal(0, get(progress, 'complete', 0))
    call assert_true(s:m.isWorking(progress))
    call assert_equal(2, progress['nextMatchCol'])
endfunction

function! s:testConsumeFromMiddle()
    let progress = { 'consume': 'astring' }
    let col = s:m['ProcessConsume']('xxxastringbbb', 3, progress)
    call assert_equal(1, progress['complete'])
    call assert_equal(3 + len('astring'), col)
endfunction

function! s:testNumberStart()
    let progress = {}
    let col = s:m['ProcessNumber']('123', 0, progress)
    call assert_equal(0, get(progress, 'complete', 0))
    call assert_equal(3, col)
endfunction

function! s:testNumber()
    let progress = { 'match' : '123' }
    let col = s:m['ProcessNumber']('456', 0, progress)
    call assert_equal(0, get(progress, 'complete', 0))
    call assert_equal(3, col)
endfunction

function! s:testNumberComplete()
    let progress = { 'match' : '123' }
    let col = s:m['ProcessNumber']('end', 0, progress)
    call assert_equal(1, get(progress, 'complete', 1))
    call assert_equal(0, col)
endfunction

function! s:testNumberNotMatch()
    let progress = {}
    let col = s:m['ProcessNumber']('a123', 0, progress)
    call assert_true(s:m.isFail(progress))
    call assert_equal(0, col)
endfunction

function! s:testBetweenStart()
    let target = ' "hello", '
    let progress = { "start" : ' "', "end" : '", ' }
    let col = s:m['ProcessBetween'](target, 0, progress)
    call assert_equal(2, col)
    call assert_true(progress['startProgress']['complete'])
    call assert_equal(progress['end'], progress['endProgress']['consume'])
endfunction

function! s:testBetween()
    let target = ' "hello", '
    let progress = { "start" : ' "', "end" : '", ' }
    let progress['startProgress'] = { 'complete' : 1 }
    let progress['endProgress'] = { 'consume' : progress['end'] }
    let col = s:m['ProcessBetween'](target, 2, progress)
    call assert_false(get(progress, 'complete', 0))
    call assert_equal(3, col)
endfunction

function! s:testBetweenComplete()
    let target = ' "hello", '
    let progress = { "start" : ' "', "end" : '", ' }
    let progress['startProgress'] = { 'complete' : 1 }
    let progress['endProgress'] = { 'consume' : progress['end'] }
    let col = s:m['ProcessBetween'](target, 7, progress)
    call assert_true(get(progress, 'complete', 0))
    call assert_equal(len(target), col)
endfunction

function! s:testBetweenNotMatchStart()
    let progress = { "start" : '"', "end" : '"' }
    let col = s:m['ProcessBetween']('abc"', 0, progress)
    call assert_true(s:m.isFail(progress))
    call assert_equal(0, col)
endfunction

function! s:testBetweenMatchStart()
    let progress = { "start" : '""', "end" : '",' }
    let col = s:m['ProcessBetween']('_"', 1, progress)
    call assert_false(get(progress, 'complete', 0))
    call assert_equal(2, col)
endfunction

function! s:testBetweenMatchStartComplete()
    let progress = { "start" : '""', "end" : '",' }
    let progress['startProgress'] = { 'consume' : progress['start'], 'nextMatchCol' : 1 }
    let col = s:m['ProcessBetween']('_""', 2, progress)
    call assert_false(get(progress, 'complete', 0))
    call assert_equal(3, col)
endfunction

function! s:testMethodHead()
    let progress = {}
    let col = s:m['ProcessMethod']('com.jdb.Test.method', 0, progress)
    call assert_false(get(progress, 'complete', 0))
    call assert_equal(3, col)
endfunction

function! s:testMethodDot()
    let progress = { 'match' : 'com' }
    let col = s:m['ProcessMethod']('com.jdb.Test.method', 3, progress)
    call assert_false(get(progress, 'complete', 0))
    call assert_equal(4, col)
endfunction

function! s:testMethodComplete()
    let progress = { 'match' : 'com.jdb.Test.method' }
    let matchLen = len(progress['match'])
    let col = s:m['ProcessMethod']('com.jdb.Test.method(', matchLen, progress)
    call assert_true(get(progress, 'complete', 0))
    call assert_equal(matchLen, col)
endfunction

function! s:testMethodOfInnerClassStart()
    let progress = { 'match' : 'Test' }
    let col = s:m['ProcessMethod']('Test$Case.method', 4, progress)
    call assert_false(get(progress, 'complete', 0))
    call assert_equal(5, col)
endfunction

function! s:testMethodOfInnerClass()
    let progress = { 'match' : 'Test' }
    let col = s:m['ProcessMethod']('Test$Case.method', 5, progress)
    call assert_false(get(progress, 'complete', 0))
    call assert_equal(9, col)
endfunction

function! s:testMethodOfInnerClassDot()
    let progress = { 'match' : 'Test$Case' }
    let col = s:m['ProcessMethod']('Test$Case.method', 9, progress)
    call assert_false(get(progress, 'complete', 0))
    call assert_equal(10, col)
endfunction

function! s:testMethodOfInnerClassEnd()
    let progress = { 'match' : 'Test$Case.' }
    let col = s:m['ProcessMethod']('Test$Case.method', 10, progress)
    call assert_false(get(progress, 'complete', 0))
    call assert_equal(16, col)
endfunction

function! s:testMatchLambdaMethod()
    let line = 'Clazz.lambda$method$0()'

    let progress = { 'type' : 'method' }
    let stat = { 'progresses' : [ progress ] }
    let line = s:m['Match'](line, stat)
    call assert_true(stat['succeed'])
    call assert_equal('Clazz.lambda$method$0', progress['match'])
    call assert_equal('Clazz', progress['outClass'])
endfunction

function! s:testMatchMethod()
    let line = 'com.Test.method()'

    let progress = { 'type' : 'method' }
    let stat = { 'progresses' : [ progress ] }
    let line = s:m['Match'](line, stat)
    call assert_true(stat['succeed'])
    call assert_equal('com.Test.method', progress['match'])
    call assert_equal('com.Test', progress['outClass'])
endfunction

function! s:testMatchInnerMethod()
    let line = 'com.Test$Case.method()'

    let progress = { 'type' : 'method' }
    let stat = { 'progresses' : [ progress ] }
    let line = s:m['Match'](line, stat)
    call assert_true(stat['succeed'])
    call assert_equal('com.Test$Case.method', progress['match'])
    call assert_equal('com.Test', progress['outClass'])
endfunction

function! s:testMatchDefaultPackage()
    let line = 'Test.method()'

    let progress = { 'type' : 'method' }
    let stat = { 'progresses' : [ progress ] }
    let line = s:m['Match'](line, stat)
    call assert_true(stat['succeed'])
    call assert_equal('Test.method', progress['match'])
    call assert_equal('Test', progress['outClass'])
endfunction

function! s:testMatchDefaultPackageAndInner()
    let line = 'Test$Case.method()'

    let progress = { 'type' : 'method' }
    let stat = { 'progresses' : [ progress ] }
    let line = s:m['Match'](line, stat)
    call assert_true(stat['succeed'])
    call assert_equal('Test$Case.method', progress['match'])
    call assert_equal('Test', progress['outClass'])
endfunction

function! s:testMatch2Dollar()
    let line = 'Test$$com'

    let progress = { 'type' : 'method' }
    let stat = { 'progresses' : [ progress ] }
    let line = s:m['Match'](line, stat)
    call assert_false(stat['succeed'])
endfunction

function! s:testMatch2Dot()
    let line = 'Test..com'

    let progress = { 'type' : 'method' }
    let stat = { 'progresses' : [ progress ] }
    let line = s:m['Match'](line, stat)
    call assert_false(stat['succeed'])
endfunction

function! s:testMatchLines() 
    let lines = s:createLines(['com.Tes', 't.method', '()'])
    let stat = { 'progresses' : [{ 'type' : 'method' }] }
    function stat.match(line)
        call s:m.Match(a:line, self)
        return s:m.isMatchSucceed(self)
    endfunction
    function stat.onSucceed()
        let self.onSucceedCalled = 1
    endfunction
    let row = s:m.MatchLines(lines, 0, stat)
    call assert_equal(len(lines), row)
    call assert_true(stat.onSucceedCalled)
endfunction

function! s:testMatchLinesFail() 
    let lines = s:createLines(['com.Tes', 't..method', '()'])
    let stat = { 'progresses' : [{ 'type' : 'method' }] }
    function stat.match(line)
        call s:m.Match(a:line, self)
        return s:m.isMatchSucceed(self)
    endfunction
    function stat.onFail()
        let self.onFailCalled = 1
    endfunction
    let row = s:m.MatchLines(lines, 0, stat)
    call assert_equal(0, row)
    call assert_true(stat.onFailCalled)
endfunction

function! s:testMatchLinesPartial() 
    let lines = s:createLines(['com.Tes', 't.'])
    let stat = { 'progresses' : [{ 'type' : 'method' }] }
    function stat.match(line)
        return s:m.Match(a:line, self)
        "return s:m.isMatchSucceed(self)
    endfunction
    let row = s:m.MatchLines(lines, 0, stat)
    call assert_equal(0, row)
    call assert_true(s:m.isMatching(stat))
endfunction

function! s:testMatchEmptyLine()
    let lines = s:createLines([''])
    let stat = { 'progresses' : [{ 'type' : 'method' }] }
    function stat.match(line)
        call s:m.Match(a:line, self)
        return s:m.isMatchSucceed(self)
    endfunction
    let row = s:m.MatchLines(lines, 0, stat)
    call assert_equal(0, row)
    call assert_true(s:m.isMatchFail(stat))
endfunction

function! s:testMatch2Progresses()
    let line = '[1] Test.case.method '
    let between = { 'type' : 'between', 'start' : '[', 'end' : '] ' }
    let method = { 'type' : 'method' }
    let stat = { 'progresses' : [ between, method ] }
    let line = s:m['Match'](line, stat)
    call assert_true(stat['succeed'])
    call assert_equal('Test.case', method['outClass'])
endfunction

function! s:testMatchStopBreakpoint()
    let line = 'Breakpoint hit: "thread=main", Add.main(), line=11 bci=0'
    let stat = {}
    let line = s:m['MatchStop'](line, stat)
    call assert_true(stat['succeed'])
    call assert_equal('Add', stat['outClass'])
    call assert_equal('11', stat['line'])
    call assert_equal('Breakpoint hit', stat['type'])
endfunction

function! s:testMatchStopStep()
    let line = 'Step completed: "thread=http-nio-8080-exec-1", org.javahotfix.threading.controller.SomeController.performOperation(), line=24 bci=2'
    let stat = {}
    let line = s:m['MatchStop'](line, stat)
    call assert_true(stat['succeed'])
    call assert_equal('org.javahotfix.threading.controller.SomeController', stat['outClass'])
    call assert_equal('24', stat['line'])
    call assert_equal('Step completed', stat['type'])
endfunction

function! s:testMatchWhere()
    let line = '  [1] org.javahotfix.threading.controller.SomeController$Inner.performOperation (SomeController.java:21)'
    let stat = {}
    let line = s:m['MatchWhere'](line, stat)
    call assert_true(stat['succeed'])
    call assert_equal('org.javahotfix.threading.controller.SomeController', stat['outClass'])
    call assert_equal('21', stat['line'])
endfunction

function! s:testProcessAnyPartial()
    let line = 'Break'
    let col = 0
    let progress = {
                \'candidates' : [{ 'consume' : 'Breakpoint', 'type' : 'consume' }]
                \}
    let matchCol = s:m.ProcessAny(line, col, progress)
    call assert_equal(len(line), matchCol)
endfunction

function! s:testProcessAnyFail()
    let line = 'Break'
    let col = 1
    let progress = {
                \'candidates' : [{ 'consume' : 'Breakpoint', 'type' : 'consume' }]
                \}
    let matchCol = s:m.ProcessAny(line, col, progress)
    call assert_equal(col, matchCol)
    call assert_true(s:m.isFail(progress))
endfunction

function! s:testMatchOutput()
    let lines = s:createLines([
                \'main[1] next',
                \'Hello world!',
                \'>',
                \'Step completed: "thread=main", Hello.main(), line=4 bci=8'
                \])
    let stopStat = {}
    function stopStat.match(line)
        return s:m.MatchStop(a:line, self)
    endfunction

    function stopStat.onSucceed()
        let self.matched = 1
    endfunction

    let whereStat = {}
    function whereStat.match(line)
        return s:m.MatchWhere(a:line, self)
    endfunction

    let stats = [ whereStat, stopStat ]

    call s:m.MatchOutput(lines, stats)
    call assert_true(stopStat.matched)
endfunction

function! s:testMatchOutputPartially()
    let lines = s:createLines([
                \'main[1] next',
                \'Hello world!',
                \'>',
                \'Step completed: "thread=main", Hello.main(), '
                \])

    let stopStat = {}
    function stopStat.match(line)
        return s:m.MatchStop(a:line, self)
    endfunction

    function stopStat.onSucceed()
        let self.matched = 1
    endfunction

    let whereStat = {}
    function whereStat.match(line)
        return s:m.MatchWhere(a:line, self)
    endfunction

    let stats = [ whereStat, stopStat ]

    let matchingStat = s:m.MatchOutput(lines, stats)
    call assert_true(s:m.isMatching(matchingStat))
endfunction

function! s:testMatchOutputContinuous()
    let lines = s:createLines([
                \'com.Test.method',
                \ '  [12] org.javahotfix.threading.controller.SomeController$Inner.performOperation (SomeController.java:21)'
                \])
    let methodStat = {}
    let methodStat.progresses = [ { 'type' : 'method' } ]
    function! methodStat.match(line)
        if exists('self.succeed')
            let self.progresses = [ { 'type' : 'method' } ]
            unlet self.succeed
        endif
        return s:m.Match(a:line, self)
    endfunction
    let whereStat = {}
    function whereStat.match(line)
        return s:m.MatchWhere(a:line, self)
    endfunction
    let stats = [ methodStat, whereStat ]
    call s:m.MatchOutput(lines,  stats)
    call assert_true(whereStat.succeed)
endfunction

function! s:createLines(data)
    let lines = { 'data' : a:data  }
    function! lines.len()
        return self.data->len()
    endfunction

    function! lines.get(row)
        return self.data[a:row]
    endfunction
    return lines
endfunction
call JdbTest()
