' Gemma Health Edge - Silent Launcher
' This script runs the unified launcher in the background with no visible window.

Set WshShell = CreateObject("WScript.Shell")
strDir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
WshShell.CurrentDirectory = strDir

' Run the unified launcher with --silent flag
WshShell.Run "cmd.exe /c Launch_Gemma_Health.bat --silent", 0, False

Set WshShell = Nothing
