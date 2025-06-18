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
function Test-IsRunAsAdmin {
    $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentIdentity)
    return ($principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator) -and `
            ([System.Environment]::UserInteractive -eq $true) -and `
            ($currentIdentity.Owner -eq $currentIdentity.User))
}
#Solution END

# GLOBALS
$ScriptDir                    = Get-Location  # Az aktuális munkakönyvtárat adja vissza, ineratktív esemény esetén!
$ScriptDir                    = Split-Path -Parent $MyInvocation.MyCommand.Path #AI javaslata
#$Icon                         = New-Object system.drawing.icon ("$ScriptDir/IMG/SolutionMaster.ico") #régi metodika, winforms
$IconPath                     = Join-Path $ScriptDir "IMG/SolutionMaster.ico"
$color_text                   = ""
$color_background             = "#FF1E1E1E"
$color_primary                = ""
$color_secondary              = ""
$color_accent                 = ""

# GUI Specs
$ytDLP                   = 'C:\BIN\yt-dlp\yt-dlp.exe'

[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Link Downloader" Height="250" Width="620"
        Background="$color_background"
        WindowStartupLocation="CenterScreen"
>
    <Grid>

        <!-- URL input -->
        <TextBlock Text="URL:" Foreground="White" Margin="10,10,0,0" HorizontalAlignment="Left" VerticalAlignment="Top"/>
        <TextBox x:Name="textBox_URL" Margin="50,10,90,0" Height="25" VerticalAlignment="Top" />
        <Button x:Name="button_INSERT_Click" Content="Beilleszt" Width="70" Height="25" HorizontalAlignment="Right" Margin="0,10,10,0" VerticalAlignment="Top" />

        <!-- Directory group -->
        <GroupBox Header="Directory" Foreground="White" Margin="10,45,220,45">
            <StackPanel Orientation="Vertical" Margin="5">
                <TextBox x:Name="textBox_Directory" Height="25" />
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,5,0,0">
                    <Button x:Name="button_DirectorySelect" Content="Select" Width="80" Margin="5,0"/>
                    <Button x:Name="button_DirectoryOpen" Content="Open" Width="80" Margin="5,0"/>
                </StackPanel>
            </StackPanel>
        </GroupBox>

        <!-- Format group -->
        <GroupBox Header="Format" Foreground="White" Margin="400,45,10,45">
            <StackPanel Margin="5">
                <ComboBox x:Name="comboBox_FormatType" Height="25" SelectedIndex="0">
                    <ComboBoxItem>MP4(video)</ComboBoxItem>
                    <ComboBoxItem>MP3(audio)</ComboBoxItem>
                    <ComboBoxItem>WAV(audio)</ComboBoxItem>
                </ComboBox>
                <ComboBox x:Name="comboBox_FormatQuality" Height="25" Margin="0,5,0,0" SelectedIndex="0">
                    <ComboBoxItem>Default</ComboBoxItem>
                    <ComboBoxItem>Best</ComboBoxItem>
                    <ComboBoxItem>1080p/320Kb</ComboBoxItem>
                    <ComboBoxItem>720p/256Kb</ComboBoxItem>
                    <ComboBoxItem>480p/192Kb</ComboBoxItem>
                    <ComboBoxItem>360p/128Kb</ComboBoxItem>
                    <ComboBoxItem>144p/64Kb</ComboBoxItem>
                </ComboBox>
				<CheckBox Style="{DynamicResource NeonCheckBox}" x:Name="checkBox_Playlist" Content="Playlist"/>
            </StackPanel>
        </GroupBox>
		
		<Button x:Name="button_Start" Content="Start" Width="70" Height="25" HorizontalAlignment="Right" Margin="10,10,10,10" VerticalAlignment="Bottom" />
    </Grid>
</Window>
"@
# ablak elrejtése: <Window ... AllowsTransparency="True" WindowStyle="None" ...>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$Reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Form = [Windows.Markup.XamlReader]::Load($Reader)
if (Test-Path $IconPath)
{ # ha létezik akkor ikon beállítása
    $Form.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create((New-Object System.IO.FileStream($IconPath, 'Open', 'Read')))
}

# Neon stílusok definiálása
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
	
	<!-- Neon kék stílusú checkbox -->
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
						<!-- Aktív (kiválasztott) tab -->
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

						<!-- Egérrel fölé húzott tab -->
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

# Betöltés memóriába
[xml]$styleXml = $styleXaml
$reader2 = (New-Object System.Xml.XmlNodeReader $styleXml)
$resources = [Windows.Markup.XamlReader]::Load($reader2)
$Form.Resources.MergedDictionaries.Add($resources)

$Form.FindName("button_DirectorySelect").Add_Click({
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
	$Dialog = New-Object System.Windows.Forms.FolderBrowserDialog
	$Dialog.ShowDialog()
	$filePath = $Dialog.SelectedPath
	if ([string]::IsNullOrEmpty($filePath))
	{
		return
	}
	$Form.FindName("textBox_Directory").Text = Join-Path $filePath "\"
})

$Form.FindName("button_DirectoryOpen").Add_Click({
    try
	{
		if ([string]::IsNullOrWhiteSpace($Form.FindName("textBox_Directory").Text))
		{
			throw "Az útvonal mezõ üres. Kérlek, adj meg egy érvényes könyvtárat."
		}
		if (-not (Test-Path -Path $Form.FindName("textBox_Directory").Text))
		{
			throw "A megadott könyvtár nem létezik: $($Form.FindName(""textBox_Directory"").Text)"
		}
		
		Start-Process -FilePath "explorer.exe" -ArgumentList $Form.FindName("textBox_Directory").Text
	}
	catch
	{
		[System.Windows.Forms.MessageBox]::Show("Hiba történt: $_")
	}
})

$Form.FindName("button_Start").Add_Click({
	Add-Type -AssemblyName System.Windows.Forms
	
	$url         = $Form.FindName("textBox_URL").Text
	$outputDir   = $Form.FindName("textBox_Directory").Text
	$formatType  = $Form.FindName("comboBox_FormatType").SelectedItem.Content.ToString()
	$quality     = $Form.FindName("comboBox_FormatQuality").SelectedItem.Content.ToString()
	
	# Playlist checkbox érték lekérése
	$playlistCheckBox = $Form.FindName("checkBox_Playlist")
	$playlistMode = $playlistCheckBox.IsChecked -eq $true

	# Alapértelmezett értékek
	$formatParam = $null
	$audioQuality = '0'

	# Minõség meghatározása
	switch ($quality)
	{
		"Default"      { $formatParam = $null; $audioQuality = '0' }
		"Best"         { $formatParam = "bestaudio"; $audioQuality = '0' }
		"1080p/320Kb"  { $formatParam = "bestaudio[abr<=320]"; $audioQuality = '0' }
		"720p/256Kb"   { $formatParam = "bestaudio[abr<=256]"; $audioQuality = '2' }
		"480p/192Kb"   { $formatParam = "bestaudio[abr<=192]"; $audioQuality = '4' }
		"360p/128Kb"   { $formatParam = "bestaudio[abr<=128]"; $audioQuality = '5' }
		"144p/64Kb"    { $formatParam = "bestaudio[abr<=64]"; $audioQuality = '9' }
		default        { $formatParam = $null; $audioQuality = '0' }
	}

	switch ($formatType)
	{
		"MP4(video)" {
			$args = @()
			if (-not $playlistMode) {
				$args += "--no-playlist"
			}
			if ($formatParam) {
				$args += "-f"
				$args += $formatParam.Replace("bestaudio", "bestvideo+bestaudio/best") # videó formátumhoz alakítjuk
			}
			$args += "-o"
			$args += "$outputDir%(title)s.%(ext)s"
			$args += $url
			
			Start-Process -FilePath "$ytDLP" -ArgumentList $args
			#[System.Windows.Forms.MessageBox]::Show("Start-Process -FilePath `"$ytDLP`" -ArgumentList $($args -join ' ')")
		}
		
		"MP3(audio)" {
			$args = @(
				'-x',
				'--audio-format', 'mp3',
				'--audio-quality', $audioQuality
			)
			if (-not $playlistMode) {
				$args += "--no-playlist"
			}
			if ($formatParam) {
				$args += "-f"
				$args += $formatParam
			}
			$args += "-o"
			$args += "$outputDir%(title)s.%(ext)s"
			$args += $url
			
			Start-Process -FilePath "$ytDLP" -ArgumentList $args
			#[System.Windows.Forms.MessageBox]::Show("Start-Process -FilePath `"$ytDLP`" -ArgumentList $($args -join ' ')")
		}
		
		"WAV(audio)" {
			[System.Windows.Forms.MessageBox]::Show("Fejlesztés alatt ...")
		}
		
		default {
			[System.Windows.Forms.MessageBox]::Show("Selected : $formatType")
		}
	}
})

$Form.FindName("button_INSERT_Click").Add_Click({
    Add-Type -AssemblyName System.Windows.Forms
	$clipboardText = [System.Windows.Forms.Clipboard]::GetText()
	$Form.FindName("textBox_URL").Text = $clipboardText
})

# Megjelenítés
$Form.ShowDialog() | Out-Null