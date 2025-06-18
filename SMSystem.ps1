# .Net methods for hiding/showing the console in the background START
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
# END
#Solution START
function ShowConsole
{
    $consolePtr = [Console.Window]::GetConsoleWindow()

    # Hide = 0,
    # ShowNormal = 1,
    # ShowMinimized = 2,
    # ShowMaximized = 3,
    # Maximize = 3,
    # ShowNormalNoActivate = 4,
    # Show = 5,
    # Minimize = 6,
    # ShowMinNoActivate = 7,
    # ShowNoActivate = 8,
    # Restore = 9,
    # ShowDefault = 10,
    # ForceMinimized = 11

    [Console.Window]::ShowWindow($consolePtr, 4)
}
function HideConsole
{
    $consolePtr = [Console.Window]::GetConsoleWindow()
    #0 hide
    [Console.Window]::ShowWindow($consolePtr, 0)
}
function Test-IsRunAsAdmin
{
    $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentIdentity)
    return ($principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator) -and `
            ([System.Environment]::UserInteractive -eq $true) -and `
            ($currentIdentity.Owner -eq $currentIdentity.User))
}
function systemADBlockCheck
{
    param (
        [object]$chkAdProtection
    )

    $hostFileLines = @()
    if (Test-Path $hostFile) {
        $hostFileLines = Get-Content -Path $hostFile
    }

    # Keress�k meg a "###ADBLOCK###" sor index�t
    $index = -1
    for ($i = 0; $i -lt $hostFileLines.Count; $i++) {
        if ($hostFileLines[$i] -eq "###ADBLOCK###") {
            $index = $i
            break
        }
    }

    # Be�ll�tjuk a glob�lis v�ltoz�t
    $adblock_start = $index

    # A checkbox be�ll�t�sa az eredm�ny alapj�n
    if ($index -eq -1) {
        $chkAdProtection.IsChecked = $false
    } else {
        $chkAdProtection.IsChecked = $true
    }
	
	#[System.Windows.MessageBox]::Show("$adblock_start")#debug �zenet
}
function adProtection_Click
{

    $version = "100"
    $hostFileLines = @()
    if (Test-Path $hostFile) {
        $hostFileLines = Get-Content -Path $hostFile
    }

    $req_start       = $hostFileLines.IndexOf("###REQ###")        #aj�nlott sorok
    $user_start      = $hostFileLines.IndexOf("###USER###")       #felhaszn�l� eredeti sorai
    $adblock_start   = $hostFileLines.IndexOf("###ADBLOCK###")    #rekl�msz�r�s sorai

    # Biztons�gi ment�s
    try {
        $backupFile = Join-Path "$ScriptDir/BACK/" ("hosts_" + (Get-Date -Format "yyyyMMddHHmmss"))
        Copy-Item -Path $hostFile -Destination $backupFile -Force
        [System.Windows.MessageBox]::Show("A hosts f�jl sikeresen mentve: $backupFile")
    } catch {
        [System.Windows.MessageBox]::Show("Hiba t�rt�nt: $_")
        return
    }
	
	$canActivate = $true
    $NEWhostFileURL   = "https://pc.solutionmaster.hu/SMSystem/hosts_$version"
	$NEWhostFile      = "$ScriptDir/CONF/hosts_$version"

	if (-not (Test-Path $NEWhostFile)) {
		try {
			$client = New-Object System.Net.WebClient
			$client.DownloadFile($NEWhostFileURL, $NEWhostFile)
			Write-Host "Let�lt�s sikeres: $NEWhostFile"
		} catch {
			Write-Host "Hiba t�rt�nt a let�lt�s sor�n: $_"
		} finally {
			$client.Dispose()
		}
	}
	
	#�j host file elk�sz�t�se
	$NEWhostFileLines    = @()
    $NEWreq_start        = -1
    $NEWuser_start       = -1
    $NEWadblock_start    = -1
	
	if (Test-Path $NEWhostFile)
	{
        $NEWhostFileLines = Get-Content $NEWhostFile
        $NEWreq_start     = $NEWhostFileLines.IndexOf("###REQ###")
        $NEWuser_start    = $NEWhostFileLines.IndexOf("###USER###")
        $NEWadblock_start = $NEWhostFileLines.IndexOf("###ADBLOCK###")
    }
	else
	{
        $canActivate = $false
        [System.Windows.MessageBox]::Show("Rekl�msz�r�s nem el�rhet� jelenleg, csak inaktiv�lni lehet!")
    }
	
	if ($adblock_start -ne -1)
	{
		# Inaktiv�l�s
		[System.Windows.MessageBox]::Show("Rekl�mv�delem inaktiv�l�sa")
		$lines = @()
		for ($i = 0; $i -lt $adblock_start; $i++) {
			$lines += $hostFileLines[$i]
		}

		try
		{
			Set-Content -Path $hostFile -Value $lines -Encoding UTF8
			[System.Windows.MessageBox]::Show("Rekl�mv�delem inakt�v")
			$chkAdProtection.IsChecked = $false
		}
		catch
		{
			$fallbackFile = "$ScriptDir/CONF/hosts.txt"
			Set-Content -Path $fallbackFile -Value $lines -Encoding UTF8
			[System.Windows.MessageBox]::Show("Hiba t�rt�nt, nem siker�lt a f�jl meg�r�sa! A f�jlt $fallbackFile n�ven mentettem. Aktiv�l�shoz futtasd a programot rendszergazdak�nt, vagy k�zzel �rd fel�l a hosts f�jl tartalm�t.")
			$chkAdProtection.IsChecked = $true
		}
    }
	elseif ($canActivate)
	{
        # Aktiv�l�s
        [System.Windows.MessageBox]::Show("Rekl�mv�delem aktiv�l�sa")
        $lines = @()

        if ($req_start -ne -1) {
            if ($user_start -ne -1) {
				$sectionEnd = $user_start
			} else {
				$sectionEnd = $hostFileLines.Count
			}
            for ($i = $req_start; $i -lt $sectionEnd; $i++) {
                $lines += $hostFileLines[$i]
            }
            if ($user_start -ne -1) {
                for ($i = $user_start; $i -lt $hostFileLines.Count; $i++) {
                    $lines += $hostFileLines[$i]
                }
            } else {
                for ($i = $NEWreq_start; $i -lt $NEWuser_start; $i++) {
                    $lines += $NEWhostFileLines[$i]
                }
            }
        } else {
            for ($i = $NEWreq_start; $i -lt $NEWuser_start; $i++) {
                $lines += $NEWhostFileLines[$i]
            }
            if ($user_start -ne -1) {
                for ($i = $user_start; $i -lt $hostFileLines.Count; $i++) {
                    $lines += $hostFileLines[$i]
                }
            } else {
                for ($i = $NEWuser_start; $i -lt $NEWadblock_start; $i++) {
                    $lines += $NEWhostFileLines[$i]
                }
                $lines += $hostFileLines
            }
        }

        # Rekl�msz�r�s blokk
        for ($i = $NEWadblock_start; $i -lt $NEWhostFileLines.Count; $i++) {
            $lines += $NEWhostFileLines[$i]
        }

        try {
            Set-Content -Path $hostFile -Value $lines -Encoding UTF8
            [System.Windows.MessageBox]::Show("Rekl�mv�delem akt�v")
            $chkAdProtection.IsChecked = $true
        } catch {
			$fallbackFile = "$ScriptDir/CONF/hosts.txt"
			Set-Content -Path $fallbackFile -Value $lines -Encoding UTF8
			[System.Windows.MessageBox]::Show("Hiba t�rt�nt, nem siker�lt a f�jl meg�r�sa! A f�jlt $fallbackFile n�ven mentettem. Aktiv�l�shoz futtasd a programot rendszergazdak�nt, vagy k�zzel �rd fel�l a hosts f�jl tartalm�t.")
			$chkAdProtection.IsChecked = $false
        }
    }
}
#Solution END

