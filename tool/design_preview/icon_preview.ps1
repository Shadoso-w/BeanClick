# Icon preview generator: scheme 2 "top-down cup rim" (ASCII only on purpose:
# Windows PowerShell 5.1 reads BOM-less UTF-8 as ANSI, so keep this script ASCII).
Add-Type -AssemblyName System.Drawing

$outDir = Join-Path $PSScriptRoot 'out'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$brown  = [System.Drawing.Color]::FromArgb(255, 111, 78, 55)   # seed #6F4E37
$cream  = [System.Drawing.Color]::FromArgb(255, 250, 246, 240) # #FAF6F0
$crema  = [System.Drawing.Color]::FromArgb(255, 196, 154, 108) # #C49A6C
$espresso = [System.Drawing.Color]::FromArgb(255, 74, 51, 36)  # darker than seed
$espressoBlack = [System.Drawing.Color]::FromArgb(255, 42, 29, 20) # near-black coffee
$darkbg = [System.Drawing.Color]::FromArgb(255, 28, 22, 19)    # #1C1613 dark surface

function New-Canvas([int]$size) {
  $bmp = New-Object System.Drawing.Bitmap($size, $size)
  $bmp.SetResolution(96, 96)
  return $bmp
}

# Rounded-square background, radius = 22% of canvas.
function Draw-RoundRect($g, [int]$size, $color, [double]$radiusRatio = 0.22) {
  $r = [int]($size * $radiusRatio)
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $r * 2
  $path.AddArc(0, 0, $d, $d, 180, 90)
  $path.AddArc($size - $d - 1, 0, $d, $d, 270, 90)
  $path.AddArc($size - $d - 1, $size - $d - 1, $d, $d, 0, 90)
  $path.AddArc(0, $size - $d - 1, $d, $d, 90, 90)
  $path.CloseFigure()
  $brush = New-Object System.Drawing.SolidBrush($color)
  $g.FillPath($brush, $path)
  $brush.Dispose(); $path.Dispose()
}

# Top-down cup: outer ring (rim) + optional liquid disc + crema swirl.
function Draw-Cup($g, [int]$size, $ringColor, $liquidColor, $swirlColor, [bool]$solid, [double]$scale = 0.62) {
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $cx = $size / 2.0
  $cy = $size / 2.0
  $outerR = $size * $scale / 2.0
  $stroke = $size * 0.072

  # rim
  $pen = New-Object System.Drawing.Pen($ringColor, [single]$stroke)
  $pen.Alignment = [System.Drawing.Drawing2D]::PenAlignment.Inset
  $g.DrawEllipse($pen, [single]($cx - $outerR), [single]($cy - $outerR), [single]($outerR * 2), [single]($outerR * 2))

  $innerR = $outerR - $stroke * 0.55
  if ($solid) {
    $brush = New-Object System.Drawing.SolidBrush($liquidColor)
    $g.FillEllipse($brush, [single]($cx - $innerR), [single]($cy - $innerR), [single]($innerR * 2), [single]($innerR * 2))
    $brush.Dispose()
  }

  # crema swirl: an archimedean spiral, 2.2 turns
  $swirlPen = New-Object System.Drawing.Pen($swirlColor, [single]($size * 0.055))
  $swirlPen.StartCap = [System.Drawing.Drawing2D]::LineCap::Round
  $swirlPen.EndCap = [System.Drawing.Drawing2D]::LineCap::Round
  $pts = New-Object 'System.Collections.Generic.List[System.Drawing.PointF]'
  $turns = 2.2
  $steps = 120
  $maxR = $innerR * 0.72
  for ($i = 0; $i -le $steps; $i++) {
    $t = $i / [double]$steps
    $ang = $t * $turns * 2 * [Math]::PI - [Math]::PI / 2
    $rr = $maxR * (0.10 + 0.90 * $t)
    $pts.Add((New-Object System.Drawing.PointF([single]($cx + $rr * [Math]::Cos($ang)), [single]($cy + $rr * [Math]::Sin($ang)))))
  }
  $g.DrawCurve($swirlPen, $pts.ToArray())
  $pen.Dispose(); $swirlPen.Dispose()
}

