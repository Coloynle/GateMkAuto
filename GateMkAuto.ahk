#Requires AutoHotkey v2.0
#SingleInstance Force
CoordMode "ToolTip", "Window"
CoordMode "Mouse", "Window"
CoordMode "Pixel", "Window"

GMGui := GateMkGui()
GMGui.Show()

F1:: GMGui.Show()
F2:: GMGui.GateMk.Test()

F10:: Pause -1
F11:: GMGui.GateMk.Exit()
F12:: ExitApp

class GateMk {
    WinTitle := "ahk_exe GateMK-Win64-Shipping.exe"
    BaseWidth := 1440
    BaseHeight := 900
    Width := 0
    Height := 0
    Status := "未启动"
    Route := "通用"
    AllRoute := []
    ScriptDir := A_ScriptDir
    ConfigFolder := this.ScriptDir . "\config"
    ConfigIniPath := this.ConfigFolder . "\config.ini"
    FightIniPath := this.configFolder . "\Fight\"
    RoutePath := this.configFolder . "\Route"
    CurrentRouteIni := this.RoutePath . "\空想王国.ini"

    FightIniKeys := ["StarFight", "Esc", "LeaveFight1", "LeaveFight2", "Resume", "Avoid", "Verify", "Leave"]
    ; Fight := Map("Color", "0xEF4C4A", "PosX", "1380", "PosY", "599")
    StarFight := Map("Color", "0xEF6100", "PosX", "585", "PosY", "708")
    Esc := Map("Color", "0xFFFFFF", "PosX", "70", "PosY", "90")
    LeaveFight1 := Map("Color", "0xEF6100", "PosX", "688", "PosY", "739")
    LeaveFight2 := Map("Color", "0x29FFFF", "PosX", "748", "PosY", "589")
    Resume := Map("Color", "0xFFFFFF", "PosX", "616", "PosY", "592")
    Avoid := Map("Color", "0x7B6C91", "PosX", "953", "PosY", "576")
    Verify := Map("Color", "0xFFFFFF", "PosX", "806", "PosY", "597")
    Leave := Map("Color", "0xB2C1CE", "PosX", "100", "PosY", "100")


    DefaultStarFight := Map("Color", "0xEF6100", "PosX", "585", "PosY", "708")
    DefaultEsc := Map("Color", "0xFFFFFF", "PosX", "70", "PosY", "90")
    DefaultLeaveFight1 := Map("Color", "0xEF6100", "PosX", "688", "PosY", "739")
    DefaultLeaveFight2 := Map("Color", "0x29FFFF", "PosX", "748", "PosY", "589")
    DefaultResume := Map("Color", "0xFFFFFF", "PosX", "616", "PosY", "592")
    DefaultAvoid := Map("Color", "0x7B6C91", "PosX", "953", "PosY", "576")
    DefaultVerify := Map("Color", "0xFFFFFF", "PosX", "806", "PosY", "597")
    DefaultLeave := Map("Color", "0xB2C1CE", "PosX", "100", "PosY", "100")


    RunSleep := 1000
    AutoSkipFightStatus := 1
    NotSkipFight := false

    StatusBar := ''

    ExitStatus := false
    FightStepKey := Array()
    FightStep := Map()

    __New() {
        if this.Activate() {
            WinGetClientPos(, , &width, &height, this.WinTitle)
            this.Width := width
            this.Height := height
            this.Status := "已启动"
        }
        this.FightIniPath := this.FightIniPath . this.Width . 'x' . this.Height . '.ini'
        File := FileExist(this.ConfigFolder)
        if File != 'D'
            DirCreate(this.ConfigFolder)
        if !FileExist(this.FightIniPath)
            this.DefaultIni()
        else
            this.IniInit()

        this.NotActiveTimer := this.NotActive.Bind(this)
    }

    Activate() {
        if WinExist(this.WinTitle) {
            WinActivate(this.WinTitle)
            return true
        } else {
            MsgBox "游戏未启动"
            return false
        }
    }

