@echo off
setlocal

:: Ellen�rizz�k, hogy admink�nt fut-e
net session >nul 2>&1
if %errorlevel%==0 (
    echo [ADMIN] ExecutionPolicy be�ll�t�sa emelt szinten...
    powershell -Command "Start-Process powershell -Verb runAs -ArgumentList 'Set-ExecutionPolicy RemoteSigned -Scope CurrentUser'"
) else (
    echo [USER] ExecutionPolicy be�ll�t�sa jelenlegi userre...
    powershell -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
)

:: PS1 f�jlok blokkol�s�nak felold�sa
echo [INFO] PS1 f�jlok Unblock-File...
powershell -Command "Get-ChildItem -Path '.' -Filter '*.ps1' | Unblock-File"

:: Parancsikon l�trehoz�sa aktu�lis mapp�ba
echo [INFO] Parancsikon l�trehoz�sa az aktu�lis mapp�ba...
powershell -NoProfile -Command "$s = (New-Object -ComObject WScript.Shell).CreateShortcut('SMSystem.lnk'); $s.TargetPath = '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe'; $s.Arguments = '-W Hidden -ExecutionPolicy Bypass -File \"' + (Resolve-Path .\SMSystem.ps1).Path + '\"'; $s.IconLocation = (Resolve-Path .\IMG\SolutionMaster.ico).Path; $s.WorkingDirectory = (Get-Location).Path; $s.Save()"

:: Parancsikon l�trehoz�sa az Asztalra
echo [INFO] Parancsikon l�trehoz�sa az Asztalra...
powershell -NoProfile -Command "$desktop = [Environment]::GetFolderPath('Desktop'); $s = (New-Object -ComObject WScript.Shell).CreateShortcut(\"$desktop\SMSystem.lnk\"); $s.TargetPath = '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe'; $s.Arguments = '-W Hidden -ExecutionPolicy Bypass -File \"' + (Resolve-Path .\SMSystem.ps1).Path + '\"'; $s.IconLocation = (Resolve-Path .\IMG\SolutionMaster.ico).Path; $s.WorkingDirectory = (Get-Location).Path; $s.Save()"

echo [K�SZ] A parancsikonok l�trej�ttek.
pause
endlocal
