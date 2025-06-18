$ErrorActionPreference = "Stop"

# === Elõkészületek ===
$TMP     = "$PSScriptRoot\TMP"
$BIN     = "$PSScriptRoot\BIN"
$CONF    = "$PSScriptRoot\CONF"

# TMP mappa létrehozása
if (!(Test-Path $TMP)) {
    New-Item -ItemType Directory -Path $TMP | Out-Null
}

# Függvény: fájl letöltése
function Download-File {
    param (
        [string]$Url,
        [string]$DestinationFolder
    )

    try {
        # Csak a fájlnév részt vesszük (a ? utáni rész nélkül)
        $fileName = [System.IO.Path]::GetFileName(($Url -split '\?')[0])
        $destination = Join-Path $DestinationFolder $fileName

        Write-Host "? Letöltés: $Url -> $destination"
        Invoke-WebRequest -Uri $Url -OutFile $destination -UseBasicParsing

        return $destination
    }
    catch {
        Write-Warning "?? Hiba a letöltéskor: $Url"
        return $null
    }
}

# Függvény: kicsomagolás ZIP esetén
function Extract-Zip {
    param (
        [string]$ZipFile,
        [string]$Destination
    )
    try {
        #if (Test-Path $Destination) { Remove-Item $Destination -Recurse -Force }
        Expand-Archive -Path $ZipFile -DestinationPath $Destination -Force
    }
    catch {
        Write-Warning "?? Hiba a kicsomagoláskor: $ZipFile"
    }
}

# Függvény: fájl másolása
function Move-File {
    param (
        [string]$Source,
        [string]$Target
    )
    try {
        Move-Item -Path $Source -Destination $Target -Force
    }
    catch {
        Write-Warning "?? Nem sikerült áthelyezni: $Source -> $Target"
    }
}

# Függvény: mappa másolása (pl. CONF/DC tartalom)
function Copy-FolderContent {
    param (
        [string]$Source,
        [string]$Target
    )
    try {
        Copy-Item "$Source\*" -Destination $Target -Recurse -Force
    }
    catch {
        Write-Warning "?? Nem sikerült másolni: $Source -> $Target"
    }
}

# === Letöltendõ elemek definiálása ===
$apps = @(
    @{ Name="CPU-Z"; Url="https://download.cpuid.com/cpu-z/cpu-z_2.15-en.zip"; Target="$BIN\CPU-Z"; Type="zip" },
    @{ Name="CrystalDiskInfo"; Url="https://deac-fra.dl.sourceforge.net/project/crystaldiskinfo/9.7.0/CrystalDiskInfo9_7_0.zip?viasf=1"; Target="$BIN\CrystalDiskInfo"; Type="zip" },
    @{ Name="DoubleCommander"; Url="https://netcologne.dl.sourceforge.net/project/doublecmd/DC%20for%20Windows%2064%20bit/Double%20Commander%201.1.26/doublecmd-1.1.26.x86_64-win64.zip"; Target="$BIN"; Type="zip"; ConfCopy=$true }
    @{ Name="GPU_Caps_Viewer"; Url="https://geeks3d.com/downloads/2025/gcv/GPU_Caps_Viewer_1.64.2.0.zip"; Target="$BIN"; Type="zip" },
    @{ Name="GPU-Z"; Url="https://de2-dl.techpowerup.com/files/0sfzSfgBCMufOb0Xeflhgg/1750246498/GPU-Z.2.66.0.exe"; Target="$BIN\GPU-Z.exe"; Type="exe" },
    @{ Name="HWiNFO"; Url="https://deac-ams.dl.sourceforge.net/project/hwinfo/Windows_Portable/hwi_826.zip?viasf=1"; Target="$BIN\HWiNFO"; Type="zip" },
    @{ Name="Audacious"; Url="https://distfiles.audacious-media-player.org/audacious-4.4.2-win32.zip"; Target="$BIN\MPlayer"; Type="zip" },
    @{ Name="SSD-Z"; Url="http://aezay.dk/aezay/ssdz/SSD-Z_16.09.09wip.zip"; Target="$BIN\SSD-Z"; Type="zip" },
    @{ Name="RustDesk"; Url="https://github.com/rustdesk/rustdesk/releases/download/1.4.0/rustdesk-1.4.0-x86_64.exe"; Target="$BIN\rustdesk.exe"; Type="exe" },
    @{ Name="XtremeShell"; Url="https://xtremeshell.neonity.hu/files/XtremeShell%204.4%20Portable.exe"; Target="$BIN\XtremeShell.exe"; Type="exe" },
    @{ Name="AdwCleaner"; Url="https://adwcleaner.malwarebytes.com/adwcleaner?channel=release&_gl=1*isohgs*_gcl_au*Mjc0NzY3MTkuMTc1MDIwMzY5OA..*_ga*MTkyODQ3MTgzMi4xNzUwMjAzNjk4*_ga_K8KCHE3KSC*czE3NTAyMDM2OTckbzEkZzAkdDE3NTAyMDM3MDIkajU1JGwwJGgw"; Target="$BIN\adwcleaner.exe"; Type="exe" },
    @{ Name="Rufus"; Url="https://github.com/pbatard/rufus/releases/download/v4.9/rufus-4.9p.exe"; Target="$BIN\rufus.exe"; Type="exe" }
)

# === Fõ letöltési ciklus ===
foreach ($app in $apps) {
    #$tempFile = Join-Path $TMP ([System.IO.Path]::GetFileName($app.Url))
    #Download-File -Url $app.Url -Destination $tempFile
	$tempFile = Download-File -Url $app.Url -DestinationFolder $TMP
	if (-not $tempFile) { continue }

    switch ($app.Type) {
        "zip" {
            Extract-Zip -ZipFile $tempFile -Destination $app.Target
            if ($app.ConfCopy -eq $true) {
                Copy-FolderContent -Source "$CONF\doublecmd" -Target "$BIN\doublecmd"
            }
        }
        "exe" {
            Move-File -Source $tempFile -Target $app.Target
        }
        default {
            Write-Warning "? Ismeretlen típus: $($app.Type)"
        }
    }
}

Write-Host "`n? Minden letöltés és feldolgozás kész." -ForegroundColor Green