    SetStatusBar(StatusBar) {
        this.StatusBar := StatusBar
    }

    DefaultIni() {
        this.FightDefaultIni()
        this.RouteIniInit()
        this.ConfigIniInit()
    }

    IniInit() {
        this.FightIniInit()
        this.RouteIniInit()
        this.ConfigIniInit()
    }

    FightDefaultIni() {
        for Section in this.FightIniKeys {
            IniWrite(this.%Section%['Color'], this.FightIniPath, Section, "Color")
            IniWrite(this.%Section%['PosX'], this.FightIniPath, Section, "PosX")
            IniWrite(this.%Section%['PosY'], this.FightIniPath, Section, "PosY")
        }
    }

    FightIniInit() {
        for Section in this.FightIniKeys {
            this.%Section%['Color'] := IniRead(this.FightIniPath, Section, "Color")
            this.%Section%['PosX'] := IniRead(this.FightIniPath, Section, "PosX")
            this.%Section%['PosY'] := IniRead(this.FightIniPath, Section, "PosY")
        }
    }

    RouteIniInit() {
        CurrentRoute := IniRead(this.ConfigIniPath, "CurrentRoute", "Path")
        if CurrentRoute = "" {
            CurrentRoute := "通用"
        }
        this.Route := CurrentRoute
        IniWrite(this.Route, this.ConfigIniPath, "CurrentRoute", "Path")
        if this.Route != "通用" {
            this.CurrentRouteIni := this.RoutePath . "\" . this.Route . ".ini"
            this.GetPath(this.CurrentRouteIni)
        }
    }

    ConfigIniInit() {
        this.RunSleep := IniRead(this.ConfigIniPath, "RunSleep", "Time")
        this.AutoSkipFightStatus := IniRead(this.ConfigIniPath, "SkipFight", "Status")
        this.AllRoute := StrSplit(IniRead(this.ConfigIniPath, "AllRoute"), ",")
    }

    SetCurrentRoute(Route) {
        IniWrite(Route, this.ConfigIniPath, "CurrentRoute", "Path")
    }

    ToolTip(Msg, Time := 5000) {
        ToolTip(Msg, 8, this.Height)
        SetTimer () => ToolTip(), -Time
        if this.StatusBar {
            this.StatusBar.SetText(Msg)
        }
    }

    SetFightIni(Section) {
        Button := this.FindButton()
        IniWrite(Button['Color'], this.FightIniPath, Section, "Color")
        IniWrite(Button['PosX'], this.FightIniPath, Section, "PosX")
        IniWrite(Button['PosY'], this.FightIniPath, Section, "PosY")
        return Button
    }

    FindButton() {
        MouseGetPos(&PosX, &PosY)
        color := PixelGetColor(PosX, PosY)
        this.ToolTip("Color" color)
        return Map("Color", Color, "PosX", PosX, "PosY", PosY)
    }

    SetFightIniAuto(Section) {
        DefalutBase := this.Default%Section%
        Default := Map("Color", DefalutBase['Color'], "PosX", DefalutBase['PosX'], "PosY", DefalutBase['PosY'])

        Default['PosX'] := Round(Default['PosX'] * this.Width / this.BaseWidth)
        Default['PosY'] := Round(Default['PosY'] * this.Height / this.BaseHeight)
        search := PixelSearch(&PosX, &PosY, Default["PosX"] - 30, Default["PosY"] - 30, Default["PosX"] + 20, Default["PosY"] + 30, Default["Color"], 0)
        if search {
            color := PixelGetColor(PosX, PosY)
            this.ToolTip("Color:" color)
            Button := Map("Color", Color, "PosX", PosX, "PosY", PosY)
            IniWrite(Button['Color'], this.FightIniPath, Section, "Color")
            IniWrite(Button['PosX'], this.FightIniPath, Section, "PosX")
            IniWrite(Button['PosY'], this.FightIniPath, Section, "PosY")
            return Button
        } else {
            MsgBox "快捷寻找失败，请确认游戏中按钮存在或使用获取自行选择位置"
            return false
        }
    }