function Render-Variant([string]$name, $bgColor, $ringColor, $liquidColor, $swirlColor, [bool]$solid, [double]$scale = 0.62) {
  $bmp = New-Canvas 512
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::Transparent)
  Draw-RoundRect $g 512 $bgColor
  Draw-Cup $g 512 $ringColor $liquidColor $swirlColor $solid $scale
  $g.Dispose()
  $path = Join-Path $outDir "$name.png"
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  return $bmp
}

# A: brown bg / cream rim / near-black espresso disc / cream swirl (high contrast)
$a = Render-Variant 'scheme2_A' $brown $cream $espressoBlack $cream $true
# B: cream bg / brown rim / espresso disc / crema swirl (light version)
$b = Render-Variant 'scheme2_B' $cream $brown $espressoBlack $crema $true
# C: brown bg / cream rim + cream swirl, no disc (minimal line version)
$c = Render-Variant 'scheme2_C' $brown $cream $espressoBlack $cream $false
# D: dark bg / crema rim / espresso disc / cream swirl (dark-mode flavoured)
$d = Render-Variant 'scheme2_D' $darkbg $crema $espressoBlack $cream $true

# ---- contact sheet: rounded / circular mask / 96 / 72 / 48 / 36 + size labels ----
$rowH = 220
$colW = 210
$sheet = New-Object System.Drawing.Bitmap(($colW * 6 + 40), ($rowH * 4 + 60))
$sg = [System.Drawing.Graphics]::FromImage($sheet)
$sg.Clear([System.Drawing.Color]::White)
$sg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$sg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$labelFont = New-Object System.Drawing.Font('Arial', 12)
$headFont = New-Object System.Drawing.Font('Arial', 13, [System.Drawing.FontStyle]::Bold)
$labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 70, 70, 70))
$hairPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 215, 215, 215), 1)

$variants = @(
  @{ name = 'A  brown bg'; bmp = $a },
  @{ name = 'B  cream bg'; bmp = $b },
  @{ name = 'C  line only'; bmp = $c },
  @{ name = 'D  dark bg'; bmp = $d }
)
$sizes = @(96, 72, 48, 36)
$headers = @('192 rounded', '192 circle mask', '96', '72', '48', '36')
for ($i = 0; $i -lt $headers.Count; $i++) {
  $sg.DrawString($headers[$i], $headFont, $labelBrush, (20 + $i * $colW), 8)
}

$y = 40
foreach ($v in $variants) {
  $sg.DrawString($v.name, $labelFont, $labelBrush, 20, ($y + 95))
  # 192 rounded
  $sg.DrawImage($v.bmp, 20, ($y + 5), 192, 192)
  # 192 circular mask
  $circlePath = New-Object System.Drawing.Drawing2D.GraphicsPath
  $circlePath.AddEllipse(230, ($y + 5), 192, 192)
  $oldClip = $sg.Clip
  $sg.SetClip($circlePath)
  $sg.DrawImage($v.bmp, 230, ($y + 5), 192, 192)
  $sg.Clip = $oldClip
  $sg.DrawEllipse($hairPen, 230, ($y + 5), 192, 192)
  $circlePath.Dispose()
  # small sizes, top aligned
  $x = 20 + 2 * $colW
  foreach ($s in $sizes) {
    $sg.DrawImage($v.bmp, ($x + 10), ($y + 5), $s, $s)
    $sg.DrawRectangle($hairPen, ($x + 10), ($y + 5), $s, $s)
    $x += $colW
  }
  $y += $rowH
}
$sg.Dispose()
$sheet.Save((Join-Path $outDir 'scheme2_sheet.png'), [System.Drawing.Imaging.ImageFormat]::Png)

foreach ($bmp in @($a, $b, $c, $d, $sheet)) { $bmp.Dispose() }
Write-Output "wrote to $outDir"
Get-ChildItem $outDir | Select-Object Name, Length
