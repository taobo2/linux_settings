#z::Run, %ComSpec% /c start gvim d:\projects\linux_settings\work_space.ahk  ; Win+Z
^#/::Reload

^!n::  ; Ctrl+Alt+N
if WinExist("Untitled - Notepad")
    WinActivate
else
    Run Notepad
return

;Signal Onboarding
^#m::
switch2Desktop(3)
Sleep, 1000

SetTitleMatchMode 2

if WinExist("Edge"){
    activateAll("Signal Onboarding")
    return
}

Run, %ComSpec% /c start msedge --start-maximized --new-window "http://54.84.45.75:8080/vitria-oi/app/?min=false#uri=/app/ax/space/Digital`%20Operations/axv/DO`%20-`%20Signal`%20Onboarding`%20Comp`%20V2" 
Sleep, 1000
move2Left()

if WinExist("User Login"){
    Sleep, 1000
	Send btao
	Send {Tab}
	Send vitria{Enter}
}

Run, %ComSpec% /c start msedge --start-maximized --new-window http://54.84.45.75:8080/vitria-oi/app/?min=false&min.ax=false&enableGridster=true
Sleep, 1000
move2Right()
return


^#,::
switch2Desktop(2)
sleep 1000
SetTitleMatchMode 2

if WinExist("Adobe") or WinExist("SumatraPDF")
    return

Run, %ComSpec% /c start acrord32 
WinWait, Adobe
move2Right()

Run, %ComSpec% /c start SumatraPDF
WinWait, SumatraPDF
move2Left()
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
            Sleep, 100
        }
    }else
    {
        Loop % ix-id{
            Send ^#{Left}
            Sleep, 100
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

move2Left()
{
    WinRestore,A
    SysGet, MonitorCount, MonitorCount
    if ( MonitorCount = 1)
    {
        Send #{Left}
        Send {Esc}
    }else
    {
        WinMove,A,,0,0
        WinMaximize,A
    }
}

move2Right()
{
    WinRestore,A
    SysGet, MonitorCount, MonitorCount
    if ( MonitorCount = 1)
    {
        Send #{Right}
        Send {Esc}
    }else
    {
        Loop, %MonitorCount%
        {
            SysGet, MonitorWorkArea, MonitorWorkArea, %A_Index%
            if ( MonitorWorkAreaLeft  > 0 )
            {
                WinMove,A,, %MonitorWorkAreaLeft%, %MonitorWorkAreaTop%
                WinMaximize,A
                return
            }
        }
    }
}

activateAll(winTitle){
    WinGet,Windows,List,%winTitle%
    Loop,%Windows%
    {
        this_id := "ahk_id " . Windows%A_Index%
        WinActivate, %this_id%
    }
}
