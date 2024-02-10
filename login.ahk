; Begin Configuration
NeedsConfiguration()
NeedsConfiguration() {
    local L, T, R, B, WL, WT, WR, WB
    MsgBox "FIXME - You need to modify login.ahk to set the configuration values and remove the call to this function!"
    MonitorCount := MonitorGetCount()
    MonitorPrimary := MonitorGetPrimary()
    MsgBox "Monitor Count:`t" MonitorCount "`nPrimary Monitor:`t" MonitorPrimary
    Loop MonitorCount
    {
        MonitorGet A_Index, &L, &T, &R, &B
        MonitorGetWorkArea A_Index, &WL, &WT, &WR, &WB
        MsgBox
        (
            "Monitor:`t#" A_Index "
            Name:`t" MonitorGetName(A_Index) "
            Left:`t" L " (" WL " work)
            Top:`t" T " (" WT " work)
            Right:`t" R " (" WR " work)
            Bottom:`t" B " (" WB " work)"
        )
    }
    ExitApp
}

N7_PATH := "C:\Program Files (x86)\Net-7\"
;N7_PATH := "C:\Program Files\Net-7\"

MAX_CLIENTS := 6
CURRENT_CLIENTS := MAX_CLIENTS
; default calculates based on 3x2 grid for CURRENT_CLIENTS=6
CLIENT_WIDTH := "default"
CLIENT_HEIGHT := "default"

;CLIENT_WIDTH := "1280"
;CLIENT_HEIGHT := "960"

; These can be used to tweak the size and position of the client windows
; respectively while mostly using the default sizing/positioning. This was
; necessary on Linux but probably isn't on Windows.
CLIENT_X_BORDER_DELTA := 0 ; -6 for Linux
CLIENT_Y_BORDER_DELTA := 0 ; 6 for Linux
CLIENT_X_MOVE_DELTA := 0 ; -6 for Linux
CLIENT_Y_MOVE_DELTA := 0 ; 10 for Linux
CLIENT_X_DESKTOP_DELTA := 0 ; -4 for Linux
CLIENT_Y_DESKTOP_DELTA := 0 ; 0 for Linux

; Client 1
USER1 := "user1"
PASS1 := "pass1"
; top left corner
X1 := "default"
Y1 := "default"
; The monitor setting is only used for the relative size and position
; defaults; AHK has no way to move a window to a particular monitor so you have
; to use the X/Y coords above to explicitly specify coords which are +/- pixels
; relative to your primary monitor (1) to shift the windows onto the correct
; one. If you only have one monitor you can just leave this as default,
; otherwise it should be set to the integer values reported by
; NeedsConfiguration representing the monitor you want this client on.
MONITOR1 := "default"

; Client 2
USER2 := "user2"
PASS2 := "pass2"
X2 := "default"
Y2 := "default"
MONITOR2 := "default"

; Client 3
USER3 := "user3"
PASS3 := "pass3"
X3 := "default"
Y3 := "default"
MONITOR3 := "default"

; Client 4
USER4 := "user4"
PASS4 := "pass4"
X4 := "default"
Y4 := "default"
MONITOR4 := "default"

; Client 5
USER5 := "user5"
PASS5 := "pass5"
X5 := "default"
Y5 := "default"
MONITOR5 := "default"

; Client 6
USER6 := "user6"
PASS6 := "pass6"
X6 := "default"
Y6 := "default"
MONITOR6 := "default"
; End Configuration

; Begin Initialization
#SingleInstance Force
#WinActivateForce
#Warn ; Enable warnings to assist with detecting common errors.
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.
CoordMode "Mouse", "Client"
Persistent  ; Prevent the script from exiting automatically.
MsgBox "Initialized! Ctrl+Shift+m to start clients"
; End Initialization

; Super+= : Switch to 1-client mode.
#=::
{
    SetResolution(1, 1, 1)
}

; Super+- : Switch to MAX_CLIENTS mode.
#-::
{
    SetResolution(6, 3, 2)
}

; Ctrl+Shift+m : Create CURRENT_CLIENTS.
^+m::
{
    Loop CURRENT_CLIENTS {
        StartLaunchNet7()
    }

    Loop CURRENT_CLIENTS {
        AcceptRulesOfConduct()
    }

    ; wait for all the Rules of Conduct to close as they have the same window title as the game window
    Sleep(1000)

    FindAndActivate("Earth & Beyond")
    WindowLocations.Calibrate("Earth & Beyond")

    ; wait for all the clients to fully load
    Sleep(10000)

    enbids := WinGetList("Earth & Beyond")
    for enbid in enbids {
        index := A_Index
        FindAndActivate("ahk_id " enbid)
        LoginClient(index)
    }
}

; Ctrl+Shift+1
^+1::
{
    LoginClient(1)
}

; Ctrl+Shift+2
^+2::
{
    LoginClient(2)
}

; Ctrl+Shift+3
^+3::
{
    LoginClient(3)
}

; Ctrl+Shift+4
^+4::
{
    LoginClient(4)
}

; Ctrl+Shift+5
^+5::
{
    LoginClient(5)
}

; Ctrl+Shift+6
^+6::
{
    LoginClient(6)
}

;;;;;;;;;;;;;;;;;;;;
; Helper Functions ;
;;;;;;;;;;;;;;;;;;;;

; Set optimal resolution for X Clients in an gx*gy grid, e.g.
; 1 2 3
; 4 5 6
; SetResolution(6, 3, 2)
SetResolution(Clients, gx, gy) {
    global
    local WL, WT, WR, WB, w, h, cw, ch, cww, cwh, xwaste, ywaste
    CURRENT_CLIENTS := Clients
    if CLIENT_WIDTH == "default" {
        ; get the max possible area we can occupy sans task bars, etc.
        MonitorGetWorkArea(1, &WL, &WT, &WR, &WB)
        w := WR - WL
        h := WB - WT

        ; get the amount of wasted space associated with each window due to title bars and borders
        GetGameAreaSizeByTitle("A", &cw, &ch)
        GetWindowSizeWithBordersByTitle("A", &cww, &cwh)
        xwaste := cww - cw + CLIENT_X_BORDER_DELTA ; 6 before delta
        ywaste := cwh - ch + CLIENT_Y_BORDER_DELTA ; 32 before delta

        ; reduce the work area by that amount times the expected number of clients
        w := w - (xwaste * gx)
        h := h - (ywaste * gy)

        ; first try with vertical resolution as the limiting factor (i.e. for ultrawides)
        ch := Floor(h / gy)
        cw := Floor(( ch * 4 ) / 3)
        if cw * gx > w {
            ; failing that use horizontal resolution as the limiting factor
            cw := Floor(w / gx)
            ch := Floor(( cw * 3 ) / 4)
        }
    } else {
        cw := CLIENT_WIDTH
        ch := CLIENT_HEIGHT
    }

    RegWrite(cw, "REG_DWORD", "HKEY_LOCAL_MACHINE\SOFTWARE\Westwood Studios\Earth and Beyond\Render", "RenderDeviceWidth")
    RegWrite(ch, "REG_DWORD", "HKEY_LOCAL_MACHINE\SOFTWARE\Westwood Studios\Earth and Beyond\Render", "RenderDeviceHeight")
    RegWrite(1, "REG_DWORD", "HKEY_LOCAL_MACHINE\SOFTWARE\Westwood Studios\Earth and Beyond\Render", "RenderDeviceWindowed")
    MsgBox "RenderDeviceWindowed: 1`nRenderDeviceWidth: " cw "`nRenderDeviceHeight:" ch
}

FindAndActivate(WinTitle, WinText := "") {
    if WinWait(WinTitle, WinText, 30) {
        WinActivate(WinTitle, WinText)
    } else {
        MsgBox "WinTitle: " WinTitle ", WinText: " WinText " not found in time, exiting..."
        ExitApp
    }
}

FindAndActivateIfExists(WinTitle, WinText := "") {
    if WinWait(WinTitle, WinText, 1) {
        WinActivate(WinTitle, WinText)
        return 1
    }
    return 0
}

StartLaunchNet7()
{
    ; Launch Net7 and update if necessary
    Run N7_PATH . "bin\LaunchNet7.exe", N7_PATH

    failed := 0
    Loop {
        if FindAndActivateIfExists("LaunchNet7 - Information") {
            failed := 0
            ControlClick("Cancel")
            WinWaitClose()
            continue
        }

        if FindAndActivateIfExists("Update available") {
            failed := 0
            ControlClick("Update")
            WinWaitClose()
            continue
        }

        if FindAndActivateIfExists("LaunchNet7 v") {
            failed := 0
            PlayEnabled := ControlGetEnabled("Play")
            if PlayEnabled {
                ControlClick("Play")
                WinWaitClose()
                break
            }
        }

        failed := failed + 1
        if (failed > 60) {
            MsgBox N7_PATH . "bin\LaunchNet7.exe failed to start, exiting..."
            ExitApp
        }
        Sleep 100
    }
}

AcceptRulesOfConduct()
{
    failed := 0
    Loop {
        if FindAndActivateIfExists("Earth & Beyond", "I Agree") {
            failed := 0
            AgreeEnabled := ControlGetEnabled("I Agree")
            if AgreeEnabled {
                ControlClick("I Agree")
                WinWaitClose()
                break
            }
        }

        failed := failed + 1
        if (failed > 60) {
            MsgBox "Rules of Conduct pop-up failed to appear, exiting..."
            ExitApp
        }
        Sleep 100
    }
}

MoveClientWindow(index, title)
{
    local xconfv, yconfv, mconfv, m, WL, WT, WR, WB, wx, wy, cww, cwh, gx, gy, x, y

    ; stacked layout simply leaves the windows where they are
    ; default layout is to tile the windows in a grid gx*gy where gx is typically 3 and gy is typically 2 for 6 clients
    ; 1 2 3
    ; 4 5 6
    ; anything else will be interpreted as explicit desktop coords for the top left corner

    xconfv := "X" . index
    yconfv := "Y" . index
    mconfv := "MONITOR" . index

    if %xconfv% == "stacked"
        return
    else if %xconfv% == "default" {
        if %mconfv% == "default"
            m := 1
        else
            m := %mconfv%
        MonitorGetWorkArea(m, &WL, &WT, &WR, &WB)
        wx := WR - WL
        wy := WB - WT
        GetWindowSizeWithBordersByTitle(title, &cww, &cwh)
        cww := cww + CLIENT_X_MOVE_DELTA
        cwh := cwh + CLIENT_Y_MOVE_DELTA
        gx := Floor(wx / cww)
        gy := Floor(wy / cwh)
        x := Floor((Mod(index - 1, gx) * cww)) + WL + CLIENT_X_DESKTOP_DELTA
        y := (Floor((index - 1) / gx) * cwh) + (Floor((index - 1) / gx) >= 1? 1 : 0) + WT + CLIENT_Y_DESKTOP_DELTA
    } else {
        x := %xconfv%
        y := %yconfv%
    }

    WinMove(x, y)
}

LoginClient(index)
{
    KeyWait("Control") ; Wait for both Control and Shift to be released.
    KeyWait("Shift")

    userv := "USER" . index
    passv := "PASS" . index

    ;Change window name
    title := "enb-" . index
    ;title := "enb-" . %userv%
    WinSetTitle(title)

    MoveClientWindow(index, title)

    ;Login
    Click(WindowLocations.Scaled["LoginUser"].x, WindowLocations.Scaled["LoginUser"].y)
    Sleep(100)
    Send(%userv%)
    Sleep(100)
    Send("{Tab}")
    Sleep(100)
    Send(%passv%)
    Sleep(100)
    Send("{Enter}")
    Sleep(100)
}

GetGameAreaSizeByTitle(title, &cw := "", &ch := "") {
    WinGetClientPos(, , &cw, &ch, title)
}

GetWindowSizeWithBordersByTitle(title, &cww := "", &cwh := "") {
    WinGetPos(, , &cww, &cwh, title)
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

    static __New() {
        ; These were the dimensions on which all the points were measured
        WindowLocations.Absolute["Base"] := ObjectXY(1792, 1344)

        ; Login
        WindowLocations.Absolute["LoginUser"] := ObjectXY(426, 324)
        WindowLocations.Absolute["LoginQuit"] := ObjectXY(244, 1245)
        WindowLocations.Absolute["Yes"] := ObjectXY(721, 706)
    }

    static Calibrate(title) {
        local cw, ch
        GetGameAreaSizeByTitle(title, &cw, &ch)
        for k,v in WindowLocations.Absolute {
            x := Round(v.x * cw / WindowLocations.Absolute["Base"].x)
            y := Round(v.y * ch / WindowLocations.Absolute["Base"].y)
            WindowLocations.Scaled[k] := ObjectXY(x, y)
        }
    }
}
