# Generate Android launcher icons from the user-provided source image.
#
# ASCII only on purpose: Windows PowerShell 5.1 reads BOM-less UTF-8 as ANSI,
# so non-ASCII comments break the parser.
#
# Source: assets/icon/app_icon_source.png  (1254x1254, cream rounded square
# with a dark ring, a coffee bean in the middle and tick marks around it)
# Outputs:
#   android/app/src/main/res/mipmap-*/ic_launcher.png           legacy icon
#   android/app/src/main/res/mipmap-*/ic_launcher_foreground.png adaptive foreground
#   assets/icon/app_icon_512.png                                 archived 512px
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$srcPath = Join-Path $root 'assets\icon\app_icon_source.png'
$resDir = Join-Path $root 'android\app\src\main\res'

if (-not (Test-Path $srcPath)) { throw "source icon not found: $srcPath" }
$src = New-Object System.Drawing.Bitmap($srcPath)

# How much of the 108dp adaptive canvas the source should fill.
#
# 1.00 makes the dark ring reach ~85% of the canvas, but the launcher only shows
# the middle 72/108 (a circle) to 78/108 (MIUI's squircle) of it -- the ring ends
# up touching the mask edge. 0.88 pulls the ring back to ~75% and leaves the
# margin the launcher masks expect. Preview: tool/icon_review_sheet.ps1
$foregroundKeep = 0.88

# Legacy sizes per density (mdpi 48 ... xxxhdpi 192); adaptive foreground is 2.25x.
$densities = @(
  @{ name = 'mdpi';    size = 48 },
  @{ name = 'hdpi';    size = 72 },
  @{ name = 'xhdpi';   size = 96 },
  @{ name = 'xxhdpi';  size = 144 },
  @{ name = 'xxxhdpi'; size = 192 }
)

function New-TransparentBitmap([int]$size) {
  $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $bmp.SetResolution(96, 96)
  return $bmp
}

# Copy $src into a $size canvas, keying out near-white pixels (the page outside
# the rounded square). Cream stays opaque: cream luminance is ~237, page ~254.
function Render-Legacy([int]$size) {
  $bmp = New-TransparentBitmap $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::Transparent)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.DrawImage($src, 0, 0, $size, $size)
  $g.Dispose()
  Key-OutPixels $bmp 252 245
  return $bmp
}

# Adaptive foreground: key out near-white AND the cream background, keeping only
# the dark ring, the bean and the brown ticks. The system paints the background
# color behind it, so the icon still looks like the source.
# The source is scaled to $keep of the canvas and centred, which shrinks the
# motif and grows the transparent margin around it.
function Render-Foreground([int]$size, [double]$keep) {
  $bmp = New-TransparentBitmap $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::Transparent)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $inner = [int]($size * $keep)
  $off = [int](($size - $inner) / 2)
  $g.DrawImage($src, $off, $off, $inner, $inner)
  $g.Dispose()
  Key-OutPixels $bmp 215 185
  return $bmp
}

# alpha = 0 for luminance >= $keepBelowHi, 255 for <= $keepBelowLo, linear between.
# Pixels that are already fully transparent are left alone: a cleared 32bppArgb
# pixel is (0,0,0,0), whose luminance is 0, so keying it would make it OPAQUE
# BLACK -- and any margin the source did not paint would turn into a black square.
function Key-OutPixels($bmp, [int]$hi, [int]$lo) {
  $w = $bmp.Width
  $h = $bmp.Height
  $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
  $data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $bytes = New-Object byte[] ($data.Stride * $h)
  [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
  for ($y = 0; $y -lt $h; $y++) {
    $row = $y * $data.Stride
    for ($x = 0; $x -lt $w; $x++) {
      $i = $row + $x * 4
      if ($bytes[$i + 3] -eq 0) { continue }
      $b = $bytes[$i]; $g = $bytes[$i + 1]; $r = $bytes[$i + 2]
      $lum = 0.299 * $r + 0.587 * $g + 0.114 * $b
      if ($lum -ge $hi) {
        $bytes[$i + 3] = 0
      } elseif ($lum -le $lo) {
        $bytes[$i + 3] = 255
      } else {
        $bytes[$i + 3] = [byte](255.0 * ($hi - $lum) / ($hi - $lo))
      }
    }
  }
  [System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $data.Scan0, $bytes.Length)
  $bmp.UnlockBits($data)
}

foreach ($d in $densities) {
  $dir = Join-Path $resDir ("mipmap-" + $d.name)
  New-Item -ItemType Directory -Force -Path $dir | Out-Null

  $legacy = Render-Legacy $d.size
  $legacy.Save((Join-Path $dir 'ic_launcher.png'), [System.Drawing.Imaging.ImageFormat]::Png)
  $legacy.Dispose()

  $fgSize = [int]($d.size * 2.25)
  $fg = Render-Foreground $fgSize $foregroundKeep
  $fg.Save((Join-Path $dir 'ic_launcher_foreground.png'), [System.Drawing.Imaging.ImageFormat]::Png)
  $fg.Dispose()
}

# Archived 512px source-resized copy.
$archived = Render-Legacy 512
$archived.Save((Join-Path $root 'assets\icon\app_icon_512.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$archived.Dispose()

# Review sheet: legacy / foreground-on-cream / foreground-on-checkerboard, at 192.
$sheetSize = 700
$sheet = New-Object System.Drawing.Bitmap($sheetSize, 260)
$sg = [System.Drawing.Graphics]::FromImage($sheet)
$sg.Clear([System.Drawing.Color]::White)
$sg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
# checkerboard to reveal transparency
for ($y = 0; $y -lt 260; $y += 13) {
  for ($x = 0; $x -lt $sheetSize; $x += 13) {
    if ((($x / 13) + ($y / 13)) % 2 -eq 0) {
      $sg.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 230, 230, 230))), $x, $y, 13, 13)
    }
  }
}
$legacy192 = Render-Legacy 192
$fg432 = Render-Foreground 432 $foregroundKeep
$fg192 = Render-Foreground 192 $foregroundKeep

$sg.DrawImage($legacy192, 30, 34, 192, 192)

# foreground composited on the cream background color, at 192
$cream = New-Object System.Drawing.Bitmap(192, 192)
$cg = [System.Drawing.Graphics]::FromImage($cream)
$cg.Clear([System.Drawing.Color]::FromArgb(255, 243, 235, 220))
$cg.DrawImage($fg192, 0, 0, 192, 192)
$cg.Dispose()
$sg.DrawImage($cream, 250, 34, 192, 192)

# foreground on checkerboard (192)
$sg.DrawImage($fg192, 470, 34, 192, 192)
$sg.Dispose()
$outDir = Join-Path $PSScriptRoot 'out'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$sheet.Save((Join-Path $outDir 'app_icon_preview.png'), [System.Drawing.Imaging.ImageFormat]::Png)

foreach ($b in @($legacy192, $fg432, $fg192, $cream, $sheet)) { $b.Dispose() }
$src.Dispose()

Write-Output 'icons written'
Get-ChildItem $resDir -Recurse -Filter 'ic_launcher*.png' | Select-Object FullName, Length
