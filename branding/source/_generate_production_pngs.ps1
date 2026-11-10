# Generates production PNG masters from approved D2 / lockup geometry.
# Not a redesign — matches branding/concepts D2 + L1/L2/L4 sources.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$ink = [System.Drawing.ColorTranslator]::FromHtml('#111522')
$mist = [System.Drawing.ColorTranslator]::FromHtml('#EEF1F7')
$slate = [System.Drawing.ColorTranslator]::FromHtml('#DCE3EF')
$transparent = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$out = Join-Path $root 'generated'
New-Item -ItemType Directory -Force -Path $out | Out-Null

function New-Bmp([int]$w, [int]$h, [bool]$alpha) {
  $fmt = if ($alpha) { [System.Drawing.Imaging.PixelFormat]::Format32bppArgb } else { [System.Drawing.Imaging.PixelFormat]::Format32bppArgb }
  $b = New-Object System.Drawing.Bitmap $w, $h, $fmt
  $b.SetResolution(72, 72)
  return $b
}
function G([System.Drawing.Bitmap]$b) {
  $g = [System.Drawing.Graphics]::FromImage($b)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
  $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $g.Clear($transparent)
  return $g
}
function S([single]$v, [single]$size) { return ($v / 1024.0) * $size }
function RoundRect([single]$x, [single]$y, [single]$w, [single]$h, [single]$r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = [Math]::Min($r * 2, [Math]::Min($w, $h))
  $p.AddArc($x, $y, $d, $d, 180, 90)
  $p.AddArc(($x + $w - $d), $y, $d, $d, 270, 90)
  $p.AddArc(($x + $w - $d), ($y + $h - $d), $d, $d, 0, 90)
  $p.AddArc($x, ($y + $h - $d), $d, $d, 90, 90)
  $p.CloseFigure()
  return $p
}
function Draw-D2([System.Drawing.Graphics]$g, [single]$ox, [single]$oy, [single]$size, [System.Drawing.Color]$mark) {
  $st = $g.Save()
  $g.TranslateTransform($ox, $oy)
  $body = RoundRect (S 160 $size) (S 232 $size) (S 704 $size) (S 560 $size) (S 88 $size)
  $region = New-Object System.Drawing.Region $body
  $hole = New-Object System.Drawing.Drawing2D.GraphicsPath
  $hr = S 78 $size
  $hole.AddEllipse(((S 864 $size) - $hr), ((S 512 $size) - $hr), (2 * $hr), (2 * $hr))
  $region.Exclude($hole)
  $brush = New-Object System.Drawing.SolidBrush $mark
  $g.FillRegion($brush, $region)
  $body.Dispose(); $hole.Dispose(); $region.Dispose(); $brush.Dispose()
  $g.Restore($st)
}
function Save-Png([System.Drawing.Bitmap]$bmp, [string]$path) {
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  Write-Host "Wrote $path"
}

# 1) Full app icon 1024 — mist bg + ink mark (iOS / Android image_path)
$icon = New-Bmp 1024 1024 $true
$ig = G $icon
$ig.Clear($mist)
Draw-D2 $ig 0 0 1024 $ink
Save-Png $icon (Join-Path $out 'app_icon.png')
$ig.Dispose(); $icon.Dispose()

# 2) Adaptive foreground — transparent full-canvas mark.
# flutter_launcher_icons applies its own ~16% inset for the adaptive safe zone.
$fg = New-Bmp 1024 1024 $true
$fgg = G $fg
Draw-D2 $fgg 0 0 1024 $ink
Save-Png $fg (Join-Path $out 'app_icon_foreground.png')
$fgg.Dispose(); $fg.Dispose()

# 3) Adaptive foreground dark-compatible (slate mark) — optional master
$fgd = New-Bmp 1024 1024 $true
$fgdg = G $fgd
Draw-D2 $fgdg 0 0 1024 $slate
Save-Png $fgd (Join-Path $out 'app_icon_foreground_dark.png')
$fgdg.Dispose(); $fgd.Dispose()

# 4) Splash L2 lockup — transparent canvas, light (ink) and dark (slate) marks
function Render-L2Splash([System.Drawing.Color]$markColor, [string]$fileName) {
  # Tall canvas; flutter_native_splash centers the image.
  $w = 1024; $h = 1024
  $bmp = New-Bmp $w $h $true
  $g = G $bmp
  $markSize = 360
  $mx = ($w - $markSize) / 2
  $my = 220
  Draw-D2 $g $mx $my $markSize $markColor
  $font = [System.Drawing.Font]::new('Segoe UI', 92.0, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
  $brush = New-Object System.Drawing.SolidBrush $markColor
  $sz = $g.MeasureString('Fleet', $font)
  $g.DrawString('Fleet', $font, $brush, (($w - $sz.Width) / 2), 640)
  Save-Png $bmp (Join-Path $out $fileName)
  $g.Dispose(); $bmp.Dispose(); $font.Dispose(); $brush.Dispose()
}
Render-L2Splash $ink 'splash_lockup_light.png'
Render-L2Splash $slate 'splash_lockup_dark.png'

# 5) Android 12 splash icon — simpler centered mark (platform crops to circle/icon)
function Render-A12([System.Drawing.Color]$markColor, [string]$fileName) {
  $bmp = New-Bmp 1152 1152 $true
  $g = G $bmp
  # Keep content inside Android 12 splash icon safe circle (~2/3)
  $box = 720
  $ox = (1152 - $box) / 2
  $oy = (1152 - $box) / 2
  Draw-D2 $g $ox $oy $box $markColor
  Save-Png $bmp (Join-Path $out $fileName)
  $g.Dispose(); $bmp.Dispose()
}
Render-A12 $ink 'splash_android12_light.png'
Render-A12 $slate 'splash_android12_dark.png'

# 6) Lockup masters for reference (opaque backgrounds)
function Render-L1([System.Drawing.Color]$bg, [System.Drawing.Color]$fg, [string]$fileName) {
  $bmp = New-Bmp 1840 560 $true
  $g = G $bmp
  $g.Clear($bg)
  Draw-D2 $g 96 80 400 $fg
  $font = [System.Drawing.Font]::new('Segoe UI', 156.0, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
  $brush = New-Object System.Drawing.SolidBrush $fg
  $g.DrawString('Fleet', $font, $brush, 584, 156)
  Save-Png $bmp (Join-Path $out $fileName)
  $g.Dispose(); $bmp.Dispose(); $font.Dispose(); $brush.Dispose()
}
Render-L1 $mist $ink 'lockup_l1_light.png'
Render-L1 $ink $slate 'lockup_l1_dark.png'

function Render-L4([System.Drawing.Color]$bg, [System.Drawing.Color]$fg, [string]$fileName) {
  $bmp = New-Bmp 1040 320 $true
  $g = G $bmp
  $g.Clear($bg)
  Draw-D2 $g 56 56 208 $fg
  $font = [System.Drawing.Font]::new('Segoe UI', 88.0, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
  $brush = New-Object System.Drawing.SolidBrush $fg
  $g.DrawString('Fleet', $font, $brush, 324, 84)
  Save-Png $bmp (Join-Path $out $fileName)
  $g.Dispose(); $bmp.Dispose(); $font.Dispose(); $brush.Dispose()
}
Render-L4 $mist $ink 'lockup_l4_light.png'
Render-L4 $ink $slate 'lockup_l4_dark.png'

Write-Host 'Production PNGs ready.'
