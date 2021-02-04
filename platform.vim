function! GetTemp()
    if strlen($TEMP) > 0 
        return $TEMP
    elseif strlen($TMPDIR) > 0
        return $TMPDIR
    else
        return '/tmp'
    endif
endfunction

function! UseNativeSep(path)
    if has("gui_win32")
        return substitute(a:path, '/', '\', 'g')
    else
        return substitute(a:path, '\', '/', 'g')
    endif
endfunction

let g:javaFolders=[
            \$YODA . "/unbundled/apps/dashboard_plugin/ui/services/src",
            \$YODA . "/m3o/ui/src/m3o/java/app/src",
            \$YODA . "/unbundled/af/java/applib/src"
            \]->map({k,v->UseNativeSep(v)})

let g:jsFolders=[
            \$YODA . "/unbundled/apps/dashboard_plugin/ui/clients/html/vitria"
            \]


let g:javaTagsPath =  UseNativeSep(GetTemp() . "/platform_java.tags")
let g:jsTagsPath =  UseNativeSep(GetTemp() . "/platform_js.tags")

function! GetWslPath(path)
    return system('wsl wslpath "' . a:path . '"')
endfunction

let s:translateWinPath= 
            \ "^| while IFS=$'\\t' read -r f1 f2 f3;" . 'do printf "%s\t%s\t%s\n" $f1 "$(wslpath -w "$f2")" "$f3"; done'

function! MakeTagCommand(folders, fileType, tagsPath)
    let find = has("gui_win32") ? 'wsl find' : 'find'

    let findPaths = copy(a:folders)
    if has("gui_win32")
        return map(findPaths, { k,v -> "$(wslpath '" .v ."')"})
                    \->reduce({ acc, val -> acc . ' ' . val }, 'wsl find')
                    \ . " -iname '*." . a:fileType ."'"
                    \ . " ^| ctags -L - -o -"
                    \ . s:translateWinPath . ' > ' . a:tagsPath
    endif

    return findPaths->reduce({ acc, val -> acc . ' ' . val }, 'find')
                \ . " -iname '*." . a:fileType ."'"
                \ . " | ctags -L - -o '" . a:tagsPath . "'"
endfunction

function! s:appendOptions(name, options, local)
    for o in a:options
        if a:local
            exe 'setlocal ' . a:name . '+=' . substitute(o, '\', '\\\\', 'g')
        else
            exe 'set ' . a:name . '+=' . substitute(o, '\', '\\\\', 'g')
        endif
    endfor
endfunction

set path=
call s:appendOptions('path', g:javaFolders->copy()->map({k,v->UseNativeSep(v . '/**')}), 0)
call s:appendOptions('path', g:jsFolders->copy()->map({k,v->UseNativeSep(v . '/**')}), 0)

function! ChangeCwd(file, paths)
    for p in a:paths
        if stridx(a:file, p) >= 0
            exe 'lcd ' . p  
            return
        endif
    endfor
endfunction

augroup platform
    autocmd!
    autocmd FileType javascript call s:appendOptions('tags', [g:jsTagsPath], 1)
    autocmd FileType java call s:appendOptions('tags', [g:javaTagsPath], 1)
    autocmd BufWinEnter * call ChangeCwd(expand('<afile>:p'), g:javaFolders + g:jsFolders)
augroup end

call job_start(MakeTagCommand(g:javaFolders, 'java', g:javaTagsPath))
call job_start(MakeTagCommand(g:jsFolders, 'js', g:jsTagsPath))

cd $yoda_apps
n dashboard_plugin/**/*java    
