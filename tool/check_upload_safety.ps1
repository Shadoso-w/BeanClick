# check_upload_safety.ps1 -- pre-push upload safety scanner for BeanClick.
#
# Answers three questions before anything is pushed to the PUBLIC repo:
#   A. Necessity   -- is a generated / binary / oversized file being uploaded?
#   B. Leakage     -- does any uploaded byte expose this machine, this device,
#                     a credential, or real personal data?
#   C. Hardcoding  -- is a machine-specific absolute path baked into code?
#
# ASCII only on purpose: Windows PowerShell 5.1 reads BOM-less UTF-8 as ANSI,
# so non-ASCII text in this file would break the parser. Same rule as
# tool/make_app_icons.ps1 -- see docs/DEVELOPMENT.md section 10.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\check_upload_safety.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\check_upload_safety.ps1 -All
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\check_upload_safety.ps1 -SummaryOnly
#
# Exit codes:
#   0 = no BLOCK findings (WARN / INFO may still be present)
#   1 = at least one BLOCK finding -> do NOT push
#   2 = scanner could not run (not a git repo, git missing)
#
# Escape hatch: a source line containing 'upload-safety:ignore' is skipped by
# the content rules. Use it only where documentation must show a raw pattern.

[CmdletBinding()]
param(
  # What to scan. Default is "tracked files only" (what a push would upload).
  [switch]$IncludeStaged,
  [switch]$IncludeUntracked,
  [switch]$All,

  # Extra path prefixes (e.g. 'D:\devtools') that are treated as a documented
  # project convention. Only downgrades findings inside .md files to INFO;
  # absolute paths in code and scripts always stay WARN.
  [string[]]$AllowPathPrefix = @(),

  # Any binary/archive file bigger than this gets a necessity warning.
  [int]$MaxBinaryKB = 512,

  # Skip files bigger than this when scanning text (keeps the run fast).
  [int]$MaxTextKB = 4096,

  # Escape non-ASCII as \uXXXX. Use on consoles that mangle UTF-8 paths.
  [switch]$EscapeNonAscii,

  # Print counts + verdict only.
  [switch]$SummaryOnly,

  # Print every INFO hit instead of collapsing INFO per file.
  [switch]$VerboseInfo,

  # Defaults to the repository that contains this script.
  [string]$RepoRoot = ''
)

$ErrorActionPreference = 'Stop'

if ($All) { $IncludeStaged = $true; $IncludeUntracked = $true }

# ---------------------------------------------------------------------------
# Repo discovery
# ---------------------------------------------------------------------------

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = Join-Path (Split-Path -Parent $PSScriptRoot) '.'
}
try {
  $root = (& git -C $RepoRoot rev-parse --show-toplevel 2>$null | Select-Object -First 1)
} catch {
  $root = $null
}
if ([string]::IsNullOrWhiteSpace($root)) {
  Write-Output 'FATAL: not a git repository (or git is not on PATH).'
  exit 2
}
$root = $root.Trim()

# Documented toolchain roots for THIS project. These are not secrets: the same
# paths are already published on purpose in docs/DEVELOPMENT.md as the project's
# portable-toolchain convention. They exist here only so a documented path in a
# .md file is reported as INFO instead of WARN. Override or extend with
# -AllowPathPrefix. Absolute paths in code/scripts are never downgraded.
$defaultConventions = @(
  'D:\devtools',
  'D:\Android\Sdk',
  'D:\BeanClick'
)
$conventions = @($defaultConventions + $AllowPathPrefix)

# Inline escape hatch: any source line containing this token is skipped by the
# content rules. Use it only for documentation that must SHOW a raw pattern,
# never to hide a real value. Example (inside the checklist doc):
#   C:\Users\<local-user>\...   upload-safety:ignore
$suppressToken = 'upload-safety:ignore'

