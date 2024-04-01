#Requires AutoHotkey v2.0
#SingleInstance Force
CoordMode "ToolTip", "Window"
CoordMode "Mouse", "Window"
CoordMode "Pixel", "Window"

class GateMk {
    BaseWeight := 1440
    BaseHeight := 900
    Weight := 0
    Height := 0
    ScriptDir := A_ScriptDir
    ConfigFolder := this.ScriptDir . "\config"
    IniPath := this.configFolder . "\白荆.ini"
    KongPath := this.configFolder . "\空想王国.ini"
    IniKeys := ["Esc", "Fight"]
    Fight := Map("Color", "0xEF4C4A", "PosX", "1380", "PosY", "599")
    LeaveFight := Map("Color", "0xFFFFFF", "PosX", "844", "PosY", "738")
    Esc := Map("Color", "0xFFFFFF", "PosX", "54", "PosY", "88")
    Resume := Map("Color", "0xFFFFFF", "PosX", "616", "PosY", "592")
    Avoid := Map("Color", "0x7B6C91", "PosX", "953", "PosY", "576")
    Verify := Map("Color", "0xFFFFFF", "PosX", "806", "PosY", "597")
    Tag := Map("Color", "0x2C9EF4", "PosX", "1042", "PosY", "548")


    FightStepKey := Array()
    FightStep := Map()

    __New() {
        WinGetClientPos(, , &weight, &height, "白荆回廊")
        this.Weight := weight
        this.Height := height
        File := FileExist(this.ConfigFolder)
        if File != 'D'
            DirCreate(this.ConfigFolder)
        if !FileExist(this.IniPath)
            this.DefaultIni()
        else
            this.IniInit()
    }

    DefaultIni() {
        this.IniWrite(this.Esc['Color'], "Esc", "Color")
        this.IniWrite(this.Esc['PosX'], "Esc", "PosX")
        this.IniWrite(this.Esc['PosY'], "Esc", "PosY")
        this.IniWrite(this.Fight['Color'], "Fight", "Color")
        this.IniWrite(this.Fight['PosX'], "Fight", "PosX")
        this.IniWrite(this.Fight['PosY'], "Fight", "PosY")
    }

    IniInit() {
        this.Esc['Color'] := this.IniRead("Esc", "Color")
        this.Esc['PosX'] := this.IniRead("Esc", "PosX")
        this.Esc['PosY'] := this.IniRead("Esc", "PosY")
        this.Fight['Color'] := this.IniRead("Fight", "Color")
        this.Fight['PosX'] := this.IniRead("Fight", "PosX")
        this.Fight['PosY'] := this.IniRead("Fight", "PosY")
    }

    ToolTip(Msg) {
        ToolTip(Msg, 8, this.Height)
    }

    IniRead(Section, Key) {
        return IniRead(this.IniPath, Section, Key)
    }

    IniWrite(Value, Section, Key) {
        IniWrite(Value, this.IniPath, Section, Key)
    }

    EscSet() {
        Button := this.FindButton()
        this.IniWrite(Button['Color'], "Esc", "Color")
        this.IniWrite(Button['PosX'], "Esc", "PosX")
        this.IniWrite(Button['PosY'], "Esc", "PosY")
    }

    FightSet() {
        Button := this.FindButton()
        this.IniWrite(Button['Color'], "Fight", "Color")
        this.IniWrite(Button['PosX'], "Fight", "PosX")
        this.IniWrite(Button['PosY'], "Fight", "PosY")
    }

    FindButton() {
        MouseGetPos(&PosX, &PosY)
        color := PixelGetColor(PosX, PosY)
        this.ToolTip("Color" color)
        return Map("Color", Color, "PosX", PosX, "PosY", PosY)
    }

    SkipFight() {
        this.ToolTip("发现战斗，自动跳过")
        ;移动到战斗按钮
        MouseClick("Left", this.Fight['PosX'], this.Fight['PosY'])
        Sleep(1000)
    }

    GetPath(Path) {
        SectionsStr := IniRead(Path)
        this.FightStepKey := StrSplit(SectionsStr, '`n')
        for index, Section in this.FightStepKey {
            key := IniRead(Path, Section)
            this.FightStep[Section] := StrSplit(key, ',')
        }
    }

    Run() {
        for section in this.FightStepKey {
            Sleep(1000)
            for index, key in this.FightStep[section] {
                this.ToolTip(section "-" index "-" key)
                Send key
                Sleep(700)
            }
        }
    }

}

^F4:: {
    a := GateMk()
    a.GetPath(a.KongPath)
    for section in a.FightStepKey {
        MsgBox section
        for index, key in a.FightStep[section] {
            MsgBox key
        }
    }

}

^F1:: {
    a := GateMk()
    a.GetPath(a.KongPath)
    a.Run()
}

^F2:: {
    a := GateMk()
    color := a.FightSet()
}

^F3:: {
    a := GateMk()
    MsgBox(a.Esc['Color'])
}