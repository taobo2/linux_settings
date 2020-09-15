#z::Run https://www.autohotkey.com  ; Win+Z

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
WinRestore
WinMove, 0, 0
WinMaximize

Run, %ComSpec% /c start msedge --start-maximized --new-window http://54.84.45.75:8080/vitria-oi/app/?min=false&min.ax=false&enableGridster=true
Loop{
    WinWait, Vitria,,1
    if !ErrorLevel
        break
    WinWait, User Login,, 1
    if !ErrorLevel
        break
}

WinRestore
WinMove, 1600, 0
WinMaximize
Run, "http://54.84.45.75:8080/vitria-oi/app/?min=false#uri=/app/ax/space/Digital Operations/axv/DO - Signal Onboarding Comp"



^#,::
switch2Desktop(2)
sleep 1000
SetTitleMatchMode 2

if WinExist("Adobe") or WinExist("SumatraPDF")
    return

Run, %ComSpec% /c start acrord32 D:\dropbox\Dropbox\books\Introduction-to-Calculus-and-Analysis-Volume-2.pdf
WinWait, Adobe
WinRestore
WinMove, 1600, 0
WinMaximize

Run, "D:\dropbox\Dropbox\books\Introduction-to-Calculus-and-Analysis-Volume-2 (1).pdf"
WinWait, SumatraPDF
WinRestore
WinMove, 0, 0
WinMaximize


switch2Desktop(id){
    RegRead, cur, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\1\VirtualDesktops, CurrentVirtualDesktop
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
