Set WshShell = CreateObject("WScript.Shell")
AppData = WshShell.ExpandEnvironmentStrings("%APPDATA%")
ScriptPath = AppData & "\obs-studio\scripts\ReplayOverlay.ps1"

WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ScriptPath & """", 0, False
