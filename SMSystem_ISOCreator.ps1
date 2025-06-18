# Win11_Modifier.ps1
# Teljesen nyílt, PowerShell-alapú Windows 11 ISO módosító script

#####################################################################
## Beállítások
#####################################################################
# Felhasználónév az automatikus bejelentkezéshez/offline fiókhoz
$UserName = "smhost"
# Az install.wim fájl darabolásának mérete MB-ban (FAT32 kompatibilitás miatt)
$WimSplitSizeMB = 3000
# A szkript futási könyvtára
$WorkingDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# A letöltendő Windows 11 ISO URL címe
$ISOUrl = "https://software.download.prss.microsoft.com/dbazure/Win11_24H2_Hungarian_x64.iso?t=b4d469f2-a839-42e4-bf4c-4a9a4a82ded3&P1=1749488988&P2=601&P3=2&P4=KWwckdQUXok%2bK83mpvsij6UHRkZnzn73aBgaSbKU5yG2sxcJMUZT%2bdsTiGrNO5rF%2brurXm4uq04nFRUousqA%2bGm8iJc3vc5wAUWvfZIURrc5R8%2bT%2bqIUF8PE5S6COKlWfQjFqgzlYztkkhzmPlEMIvb5OnD6OBlC3J2wAWUGPMNBBuCQotCLEuBhO3vq44x4HKBF4MoP2Rl13AYiV9vo6YWqKEOUDSI0Q%2b2e9UrZ6Ra3pwEB5Qd%2f0hErrGSQFkzH7DY6ijlTNMnAwN6NpbLA%2b0gJEWCietVPQ9uZfLABc1f3BVylfj8m%2b2xsJjDXZmSByEKyLN8ohF8D6oVa5qHc9Q%3d%3d"

# Munkafolyamat könyvtárak és fájlnevek
$DownloadISO = Join-Path $WorkingDir "Win11_Original.iso"
$MountDir = Join-Path $WorkingDir "ISO_Mount"
$ExtractDir = Join-Path $WorkingDir "ISO_Extracted"
$WimMountDir = Join-Path $WorkingDir "WIM_Mount"
$OutputDir = Join-Path $WorkingDir "Output"
$AutounattendPath = Join-Path $WorkingDir "autounattend.xml"

#####################################################################
## Windows ADK telepítés (ha szükséges)
#####################################################################
# Ellenőrizzük, hogy az oscdimg.exe elérhető-e már
$OscdimgPath = "C:\ADK\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe" # Define the path
$env:Path += ";C:\ADK\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\"

