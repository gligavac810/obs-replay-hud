# OBS Replay Overlay (PowerShell + WPF, no install needed)
# Shows a floating notification in the top-right corner when the Replay Buffer
# starts, stops or saves a clip. Always on top, never steals focus, and
# mouse clicks pass straight through it.
#
# Events are sent by replay_overlay_events.lua through a small file in %TEMP%.

param([switch]$Test)

# ================================ SETTINGS ===================================
$ShowMs = 2800   # how long the notification stays on screen (ms)
$MARGIN = 24     # distance from the screen edge (px)
# =============================================================================

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$LogPath = Join-Path $env:TEMP 'obs_replay_overlay.log'
$SigPath = Join-Path $env:TEMP 'obs_replay_overlay.txt'
function Write-Log([string]$msg) {
    try { Add-Content -Path $LogPath -Value ("{0} {1}" -f (Get-Date -Format s), $msg) } catch {}
}

# single instance only
$created = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\ObsReplayOverlay', [ref]$created)
if (-not $created) { exit }

try {

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class OverlayWinApi {
    [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h, int i);
    [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr h, int i, int v);
}
"@

$PAD   = 28   # room around the card for the shadow
$SLIDE = 56   # slide distance for enter / exit (px)

# ------------------------------ THEMES --------------------------------------
$themes = @{
    started = @{ accent = '#34E0B0'; accent2 = '#8CF7DC'; title = 'Replay buffer started'; sub = 'Capturing in the background'; pill = 'ACTIVE';  path = 'M8,5.5 L18.5,12 L8,18.5 Z';        fill = $true;  thick = 2.2 }
    stopped = @{ accent = '#FF6477'; accent2 = '#FFA3AE'; title = 'Replay buffer stopped'; sub = 'No longer capturing';          pill = 'STOPPED'; path = 'M7.5,7.5 L16.5,7.5 L16.5,16.5 L7.5,16.5 Z'; fill = $true;  thick = 2.4 }
    saved   = @{ accent = '#6E8BFF'; accent2 = '#B4C3FF'; title = 'Replay saved';          sub = 'Clip saved successfully';        pill = 'SAVED';   path = 'M5.5,12.5 L10,17 L18.5,7.5';       fill = $false; thick = 2.6 }
}

function Get-Tint($c, [int]$a) { [System.Windows.Media.Color]::FromArgb([byte]$a, $c.R, $c.G, $c.B) }
function New-Solid($color) { $b = [System.Windows.Media.SolidColorBrush]::new($color); $b.Freeze(); return $b }
function New-Linear($c1, $c2, [double]$angle) {
    $b = [System.Windows.Media.LinearGradientBrush]::new($c1, $c2, $angle); $b.Freeze(); return $b
}

# build every brush once, so showing a toast allocates almost nothing
foreach ($k in @($themes.Keys)) {
    $t  = $themes[$k]
    $c1 = [System.Windows.Media.ColorConverter]::ConvertFromString($t.accent)
    $c2 = [System.Windows.Media.ColorConverter]::ConvertFromString($t.accent2)
    $t.main       = New-Solid $c1
    $t.tile       = New-Linear (Get-Tint $c1 70) (Get-Tint $c1 22) 45
    $t.tileBorder = New-Solid (Get-Tint $c1 90)
    $t.pillBg     = New-Solid (Get-Tint $c1 38)
    $t.bar        = New-Linear $c1 $c2 0
    $glow = New-Object System.Windows.Media.RadialGradientBrush
    $glow.Center         = [System.Windows.Point]::new(0.08, 0.5)
    $glow.GradientOrigin = [System.Windows.Point]::new(0.08, 0.5)
    $glow.RadiusX = 0.8
    $glow.RadiusY = 1.3
    $glow.GradientStops.Add([System.Windows.Media.GradientStop]::new((Get-Tint $c1 62), 0.0))
    $glow.GradientStops.Add([System.Windows.Media.GradientStop]::new((Get-Tint $c1 0), 1.0))
    $glow.Freeze()
    $t.glow = $glow
    $geo = [System.Windows.Media.Geometry]::Parse($t.path)
    $geo.Freeze()
    $t.geo = $geo
}

# ------------------------------ WINDOW --------------------------------------
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="OBS Replay Overlay" Width="448" Height="150"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        Topmost="True" ShowInTaskbar="False" ShowActivated="False"
        ResizeMode="NoResize" Focusable="False" UseLayoutRounding="True"
        TextOptions.TextRenderingMode="Grayscale">
  <Grid x:Name="Stage" Opacity="0">
    <Grid.RenderTransform>
      <TranslateTransform X="56"/>
    </Grid.RenderTransform>
    <Grid Margin="28">

      <!-- soft shadow, rendered once and cached (cheap while animating) -->
      <Border CornerRadius="16" Background="#000000">
        <Border.Effect>
          <DropShadowEffect BlurRadius="28" ShadowDepth="8" Direction="270" Opacity="0.55" Color="#000000"/>
        </Border.Effect>
        <Border.CacheMode>
          <BitmapCache/>
        </Border.CacheMode>
      </Border>

      <!-- card -->
      <Border CornerRadius="16" BorderThickness="1">
        <Border.Background>
          <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#FA1B1E29" Offset="0"/>
            <GradientStop Color="#FA0F1117" Offset="1"/>
          </LinearGradientBrush>
        </Border.Background>
        <Border.BorderBrush>
          <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
            <GradientStop Color="#33FFFFFF" Offset="0"/>
            <GradientStop Color="#0DFFFFFF" Offset="1"/>
          </LinearGradientBrush>
        </Border.BorderBrush>
        <Grid>
          <Border x:Name="Glow" CornerRadius="15"/>

          <Grid Margin="16,14,18,24">
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="Auto"/>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>

            <Grid Width="48" Height="48" VerticalAlignment="Center">
              <Border x:Name="PulseRing" CornerRadius="14" BorderThickness="2" Opacity="0"
                      RenderTransformOrigin="0.5,0.5">
                <Border.RenderTransform><ScaleTransform ScaleX="1" ScaleY="1"/></Border.RenderTransform>
              </Border>
              <Border x:Name="IconTile" CornerRadius="14" BorderThickness="1"
                      RenderTransformOrigin="0.5,0.5">
                <Border.RenderTransform><ScaleTransform ScaleX="1" ScaleY="1"/></Border.RenderTransform>
                <Viewbox Width="22" Height="22" HorizontalAlignment="Center" VerticalAlignment="Center">
                  <Canvas Width="24" Height="24">
                    <Path x:Name="IconPath" StrokeLineJoin="Round" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
                  </Canvas>
                </Viewbox>
              </Border>
            </Grid>

            <StackPanel Grid.Column="1" Margin="14,0,10,0" VerticalAlignment="Center">
              <TextBlock x:Name="TitleTb" FontFamily="Segoe UI Variable Text, Segoe UI" FontSize="15"
                         FontWeight="SemiBold" Foreground="#F5F6FA" TextTrimming="CharacterEllipsis"/>
              <TextBlock x:Name="SubTb" FontFamily="Segoe UI Variable Text, Segoe UI" FontSize="12"
                         Foreground="#8FFFFFFF" TextTrimming="CharacterEllipsis" Margin="0,3,0,0"/>
            </StackPanel>

            <Border x:Name="Pill" Grid.Column="2" CornerRadius="9" Padding="8,3,9,3" VerticalAlignment="Center">
              <StackPanel Orientation="Horizontal">
                <Ellipse x:Name="PillDot" Width="6" Height="6" Margin="0,0,6,0" VerticalAlignment="Center"/>
                <TextBlock x:Name="PillTxt" FontFamily="Segoe UI Variable Text, Segoe UI" FontSize="10.5"
                           FontWeight="Bold" VerticalAlignment="Center"/>
              </StackPanel>
            </Border>
          </Grid>

          <!-- countdown bar -->
          <Border Height="3" VerticalAlignment="Bottom" Margin="16,0,16,12" CornerRadius="1.5" Background="#14FFFFFF"/>
          <Border x:Name="Bar" Height="3" VerticalAlignment="Bottom" Margin="16,0,16,12"
                  CornerRadius="1.5" RenderTransformOrigin="0,0.5">
            <Border.RenderTransform><ScaleTransform ScaleX="1"/></Border.RenderTransform>
          </Border>
        </Grid>
      </Border>
    </Grid>
  </Grid>
</Window>
'@

$win = [System.Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader ([xml]$xaml)))
$Stage     = $win.FindName('Stage')
$StageMove = $Stage.RenderTransform
$Glow      = $win.FindName('Glow')
$PulseRing = $win.FindName('PulseRing')
$PulseSc   = $PulseRing.RenderTransform
$IconTile  = $win.FindName('IconTile')
$IconSc    = $IconTile.RenderTransform
$IconPath  = $win.FindName('IconPath')
$TitleTb   = $win.FindName('TitleTb')
$SubTb     = $win.FindName('SubTb')
$Pill      = $win.FindName('Pill')
$PillDot   = $win.FindName('PillDot')
$PillTxt   = $win.FindName('PillTxt')
$Bar       = $win.FindName('Bar')
$BarScale  = $Bar.RenderTransform

