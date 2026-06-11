param(
  [Parameter(Mandatory = $true)]
  [string]$Url
)

$ErrorActionPreference = "Stop"

$response = Invoke-WebRequest -Uri $Url -Method GET
$headers = $response.Headers

$checks = @(
  [PSCustomObject]@{ Name = "Content-Security-Policy"; Required = $true; Validator = { param($v) -not [string]::IsNullOrWhiteSpace($v) } },
  [PSCustomObject]@{ Name = "X-Content-Type-Options"; Required = $true; Validator = { param($v) $v -match "(?i)^nosniff$" } },
  [PSCustomObject]@{ Name = "X-Frame-Options"; Required = $true; Validator = { param($v) $v -match "(?i)^(deny|sameorigin)$" } },
  [PSCustomObject]@{ Name = "Referrer-Policy"; Required = $true; Validator = { param($v) -not [string]::IsNullOrWhiteSpace($v) } },
  [PSCustomObject]@{ Name = "Permissions-Policy"; Required = $true; Validator = { param($v) -not [string]::IsNullOrWhiteSpace($v) } }
)

if ($Url -match "^https://") {
  $checks += [PSCustomObject]@{ Name = "Strict-Transport-Security"; Required = $true; Validator = { param($v) -not [string]::IsNullOrWhiteSpace($v) } }
}

$failed = @()

foreach ($check in $checks) {
  $value = $headers[$check.Name]
  if ([string]::IsNullOrWhiteSpace($value)) {
    if ($check.Required) {
      $failed += "MISSING: $($check.Name)"
    }
    continue
  }

  if (-not (& $check.Validator $value)) {
    $failed += "WEAK VALUE: $($check.Name) = $value"
  }
}

if ($failed.Count -gt 0) {
  Write-Host "Security header test FAILED for $Url" -ForegroundColor Red
  $failed | ForEach-Object { Write-Host " - $_" }
  exit 1
}

Write-Host "Security header test PASSED for $Url" -ForegroundColor Green
exit 0