# This scanner's own path: it necessarily contains the patterns it looks for.
$selfRel = ''
try {
  $selfFull = (Resolve-Path -LiteralPath $PSCommandPath).Path -replace '\\', '/'
  $rootSlash = $root -replace '\\', '/'
  if ($selfFull -like ($rootSlash + '/*')) {
    $selfRel = $selfFull.Substring($rootSlash.Length).TrimStart('/')
  }
} catch {
  $selfRel = ''
}
$selfRel = $selfRel -replace '\\', '/'

# ---------------------------------------------------------------------------
# Rule tables
# ---------------------------------------------------------------------------

# Rules are matched per line of text. 'Exclude' is applied to capture group 1
# when present, and skips the hit when it matches (indirection, not a literal).
$contentRules = @(
  # ---- BLOCK: real credentials -------------------------------------------
  @{ Sev = 'BLOCK'; Id = 'secret.private-key';
     Re = '-----BEGIN [A-Z ]*PRIVATE KEY-----' }

  @{ Sev = 'BLOCK'; Id = 'secret.keystore-password';
     Re = '(?i)\b(?:storePassword|keyPassword)\s*[=:]\s*(\S+)';
     Ex = '^(\$\{|<%?|\.{3}|keystoreProperties|getProperty|os\.getenv|System\.getenv|%[A-Za-z_]+%|["'']\s*$)' }

  @{ Sev = 'BLOCK'; Id = 'secret.hardcoded-password';
     Re = '(?i)\b(?:password|passwd|secret|api[_-]?key|access[_-]?token|auth[_-]?token)\s*[=:]\s*["'']([^"'']{8,})["'']';
     Ex = '(?i)^(\$\{|<%?|\.{3}|example|placeholder|dummy|redacted|changeme|your[_-]?|xxx)' }

  @{ Sev = 'BLOCK'; Id = 'secret.github-token';
     Re = '\b(?:ghp_[A-Za-z0-9]{20,}|gho_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})\b' }

  @{ Sev = 'BLOCK'; Id = 'secret.cloud-key';
     Re = '\b(?:AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,})\b' }

  @{ Sev = 'BLOCK'; Id = 'secret.personal-profile-path';
     Re = '(?i)(?:[A-Za-z]:[\\/]+Users[\\/]+(?![<%\$\{])([A-Za-z0-9._-]+)|/(?:home|Users)/(?![<%\$\{])([A-Za-z0-9._-]+))' }

  # ---- WARN: machine layout, device identity, personal data --------------
  @{ Sev = 'WARN'; Id = 'machine.absolute-path';
     Re = '(?<![A-Za-z0-9+.\-])[A-Za-z]:[\\/]' }

  @{ Sev = 'WARN'; Id = 'machine.powershell-home';
     Re = '(?i)\$(?:PSHOME|env:USERPROFILE|env:HOME|HOME)\b|%USERPROFILE%' }

  @{ Sev = 'WARN'; Id = 'device.model-code';
     Re = '\b(?:M20[0-9]{2}[A-Z0-9]{2,}|2[0-9]{6}[A-Z]{2,}[A-Z0-9]*|SM-[A-Z0-9]{5,}|V2[0-9]{3}[A-Z]?)\b' }

  @{ Sev = 'WARN'; Id = 'device.adb-serial';
     Re = '(?m)\b[0-9A-Za-z]{8,}\s+(?:device|unauthorized|offline)\s*$' }

  @{ Sev = 'WARN'; Id = 'network.private-ip';
     Re = '\b(?:10\.\d{1,3}\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3}|172\.(?:1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3})\b' }

  @{ Sev = 'WARN'; Id = 'network.localhost-port';
     Re = '(?i)\b(?:127\.0\.0\.1|localhost|0\.0\.0\.0):\d{2,5}\b' }

  @{ Sev = 'WARN'; Id = 'identity.email';
     Re = '\b[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}\b';
     Ex = '(?i)@(?:example\.(?:com|org|net)|users\.noreply\.github\.com|github\.com|anthropic\.com|dart\.dev|flutter\.dev)$' }

  @{ Sev = 'WARN'; Id = 'identity.cn-phone';
     Re = '(?<!\d)1[3-9]\d{9}(?!\d)' }
)

