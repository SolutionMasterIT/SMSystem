@echo off
setlocal

:: Ellenõrizzük, hogy adminként fut-e
net session >nul 2>&1
if %errorlevel%==0 (
    echo [ADMIN] ExecutionPolicy beállítása emelt szinten...
    powershell -Command "Start-Process powershell -Verb runAs -ArgumentList 'Set-ExecutionPolicy RemoteSigned -Scope CurrentUser'"
) else (
    echo [USER] ExecutionPolicy beállítása jelenlegi userre...
    powershell -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
)

:: PS1 fájlok blokkolásának feloldása
echo [INFO] PS1 fájlok Unblock-File...
powershell -Command "Get-ChildItem -Path '.' -Filter '*.ps1' | Unblock-File"

:: Parancsikon létrehozása aktuális mappába
echo [INFO] Parancsikon létrehozása az aktuális mappába...
powershell -NoProfile -Command "$s = (New-Object -ComObject WScript.Shell).CreateShortcut('SMSystem.lnk'); $s.TargetPath = '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe'; $s.Arguments = '-W Hidden -ExecutionPolicy Bypass -File \"' + (Resolve-Path .\SMSystem.ps1).Path + '\"'; $s.IconLocation = (Resolve-Path .\IMG\SolutionMaster.ico).Path; $s.WorkingDirectory = (Get-Location).Path; $s.Save()"

:: Parancsikon létrehozása az Asztalra
echo [INFO] Parancsikon létrehozása az Asztalra...
powershell -NoProfile -Command "$desktop = [Environment]::GetFolderPath('Desktop'); $s = (New-Object -ComObject WScript.Shell).CreateShortcut(\"$desktop\SMSystem.lnk\"); $s.TargetPath = '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe'; $s.Arguments = '-W Hidden -ExecutionPolicy Bypass -File \"' + (Resolve-Path .\SMSystem.ps1).Path + '\"'; $s.IconLocation = (Resolve-Path .\IMG\SolutionMaster.ico).Path; $s.WorkingDirectory = (Get-Location).Path; $s.Save()"

echo [KÉSZ] A parancsikonok létrejöttek.
pause
endlocal
