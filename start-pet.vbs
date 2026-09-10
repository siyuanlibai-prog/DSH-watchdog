' ============================================================
' DSH Watchdog - 桌面宠物启动器（隐藏窗口方式启动 watchdog-pet.ps1）
' ============================================================
Set fso = CreateObject("Scripting.FileSystemObject")
ps1 = fso.BuildPath(fso.GetParentFolderName(WScript.ScriptFullName), "watchdog-pet.ps1")
Set shell = CreateObject("WScript.Shell")
If Not fso.FileExists(ps1) Then
  MsgBox "Watchdog pet script not found: " & ps1, 48, "Watchdog Pet"
  WScript.Quit 1
End If
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File """ & ps1 & """", 0, False