# GLOBALS
$ScriptDir                    = Get-Location  # Az aktu�lis munkak�nyvt�rat adja vissza, ineratkt�v esem�ny eset�n!
$ScriptDir                    = Split-Path -Parent $MyInvocation.MyCommand.Path #AI javaslata
#$Icon                         = New-Object system.drawing.icon ("$ScriptDir/IMG/SolutionMaster.ico") #r�gi metodika, winforms
$IconPath                     = Join-Path $ScriptDir "IMG/SolutionMaster.ico"
$color_text                   = ""
$color_background             = "#FF1E1E1E"
$color_primary                = ""
$color_secondary              = ""
$color_accent                 = ""

# Rekl�msz�r�s
$hostFile                     = "C:/Windows/System32/drivers/etc/hosts"

# GUI Specs
$programf86                   = 'C:\Program Files (x86)'
$programf                     = 'C:\Program Files'
$chrome                       = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$firefox                      = 'C:\Program Files\Mozilla Firefox\firefox.exe'
$msedge                       = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
$thunderbird                  = 'C:\Program Files\Mozilla Thunderbird\thunderbird.exe'
$winscp                       = 'W:\BIN\WinSCP\WinSCP.exe'

[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SMSystem 1.0.0" Height="500" Width="700"
        Background="$color_background"
        WindowStartupLocation="CenterScreen"
>
    <Grid>
		<Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
	
		<TabControl Grid.Row="0" Background="$color_background" BorderThickness="0">
			<TabItem Header="Home">
				<WrapPanel>
					<Button Width="200" Height="40" Style="{DynamicResource NeonPink}" Name="btn_DC" Content="SM Console"/>
					<Button Width="200" Height="40" Style="{DynamicResource NeonPink}" Name="btn_MPlayer" Content="BASS Player ind�t�sa"/>
					<Button Width="200" Height="40" Style="{DynamicResource NeonPink}" Name="btn_LinkDown" Content="LINK downloader"/>
					<Button Width="200" Height="40" Style="{DynamicResource NeonPink}" Name="btn_NiniteFree" Content="Ninite Free"/>
					<Button Width="200" Height="40" Style="{DynamicResource NeonPink}" Name="btn_Show" Content="Console megjelen�t�se"/>
					<Button Width="200" Height="40" Style="{DynamicResource NeonPink}" Visibility="Collapsed" Name="btn_Hide" Content="Console elrejt�se"/>
				</WrapPanel>
			</TabItem>
			<TabItem Header="T�mogat�s">
				<WrapPanel>
					<Button Width="300" Height="40" Style="{DynamicResource NeonPink}" Name="btn_RustDesk" Content="RustDesk ind�t�sa"/>
					<Button Width="300" Height="40" Style="{DynamicResource NeonPink}" Name="btn_DRV" Content="Driver csomag mappa megnyit�sa"/>
				</WrapPanel>
			</TabItem>
			<TabItem Header="Rendszer optimaliz�l�s">
				<WrapPanel>
					<Button Width="300" Height="40" Style="{DynamicResource NeonPink}" Name="btn_SysRES" Content="Rendszer vissza�ll�t�si pont l�trehoz�sa"/>
					<Button Width="300" Height="40" Style="{DynamicResource NeonPink}" Name="btn_TimeUpdate" Content="Rendszerid� friss�t�se"/>
					<Button Width="300" Height="40" Style="{DynamicResource NeonPink}" Name="btn_InstPRG" Content="Telep�tett programok"/>
					<Button Width="300" Height="40" Style="{DynamicResource NeonPink}" Name="btn_WindowsUpdate" Content="Windows Update"/>
					<Button Name="btn_rex" Content="Explorer �jraind�t�sa" Width="200" Height="40" Style="{DynamicResource NeonPink}"/>
					<Button Name="btn_VScan" Content="R�KA �rt�s" Width="200" Height="40" Style="{DynamicResource NeonPink}"/>
					<CheckBox Style="{DynamicResource NeonCheckBox}" Name="chkAdProtection" Content="Rekl�mv�delem" />
				</WrapPanel>
			</TabItem>
			<TabItem Header="Bench">
				<WrapPanel>
					<Button Width="300" Height="40" Style="{DynamicResource NeonPink}" Name="btn_AIDA64" Content="AIDA64"/>
					<Button Width="300" Height="40" Style="{DynamicResource NeonPink}" Name="btn_HardDiskSentinel" Content="Hard Disk Sentinel"/>
					<Button Width="300" Height="40" Style="{DynamicResource NeonPink}" Name="btn_CrystalDiskInfo" Content="Crystal Disk Info"/>
					<Button Width="300" Height="40" Style="{DynamicResource NeonPink}" Name="btn_HWiNFO" Content="HWiNFO"/>
					<Button Width="300" Height="40" Style="{DynamicResource NeonPink}" Name="btn_CPUZ" Content="CPU-Z"/>
					<Button Width="300" Height="40" Style="{DynamicResource NeonPink}" Name="btn_GPUZ" Content="GPU-Z"/>
					<Button Width="300" Height="40" Style="{DynamicResource NeonPink}" Name="btn_GPUCapsViewer" Content="GPU Caps Viewer"/>
					<Button Width="300" Height="40" Style="{DynamicResource NeonPink}" Name="btn_SSDZ" Content="SSD-Z"/>
				</WrapPanel>
			</TabItem>
		</TabControl>
		<WrapPanel Grid.Row="1" HorizontalAlignment="Center" Margin="10">
			<Image Height="80" Margin="10" Name="img_foxL" Source="$ScriptDir/IMG/Iconarchive-Wild-Camping-Fox.1024.png" RenderTransformOrigin="0.5,0.5">
				<Image.RenderTransform>
					<ScaleTransform ScaleX="-1" />
				</Image.RenderTransform>
			</Image>
			<Image Height="60" Margin="10" Name="img_rufus" Source="$ScriptDir/IMG/rufus.png"/>
            <Image Height="30" Margin="10" Name="img_neonity" Source="$ScriptDir/IMG/neonity.png"/>
            <Image Height="30" Margin="10" Name="img_rackhost" Source="$ScriptDir/IMG/rackhost.png"/>
            <Image Height="25" Margin="10" Name="img_sectigo" Source="$ScriptDir/IMG/sectigo.png"/>
            <Image Height="80" Margin="10" Name="img_foxR" Source="$ScriptDir/IMG/Iconarchive-Wild-Camping-Fox.1024.png"/>
        </WrapPanel>
    </Grid>
</Window>
"@
# ablak elrejt�se: <Window ... AllowsTransparency="True" WindowStyle="None" ...>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$Reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Form = [Windows.Markup.XamlReader]::Load($Reader)
if (Test-Path $IconPath)
{ # ha l�tezik akkor ikon be�ll�t�sa
    $Form.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create((New-Object System.IO.FileStream($IconPath, 'Open', 'Read')))
}

# Neon st�lusok defini�l�sa
$styleXaml = @"
<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <!-- Neon Blue Button -->
    <Style x:Key="NeonBlue" TargetType="Button">
        <Setter Property="FontSize" Value="12" />
        <Setter Property="FontWeight" Value="Bold" />
        <Setter Property="Foreground" Value="#00FFFF" />
        <Setter Property="Background" Value="Transparent" />
        <Setter Property="BorderThickness" Value="2" />
        <Setter Property="BorderBrush" Value="#00FFFF" />
        <Setter Property="Margin" Value="10" />
        <Setter Property="Width" Value="250" />
        <Setter Property="Height" Value="100" />
        <Setter Property="Effect">
            <Setter.Value>
                <DropShadowEffect Color="#00FFFF" BlurRadius="15" ShadowDepth="0" />
            </Setter.Value>
        </Setter>
    </Style>
	
	<!-- Neon k�k st�lus� checkbox -->
	<Style x:Key="NeonCheckBox" TargetType="CheckBox">
		<Setter Property="Foreground" Value="#00FFFF" />
		<Setter Property="FontSize" Value="14" />
		<Setter Property="FontWeight" Value="Bold" />
		<Setter Property="Margin" Value="10" />
		<Setter Property="Effect">
			<Setter.Value>
				<DropShadowEffect Color="#00FFFF" BlurRadius="10" ShadowDepth="0" />
			</Setter.Value>
		</Setter>
	</Style>

    <!-- Neon Pink Button -->
    <Style x:Key="NeonPink" TargetType="Button" BasedOn="{StaticResource NeonBlue}">
        <Setter Property="Foreground" Value="#FF00FF" />
        <Setter Property="BorderBrush" Value="#FF00FF" />
        <Setter Property="Effect">
            <Setter.Value>
                <DropShadowEffect Color="#FF00FF" BlurRadius="15" ShadowDepth="0" />
            </Setter.Value>
        </Setter>
    </Style>

    <!-- Neon TabItem Style -->
    <Style TargetType="TabItem">
        <Setter Property="Margin" Value="0"/>
        <Setter Property="Padding" Value="8"/>
        <Setter Property="Height" Value="40"/>
        <Setter Property="Width" Value="150"/>
		<Setter Property="FontSize" Value="13" />
        <Setter Property="Foreground" Value="#00FFFF"/>
        <Setter Property="Background" Value="$color_background"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="TabItem">
                    <Border Name="Bd"
                            Background="{TemplateBinding Background}"
                            BorderBrush="#00FFFF"
                            BorderThickness="1"
                            CornerRadius="8"
                            Margin="2">
                        <ContentPresenter x:Name="ContentSite"
                                          VerticalAlignment="Center"
                                          HorizontalAlignment="Center"
                                          ContentSource="Header"
                                          RecognizesAccessKey="True"/>
                    </Border>
					<ControlTemplate.Triggers>
						<!-- Akt�v (kiv�lasztott) tab -->
						<Trigger Property="IsSelected" Value="True">
							<Setter Property="Background" Value="#FF2A2A2A"/>
							<Setter Property="FontWeight" Value="Bold"/>
							<Setter Property="BorderBrush" Value="#00FFFF"/>
							<Setter Property="Foreground" Value="#00FFFF"/>
							<Setter Property="Effect">
								<Setter.Value>
									<DropShadowEffect Color="#00FFFF" BlurRadius="15" ShadowDepth="0"/>
								</Setter.Value>
							</Setter>
						</Trigger>

						<!-- Eg�rrel f�l� h�zott tab -->
						<Trigger Property="IsMouseOver" Value="True">
							<Setter Property="BorderBrush" Value="#00FFFF"/>
							<Setter Property="Background" Value="#FF2A2A2A"/>
							<Setter Property="Effect">
								<Setter.Value>
									<DropShadowEffect Color="#00FFFF" BlurRadius="10" ShadowDepth="0"/>
								</Setter.Value>
							</Setter>
						</Trigger>
					</ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
</ResourceDictionary>
"@

# Bet�lt�s mem�ri�ba
[xml]$styleXml = $styleXaml
$reader2 = (New-Object System.Xml.XmlNodeReader $styleXml)
$resources = [Windows.Markup.XamlReader]::Load($reader2)
$Form.Resources.MergedDictionaries.Add($resources)

#Rekl�mv�delem START
$chkAdProtection = $Form.FindName("chkAdProtection")
systemADBlockCheck -chkAdProtection $chkAdProtection
$chkAdProtection.Add_Checked({ adProtection_Click })
$chkAdProtection.Add_Unchecked({ adProtection_Click })
#Rekl�mv�delem END

# Gombok esem�nyei (p�ld�ul csak �zenet jelenjen meg)
#$Form.FindName("btnConsole").Add_Click({ [System.Windows.MessageBox]::Show("SM Console megnyitva") })
$btn_DC      = $Form.FindName("btn_DC")
$btn_DC.Add_Click({ Start-Process "$ScriptDir\BIN\doublecmd\doublecmd.exe" })

$btn_MPlayer = $Form.FindName("btn_MPlayer")
$btn_MPlayer.Add_Click({ Start-Process "$ScriptDir\BIN\MPlayer\bin\audacious.exe" })

$btn_LinkDown= $Form.FindName("btn_LinkDown")
#$btn_LinkDown.Add_Click({ Start-Process "$ScriptDir\LinkDownloader.ps1" })
$btn_LinkDown.Add_Click({ Start-Process -FilePath "powershell.exe" -ArgumentList "-W Hidden -NoProfile -File `"$ScriptDir\LinkDownloader.ps1`"" })

$btn_Hide    = $Form.FindName("btn_Hide")
$btn_Hide.Add_Click({
    HideConsole
    $btn_Hide.Visibility = 'Collapsed'
    $btn_Show.Visibility = 'Visible'
})

$btn_Show    = $Form.FindName("btn_Show")
$btn_Show.Add_Click({
    ShowConsole
    $btn_Show.Visibility = 'Collapsed'
    $btn_Hide.Visibility = 'Visible'
})

$btn_SysRES  = $Form.FindName("btn_SysRES")
$btn_SysRES.Add_Click({
    $exePath = "C:\Windows\System32\SystemPropertiesProtection.exe"
    $adminCheck = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $adminCheck) {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command Start-Process '$exePath' -Verb RunAs" -WindowStyle Hidden
    } else {
        Start-Process -FilePath $exePath
    }
})

$btn_rex     = $Form.FindName("btn_rex")
$btn_rex.Add_Click({ Start-Process "$ScriptDir\rex.cmd"})

$btn_VScan   = $Form.FindName("btn_VScan")
$btn_VScan.Add_Click({ Start-Process "$ScriptDir\BIN\adwcleaner.exe" -Verb RunAs })

$btn_RustDesk   = $Form.FindName("btn_RustDesk")
$btn_RustDesk.Add_Click({ Start-Process "$ScriptDir\BIN\rustdesk.exe"})

$img_rufus   = $Form.FindName("img_rufus")
$img_rufus.Add_MouseDown({
    Start-Process "$ScriptDir\BIN\rufus.exe"
})

$img_neonity   = $Form.FindName("img_neonity")
$img_neonity.Add_MouseDown({
    Start-Process "$ScriptDir\BIN\XtremeShell.exe"
})

$tools = @(
    @{ Button = "btn_AIDA64"; Path = "BIN\AIDA64\aida64.exe" },
    @{ Button = "btn_HardDiskSentinel"; Path = "BIN\HardDiskSentinel\HDSentinel.exe" },
    @{ Button = "btn_CPUZ"; Path = "BIN\CPU-Z\cpuz_x64.exe" },
    @{ Button = "btn_GPUZ"; Path = "BIN\GPU-Z.exe" },
    @{ Button = "btn_SSDZ"; Path = "BIN\SSD-Z\SSD-Z.exe" },
    @{ Button = "btn_HWiNFO"; Path = "BIN\HWiNFO\HWiNFO64.exe" },
    @{ Button = "btn_GPUCapsViewer"; Path = "BIN\GPU_Caps_Viewer\GPU_Caps_Viewer.exe" },
    @{ Button = "btn_CrystalDiskInfo"; Path = "BIN\CrystalDiskInfo\DiskInfo64.exe" }
)

foreach ($tool in $tools) {
    $buttonName = $tool.Button
    $relativePath = $tool.Path
    $btn = $Form.FindName($buttonName)
    if (-not $btn) { continue }

    $fullPath = Join-Path $ScriptDir $relativePath

    # A v�ltoz�k �rt�k�t itt z�rom le egy k�l�n scriptblockban
    $Form.Add_Loaded(
        [scriptblock]::Create(@"
`$btn = `$Form.FindName('$buttonName')
if (`$btn) {
    `$btn.IsEnabled = [System.IO.File]::Exists('$fullPath')
}
"@)
    )

    $btn.Add_Click(
        [scriptblock]::Create(@"
if ([System.IO.File]::Exists('$fullPath')) {
    Start-Process '$fullPath' -Verb RunAs
} else {
    [System.Windows.MessageBox]::Show('A f�jl nem tal�lhat�:`n$fullPath', 'Hiba', 'OK', 'Error')
}
"@)
    )
}




