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
R2
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
  line := Trim(line)
  if line != "" {
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
lv.OnEvent("ContextMenu", ShowContextMenu) ; Handle right-click context menu for ListView

searchEdit.OnEvent("Change", SearchChanged) ; Handle search input changes
mGui.OnEvent("Close", (*) => ExitApp()) ; Handle GUI close event
mGui.OnEvent("Size", OnGuiResize) ; Handle GUI resize event

ShowIcons(allIcons)

totalWidth := 0
loop 3 { ; Loop through the number of columns in the ListView
  lv.ModifyCol(A_Index, "Auto") ; Set each column to auto width
  totalWidth += GetColWidth(lv, A_Index) ; Calculate total width of all columns
}
OnGuiResize(mGui, 0, totalWidth, gui_H) ; Resize the GUI to fit the ListView

; Add context menu for ListView
lvMenu := Menu()
Loop lv.GetCount("Column") { ; Get the number of columns in the ListView
  colHeader := lv.GetText(0, A_Index) ; Get the header text for each column
  lvMenu.Add("Copy " colHeader, CopyLVItem) ; Add a menu item for each column
}

mGui.Show() ; Show the main GUI

; Context menu for ListView
ShowContextMenu(LV, Item, IsRightClick, X, Y) {
  global lvMenu
  if Item > 0 ; If an item is selected in the ListView
    lvMenu.Show(X, Y) ; Show the context menu at the specified position
}

; Copy the selected ListView item to clipboard
CopyLVItem(Item, Pos, Menu) {
  global lv
  row := lv.GetNext(0, "F") ; Get the first selected row
  if !row ; If no row is selected, do nothing
    return
  A_Clipboard := lv.GetText(row, Pos) ; Get the text of the selected item in the specified column
}

; Get the ListView control's column width
GetColWidth(lv, colIdx) {
  LVM_GETCOLUMNWIDTH := 0x101D 
  return DllCall("SendMessage", "Ptr", lv.hwnd, "UInt", LVM_GETCOLUMNWIDTH, "Ptr", colIdx - 1, "Ptr", 0, "Int")
}

; On Window resize
OnGuiResize(guiObj, minMax, width, height) {
  global searchEdit, lv
  searchEdit.Move(, , width) ; Resize the search edit box to fit the width of the GUI
  lv.Move(, , width, height - searchEdit_H) ; Resize the ListView to fit the remaining height of the GUI
}

; Search input and filter icons
SearchChanged(*) {
  query := Trim(StrLower(searchEdit.Value)) ; Get the search query from the edit box
  if !query { ; If the search query is empty
    ShowIcons(allIcons) ; Show all icons
    return
  }
  filtered := [] 
  for icon in allIcons {
    ; Check if the icon code or name contains the search query
    if InStr(StrLower(icon.Code), query) || InStr(StrLower(icon.Name), query)
      filtered.Push(icon) ; Add matching icons to the filtered list
  }
  ShowIcons(filtered) ; Show the filtered icons in the ListView
}

; Show the filtered icons in the ListView
ShowIcons(filteredIcons) {
  global lv
  lv.Opt("-Redraw") ; Disable redrawing to improve performance
  lv.Delete() ; Clear the ListView before adding new items
  for icon in filteredIcons { ; Loop through each icon in the filtered list
    lv.Add("", Chr("0x" icon.Code) , icon.Code, icon.Name) ; Add the icon character, code, and name to the ListView
  }
  lv.Opt("+Redraw") ; Re-enable redrawing
}

; Set the window icon using a specified icon file and index
SetWindowIcon(hwnd, iconFile, iconIndex) {
  try { ; Attempt to extract the icon from the specified file
    for big in [1, 0] { ; Loop through both big (1) and small (0) icon sizes
      hIcon := DllCall("Shell32.dll\ExtractIconW", "Ptr", 0, "WStr", iconFile, "Int", iconIndex, "Ptr") ; Extract the icon
      if hIcon ; If the icon was successfully extracted
        DllCall("User32.dll\SendMessageW", "Ptr", hwnd, "UInt", 0x80, "Ptr", big, "Ptr", hIcon) ; Send the icon to the window
    }
  }
}