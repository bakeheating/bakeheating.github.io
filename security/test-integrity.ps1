param(
  [string]$ProjectRoot,
  [string]$BaselinePath
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

if ([string]::IsNullOrWhiteSpace($BaselinePath)) {
  $BaselinePath = Join-Path $PSScriptRoot "integrity-baseline.json"
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

if (-not (Test-Path $BaselinePath)) {
  throw "Baseline file not found: $BaselinePath. Run generate-integrity-baseline.ps1 first."
}

$baselineData = Get-Content -Path $BaselinePath -Raw | ConvertFrom-Json
$expectedMap = @{}
foreach ($entry in $baselineData.files) {
  $expectedMap[$entry.path] = $entry.sha256
}

$currentFiles = @()
$rootIndex = Join-Path $ProjectRoot "index.html"
$rootStyles = Join-Path $ProjectRoot "styles.css"
$imagesDir = Join-Path $ProjectRoot "assets\images"

if (Test-Path $rootIndex) { $currentFiles += Get-Item $rootIndex }
if (Test-Path $rootStyles) { $currentFiles += Get-Item $rootStyles }
if (Test-Path $imagesDir) {
  $currentFiles += Get-ChildItem -Path $imagesDir -File -Recurse
}

$currentMap = @{}
foreach ($file in ($currentFiles | Sort-Object FullName -Unique)) {
  $relPath = Get-RelativePathUnix -Base $ProjectRoot -Target $file.FullName
  $currentMap[$relPath] = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
}

$failures = @()

foreach ($path in $expectedMap.Keys) {
  if (-not $currentMap.ContainsKey($path)) {
    $failures += "MISSING: $path"
    continue
  }

  if ($currentMap[$path] -ne $expectedMap[$path]) {
    $failures += "MODIFIED: $path"
  }
}

foreach ($path in $currentMap.Keys) {
  if (-not $expectedMap.ContainsKey($path)) {
    $failures += "UNEXPECTED FILE: $path"
  }
}

if ($failures.Count -gt 0) {
  Write-Host "Integrity test FAILED" -ForegroundColor Red
  $failures | Sort-Object | ForEach-Object { Write-Host " - $_" }
  exit 1
}

Write-Host "Integrity test PASSED. No text/image tampering detected against baseline." -ForegroundColor Green
exit 0