# clicks pass through, no focus, hidden from Alt+Tab
$win.Add_SourceInitialized({
    $h  = (New-Object System.Windows.Interop.WindowInteropHelper($win)).Handle
    $ex = [OverlayWinApi]::GetWindowLong($h, -20)
    [OverlayWinApi]::SetWindowLong($h, -20, ($ex -bor 0x20 -bor 0x80 -bor 0x08000000)) | Out-Null
})

$S = @{ state = 'idle'; last = ''; stamp = 0; ti = 0 }

# ----------------------------- ANIMATION ------------------------------------
$easeOut = New-Object System.Windows.Media.Animation.CubicEase
$easeOut.EasingMode = 'EaseOut'
$easeOut.Freeze()
$easeIn = New-Object System.Windows.Media.Animation.CubicEase
$easeIn.EasingMode = 'EaseIn'
$easeIn.Freeze()
$easePop = New-Object System.Windows.Media.Animation.BackEase
$easePop.EasingMode = 'EaseOut'
$easePop.Amplitude = 0.7
$easePop.Freeze()

function New-Anim([double]$from, [double]$to, [int]$ms, [string]$ease) {
    $a = New-Object System.Windows.Media.Animation.DoubleAnimation
    $a.From = $from
    $a.To = $to
    $a.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds($ms))
    switch ($ease) {
        'out' { $a.EasingFunction = $easeOut }
        'in'  { $a.EasingFunction = $easeIn }
        'pop' { $a.EasingFunction = $easePop }
    }
    return $a
}

