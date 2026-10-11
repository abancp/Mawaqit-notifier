Set WshShell = CreateObject("WScript.Shell")
appData = WshShell.ExpandEnvironmentStrings("%APPDATA%")
guiPath = appData & "\mawaqit-notify\mawaqit_gui.py"

' Run pythonw without opening a command window
WshShell.Run "pythonw """ & guiPath & """", 0, False
