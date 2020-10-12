#z::Run, %ComSpec% /c start gvim d:\projects\linux_settings\qilin_office.ahk  ; Win+Z

^!n::  ; Ctrl+Alt+N
if WinExist("Untitled - Notepad")
    WinActivate
else
    Run Notepad
return

^#m::
switch2Desktop(3)
Sleep, 1000

SetTitleMatchMode 2

if WinExist("Edge")
    return

Run https://www.youtube.com/
WinWait, YouTube
move2Left()

Run, %ComSpec% /c start msedge --start-maximized --new-window http://54.84.45.75:8080/vitria-oi/app/?min=false&min.ax=false&enableGridster=true
Loop{
    WinWait, Vitria,,1
    if !ErrorLevel
        break
    WinWait, User Login,, 1
    if !ErrorLevel
        break
}

move2Right()
Run, "http://54.84.45.75:8080/vitria-oi/app/?min=false#uri=/app/ax/space/Digital`%20Operations/axv/DO`%20-`%20Signal`%20Onboarding`%20Comp"
return


^#,::
switch2Desktop(2)
sleep 1000
SetTitleMatchMode 2

if WinExist("Adobe") or WinExist("SumatraPDF")
    return

Run, %ComSpec% /c start acrord32 D:\dropbox\Dropbox\books\Introduction-to-Calculus-and-Analysis-Volume-2.pdf
WinWait, Adobe
move2Right()

Run, "D:\dropbox\Dropbox\books\Introduction-to-Calculus-and-Analysis-Volume-2 (1).pdf"
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
        }
    }else
    {
        Loop % ix-id{
            Send ^#{Left}
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
    WinRestore
    SysGet, MonitorCount, MonitorCount
    if (%MonitorCount% = 1)
    {
        Send #{Left}
        Send {Esc}
    }else
    {
        WinMove,0,0
        WinMaximize
    }
}

move2Right()
{
    WinRestore
    SysGet, MonitorCount, MonitorCount
    if (%MonitorCount% = 1)
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
                WinMove, %MonitorWorkAreaLeft%, %MonitorWorkAreaTop%
                WinMaximize
                return
            }
        }
    }
}