$onOutDone = {
    if ($S.state -eq 'hiding') {
        $StageMove.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $null)
        $Stage.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
        $Stage.Opacity = 0
        $StageMove.X = $SLIDE
        $win.Hide()
        $S.state = 'idle'
    }
}

function Hide-Toast {
    $S.state = 'hiding'
    $a = New-Anim $StageMove.X $SLIDE 300 'in'
    $a.Add_Completed($onOutDone)
    $StageMove.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $a)
    $Stage.BeginAnimation([System.Windows.UIElement]::OpacityProperty, (New-Anim $Stage.Opacity 0 260 'in'))
}

function Show-Toast([string]$kind, [string]$sub) {
    $th = $themes[$kind]
    $S.state = 'showing'

    $IconTile.Background  = $th.tile
    $IconTile.BorderBrush = $th.tileBorder
    $PulseRing.BorderBrush = $th.main
    $IconPath.Data = $th.geo
    $IconPath.Stroke = $th.main
    $IconPath.StrokeThickness = $th.thick
    if ($th.fill) { $IconPath.Fill = $th.main } else { $IconPath.Fill = $null }
    $Glow.Background = $th.glow
    $Bar.Background  = $th.bar
    $Pill.Background = $th.pillBg
    $PillDot.Fill    = $th.main
    $PillTxt.Foreground = $th.main
    $PillTxt.Text    = $th.pill
    $TitleTb.Text    = $th.title
    if ($sub) { $SubTb.Text = $sub } else { $SubTb.Text = $th.sub }

    $wa = [System.Windows.SystemParameters]::WorkArea
    $win.Left = $wa.Right - $win.Width + $PAD - $MARGIN
    $win.Top  = $wa.Top + $MARGIN - $PAD

    $win.Topmost = $false
    $win.Topmost = $true

    if (-not $win.IsVisible) {
        $StageMove.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $null)
        $Stage.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
        $Stage.Opacity = 0
        $StageMove.X = $SLIDE
        $win.Show()
    }

    # slide + fade in
    $StageMove.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, (New-Anim $StageMove.X 0 440 'out'))
    $Stage.BeginAnimation([System.Windows.UIElement]::OpacityProperty, (New-Anim $Stage.Opacity 1 240 'out'))

    # icon pop + one soft pulse ring
    $pop = New-Anim 0.6 1 520 'pop'
    $IconSc.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $pop)
    $IconSc.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $pop)
    $ring = New-Anim 1 1.7 760 'out'
    $PulseSc.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $ring)
    $PulseSc.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $ring)
    $PulseRing.BeginAnimation([System.Windows.UIElement]::OpacityProperty, (New-Anim 0.6 0 760 'out'))

    # countdown bar (30 fps is plenty for a thin bar and halves the cost)
    $bar = New-Anim 1 0 $ShowMs 'none'
    [System.Windows.Media.Animation.Timeline]::SetDesiredFrameRate($bar, 30)
    $BarScale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $bar)

    $S.hold.Stop()
    $S.hold.Start()
}