$btn_DRV   = $Form.FindName("btn_DRV")
$btn_DRV.Add_Click({
    Start-Process "$ScriptDir\DRV"
})



$img_rackhost   = $Form.FindName("img_rackhost")
$img_rackhost.Add_MouseDown({
    Start-Process "https://www.rackhost.hu/"
})

$img_sectigo   = $Form.FindName("img_sectigo")
$img_sectigo.Add_MouseDown({
    Start-Process "https://www.sectigo.com/"
})

$img_foxL   = $Form.FindName("img_foxL")
$img_foxL.Add_MouseDown({
    Start-Process "https://www.iconarchive.com/show/wild-camping-icons-by-iconarchive/Fox-icon.html"
})
$img_foxR   = $Form.FindName("img_foxR")
$img_foxR.Add_MouseDown({
    Start-Process "https://www.iconarchive.com/show/wild-camping-icons-by-iconarchive/Fox-icon.html"
})

$btn_NiniteFree   = $Form.FindName("btn_NiniteFree")
$btn_NiniteFree.Add_Click({
    Start-Process "https://ninite.com/"
})

$btn_InstPRG = $Form.FindName("btn_InstPRG")
$btn_InstPRG.Add_Click({
    Start-Process "control.exe" -ArgumentList "/name Microsoft.ProgramsAndFeatures"
})

$btn_TimeUpdate = $Form.FindName("btn_TimeUpdate")
$btn_TimeUpdate.Add_Click({
    Start-Process -FilePath "w32tm" -ArgumentList "/config /update" -Verb RunAs
})

$btn_WindowsUpdate = $Form.FindName("btn_WindowsUpdate")
$btn_WindowsUpdate.Add_Click({
    Start-Process "control.exe" -ArgumentList "/name Microsoft.WindowsUpdate"
})





# Megjelen�t�s
$Form.ShowDialog() | Out-Null