# Path-level rules: matched against the repo-relative path.
$pathRules = @(
  # ---- BLOCK: credential material must never be tracked -------------------
  @{ Sev = 'BLOCK'; Id = 'path.credential-file';
     Re = '(?i)(?:^|/)(?:key\.properties|keystore\.properties|\.env(?:\.[A-Za-z0-9_]+)?|id_rsa|id_dsa|id_ecdsa|id_ed25519)$' }
  @{ Sev = 'BLOCK'; Id = 'path.keystore-extension';
     Re = '(?i)\.(?:jks|keystore|p12|pfx|pepk|pk8|bks|pem|key|p8)$' }

  # ---- BLOCK: generated trees that .gitignore already excludes -----------
  @{ Sev = 'BLOCK'; Id = 'path.generated-tree';
     Re = '(?i)^(?:build|dist|coverage|\.dart_tool|\.gradle|\.pub-cache)/' }

  # ---- WARN: generated artifacts and heavy binaries ----------------------
  @{ Sev = 'WARN'; Id = 'path.preview-output';
     Re = '(?i)(?:^|/)out/' }
  @{ Sev = 'WARN'; Id = 'path.android-artifact';
     Re = '(?i)\.(?:apk|aab|ap_|jar|so|dll|dylib|class|dex|zip|7z|tar|gz)$' }
  @{ Sev = 'WARN'; Id = 'path.database';
     Re = '(?i)\.(?:db|sqlite|sqlite3|realm)(?:-(?:wal|shm))?$' }
  @{ Sev = 'WARN'; Id = 'path.log-or-dump';
     Re = '(?i)\.(?:log|trace|dmp|hprof|bak|tmp|orig|rej)$' }

  # ---- INFO: legitimately tracked generated / baseline files -------------
  @{ Sev = 'INFO'; Id = 'path.golden-baseline';
     Re = '(?i)(?:^|/)goldens?/' }
  @{ Sev = 'INFO'; Id = 'path.generated-source';
     Re = '(?i)\.g\.dart$' }
)

