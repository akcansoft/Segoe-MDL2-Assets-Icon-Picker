/*
This script provides a searchable picker for Segoe MDL2 Assets icons.
Use the search box to filter icons. Right-click any icon to copy its character or Unicode code.

This script is free to use and modify. Please give credit if you share or use it in your projects.

Mesut Akcan
makcan@gmail.com
akcansoft.blogspot.com
mesutakcan.blogspot.com
github.com/akcansoft
youtube.com/mesutakcan

19/06/2025
v1.0
R1
*/

#Requires AutoHotkey v2.0
#NoTrayIcon

iconDataFile := "Segoe MDL2 Assets Icons.csv"
; https://learn.microsoft.com/en-us/windows/apps/design/style/segoe-ui-symbol-font

; Check if the icon file exists
if !FileExist(iconDataFile) {
  MsgBox("The icon data file does not exist: " iconDataFile, "Error", 16)
  ExitApp
}
; Read the icon data from the CSV file
; The file should contain lines in the format: "Code,Description"
; Example: "E701,Wifi", "E702,Bluetooth", "E703,Connect"
allIcons := []
fileContent := FileRead(iconDataFile)
for line in StrSplit(fileContent, "`n", "`r") {
  if !RegExMatch(line, "^\s*$") {
    parts := StrSplit(line, ",")
    if parts.Length = 2
      allIcons.Push({ Code: parts[1], Name: parts[2] })
  }
}

; Create GUI
searchEdit_H := 30
gui_H := 600
mGui := Gui("+Resize +MinSize300x300", "Segoe MDL2 Assets Icons")
SetWindowIcon(mGui.Hwnd, A_WinDir "\System32\shell32.dll", 75)
mGui.MarginX := mGui.MarginY := 0
mGui.SetFont("s12", "Segoe UI")
searchEdit := mGui.Add("Edit", "BackgroundFFFFEF h" searchEdit_H)
mGui.SetFont("s16", "Segoe MDL2 Assets")
lv := mGui.Add("ListView", "Grid Backgrounde1eafc h" gui_H, ["Icon", "Code", "Description"])
lv.OnEvent("ContextMenu", LV_ContextMenu)

searchEdit.OnEvent("Change", SearchChanged)
mGui.OnEvent("Close", (*) => ExitApp())
mGui.OnEvent("Size", OnGuiResize)

ShowIcons(allIcons)

totalWidth := 0
loop 3 {
  lv.ModifyCol(A_Index, "Auto")
  totalWidth += GetColWidth(lv, A_Index)
}
OnGuiResize(mGui, 0, totalWidth, gui_H)

; Add context menu for ListView
lvMenu := Menu()
lvMenu.Add("Copy icon", (*) => CopyLVItem(1))
lvMenu.Add("Copy code", (*) => CopyLVItem(2))

mGui.Show()

; Context menu for ListView
LV_ContextMenu(ctrl, row, col, x, y) {
  global lvMenu
  if row > 0
    lvMenu.Show()
}

; Copy the selected ListView item to clipboard
; col = 1 for icon character, col = 2 for icon code
CopyLVItem(col) {
  global lv
  row := lv.GetNext(0, "F") ; Seçili satırı al
  if !row
    return
  iconChar := lv.GetText(row, 1)
  iconCode := lv.GetText(row, 2)
  if col = 1
    A_Clipboard := iconChar
  else if col = 2
    A_Clipboard := iconCode
}

; Get the ListView control's column width
GetColWidth(lv, colIdx) {
  LVM_GETCOLUMNWIDTH := 0x101D
  return DllCall("SendMessage", "Ptr", lv.hwnd, "UInt", LVM_GETCOLUMNWIDTH, "Ptr", colIdx - 1, "Ptr", 0, "Int")
}

; On Window resize
OnGuiResize(guiObj, minMax, width, height) {
  global searchEdit, lv
  searchEdit.Move(, , width)
  lv.Move(, , width, height - searchEdit_H)
}

; Search input and filter icons
SearchChanged(*) {
  query := Trim(StrLower(searchEdit.Value))
  if !query {
    ShowIcons(allIcons)
    return
  }
  filtered := []
  for icon in allIcons {
    ; Check if the icon code or name contains the search query
    if InStr(StrLower(icon.Code), query) || InStr(StrLower(icon.Name), query)
      filtered.Push(icon)
  }
  ShowIcons(filtered)
}

; Show the filtered icons in the ListView
ShowIcons(filteredIcons) {
  global lv
  lv.Delete()
  for icon in filteredIcons {
    char := Chr("0x" icon.Code)
    lv.Add("", char, icon.Code, icon.Name)
  }
}

; Set the window icon using a specified icon file and index
SetWindowIcon(hwnd, iconFile, iconIndex := 0) {
  hIconBig := DllCall("Shell32.dll\ExtractIconW", "Ptr", 0, "WStr", iconFile, "Int", iconIndex, "Ptr")
  hIconSmall := DllCall("Shell32.dll\ExtractIconW", "Ptr", 0, "WStr", iconFile, "Int", iconIndex, "Ptr")
  if hIconBig
    DllCall("User32.dll\SendMessageW", "Ptr", hwnd, "UInt", 0x80, "Ptr", 1, "Ptr", hIconBig) ; WM_SETICON (ICON_BIG)
  if hIconSmall
    DllCall("User32.dll\SendMessageW", "Ptr", hwnd, "UInt", 0x80, "Ptr", 0, "Ptr", hIconSmall) ; WM_SETICON (ICON_SMALL)
}