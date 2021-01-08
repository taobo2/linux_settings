﻿SetTitleMatchMode 2
global SO_ID
global SO_EDITOR_1
global SO_EDITOR_2
global OUTLOOK
global BEARYCHAT
global ADOBE
global SUMATRA
global VIASO
global VIAAPP

#z::Run, %ComSpec% /c start gvim d:\projects\linux_settings\work_space.ahk  ; Win+Z
^#/::Reload


^!n::listvars  ;

;via app
^#p::
if not WinExist(getIdTitle(VIAAPP)){
    VIAAPP := openWindow("runViaapp", "yoda")
    WinMaximize, % getIdTitle(VIAAPP)
}
WinActivate, % getIdTitle(VIAAPP)
return

;via so script
^#v::
if not WinExist(getIdTitle(VIASO)){
    VIASO := openWindow("runViaso", "Ubuntu")
    moveRight(VIASO)
}

if not WinExist(getIdTitle(SO_EDITOR_1)){
    SO_EDITOR_1 := openWindow("runSobEditor", "Google Chrome")
    moveLeft(SO_EDITOR_1)
}

WinActivate, % getIdTitle(VIASO)
WinActivate, % getIdTitle(SO_EDITOR_1)
return

;Web
^#w::
WinGet, topweb, ID, Edge
if topweb{
    WinActivate, % getIdTitle(topweb)
}else{
    Run, %ComSpec% /c start msedge
}
return

;Login aws dev
^#a::
    Run, %A_ScriptDir%\via_login.cmd
    WinWaitActive,Vitria VIA Home,,10
    if ErrorLevel{
        throw "Wait login to aws dev failed"
    }
    WinClose
    return

;Signal Onboading
^#s::
if not WinExist(getIdTitle(SO_ID)){
    SO_ID := openWindow("runSob", "Google Chrome")
    WinMaximize, % getIdTitle(SO_ID)
}

if not WinExist(getIdTitle(SO_EDITOR_1)){
    SO_EDITOR_1 := openWindow("runSobEditor", "Google Chrome")
    moveLeft(SO_EDITOR_1)
}

if not WinExist(getIdTitle(SO_EDITOR_2)){
    SO_EDITOR_2 := openWindow("runSobEditor", "Google Chrome")
    moveRight(SO_EDITOR_2)
}

if WinExist("A") != SO_ID {
    WinActivate, % getIdTitle(SO_ID)
}else{
    WinActivate, % getIdTitle(SO_EDITOR_1)
    WinActivate, % getIdTitle(SO_EDITOR_2)
}

return 

;Messages
^#m::
if not WinExist(getIdTitle(OUTLOOK)){
    OUTLOOK := openWindow("runOutlook", "Outlook")
    moveLeft(OUTLOOK)
}

if not WinExist(getIdTitle(BEARYCHAT)){
    BEARYCHAT := openWindow("runBearychat", "倍洽") 
    moveRight(BEARYCHAT)
}

WinActivate, % getIdTitle(OUTLOOK)
WinActivate, % getIdTitle(BEARYCHAT)

return

;Read
^#r::
if not WinExist(getIdTitle(ADOBE)){
    ADOBE := openWindow("runAdobe", "Adobe Acrobat Reader")
    moveLeft(ADOBE)
}
if not WinExist(getIdTitle(SUMATRA)){
    SUMATRA := openWindow("runSumatra", "SumatraPDF")
    moveRight(SUMATRA)
}

WinActivate, % getIdTitle(ADOBE)
WinActivate, % getIdTitle(SUMATRA)

return

;next window of same app
^#.::
WinGetClass, ActiveClass, A
WinSet, Bottom,, A
WinActivate, ahk_class %ActiveClass%
WinSet,Top,, ahk_class %ActiveClass% ;when there is only one window, it may be activated without being in the most front
return

^#,::
WinGetClass, ActiveClass, A
WinActivateBottom, ahk_class %ActiveClass%
return


switch2Desktop(id){
    session := getSessionId()
    RegRead, cur, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\%session%\VirtualDesktops, CurrentVirtualDesktop
    RegRead, all, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops, VirtualDesktopIDs
    ix := floor(InStr(all,cur) / strlen(cur))

    if (ix < id)
    {
        Loop % id-ix{
            Send ^#{Right}
            Sleep, 200
        }
    }else
    {
        Loop % ix-id{
            Send ^#{Left}
            Sleep, 200
        }
    }
}

;
; This functions finds out ID of current session.
;
getSessionId()
{
    ProcessId := DllCall("GetCurrentProcessId", "UInt")
    if ErrorLevel {
        OutputDebug, Error getting current process id: %ErrorLevel%
        return
    }
    OutputDebug, Current Process Id: %ProcessId%
    DllCall("ProcessIdToSessionId", "UInt", ProcessId, "UInt*", SessionId)
    if ErrorLevel {
        OutputDebug, Error getting session id: %ErrorLevel%
        return
    }
    OutputDebug, Current Session Id: %SessionId%
    return SessionId
}

runSob(){
    Run, %ComSpec% /c start chrome --start-maximized --new-window "http://54.84.45.75:8080/vitria-oi/app/?min=false&debug=true#uri=/app/ax/space/Digital`%20Operations/axv/DO`%20-`%20Signal`%20Onboarding`%20Comp`%20V2" 
}

runSobEditor(){
    Run, %ComSpec% /c start chrome --new-window "http://54.84.45.75:8080/vitria-oi/app/?min=false&debug=true" 
}

runOutlook(){
    Run, %ComSpec% /c start outlook
}

runBearychat(){
    Run, %ComSpec% /c start 倍洽
}

runAdobe(){
    Run, %ComSpec% /c start AcroRd32
}

runSumatra(){
    Run, %ComSpec% /c start SumatraPDF
}

runViaso(){
    Run, %ComSpec% /c start wt -p "Ubuntu"
}

runViaapp(){
    EnvGet, folder, yoda_apps
    Run, %ComSpec% /c start gvim.exe -c "n dashboard_plugin/**/*java" %folder%
}

openWindow(command, title){
    currentId := WinExist("A")

    %command%()
    
    Loop{
        WinWaitActive, %title%, , 20
        if ErrorLevel
        {
            throw "Wait " . title . " failed"
        }
        WinGet, winid, ID
        if( currentId != winid)
            break
        Sleep, 100
    }
    return winid
}

getIdTitle(id){
    return "ahk_id " . id
}

moveLeft(id){
    ;SysGet, screen, MonitorWorkArea
    ;MsgBox, % screenLeft . " " . screenRight . " " . screenTop . " " . screenBottom
    WinRestore, ahk_id %id%
    WinActivate, ahk_id %id%
    WinWaitActive, ahk_id %id%
    Send, #{Left}
    ;WinMove, ahk_id %id%, , % screenLeft, screenTop,  (screenRight - screenLeft) / 2,  screenBottom - screenTop
}

moveRight(id){
    ;SysGet, screen, MonitorWorkArea
    WinRestore, ahk_id %id%
    WinActivate, ahk_id %id%
    WinWaitActive, ahk_id %id%
    Send, #{Right}
    ;WinMove, ahk_id %id%, , % screenLeft + (screenRight - screenLeft) / 2, screenTop,  (screenRight - screenLeft) / 2,  screenBottom - screenTop
}

minAllWin(){
    id := WinExist("A")
    WinMinimizeAll
    while WinActive(getIdTitle(id)){
        Sleep, 200
    }
}