# the bar runs down, then the notification slides out
$S.hold = New-Object System.Windows.Threading.DispatcherTimer
$S.hold.Interval = [TimeSpan]::FromMilliseconds($ShowMs)
$S.hold.Add_Tick({ $S.hold.Stop(); Hide-Toast })

# ---- reading the signal from the Lua script --------------------------------
function Read-Signal {
    try {
        $share = [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete
        $fs = [System.IO.File]::Open($SigPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, $share)
        try {
            $sr = New-Object System.IO.StreamReader($fs)
            return $sr.ReadToEnd()
        } finally { $fs.Dispose() }
    } catch { return $null }
}

# ignore whatever was left in the file from a previous session
$S.stamp = [System.IO.File]::GetLastWriteTimeUtc($SigPath).Ticks
$init = Read-Signal
if ($init) { $S.last = $init.Trim() }

# Idle cost: one cheap timestamp check per tick. The file is only opened and
# read when its timestamp actually changed.
$poll = New-Object System.Windows.Threading.DispatcherTimer
$poll.Interval = [TimeSpan]::FromMilliseconds(200)
$poll.Add_Tick({
    $stamp = [System.IO.File]::GetLastWriteTimeUtc($SigPath).Ticks
    if ($stamp -eq $S.stamp) { return }

    $raw = Read-Signal
    if (-not $raw) { return }
    $raw = $raw.Trim()
    $parts = $raw -split '\|', 3
    if ($parts.Count -lt 3) { return }          # file is still being written, retry next tick

    $S.stamp = $stamp
    if ($raw -eq $S.last) { return }
    $S.last = $raw

    $kind = $parts[0]
    if ($themes.ContainsKey($kind)) {
        $extra = ''
        if ($parts[1]) { $extra = Split-Path $parts[1] -Leaf }
        Show-Toast $kind $extra
    }
})
$poll.Start()

# ---- demo (tray menu "Test notifications" or -Test) ------------------------
$tests = @(
    @('started', ''),
    @('saved',   ('Replay ' + (Get-Date -Format 'yyyy-MM-dd HH-mm-ss') + '.mp4')),
    @('stopped', '')
)
$testTimer = New-Object System.Windows.Threading.DispatcherTimer
$testTimer.Interval = [TimeSpan]::FromMilliseconds(3600)
$testTimer.Add_Tick({
    if ($S.ti -ge $tests.Count) { $testTimer.Stop(); return }
    $t = $tests[$S.ti]
    $S.ti++
    Show-Toast $t[0] $t[1]
})
function Start-Demo {
    $testTimer.Stop()
    Show-Toast $tests[0][0] $tests[0][1]
    $S.ti = 1
    $testTimer.Start()
}

# ---- tray icon --------------------------------------------------------------
$app = New-Object System.Windows.Application
$app.ShutdownMode = 'OnExplicitShutdown'
$app.Add_DispatcherUnhandledException({
    param($sender, $e)
    Write-Log ("Error: " + $e.Exception.Message)
    $e.Handled = $true
})

$bmp = New-Object System.Drawing.Bitmap 32, 32
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$rect = New-Object System.Drawing.Rectangle 1, 1, 30, 30
$grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, [System.Drawing.Color]::FromArgb(140, 167, 255), [System.Drawing.Color]::FromArgb(86, 112, 240), 45.0)
$g.FillEllipse($grad, $rect)
$g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(20, 23, 32))), 9, 9, 14, 14)
$g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(140, 167, 255))), 12, 12, 8, 8)
$g.Dispose()
$grad.Dispose()

$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
$tray.Text = 'OBS Replay Overlay'
$menu = New-Object System.Windows.Forms.ContextMenuStrip
$hdr = $menu.Items.Add('OBS Replay Overlay')
$hdr.Enabled = $false
$null = $menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
$null = $menu.Items.Add('Test notifications', $null, { Start-Demo })
$null = $menu.Items.Add('Quit', $null, { $app.Shutdown() })
$tray.ContextMenuStrip = $menu
$tray.Visible = $true

if ($Test) { Start-Demo }

$app.Run() | Out-Null

$tray.Visible = $false
$tray.Dispose()

} catch {
    Write-Log ("Fatal error: " + $_.Exception.Message + " | " + $_.ScriptStackTrace)
} finally {
    try { $mutex.ReleaseMutex() } catch {}
}
