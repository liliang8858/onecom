param(
    [string]$Root = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"
$projectRoot = Resolve-Path $Root
$healthRoot = Join-Path $projectRoot "apps\health-agent"

Write-Host "Validating Health Agent from $healthRoot"

$iosJson = Join-Path $healthRoot "ci\ios.json"
Get-Content -Raw -Encoding UTF8 $iosJson | ConvertFrom-Json | Out-Null
Write-Host "OK ios.json"

$assetJsonFiles = Get-ChildItem -Recurse -Path (Join-Path $healthRoot "ios\HealthAgent\Resources") -Filter "*.json"
foreach ($file in $assetJsonFiles) {
    Get-Content -Raw -Encoding UTF8 $file.FullName | ConvertFrom-Json | Out-Null
}
Write-Host "OK asset catalog json"

[xml](Get-Content -Raw -Encoding UTF8 (Join-Path $healthRoot "ios\HealthAgent\Resources\Info.plist")) | Out-Null
[xml](Get-Content -Raw -Encoding UTF8 (Join-Path $healthRoot "ios\HealthAgent\Resources\HealthAgent.entitlements")) | Out-Null
Write-Host "OK plist and entitlements"

python (Join-Path $projectRoot "ci\discover_ios_projects.py") | Out-Null
Write-Host "OK project discovery"

$forbidden = "NavigationStack|import Charts|TODO|fatalError|诊断房颤|排除心脏病|治疗建议"
$matches = Select-String -Path (Join-Path $healthRoot "ios\HealthAgent\**\*.swift") -Pattern $forbidden -CaseSensitive
if ($matches) {
    $matches | ForEach-Object { Write-Host $_.Line }
    throw "Forbidden Swift pattern found"
}
Write-Host "OK Swift static scan"

$swiftCount = (Get-ChildItem -Recurse -Path (Join-Path $healthRoot "ios\HealthAgent") -Filter "*.swift").Count
$mockupCount = (Get-ChildItem -Path (Join-Path $healthRoot "product\ui\mockups") -File -Filter "*.png").Count
$mockup8kCount = (Get-ChildItem -Path (Join-Path $healthRoot "product\ui\mockups\8k") -File -Filter "*.png").Count

Write-Host "Swift files: $swiftCount"
Write-Host "Mockups: $mockupCount"
Write-Host "High-res mockups: $mockup8kCount"

if ($swiftCount -lt 30) { throw "Expected at least 30 Swift files" }
if ($mockupCount -lt 7) { throw "Expected at least 7 mockups" }
if ($mockup8kCount -lt 7) { throw "Expected at least 7 high-res mockups" }

Write-Host "Health Agent validation complete"
