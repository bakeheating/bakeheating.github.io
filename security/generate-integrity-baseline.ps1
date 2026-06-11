param(
  [string]$ProjectRoot,
  [string]$OutputPath
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
  $OutputPath = Join-Path $PSScriptRoot "integrity-baseline.json"
}

function Get-RelativePathUnix {
  param(
    [string]$Base,
    [string]$Target
  )

  $basePath = (Resolve-Path $Base).Path.TrimEnd('\\')
  $targetPath = (Resolve-Path $Target).Path

  if (-not $targetPath.StartsWith($basePath + "\", [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Target path '$targetPath' is not under base path '$basePath'."
  }

  $relative = $targetPath.Substring($basePath.Length + 1)
  return $relative.Replace('\', '/')
}

$files = @()

$rootIndex = Join-Path $ProjectRoot "index.html"
$rootStyles = Join-Path $ProjectRoot "styles.css"
$imagesDir = Join-Path $ProjectRoot "assets\images"

if (Test-Path $rootIndex) { $files += Get-Item $rootIndex }
if (Test-Path $rootStyles) { $files += Get-Item $rootStyles }
if (Test-Path $imagesDir) {
  $files += Get-ChildItem -Path $imagesDir -File -Recurse
}

if ($files.Count -eq 0) {
  throw "No target files found. Expected index.html, styles.css, and assets/images/*"
}

$records = foreach ($file in ($files | Sort-Object FullName -Unique)) {
  [PSCustomObject]@{
    path = Get-RelativePathUnix -Base $ProjectRoot -Target $file.FullName
    sha256 = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
  }
}

$baseline = [PSCustomObject]@{
  generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
  fileCount = $records.Count
  files = $records
}

$baseline | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Integrity baseline written to $OutputPath"