    SetRunSleep(Time) {
        this.RunSleep := Time
        IniWrite(Time, this.ConfigIniPath, "RunSleep", "Time")
    }

    SetSkipFight(Status) {
        Status := Status = 0 ? 0 : 1
        this.AutoSkipFightStatus := Status
        IniWrite(Status, this.ConfigIniPath, "SkipFight", "Status")
    }

    SkipFight() {
        this.ExitFlag()
        if this.AutoSkipFightStatus {
            this.ToolTip("发现战斗，自动跳过")
            Sleep(1000)
            ;移动到战斗按钮
            MouseClick("Left", this.StarFight['PosX'], this.StarFight['PosY'])
            Sleep(1000)
            while !this.CheckPixel(this.Esc) {
                this.ExitFlag()
                Sleep(500)
                this.ToolTip("等待ESC按钮加载")
            }
            MouseClick("Left", this.Esc['PosX'], this.Esc['PosY'])
            Sleep(800)
            MouseClick("Left", this.LeaveFight1['PosX'], this.LeaveFight1['PosY'])
            Sleep(1000)
            MouseClick("Left", this.LeaveFight2['PosX'], this.LeaveFight2['PosY'])
            Sleep(500)
            while !this.CheckPixel(this.Resume) {
                this.ExitFlag()
                Sleep(300)
                this.ToolTip("等待继续按钮加载")
            }
            MouseClick("Left", this.Resume['PosX'], this.Resume['PosY'])
            Sleep(800)
            MouseClick("Left", this.Avoid['PosX'], this.Avoid['PosY'])
            Sleep(800)
            MouseClick("Left", this.Verify['PosX'], this.Verify['PosY'])
            Sleep(800)
        } else {
            this.ToolTip("发现战斗，暂停脚本，按下F8继续脚本", 10000000)
            KeyWait("F8", "D")
            this.ToolTip("流程继续")
            this.NotSkipFight := true
        }
    }

    GetPath(Path) {
        try
            SectionsStr := IniRead(Path)
        catch as e {
            MsgBox "路线配置文件不存在"
            this.FightStep := Map()
        } else {
            this.FightStepKey := StrSplit(SectionsStr, '`n')
            for index, Section in this.FightStepKey {
                key := IniRead(Path, Section)
                this.FightStep[Section] := StrSplit(key, ',')
            }
        }
    }

    CheckPixel(Map) {
        return PixelSearch(&OutX, &OutY, Map["PosX"] - 10, Map["PosY"] - 10, Map["PosX"] + 10, Map["PosY"] + 10, Map["Color"], 0)
    }

    NotActive() {
        this.ExitFlag()
        if !WinActive(this.WinTitle) {
            this.ToolTip('游戏窗口不活跃，暂停脚本')
            while !WinWaitActive(this.WinTitle, , 1) {
                this.ExitFlag()
            }
        }
    }

    Exit() {
        this.ExitStatus := true
    }

    ExitFlag() {
        if this.ExitStatus {
            this.ToolTip('停止运行')
            SetTimer this.NotActiveTimer, 0
            Exit
        }
    }

    Run() {
        this.ExitStatus := false
        this.Activate()
        SetTimer this.NotActiveTimer, 10
        IsFight := 0

        if this.Route = "通用" {
            i := 0
            Loop {
                this.ExitFlag()
                this.ToolTip(i++ . "{Enter}")
                Send "{Enter}"
                Sleep(500)
                if this.CheckPixel(this.StarFight) {
                    this.SkipFight()
                }
            }
        } else {
            for section in this.FightStepKey {
                Sleep(1000)
                while !this.CheckPixel(this.Leave) {
                    this.ExitFlag()
                    Sleep(100)
                }
                for index, key in this.FightStep[section] {
                    this.ExitFlag()
                    ; 不跳过战斗的话跳过下一个按键
                    if this.NotSkipFight {
                        this.NotSkipFight := false
                        continue
                    }
                    this.ToolTip(section "-" index "-" key)
                    Send key
                    if key = "{Enter}" {
                        Sleep(500)
                    }
                    Sleep(this.RunSleep)
                    if this.CheckPixel(this.StarFight) {
                        this.SkipFight()
                    }
                }
            }
        }
        SetTimer this.NotActiveTimer, 0
    }

