# Icon shrink comparison sheet -- decision helper, NOT part of the build.
#
# For each candidate "keep" ratio it renders three views of the adaptive icon:
#   1. foreground layer alone, on the cream background colour (what the system gets)
#   2. the same, cut by a circle mask   (roughly what a round launcher shows)
#   3. the same, cut by a squircle mask (roughly what MIUI shows)
#
# usage: powershell -NoProfile -ExecutionPolicy Bypass -File tool/icon_scale_preview.ps1
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$src = New-Object System.Drawing.Bitmap((Join-Path $root 'assets\icon\app_icon_source.png'))

# Visible fraction of the 108dp canvas for each mask. Android's safe zone is
# 72/108 = 0.667; squircle masks are a bit larger than the circle.
$circleRatio = 0.72
$squircleRatio = 0.78
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
      $old = $bytes[$i + 3]
      # Never touch a pixel the source never painted. A cleared 32bppArgb pixel is
      # (0,0,0,0); its luminance is 0, so keying it would turn it into OPAQUE BLACK
      # and the keyed-out margin would come back as a black square.
      if ($old -eq 0) { continue }
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

# Foreground PNG at $size, source scaled to $keep of the canvas.
function Render-Foreground([int]$size, [double]$keep) {
  $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
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

# Flatten onto the cream background (opaque) by hand.
#
# Do NOT use Graphics.DrawImage for this: with a 32bppArgb target GDI+ paints the
# source's fully transparent pixels as OPAQUE BLACK, so the keyed-out area comes
# back as a black square.
function Flatten-OnCream([System.Drawing.Bitmap]$fg) {
  $size = $fg.Width
  $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
  $sd = $fg.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $dd = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $sb = New-Object byte[] ($sd.Stride * $size)
  $db = New-Object byte[] ($dd.Stride * $size)
  [System.Runtime.InteropServices.Marshal]::Copy($sd.Scan0, $sb, 0, $sb.Length)
  for ($y = 0; $y -lt $size; $y++) {
    $srow = $y * $sd.Stride; $drow = $y * $dd.Stride
    for ($x = 0; $x -lt $size; $x++) {
      $si = $srow + $x * 4; $di = $drow + $x * 4
      $a = $sb[$si + 3]
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
  $fg.UnlockBits($sd)
  $bmp.UnlockBits($dd)
  return $bmp
}

function Mask-Pixels($bmp, [double]$ratio, [string]$shape) {
  $w = $bmp.Width; $h = $bmp.Height
  $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
  $data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $bytes = New-Object byte[] ($data.Stride * $h)
  [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
  $d = $w * $ratio
  $c = $w / 2.0
  $r = $d / 2.0
  $half = $d / 2.0
  # squircle exponent: |x|^n + |y|^n <= r^n, n = 4 is close to MIUI's shape
  $n = 4.0
  for ($y = 0; $y -lt $h; $y++) {
    $row = $y * $data.Stride
    for ($x = 0; $x -lt $w; $x++) {
      $dx = $x + 0.5 - $c
      $dy = $y + 0.5 - $c
      $inside = $false
      if ($shape -eq 'circle') {
        $inside = (($dx * $dx) + ($dy * $dy)) -le ($r * $r)
      } else {
        $inside = ([Math]::Pow([Math]::Abs($dx / $half), $n) + [Math]::Pow([Math]::Abs($dy / $half), $n)) -le 1.0
      }
      if (-not $inside) { $bytes[$row + $x * 4 + 3] = 0 }
    }
  }
  [System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $data.Scan0, $bytes.Length)
  $bmp.UnlockBits($data)
  return $bmp
}

$scales = @(1.0, 0.94, 0.88, 0.82, 0.76)
$cell = 190
$gapBetween = 8
$gapGroups = 30
$views = 3
$labelH = 28
$groupW = $views * $cell + ($views - 1) * $gapBetween
$sheetW = 30 + $scales.Count * ($groupW + $gapGroups)
$sheetH = 24 + $cell + $labelH
$sheet = New-Object System.Drawing.Bitmap($sheetW, $sheetH)
$sg = [System.Drawing.Graphics]::FromImage($sheet)
# Mid grey sheet: transparent areas of the masked views have to be visible, and
# cream-on-cream would hide the whole thing.
$sg.Clear([System.Drawing.Color]::FromArgb(255, 190, 190, 190))
$sg.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
$font = New-Object System.Drawing.Font('Segoe UI', 11)
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 30, 30, 30))

$i = 0
foreach ($s in $scales) {
  $fg = Render-Foreground 432 $s
  $raw = Flatten-OnCream $fg
  $circ = Mask-Pixels (Flatten-OnCream $fg) $circleRatio 'circle'
  $sq = Mask-Pixels (Flatten-OnCream $fg) $squircleRatio 'squircle'
  $x = 30 + $i * ($groupW + $gapGroups)
  $sg.DrawImage($raw, $x, 24, $cell, $cell)
  $sg.DrawImage($circ, $x + $cell + $gapBetween, 24, $cell, $cell)
  $sg.DrawImage($sq, $x + 2 * ($cell + $gapBetween), 24, $cell, $cell)
  $sg.DrawString(("keep {0:N2}" -f $s), $font, $brush, $x, 24 + $cell + 6)
  foreach ($b in @($fg, $raw, $circ, $sq)) { $b.Dispose() }
  $i++
}

$sg.Dispose()
$outDir = Join-Path $PSScriptRoot 'out'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$out = Join-Path $outDir 'icon_scale_candidates.png'
$sheet.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
foreach ($b in @($sheet, $font, $brush)) { $b.Dispose() }
$src.Dispose()
Write-Output $out
