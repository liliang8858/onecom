param(
    [string]$Root = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path,
    [string]$ChromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
)

$ErrorActionPreference = "Stop"

if (!(Test-Path $ChromePath)) {
    throw "Chrome not found: $ChromePath"
}

Add-Type -AssemblyName System.Drawing

$sourceRoot = Join-Path $Root "apps\health-agent\product\uiv2"
$h5Root = Join-Path $Root "apps\health-agent\h5\uiv2"
$screenshotRoot = Join-Path $h5Root "screenshots"
New-Item -ItemType Directory -Force $screenshotRoot | Out-Null

$pages = @(
    @{ id = "ui001"; width = 1448; height = 1086 },
    @{ id = "ui002"; width = 1448; height = 1086 },
    @{ id = "ui003"; width = 1536; height = 1024 },
    @{ id = "ui004"; width = 1536; height = 1024 }
)

function Save-Crop {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [int]$Width,
        [int]$Height
    )

    $source = [System.Drawing.Bitmap]::FromFile($SourcePath)
    $crop = New-Object System.Drawing.Bitmap($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($crop)
    $graphics.DrawImage(
        $source,
        [System.Drawing.Rectangle]::new(0, 0, $Width, $Height),
        [System.Drawing.Rectangle]::new(0, 0, $Width, $Height),
        [System.Drawing.GraphicsUnit]::Pixel
    )
    $graphics.Dispose()
    $source.Dispose()
    $crop.Save($DestinationPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $crop.Dispose()
}

function Compare-Images {
    param(
        [string]$ExpectedPath,
        [string]$ActualPath
    )

    $expected = [System.Drawing.Bitmap]::FromFile($ExpectedPath)
    $actual = [System.Drawing.Bitmap]::FromFile($ActualPath)

    if ($expected.Width -ne $actual.Width -or $expected.Height -ne $actual.Height) {
        $expected.Dispose()
        $actual.Dispose()
        throw "Dimension mismatch between $ExpectedPath and $ActualPath"
    }

    $total = [int64]$expected.Width * [int64]$expected.Height
    $diff = [int64]0
    $channelDiff = [double]0

    for ($y = 0; $y -lt $expected.Height; $y++) {
        for ($x = 0; $x -lt $expected.Width; $x++) {
            $a = $expected.GetPixel($x, $y)
            $b = $actual.GetPixel($x, $y)
            if ($a.ToArgb() -ne $b.ToArgb()) {
                $diff++
            }
            $channelDiff += [Math]::Abs($a.R - $b.R) + [Math]::Abs($a.G - $b.G) + [Math]::Abs($a.B - $b.B)
        }
    }

    $exact = (1 - ($diff / $total)) * 100
    $mean = $channelDiff / ($total * 3)

    $expected.Dispose()
    $actual.Dispose()

    [pscustomobject]@{
        Page = Split-Path $ExpectedPath -Leaf
        ExactPixelRate = [Math]::Round($exact, 4)
        DifferentPixels = $diff
        MeanChannelDiff = [Math]::Round($mean, 4)
    }
}

$results = @()
foreach ($page in $pages) {
    $rawPath = Join-Path $screenshotRoot "$($page.id)-raw.png"
    $finalPath = Join-Path $screenshotRoot "$($page.id).png"
    $sourcePath = Join-Path $sourceRoot "$($page.id).png"
    $url = "file:///$($h5Root.Replace('\', '/'))/index.html#$($page.id)"

    & $ChromePath `
        --headless=new `
        --disable-gpu `
        --hide-scrollbars `
        --force-device-scale-factor=1 `
        --window-size=$($page.width + 26),$($page.height + 120) `
        --virtual-time-budget=1000 `
        --screenshot=$rawPath `
        $url | Out-Null

    Save-Crop -SourcePath $rawPath -DestinationPath $finalPath -Width $page.width -Height $page.height
    Remove-Item -LiteralPath $rawPath -Force
    $results += Compare-Images -ExpectedPath $sourcePath -ActualPath $finalPath
}

$results | Format-Table -AutoSize

$failed = $results | Where-Object { $_.ExactPixelRate -lt 99 }
if ($failed) {
    throw "UI v2 pixel verification failed"
}

Write-Host "UI v2 pixel verification passed"
