; Begin Configuration
WindowTitle := "Earth & Beyond"
; End Configuration

; Begin Initialization
#SingleInstance Force
#WinActivateForce
#Warn ; Enable warnings to assist with detecting common errors.
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.
;SetWinDelay 100 ; This is the default
SetKeyDelay 20, 20
SetMouseDelay 20
ClickDelay := 300 ; SendInput has zero delay, so add a small one (increases reliability)
CoordMode "Mouse", "Client"
Persistent  ; Prevent the script from exiting automatically.

LEADER_ID := 0
ALL_IDS := Array()
OTHER_IDS := Array()
MouseLeaderX := 0
MouseLeaderY := 0
    
; Assume Earth & Beyond is already started
WindowLocations.Calibrate(WindowTitle)

MsgBox "Initialized! Press Alt+f to multi-fire!"
; End Initialization

!f:: { ; Alt+f - Multi-fire, assumes active window is leader, all others assist and fire.
    global
    KeyWait "Alt"
    
    ; assume that the leader is the active window the first time this is called
    if LEADER_ID == 0 {
        LEADER_ID := WinGetID("A")
        ALL_IDS := WinGetList(WindowTitle)
        for id in ALL_IDS {
            if id != LEADER_ID {
                OTHER_IDS.Push id
            }
        }
    }

    ; remove the ';' below to uncomment this line if you want to also target the nearest enemy to leader first
    ;SendKeyToWin("e", LEADER_ID)

    SendClickToOthers("TargetLeaderTarget")
    SendKeyToAll("f")
}

SendKeyToWin(key, hwnd) {
    if WinExist("ahk_id " hwnd)
    {
        WinActivateCustom(hwnd)
        Send(key)
        Sleep(ClickDelay)
    }
}

SendKeyToAll(key) {
    bound_func := SendKeyToWin.Bind(key)
    ForEach(bound_func)
}

SendClickToOthers(location) {
    bound_func := SendClickToLocWin.Bind(location)
    ForEachOthers(bound_func)
}

SendClickToLocWin(location, hwnd) {
    SendClickToWin(hwnd,
                   WindowLocations.Scaled[location].x,
                   WindowLocations.Scaled[location].y)
}

SendClickToWin(hwnd, x, y) {
    if WinExist("ahk_id " hwnd)
    {
        WinActivateCustom(hwnd)
        Send("{Click " x " " y "}")
        Sleep(ClickDelay)
    }
}

ForEach(bound_func) {
    global
    for hwnd in ALL_IDS
    {
        bound_func.Call(hwnd)
    }
    WinActivateCustom(LEADER_ID)
}

ForEachOthers(bound_func) {
    global
    for hwnd in OTHER_IDS 
    {
        bound_func.Call(hwnd)
    }
    WinActivateCustom(LEADER_ID)
}

WinActivateCustom(hwnd) {
    global
    if (WinExist("ahk_id " hwnd) and not WinActive("ahk_id " hwnd))
    {
        if WinActive("ahk_id " LEADER_ID)
        {
            MouseGetPos(&MouseLeaderX, &MouseLeaderY)
        }

        WinActivate("ahk_id " hwnd)

        if WinActive("ahk_id " LEADER_ID)
        {
            MouseMove(MouseLeaderX, MouseLeaderY)
        }
    }
}

class ObjectXY {
    x := 0
    y := 0
    __New(xIn, yIn) {
        this.x := xIn
        this.y := yIn
    }
}

; Gathered originally via WindowSpy, Client: x, y (default)
; These correspond to WinGetClientPos
class WindowLocations {
    static Absolute := Map()
    static Scaled := Map()
    static Calibrated := 0

    static __New() {
        ; These were the dimensions on which all the points were measured
        WindowLocations.Absolute["Base"] := ObjectXY(1826, 1370)

        WindowLocations.Absolute["TargetLeaderTarget"] := ObjectXY(1742, 815)
    }

    static Calibrate(title) {
        local cw, ch, k, v, x, y

        if(WindowLocations.Calibrated)
            return

        if WinWait(title, , 30) {
            WinActivate(title)
        } else {
            MsgBox "title: " title " not found in time, exiting..."
            ExitApp
        }
        WinGetClientPos(, , &cw, &ch, title)

        for k,v in WindowLocations.Absolute {
            if(k == "Base")
                continue
            x := Round(v.x * cw / WindowLocations.Absolute["Base"].x)
            y := Round(v.y * ch / WindowLocations.Absolute["Base"].y)
            WindowLocations.Scaled[k] := ObjectXY(x, y)
        }

        WindowLocations.Calibrated := 1
    }
}
