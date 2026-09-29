# Final icon review sheet: the SAME asset as the phone would show it, on several
# launcher mask shapes, plus the legacy icon -- for one chosen "keep" ratio.
#
# usage: powershell -NoProfile -ExecutionPolicy Bypass -File tool/icon_review_sheet.ps1 [-Keep 0.88]
param([double]$Keep = 0.88)
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$src = New-Object System.Drawing.Bitmap((Join-Path $root 'assets\icon\app_icon_source.png'))
$cream = [System.Drawing.Color]::FromArgb(255, 243, 235, 220)

function Key-OutPixels($bmp, [int]$hi, [int]$lo) {
  $w = $bmp.Width; $h = $bmp.Height
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
      if ($lum -ge $hi) { $bytes[$i + 3] = 0 }
      elseif ($lum -le $lo) { $bytes[$i + 3] = 255 }
      else { $bytes[$i + 3] = [byte](255.0 * ($hi - $lum) / ($hi - $lo)) }
    }
  }
  [System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $data.Scan0, $bytes.Length)
  $bmp.UnlockBits($data)
}

function Render-Foreground([int]$size, [double]$keep) {
  $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::Transparent)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $inner = [int]($size * $keep); $off = [int](($size - $inner) / 2)
  $g.DrawImage($src, $off, $off, $inner, $inner)
  $g.Dispose()
  Key-OutPixels $bmp 215 185
  return $bmp
}

function Render-Legacy([int]$size, [double]$keep) {
  $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::Transparent)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $inner = [int]($size * $keep)
  $off = [int](($size - $inner) / 2)
  $g.DrawImage($src, $off, $off, $inner, $inner)
  $g.Dispose()
  Key-OutPixels $bmp 252 245
  return $bmp
}

function Flatten-OnCream([System.Drawing.Bitmap]$fg) {
  $size = $fg.Width
  $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
  $sd = $fg.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $dd = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $sb = New-Object byte[] ($sd.Stride * $size); $db = New-Object byte[] ($dd.Stride * $size)
  [System.Runtime.InteropServices.Marshal]::Copy($sd.Scan0, $sb, 0, $sb.Length)
  for ($y = 0; $y -lt $size; $y++) {
    $srow = $y * $sd.Stride; $drow = $y * $dd.Stride
    for ($x = 0; $x -lt $size; $x++) {
      $si = $srow + $x * 4; $di = $drow + $x * 4; $a = $sb[$si + 3]
      if ($a -eq 255) {
        $db[$di] = $sb[$si]; $db[$di + 1] = $sb[$si + 1]; $db[$di + 2] = $sb[$si + 2]
      } else {
        $db[$di] = [byte][int](($sb[$si] * $a + $cream.B * (255 - $a)) / 255)
        $db[$di + 1] = [byte][int](($sb[$si + 1] * $a + $cream.G * (255 - $a)) / 255)
        $db[$di + 2] = [byte][int](($sb[$si + 2] * $a + $cream.R * (255 - $a)) / 255)
      }
      $db[$di + 3] = 255
    }
  }
  [System.Runtime.InteropServices.Marshal]::Copy($db, 0, $dd.Scan0, $db.Length)
  $fg.UnlockBits($sd); $bmp.UnlockBits($dd)
  return $bmp
}

function Mask-Shape($bmp, [double]$ratio, [string]$shape) {
  $w = $bmp.Width; $h = $bmp.Height
  $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
  $data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $bytes = New-Object byte[] ($data.Stride * $h)
  [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
  $half = $w * $ratio / 2.0; $c = $w / 2.0; $n = 4.0
  for ($y = 0; $y -lt $h; $y++) {
    $row = $y * $data.Stride
    for ($x = 0; $x -lt $w; $x++) {
      $dx = $x + 0.5 - $c; $dy = $y + 0.5 - $c; $inside = $false
      if ($shape -eq 'circle') { $inside = (($dx * $dx) + ($dy * $dy)) -le ($half * $half) }
      elseif ($shape -eq 'squircle') { $inside = ([Math]::Pow([Math]::Abs($dx / $half), $n) + [Math]::Pow([Math]::Abs($dy / $half), $n)) -le 1.0 }
      else { $inside = $true }
      if (-not $inside) { $bytes[$row + $x * 4 + 3] = 0 }
    }
  }
  [System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $data.Scan0, $bytes.Length)
  $bmp.UnlockBits($data)
  return $bmp
}

# 108dp canvas; visible area is 72/108 for a circle, a bit more for a squircle.
$dp = 192
$fg = Render-Foreground 432 $Keep
$flat = Flatten-OnCream $fg
$views = @(
  @{ label = 'adaptive / square mask'; bmp = (Mask-Shape (Flatten-OnCream $fg) 1.0 'square') },
  @{ label = 'adaptive / circle 72dp'; bmp = (Mask-Shape (Flatten-OnCream $fg) 0.667 'circle') },
  @{ label = 'adaptive / squircle (MIUI)'; bmp = (Mask-Shape (Flatten-OnCream $fg) 0.78 'squircle') },
  @{ label = 'legacy ic_launcher'; bmp = (Render-Legacy $dp $Keep) }
)

$pad = 26
$labelH = 30
$cell = $dp
$sheetW = $pad + $views.Count * ($cell + $pad)
$sheetH = $pad + $cell + $labelH + $pad
$sheet = New-Object System.Drawing.Bitmap($sheetW, $sheetH)
$sg = [System.Drawing.Graphics]::FromImage($sheet)
$sg.Clear([System.Drawing.Color]::FromArgb(255, 120, 120, 120))
$sg.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
$font = New-Object System.Drawing.Font('Segoe UI', 12)
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
$x = $pad
foreach ($v in $views) {
  $sg.DrawImage($v.bmp, $x, $pad, $cell, $cell)
  $sg.DrawString($v.label, $font, $brush, $x, $pad + $cell + 6)
  $v.bmp.Dispose()
  $x += $cell + $pad
}
$sg.Dispose()
$outDir = Join-Path $PSScriptRoot 'out'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$out = Join-Path $outDir ("icon_review_keep{0}.png" -f ($Keep * 100))
$sheet.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
foreach ($b in @($sheet, $font, $brush, $fg, $flat)) { $b.Dispose() }
$src.Dispose()
Write-Output $out