#If (-not (Get-Command oscdimg.exe -ErrorAction SilentlyContinue)) {
If (-not (Test-Path $OscdimgPath)) {
    Write-Host "[!] Az 'oscdimg' parancs nem található. Megpróbálom letölteni és telepíteni a Windows ADK Deployment Tools komponensét." -ForegroundColor Yellow

    # === ADK Telepítési Beállítások ===
    # *** FONTOS ***
    # FRISSÍTSD EZT AZ URL-t a legújabb ADK telepítő (adksetup.exe) közvetlen linkjével a Microsoft oldaláról!
    # Látogass el ide: https://learn.microsoft.com/hu-hu/windows-hardware/get-started/adk-install
    # Keresd meg a "Download the Windows ADK for Windows 11, version [aktuális verziószám]" linket, és másold ki a mögötte lévő URL-t.
    $ADKInstallerUrl = "https://go.microsoft.com/fwlink/?linkid=2289980" # Ez egy *példa* link, lehet, hogy frissíteni kell!
    $ADKInstallerPath = Join-Path $WorkingDir "adksetup.exe"
    $ADKLogPath = Join-Path $WorkingDir "ADK_Install.log"

    # Ellenőrizzük a rendszergazdai jogosultságot a telepítéshez
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "[!] Az ADK telepítéséhez rendszergazdai jogosultság szükséges. Kérlek, futtasd a szkriptet rendszergazdaként." -ForegroundColor Red
        exit 1
    }

    # === ADK Telepítő letöltése ===
    If (!(Test-Path $ADKInstallerPath)) {
        Write-Host "[+] ADK telepítő letöltése: $ADKInstallerUrl"
        try {
            Invoke-WebRequest -Uri $ADKInstallerUrl -OutFile $ADKInstallerPath -ErrorAction Stop
            Write-Host "[√] ADK telepítő sikeresen letöltve." -ForegroundColor Green
        } catch {
            Write-Host "[!] Hiba történt az ADK telepítő letöltése közben: $_" -ForegroundColor Red
            Write-Host "[!] Valószínűleg az ADK letöltési URL ($ADKInstallerUrl) elavult. Kérlek, frissítsd a szkriptben!" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "[i] Az ADK telepítő már letöltve van. Kihagyom a letöltést." -ForegroundColor Yellow
    }

    # === ADK Deployment Tools komponens telepítése ===
    Write-Host "[+] Windows ADK Deployment Tools komponens telepítése..."
    # A /quiet paraméter csendes telepítést jelent, /features a telepítendő komponensek
    # `OptionId_DeploymentTools` telepíti a Deployment Tools-t (ebben van az oscdimg.exe)
    try {
        Write-Host "[i] Az ADK telepítő elindul. A 'Deployment Tools' komponens kiválasztásra kerül." -ForegroundColor Cyan
        Write-Host "[i] Ha a telepítő grafikus felületet mutat, kérlek, kattints a továbbra, amíg be nem fejeződik." -ForegroundColor Cyan
        Write-Host "[i] A telepítés után nyomj ENTER-t itt, hogy a szkript folytatódhasson." -ForegroundColor Cyan

        # Az ADK telepítése sokáig tarthat. A '-Wait' paraméter biztosítja, hogy a PowerShell megvárja a telepítő befejezését.
        # A '-NoNewWindow' megakadályozza, hogy egy új, üres PowerShell ablak nyíljon meg.
        Start-Process -FilePath $ADKInstallerPath -ArgumentList "/installpath c:\ADK /features OptionId.DeploymentTools /log $ADKLogPath" -Wait -NoNewWindow -ErrorAction Stop

        if ($LASTEXITCODE -eq 0) {
             Write-Host "[√] ADK Deployment Tools sikeresen telepítve." -ForegroundColor Green
             # Frissítjük a környezeti változókat, hogy a PowerShell megtalálja az oscdimg-et
             # Ez a lépés fontos, hogy a szkript azonnal használhassa az újonnan telepített eszközt.
             $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        } else {
             Write-Host "[!] Az ADK telepítése hibakóddal fejeződött be: $LASTEXITCODE. Kérlek, ellenőrizd a naplót: $ADKLogPath" -ForegroundColor Red
             exit 1
        }

    } catch {
        Write-Host "[!] Hiba történt az ADK telepítése közben: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[i] Az 'oscdimg' parancs már elérhető. Az ADK telepítése kihagyva." -ForegroundColor Yellow
}

#####################################################################
## Előkészítés
#####################################################################
Write-Host "[+] Munkafolyamat könyvtárak létrehozása..."
New-Item -ItemType Directory -Force -Path $MountDir, $ExtractDir, $WimMountDir, $OutputDir | Out-Null
Write-Host "[√] Előkészítés kész." -ForegroundColor Green

#####################################################################
## ISO letöltése
#####################################################################
If (!(Test-Path $DownloadISO)) {
    Write-Host "[+] ISO letöltése: $ISOUrl"
    try {
        Invoke-WebRequest -Uri $ISOUrl -OutFile $DownloadISO -ErrorAction Stop
        Write-Host "[√] ISO sikeresen letöltve." -ForegroundColor Green
    } catch {
        Write-Host "[!] Hiba történt az ISO letöltése közben: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[i] Az ISO már letöltve van." -ForegroundColor Yellow
}

#####################################################################
## ISO csatolása
#####################################################################
Write-Host "[+] ISO csatolása..."
try {
    $mount = Mount-DiskImage -ImagePath $DownloadISO -PassThru -ErrorAction Stop
    $driveLetter = ($mount | Get-Volume).DriveLetter + ":"
    Write-Host "[√] ISO sikeresen csatolva: $driveLetter" -ForegroundColor Green
} catch {
    Write-Host "[!] Hiba történt az ISO csatolása közben: $_" -ForegroundColor Red
    exit 1
}

#####################################################################
## Fájlok másolása az ISO-ból
#####################################################################
Write-Host "[+] ISO fájlok kibontása a munkakönyvtárba..."
try {
    Copy-Item "$driveLetter\*" $ExtractDir -Recurse -Force -ErrorAction Stop
    Dismount-DiskImage -ImagePath $DownloadISO -ErrorAction Stop
    Write-Host "[√] Fájlok sikeresen kicsomagolva és ISO lecsatolva." -ForegroundColor Green
} catch {
    Write-Host "[!] Hiba történt a fájlok másolása vagy az ISO lecsatolása közben: $_" -ForegroundColor Red
    exit 1
}

#####################################################################
## install.esd konvertálása install.wim-re
#####################################################################
$installESD = Join-Path $ExtractDir "sources\install.esd"
$installWIM = Join-Path $ExtractDir "sources\install.wim"
If (Test-Path $installESD) {
    Write-Host "[+] install.esd konvertálása install.wim-re..."
    try {
        # Az install.esd a 6-os indexen tartalmazza a Windows 11 Pro-t
        dism /Export-Image /SourceImageFile:$installESD /SourceIndex:6 /DestinationImageFile:$installWIM /Compress:max /CheckIntegrity
        Remove-Item $installESD -Force -ErrorAction Stop
        Write-Host "[√] Konvertálás sikeresen befejezve." -ForegroundColor Green
    } catch {
        Write-Host "[!] Hiba történt a konvertálás közben: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[i] install.wim már elérhető, az install.esd konvertálása kihagyva." -ForegroundColor Yellow
}

#####################################################################
## install.wim mountolása
#####################################################################
Write-Host "[+] install.wim mountolása a módosításhoz..."
try {
    dism /Mount-Wim /WimFile:$installWIM /index:1 /MountDir:$WimMountDir
    Write-Host "[√] WIM fájl sikeresen mountolva." -ForegroundColor Green
} catch {
    Write-Host "[!] Hiba történt a WIM mountolása közben: $_" -ForegroundColor Red
    exit 1
}

#####################################################################
## Appraiserres.dll törlése (TPM, RAM, Secure Boot skip)
#####################################################################
$appraiser = Join-Path $ExtractDir "sources\appraiserres.dll"
If (Test-Path $appraiser) {
    Write-Host "[+] appraiserres.dll törlése a TPM, RAM, Secure Boot ellenőrzés kihagyásához..."
    try {
        Remove-Item $appraiser -Force -ErrorAction Stop
        Write-Host "[√] appraiserres.dll sikeresen törölve." -ForegroundColor Green
    } catch {
        Write-Host "[!] Hiba történt az appraiserres.dll törlése közben: $_" -ForegroundColor Red
    }
} else {
    Write-Host "[i] appraiserres.dll nem található, kihagyva." -ForegroundColor Yellow
}

#####################################################################
## BitLocker és Telemetria komponensek eltávolítása
#####################################################################
Write-Host "[+] BitLocker és Telemetria komponensek eltávolítása a WIM-ből..."
try {
    # Itt érdemes lehet ellenőrizni, hogy a feature valóban létezik-e mielőtt eltávolítjuk
    # (bár a BitLocker alapértelmezetten benne van a Pro verzióban)
    dism /Image:$WimMountDir /Disable-Feature /FeatureName:BitLocker /Remove -ErrorAction Stop
    # Megjegyzés: A telemetria komponensek eltávolítása komplexebb, több szolgáltatást és csomagot érinthet.
    # Ez a script csak egy példa a BitLocker eltávolítására.
    Write-Host "[√] BitLocker komponensek sikeresen eltávolítva." -ForegroundColor Green
} catch {
    Write-Host "[!] Hiba történt a komponensek eltávolítása közben: $_" -ForegroundColor Red
}

#####################################################################
## Csak Windows 11 Pro meghagyása (WIM exportálása)
#####################################################################
Write-Host "[+] Csak a Pro verzió (Index 6) exportálása egy új install.wim fájlba..."
try {
    # Ez a lépés egy új install.wim fájlt hoz létre az OutputDir-ben, csak a Pro verzióval.
    # Ha több verzió is van az install.wim-ben és csak a Pro-t akarjuk megtartani,
    # ez a legbiztonságosabb módja, hogy ne módosítsuk az eredetit a mountolt állapotban.
    dism /Export-Image /SourceImageFile:$installWIM /SourceIndex:6 /DestinationImageFile:$OutputDir\install.wim /Compress:max /CheckIntegrity
    Write-Host "[√] Pro verzió sikeresen exportálva." -ForegroundColor Green
} catch {
    Write-Host "[!] Hiba történt a Pro verzió exportálása közben: $_" -ForegroundColor Red
    exit 1
}

#####################################################################
## WIM unmountolása
#####################################################################
Write-Host "[+] Mountolt WIM lecsatolása..."
try {
    dism /Unmount-Wim /MountDir:$WimMountDir /Discard
    Write-Host "[√] WIM sikeresen unmountolva." -ForegroundColor Green
} catch {
    Write-Host "[!] Hiba történt a WIM unmountolása közben: $_" -ForegroundColor Red
    exit 1
}

#####################################################################
## Autounattend.xml létrehozása (Offline fiók és OOBE beállítások)
#####################################################################
Write-Host "[+] Autounattend.xml fájl generálása offline felhasználói fiókkal és OOBE kihagyással..."
$autounattendContent = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <AutoLogon>
        <Enabled>false</Enabled>
        <Username>$UserName</Username>
      </AutoLogon>
      <UserAccounts>
        <LocalAccounts>
          <LocalAccount>
            <Name>$UserName</Name>
            <Group>Administrators</Group>
            <Password><Value></Value><PlainText>true</PlainText></Password>
          </LocalAccount>
        </LocalAccounts>
      </UserAccounts>
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <NetworkLocation>Work</NetworkLocation>
        <ProtectYourPC>1</ProtectYourPC>
      </OOBE>
    </component>
  </settings>
</unattend>
"@
try {
    $autounattendContent | Set-Content -Path $AutounattendPath -Encoding UTF8 -Force
    # Az autounattend.xml fájlt a gyökérkönyvtárba kell másolni az ISO-n belül
    Copy-Item $AutounattendPath -Destination "$ExtractDir\autounattend.xml" -Force -ErrorAction Stop
    Write-Host "[√] Autounattend.xml sikeresen létrehozva és az ISO gyökérkönyvtárába másolva." -ForegroundColor Green
} catch {
    Write-Host "[!] Hiba történt az Autounattend.xml létrehozása vagy másolása közben: $_" -ForegroundColor Red
    exit 1
}

#####################################################################
## install.wim darabolása install.swm fájlokra
#####################################################################
Write-Host "[+] install.wim darabolása install.swm-re (FAT32 kompatibilitás miatt, ha szükséges)..."
$splitOut = Join-Path $ExtractDir "sources" # Az .swm fájlok ide kerülnek
$splitWIM = Join-Path $OutputDir "install.wim" # Ez az a WIM fájl, amit darabolunk
try {
    # A darabolás az OutputDir-ből veszi a WIM-et, és a $ExtractDir\sources alá teszi az SWM-eket.
    dism /Split-Image /ImageFile:$splitWIM /SWMFile:$splitOut\install.swm /FileSize:$WimSplitSizeMB
    # A darabolt WIM fájl már nem kell az OutputDir-ben
    Remove-Item $splitWIM -Force -ErrorAction Stop
    Write-Host "[√] WIM fájl sikeresen darabolva .swm fájlokká." -ForegroundColor Green
} catch {
    Write-Host "[!] Hiba történt a WIM darabolása közben: $_" -ForegroundColor Red
    exit 1
}

#####################################################################
## Új ISO létrehozása
#####################################################################
$FinalISO = Join-Path $OutputDir "Windows11_Pro_Modified.iso"
Write-Host "[+] Új, módosított ISO fájl létrehozása..."
If (Get-Command oscdimg.exe -ErrorAction SilentlyContinue) {
    try {
        # Az oscdimg parancsnak a kicsomagolt ISO tartalmának gyökerét kell megadni
        oscdimg -m -o -u2 -udfver102 -lWIN11_CUSTOM -bootdata:2#p0,e,b$ExtractDir\boot\etfsboot.com#pEF,e,b$ExtractDir\efi\microsoft\boot\efisys.bin $ExtractDir $FinalISO
        Write-Host "[✔] Új ISO létrehozva: $FinalISO" -ForegroundColor Green
    } catch {
        Write-Host "[!] Hiba történt az ISO létrehozása közben: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[!] Az 'oscdimg' parancs nem található! Az ISO nem készült el." -ForegroundColor Red
    Write-Host "[!] Kérlek telepítsd a Windows Assessment and Deployment Kit (ADK) eszközt a Deployment Tools komponenssel." -ForegroundColor Red
    exit 1
}

#####################################################################
## Kérdés pendrive-ra írásról
#####################################################################
$answer = Read-Host "Szeretnéd most kiírni a módosított ISO-t egy pendrive-ra? (i/n)"
If ($answer -eq "i") {
    Write-Host "[i] Elindítom a DiskPart segédprogramot rendszergazdaként." -ForegroundColor Cyan
    Write-Host "[i] Kérlek, manuálisan készítsd elő a pendrive-ot és másold rá az elkészült ISO tartalmát (vagy használd a Rufust): $FinalISO" -ForegroundColor Cyan
    try {
        Start-Process "powershell" -ArgumentList "Start-DiskPart" -Verb RunAs -ErrorAction Stop
    } catch {
        Write-Host "[!] Hiba történt a DiskPart indítása közben. Kérlek manuálisan indítsd el!" -ForegroundColor Red
    }
}

#####################################################################
## Befejezés
#####################################################################
Write-Host "[√] A szkript futása befejeződött!" -ForegroundColor Green
Write-Host "[√] A módosított ISO elérhető itt: $FinalISO" -ForegroundColor Green
Write-Host "[i] Zárd be ezt az ablakot, vagy nyomj Entert a kilépéshez." -ForegroundColor Cyan
Read-Host