# Extensions we never read as text.
$binaryExt = @(
  '.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp', '.ico',
  '.ttf', '.otf', '.woff', '.woff2',
  '.jar', '.apk', '.aab', '.so', '.dll', '.dylib', '.class', '.dex',
  '.zip', '.7z', '.tar', '.gz', '.pdf',
  '.p12', '.pfx', '.jks', '.keystore', '.pem', '.key',
  '.db', '.sqlite', '.sqlite3'
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

$script:escapeNonAscii = [bool]$EscapeNonAscii

function Format-Text([string]$text) {
  if ([string]::IsNullOrEmpty($text)) { return '' }
  if (-not $script:escapeNonAscii) { return $text }
  $out = ''
  foreach ($ch in $text.ToCharArray()) {
    $code = [int]$ch
    if ($code -lt 32 -or $code -gt 126) {
      $out = $out + ('\u{0:X4}' -f $code)
    } else {
      $out = $out + $ch
    }
  }
  return $out
}

$findings = New-Object System.Collections.ArrayList

function Add-Finding([string]$sev, [string]$id, [string]$file, [string]$line, [string]$text) {
  $sortLine = 0
  if ($line -match '^\d+$') { $sortLine = [int]$line }
  [void]$findings.Add([pscustomobject]@{
    Severity = $sev
    Id       = $id
    File     = $file
    Line     = $line
    SortLine = $sortLine
    Text     = $text
  })
}

function Get-RepoFiles([string[]]$args1) {
  $raw = & git -C $root -c core.quotepath=false @args1 2>$null
  if ($null -eq $raw) { return @() }
  # git -z separates entries with NUL and adds no newline; PowerShell still
  # appends one via Out-String, so trim CR/LF from every entry.
  $joined = ($raw | Out-String)
  $parts = $joined -split "`0"
  $clean = @()
  foreach ($p in $parts) {
    $t = $p.Trim([char]13, [char]10)
    if ($t -ne '') { $clean += $t }
  }
  return $clean
}

# ---------------------------------------------------------------------------
# Collect the file set
# ---------------------------------------------------------------------------

$targets = New-Object System.Collections.Generic.List[string]
foreach ($f in (Get-RepoFiles @('ls-files', '-z'))) { [void]$targets.Add($f) }
if ($IncludeStaged) {
  foreach ($f in (Get-RepoFiles @('diff', '--cached', '--name-only', '--diff-filter=ACMR', '-z'))) { [void]$targets.Add($f) }
}
if ($IncludeUntracked) {
  foreach ($f in (Get-RepoFiles @('ls-files', '--others', '--exclude-standard', '-z'))) { [void]$targets.Add($f) }
}
$fileList = @($targets | Sort-Object -Unique)

Write-Output '================================================================'
Write-Output ' BeanClick upload safety scan'
Write-Output (' repo   : ' + (Format-Text $root))
Write-Output (' scope  : tracked' + $(if ($IncludeStaged) { ' + staged' } else { '' }) + $(if ($IncludeUntracked) { ' + untracked' } else { '' }))
Write-Output (' files  : ' + $fileList.Count)
Write-Output '================================================================'
Write-Output ''

if ($fileList.Count -eq 0) {
  Write-Output 'Nothing to scan.'
  exit 0
}

foreach ($rel in $fileList) {
  $relNorm = $rel -replace '\\', '/'
  if ($selfRel -ne '' -and $relNorm -eq $selfRel) {
    Write-Output ('  (skipped: this scanner itself -> ' + (Format-Text $rel) + ')')
    continue
  }

  $full = Join-Path $root $rel
  $ext = [System.IO.Path]::GetExtension($rel).ToLowerInvariant()

  # --- path rules -------------------------------------------------------
  foreach ($rule in $pathRules) {
    if ($rel -match $rule.Re) {
      Add-Finding $rule.Sev $rule.Id $rel 'path' $rel
    }
  }

  if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }

  # --- size / necessity -------------------------------------------------
  $sizeKB = [int]((Get-Item -LiteralPath $full).Length / 1KB)
  if ($binaryExt -contains $ext -and $sizeKB -gt $MaxBinaryKB) {
    Add-Finding 'WARN' 'size.large-binary' $rel 'size' ('{0} KB' -f $sizeKB)
  }

  # --- content rules ----------------------------------------------------
  if ($binaryExt -contains $ext) { continue }
  if ($sizeKB -gt $MaxTextKB) {
    Add-Finding 'INFO' 'scan.skipped-too-large' $rel 'size' ('{0} KB (not scanned as text)' -f $sizeKB)
    continue
  }

  $lines = $null
  try {
    $lines = @(Get-Content -LiteralPath $full -Encoding UTF8 -ErrorAction Stop)
  } catch {
    continue
  }

  $isDoc = ($ext -eq '.md')
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line.Length -gt 4000) { $line = $line.Substring(0, 4000) }
    if ($line.Contains($suppressToken)) { continue }

    foreach ($rule in $contentRules) {
      $m = [regex]::Match($line, $rule.Re)
      if (-not $m.Success) { continue }

      if ($rule.ContainsKey('Ex') -and $m.Groups.Count -gt 1 -and $m.Groups[1].Success) {
        if ($m.Groups[1].Value -match $rule.Ex) { continue }
        # A captured "secret" with no letter or digit is punctuation left over
        # from prose (e.g. "storePassword=`" in a doc), never a credential.
        if ($rule.Sev -eq 'BLOCK' -and $m.Groups[1].Value -notmatch '[A-Za-z0-9]') { continue }
      }

      $sev = $rule.Sev

      # Absolute paths that are a documented project convention: only inside
      # markdown docs, and only when the line hits an allowed prefix.
      if ($rule.Id -eq 'machine.absolute-path' -and $isDoc) {
        $isConvention = $false
        foreach ($prefix in $conventions) {
          if ($line -match [regex]::Escape($prefix)) { $isConvention = $true; break }
        }
        if ($isConvention) { $sev = 'INFO' }
      }
      if ($rule.Id -eq 'convention.documented-path' -and -not $isDoc) { continue }

      Add-Finding $sev $rule.Id $rel ($i + 1) ($line.Trim())
      if ($sev -eq 'BLOCK') { break }
    }
  }
}