    Test() {
    }
}

Class GateMkGui {
    Version := "v1.0"
    Title := "白荆回廊自动漫巡" . this.Version . " - 免费使用"
    GateMk := ''
    StausBar := ''
    MyGui := ''
    FightIniMapKey := ["StarFight", "Esc", "LeaveFight1", "LeaveFight2", "Resume", "Avoid", "Verify", "Leave"]
    FightIniMap := Map("StarFight", "开始战斗", "Esc", "Esc", "LeaveFight1", "离开战斗1", "LeaveFight2", "离开战斗2", "Resume", "继续", "Avoid", "回避", "Verify", "确认", "Leave", "离开")
    fightIniGui := Map("StarFight", Map("C", "", "X", "", "Y", ""), "Esc", Map("C", "", "X", "", "Y", ""), "LeaveFight1", Map("C", "", "X", "", "Y", ""), "LeaveFight2", Map("C", "", "X", "", "Y", ""), "Resume", Map("C", "", "X", "", "Y", ""), "Avoid", Map("C", "", "X", "", "Y", ""), "Verify", Map("C", "", "X", "", "Y", ""), "Leave", Map("C", "", "X", "", "Y", ""))
    GateMkGui := Map("Status", "", "Width", "", "Height", "", "Route", "")

    __New() {
        MyGui := Gui(, this.Title)
        this.StausBar := MyGui.AddStatusBar(, '免费使用')
        ; 初始化GateMk
        this.InitGateMk()
        Tab := MyGui.AddTab3("w400", ["自动漫巡", "路线配置", "跳过战斗配置"])

        ; 自动漫巡
        Tab.UseTab(1)
        MyGui.AddGroupBox("w380 h100 Section", "白荆回廊")
        MyGui.AddText("x40 y50", "进程:")
        this.GateMkGui["Status"] := MyGui.AddText("x100 yp w50", this.GateMk.Status)
        MyGui.AddText("x40 yp+20", "宽:")
        this.GateMkGui["Width"] := MyGui.AddText("x100 yp w50", this.GateMk.Width)
        MyGui.AddText("x40 yp+20", "高:")
        this.GateMkGui["Height"] := MyGui.AddText("x100 yp w50", this.GateMk.Height)
        MyGui.AddText("x40 yp+20", "路线:")
        this.GateMkGui["Route"] := MyGui.AddText("x100 yp w100", this.GateMk.Route)
        GetGateMkButton := MyGui.AddButton("x330 y100", "获取进程")
        GetGateMkButton.OnEvent("Click", GetGateMkObj)

        GetGateMkObj(GuiCtrlObj, *) {
            if this.GateMk.Activate() {
                this.InitGateMk()
                this.GateMkGui["Status"].Text := this.GateMk.Status
                this.GateMkGui["Width"].Text := this.GateMk.Width
                this.GateMkGui["Height"].Text := this.GateMk.Height
                this.GateMkGui["Route"].Text := this.GateMk.Route
                for fightIniKey in this.FightIniMapKey {
                    IniMap := this.GateMk.%fightIniKey%
                    Color := IniMap['Color']
                    this.fightIniGui[fightIniKey]["CS"].SetFont('c' Color)
                    this.fightIniGui[fightIniKey]["C"].Text := Color
                    this.fightIniGui[fightIniKey]["X"].Text := IniMap['PosX']
                    this.fightIniGui[fightIniKey]["Y"].Text := IniMap['PosY']
                }
                this.GateMk.ToolTip('获取成功')
            }
        }

        MyGui.AddGroupBox("xs w380 h50 Section", "路线选择")
        RouteSelectArray := ["通用"]
        RouteSelectArray.Push(this.GateMk.AllRoute*)
        RouteSelect := MyGui.AddDropDownList("vRouteSelect x40 yp+20 Choose1", RouteSelectArray)
        ChooseRounteButton := MyGui.AddButton("x330 yp", "确认路线")
        ChooseRounteButton.OnEvent("Click", SetGateMkRoute)

        SetGateMkRoute(GuiCtrlObj, *) {
            Route := RouteSelect.Text
            this.GateMk.SetCurrentRoute(Route)
            this.GateMk.RouteIniInit()
            this.GateMkGui["Route"].Text := this.GateMk.Route
        }

        MyGui.AddGroupBox("xs w380 h70 Section", "漫巡配置")
        MyGui.AddText("x40 yp+20", "自动跳过战斗:")
        StatusName := this.GateMk.AutoSkipFightStatus = 0 ? "关闭" : "开启"
        ButtonName := this.GateMk.AutoSkipFightStatus = 0 ? "开启" : "关闭"
        AutoSkipFightText := MyGui.AddText("xp+140 yp w50", StatusName)
        AutoSkipFightTextButton := MyGui.AddButton("x330 yp-5", ButtonName)
        AutoSkipFightTextButton.OnEvent("Click", SwitchAutoSkip)
        SwitchAutoSkip(GuiCtrlObj, *) {
            SwitchStatus := this.GateMk.AutoSkipFightStatus = 0 ? 1 : 0
            this.GateMk.SetSkipFight(SwitchStatus)
            StatusName := this.GateMk.AutoSkipFightStatus = 0 ? "关闭" : "开启"
            ButtonName := this.GateMk.AutoSkipFightStatus = 0 ? "开启" : "关闭"
            AutoSkipFightText.Text := StatusName
            AutoSkipFightTextButton.Text := ButtonName
        }


        MyGui.AddText("x40 yp+30", "自动漫巡间隔(ms):")
        RunSleepText := MyGui.AddText("xp+140 yp w50", "0000000")
        RunSleepText.Text := this.GateMk.RunSleep
        RunSleepButton := MyGui.AddButton("x330 yp-5", "设置")
        RunSleepButton.OnEvent("Click", RunSleepInput)
        RunSleepInput(GuiCtrlObj, *) {
            Time := InputBox("请输入新的漫巡间隔，单位毫秒(ms)", "间隔时间", "w220 h90")
            if Time.Result = "Cancel"
                return
            else
                if !IsInteger(Time.Value) {
                    MsgBox "输入内容必须为数字"
                } else {
                    this.GateMk.SetRunSleep(Time.Value)
                    RunSleepText.Text := this.GateMk.RunSleep
                }
        }

        StartButton := MyGui.AddButton("xs w380", "开始漫巡")
        StartButton.OnEvent("Click", Run)
        Run(GuiCtrlObj, *) {
            this.GateMk.Run()
        }
        Hotkey "F9", Run, "On"

        Tab.UseTab(2)
        RouteListBox := MyGui.AddListBox("h500 w100 Section", this.GateMk.AllRoute)
        RouteListBox.OnEvent('Change', RouteLoad)
        RouteEdit := MyGui.AddEdit("yp h495 w270", "")
        StartButton := MyGui.AddButton("xs w380", "保存")
        StartButton.OnEvent('Click', SaveRouteConfig)

        RouteLoad(GuiCtrlObj, *) {
            Route := GuiCtrlObj.Text
            RoutePath := this.GateMk.RoutePath . "\" . Route . ".ini"
            try
                RouteContent := FileRead(RoutePath)
            catch as e {
                RouteContent := ""
            }
            RouteEdit.Text := RouteContent
        }

        SaveRouteConfig(GuiCtrlObj, *) {
            Route := RouteListBox.Text
            RoutePath := this.GateMk.RoutePath . "\" . Route . ".ini"
            RoutePathBak := RoutePath . ".bak"
            if FileExist(RoutePath) {
                FileCopy(RoutePath, RoutePathBak, true)
                FileDelete(RoutePath)
            }
            FileAppend(RouteEdit.Text, RoutePath)
            MsgBox "保存成功"
        }

        Tab.UseTab(3)

        ; 第一行不需要xs
        first := ''
        for fightIniKey in this.FightIniMapKey {
            MyGui.AddGroupBox("w380 Section " first, this.FightIniMap[fightIniKey])
            if this.GateMk {
                IniMap := this.GateMk.%fightIniKey%
            } else {
                IniMap := Map("Color", "0x000000", "PosX", "1", "PosY", "1")
            }
            Color := IniMap['Color']
            PosX := IniMap['PosX']
            PosY := IniMap['PosY']
            MyGui.AddText("xs+20 ys+30", "颜色:")
            this.fightIniGui[fightIniKey]["CS"] := MyGui.AddText("xp+40 yp c" Color, "■")
            this.fightIniGui[fightIniKey]["C"] := MyGui.AddText("xp+10 yp v" fightIniKey "C", Color)
            MyGui.AddText("xp+60 yp", "坐标X:")
            this.fightIniGui[fightIniKey]["X"] := MyGui.AddText("xp+40 yp v" fightIniKey "X", "0000")
            this.fightIniGui[fightIniKey]["X"].Text := PosX
            MyGui.AddText("xp+30 yp", "坐标Y:")
            this.fightIniGui[fightIniKey]["Y"] := MyGui.AddText("xp+40 yp v" fightIniKey "Y", "0000")
            this.fightIniGui[fightIniKey]["Y"].Text := PosY
            Button := MyGui.AddButton("xp+30 yp-5 v" fightIniKey, "获取")
            ButtonAuto := MyGui.AddButton("xp+40 yp vAuto" fightIniKey, "自动获取")
            ; Button2 := MyGui.AddButton("xp+40 yp v" fightIniKey "Re", "重置")
            Button.OnEvent("Click", GetColorObj)
            ButtonAuto.OnEvent("Click", GetColorObjAuto)

            first := "xs"
        }
        GetColorObj(GuiCtrlObj, *) {
            if this.GateMk.Activate() {
                MsgBox("光标移动到需要点击的地方，按下Alt+Q")
                HotIfWinActive this.GateMk.WinTitle
                Hotkey "!Q", Disposable, "On"
                Disposable(HotkeyName) {
                    Color := this.GateMk.SetFightIni(GuiCtrlObj.Name)
                    this.GateMk.ToolTip("获取成功 Color:" Color['Color'] " X:" Color['PosX'] " Y:" Color['PosY'])
                    this.fightIniGui[GuiCtrlObj.Name]["CS"].SetFont('c' Color['Color'])
                    this.fightIniGui[GuiCtrlObj.Name]["C"].Text := Color['Color']
                    this.fightIniGui[GuiCtrlObj.Name]["X"].Text := Color['PosX']
                    this.fightIniGui[GuiCtrlObj.Name]["Y"].Text := Color['PosY']
                    Hotkey HotkeyName, "Off"
                }
            }
        }

        GetColorObjAuto(GuiCtrlObj, *) {
            if this.GateMk.Activate() {
                Section := StrReplace(GuiCtrlObj.Name, "Auto", "")
                Color := this.GateMk.SetFightIniAuto(Section)
                if !Color {
                    return
                }
                this.GateMk.ToolTip("获取成功 Color:" Color['Color'] " X:" Color['PosX'] " Y:" Color['PosY'])
                this.fightIniGui[Section]["CS"].SetFont('c' Color['Color'])
                this.fightIniGui[Section]["C"].Text := Color['Color']
                this.fightIniGui[Section]["X"].Text := Color['PosX']
                this.fightIniGui[Section]["Y"].Text := Color['PosY']
            }
        }


        this.MyGui := MyGui

    }

    InitGateMk() {
        this.GateMk := GateMk()
        this.GateMk.SetStatusBar(this.StausBar)
    }

    Show() {
        this.MyGui.Show()
    }

}