# ---------------------------------------------------------------------------
# Ignore-guard: sensitive files that exist locally must be ignored
# ---------------------------------------------------------------------------

$probes = @(
  'android/key.properties',
  'android/keystore/',
  '.env',
  'build/',
  'dist/',
  'sqlite3.dll'
)
foreach ($probe in $probes) {
  $probeFull = Join-Path $root $probe
  if (-not (Test-Path -LiteralPath $probeFull)) { continue }
  & git -C $root check-ignore -q -- $probe 2>$null
  if ($LASTEXITCODE -ne 0) {
    Add-Finding 'BLOCK' 'guard.not-ignored' $probe 'gitignore' 'exists on disk but is NOT ignored by git'
  }
}

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

$order = @('BLOCK', 'WARN', 'INFO')
$counts = @{ BLOCK = 0; WARN = 0; INFO = 0 }

foreach ($sev in $order) {
  $group = @($findings | Where-Object { $_.Severity -eq $sev })
  $counts[$sev] = $group.Count
  if ($SummaryOnly) { continue }

  Write-Output ('---- ' + $sev + ' (' + $group.Count + ') ----')
  if ($group.Count -eq 0) {
    Write-Output '  (none)'
    Write-Output ''
    continue
  }

  $sorted = @($group | Sort-Object File, SortLine)

  # INFO is context, not a to-do list: collapse it per file so the BLOCK/WARN
  # signal stays readable. -VerboseInfo prints every single hit.
  if ($sev -eq 'INFO' -and -not $VerboseInfo) {
    foreach ($fileGroup in ($sorted | Group-Object File)) {
      $items = @($fileGroup.Group)
      $shown = 0
      foreach ($f in $items) {
        if ($shown -ge 3) { break }
        Write-Output ('  ' + (Format-Text $f.File) + ':' + $f.Line + ': [' + $f.Id + '] ' + (Format-Text $f.Text))
        $shown++
      }
      if ($items.Count -gt $shown) {
        Write-Output ('  ' + (Format-Text $fileGroup.Name) + ': ... +' + ($items.Count - $shown) + ' more INFO hits')
      }
    }
    Write-Output ''
    continue
  }

  foreach ($f in $sorted) {
    Write-Output ('  ' + (Format-Text $f.File) + ':' + $f.Line + ': [' + $f.Id + '] ' + (Format-Text $f.Text))
  }
  Write-Output ''
}

Write-Output '================================================================'
Write-Output (' BLOCK=' + $counts['BLOCK'] + '  WARN=' + $counts['WARN'] + '  INFO=' + $counts['INFO'])
if ($counts['BLOCK'] -gt 0) {
  Write-Output ' VERDICT: BLOCKED -- do not push until every BLOCK item is resolved.'
  Write-Output '================================================================'
  exit 1
}
if ($counts['WARN'] -gt 0) {
  Write-Output ' VERDICT: CONDITIONAL -- no credential leak, but review every WARN item.'
  Write-Output '================================================================'
  exit 0
}
Write-Output ' VERDICT: PASS'
Write-Output '================================================================'
exit 0
