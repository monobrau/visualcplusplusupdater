<#
.SYNOPSIS
    Comprehensive updater for all Visual C++ Redistributable versions (2005-2022).

.DESCRIPTION
    This comprehensive script scans for and updates ALL major Visual C++ redistributable versions:
    - Visual C++ 2005 SP1 (KB2538242) - If installed
    - Visual C++ 2008 SP1 (KB2538243) - If installed
    - Visual C++ 2010 SP1 (KB2565063) - If installed
    - Visual C++ 2012 Update 4 - If installed
    - Visual C++ 2013 - If installed
    - Visual C++ 2015-2022 (latest) - If installed
    
    The script runs completely silently with no user interaction required.
    It intelligently compares installed versions with target versions and skips updates
    for versions that are already up to date, saving time and bandwidth.

.NOTES
    File Name: Update-AllVisualCppRedistributable.ps1
    Run this script with administrative privileges.
    All URLs point to official Microsoft downloads.
    
    Version Checking:
    - EOL versions (2005, 2008, 2010, 2012, 2013): Compares against final known versions
    - Non-EOL versions (2015-2022): Downloads latest and installs only if newer than installed version
    - Automatically detects if downloaded installer is newer than installed version
    - Skips installation if current version is already up to date
    - Avoids unnecessary downloads when versions are already current or recent enough
    
    Target Versions (EOL - Fixed):
    - 2005: 8.0.50727.6195 (KB2538242) - Final
    - 2008: 9.0.30729.5677 (KB2538243) - Final
    - 2010: 10.0.40219 (KB2565063) - Final
    - 2012: 11.0.61030.0 (Update 4) - Final
    - 2013: 12.0.40649.5 (Latest) - Final
    
    Automatically Detected Versions (Non-EOL):
    - 2015-2022: Downloads latest and installs if newer than current
#>

#Requires -RunAsAdministrator

# Enforce TLS 1.2 for downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Visual C++ All Versions Updater (2005-2022)" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Define all Visual C++ versions and their download URLs
$VCVersions = @{
    "2005" = @{
        DisplayName = "Microsoft Visual C\+\+ 2005.*Redistributable"
        KB = "KB2538242"
        TargetVersion = "8.0.50727.6195"
        IsEOL = $true
        URLs = @{}
        ConfirmationPage = "https://www.microsoft.com/download/confirmation.aspx?id=26347"
        DownloadPage = "https://www.microsoft.com/download/details.aspx?id=26347"
        DownloadFileNames = @{
            x86 = "vcredist_x86.exe"
            x64 = "vcredist_x64.exe"
        }
    }
    "2008" = @{
        DisplayName = "Microsoft Visual C\+\+ 2008.*Redistributable"
        KB = "KB2538243"
        TargetVersion = "9.0.30729.5677"
        IsEOL = $true
        URLs = @{
            x86 = "http://download.windowsupdate.com/msdownload/update/software/secu/2011/05/vcredist_x86_470640aa4bb7db8e69196b5edb0010933569e98d.exe"
            x64 = "http://download.windowsupdate.com/msdownload/update/software/secu/2011/05/vcredist_x64_a7c83077b8a28d409e36316d2d7321fa0ccdb7e8.exe"
        }
    }
    "2010" = @{
        DisplayName = "Microsoft Visual C\+\+ 2010.*Redistributable"
        KB = "KB2565063"
        TargetVersion = "10.0.40219"
        IsEOL = $true
        URLs = @{
            x86 = "https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe"
            x64 = "https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe"
        }
    }
    "2012" = @{
        DisplayName = "Microsoft Visual C\+\+ 2012.*Redistributable"
        KB = "Update 4"
        TargetVersion = "11.0.61030.0"
        IsEOL = $true
        URLs = @{
            x86 = "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe"
            x64 = "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe"
        }
    }
    "2013" = @{
        DisplayName = "Microsoft Visual C\+\+ 2013.*Redistributable"
        KB = "Latest"
        TargetVersion = "12.0.40649.5"
        IsEOL = $true
        URLs = @{
            x86 = "http://download.microsoft.com/download/c/c/2/cc2df5f8-4454-44b4-802d-5ea68d086676/vcredist_x86.exe"
            x64 = "http://download.microsoft.com/download/c/c/2/cc2df5f8-4454-44b4-802d-5ea68d086676/vcredist_x64.exe"
        }
    }
    "2015-2022" = @{
        DisplayName = "Microsoft Visual C\+\+ 201[5-9]|Microsoft Visual C\+\+ 202[0-9]"
        KB = "Latest"
        TargetVersion = $null
        IsEOL = $false
        URLs = @{
            x86 = "https://aka.ms/vs/17/release/vc_redist.x86.exe"
            x64 = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
            arm64 = "https://aka.ms/vs/17/release/vc_redist.arm64.exe"
        }
    }
}

# Function to detect installed Visual C++ version
function Test-VCInstalled {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DisplayNamePattern,
        [Parameter(Mandatory=$true)]
        [ValidateSet('x86', 'x64', 'arm64')]
        [string]$Architecture
    )
    
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    $allInstalled = @()
    
    foreach ($path in $registryPaths) {
        if (Test-Path $path) {
            $installed = Get-ItemProperty $path -ErrorAction SilentlyContinue | 
                Where-Object { 
                    $_.DisplayName -match $DisplayNamePattern -and 
                    $_.DisplayName -match $Architecture 
                }
            
            if ($installed) {
                $allInstalled += $installed
            }
        }
    }
    
    if ($allInstalled.Count -gt 0) {
        # If multiple versions are installed across all registry paths, get the one with the highest version number
        $sortedVersions = $allInstalled | Sort-Object { 
            try {
                $cleanVersion = $_.DisplayVersion -replace '[^\d\.].*$', ''
                [version]$cleanVersion
            } catch {
                [version]"0.0.0.0"
            }
        } -Descending
        
        $highestVersion = $sortedVersions | Select-Object -First 1
        
        return @{
            Installed = $true
            Details = $highestVersion
        }
    }
    
    return @{ Installed = $false }
}

# Function to check if a specific KB update is installed
function Test-KBInstalled {
    param(
        [Parameter(Mandatory=$true)]
        [string]$KBNumber
    )
    
    # Check Windows Update history
    try {
        $hotfix = Get-HotFix -Id $KBNumber -ErrorAction SilentlyContinue
        if ($hotfix) {
            return $true
        }
    }
    catch {
        # KB not found via Get-HotFix
    }
    
    # Check registry for the KB
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    foreach ($path in $registryPaths) {
        if (Test-Path $path) {
            $kbInstalled = Get-ItemProperty $path -ErrorAction SilentlyContinue | 
                Where-Object { 
                    $_.DisplayName -match $KBNumber
                }
            
            if ($kbInstalled) {
                return $true
            }
        }
    }
    
    return $false
}

# Function to compare version numbers
function Compare-Version {
    param(
        [string]$CurrentVersion,
        [string]$TargetVersion
    )
    
    if ([string]::IsNullOrEmpty($CurrentVersion) -or [string]::IsNullOrEmpty($TargetVersion)) {
        Write-Host "  DEBUG: Version comparison failed - empty version string" -ForegroundColor DarkGray
        return $false
    }
    
    try {
        # Clean versions - remove any non-numeric characters except dots
        $cleanCurrent = $CurrentVersion -replace '[^\d\.]', ''
        $cleanTarget = $TargetVersion -replace '[^\d\.]', ''
        
        # Normalize version parts (ensure both have same number of parts)
        $currentParts = $cleanCurrent.Split('.')
        $targetParts = $cleanTarget.Split('.')
        $maxParts = [Math]::Max($currentParts.Length, $targetParts.Length)
        
        # Pad with zeros to match part count
        while ($currentParts.Length -lt $maxParts) {
            $currentParts += "0"
        }
        while ($targetParts.Length -lt $maxParts) {
            $targetParts += "0"
        }
        
        $normalizedCurrent = $currentParts -join '.'
        $normalizedTarget = $targetParts -join '.'
        
        $current = [version]$normalizedCurrent
        $target = [version]$normalizedTarget
        
        $result = ($current -ge $target)
        Write-Host "  DEBUG: Comparing $normalizedCurrent >= $normalizedTarget = $result" -ForegroundColor DarkGray
        
        return $result
    }
    catch {
        Write-Host "  DEBUG: Version comparison exception: $_" -ForegroundColor DarkGray
        return $false
    }
}

# Function to get file version from an executable
function Get-InstallerVersion {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    try {
        if (Test-Path $FilePath) {
            $versionInfo = (Get-Item $FilePath).VersionInfo
            if ($versionInfo.FileVersion) {
                $cleanVersion = $versionInfo.FileVersion -replace '[^\d\.].*$', ''
                return $cleanVersion
            }
        }
    }
    catch {
        Write-Warning "Could not read installer version: $_"
    }
    
    return $null
}

# Function to resolve direct download URLs from a Microsoft confirmation page
function Resolve-DownloadUrl {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConfirmationPage,
        [Parameter(Mandatory=$true)]
        [string]$FileName
    )
    
    try {
        $headers = @{ 'User-Agent' = 'Mozilla/5.0' }
        $response = Invoke-WebRequest -Uri $ConfirmationPage -UseBasicParsing -Headers $headers -ErrorAction Stop
        $escapedFileName = [regex]::Escape($FileName)
        $pattern = "https://download\.microsoft\.com/[^`"']+$escapedFileName"
        $match = [regex]::Match($response.Content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        if ($match.Success) {
            return $match.Value
        }
    }
    catch {
        Write-Host "  DEBUG: Could not resolve download URL from confirmation page: $_" -ForegroundColor DarkGray
    }
    
    return $null
}

# Function to load cached metadata for latest 2015-2022 installers
function Get-RedistCachePath {
    $cacheDir = Join-Path $env:ProgramData "VisualCppUpdater"
    return Join-Path $cacheDir "vc_redist_cache.json"
}

function ConvertTo-Hashtable {
    param([object]$InputObject)
    
    if ($null -eq $InputObject) {
        return @{}
    }
    if ($InputObject -is [System.Collections.IDictionary]) {
        return $InputObject
    }
    
    $hash = @{}
    foreach ($property in $InputObject.PSObject.Properties) {
        $value = $property.Value
        if ($value -is [pscustomobject]) {
            $value = ConvertTo-Hashtable -InputObject $value
        }
        $hash[$property.Name] = $value
    }
    
    return $hash
}

function Load-RedistCache {
    $cachePath = Get-RedistCachePath
    if (Test-Path $cachePath) {
        try {
            $json = Get-Content -Path $cachePath -Raw -ErrorAction Stop
            if (-not [string]::IsNullOrWhiteSpace($json)) {
                $obj = $json | ConvertFrom-Json
                return ConvertTo-Hashtable -InputObject $obj
            }
        }
        catch {
            Write-Host "  DEBUG: Could not read cache: $_" -ForegroundColor DarkGray
        }
    }
    
    return @{}
}

function Save-RedistCache {
    param([hashtable]$Cache)
    
    $cachePath = Get-RedistCachePath
    try {
        $cacheDir = Split-Path $cachePath -Parent
        if (-not (Test-Path $cacheDir)) {
            New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
        }
        $Cache | ConvertTo-Json -Depth 5 | Set-Content -Path $cachePath -Encoding ASCII
    }
    catch {
        Write-Host "  DEBUG: Could not write cache: $_" -ForegroundColor DarkGray
    }
}

function Get-RemoteFileMetadata {
    param([Parameter(Mandatory=$true)][string]$Url)
    
    try {
        $headers = @{ 'User-Agent' = 'Mozilla/5.0' }
        $response = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -Headers $headers -ErrorAction Stop
        return @{
            ETag = $response.Headers.ETag
            LastModified = $response.Headers.'Last-Modified'
        }
    }
    catch {
        Write-Host "  DEBUG: Could not query remote metadata: $_" -ForegroundColor DarkGray
    }
    
    return $null
}

# Scan for installed versions
Write-Host "Scanning for installed Visual C++ redistributables..." -ForegroundColor Yellow
Write-Host ""

$installedVersions = @{}
$updateCount = 0

foreach ($version in $VCVersions.Keys | Sort-Object) {
    $vcInfo = $VCVersions[$version]
    
    Write-Host "Checking Visual C++ $version..." -ForegroundColor Gray
    
    $x86Installed = Test-VCInstalled -DisplayNamePattern $vcInfo.DisplayName -Architecture "x86"
    $x64Installed = Test-VCInstalled -DisplayNamePattern $vcInfo.DisplayName -Architecture "x64"
    $arm64Installed = Test-VCInstalled -DisplayNamePattern $vcInfo.DisplayName -Architecture "arm64"
    
    if ($x86Installed.Installed -or $x64Installed.Installed -or $arm64Installed.Installed) {
        $installedVersions[$version] = @{
            x86 = $x86Installed.Installed
            x64 = $x64Installed.Installed
            arm64 = $arm64Installed.Installed
            x86Details = $x86Installed.Details
            x64Details = $x64Installed.Details
            arm64Details = $arm64Installed.Details
        }
        
        if ($x86Installed.Installed) { $updateCount++ }
        if ($x64Installed.Installed) { $updateCount++ }
        if ($arm64Installed.Installed) { $updateCount++ }
    }
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Detection Results" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

if ($installedVersions.Count -eq 0) {
    Write-Host "No Visual C++ redistributables detected." -ForegroundColor Yellow
    Write-Host "Nothing to update." -ForegroundColor Yellow
    exit 0
}

# Display what was found
foreach ($version in $installedVersions.Keys | Sort-Object) {
    $vcInfo = $VCVersions[$version]
    $installed = $installedVersions[$version]
    
    Write-Host ""
    $statusBadge = if ($vcInfo.IsEOL) { "[EOL]" } else { "[Active]" }
    Write-Host "Visual C++ $version $statusBadge ($($vcInfo.KB)):" -ForegroundColor Green
    
    if ($installed.x86) {
        Write-Host "  [x86] INSTALLED" -ForegroundColor Green
        if ($installed.x86Details.DisplayVersion) {
            Write-Host "        Current Version: $($installed.x86Details.DisplayVersion)" -ForegroundColor Gray
            
            if ($vcInfo.IsEOL) {
                if ($vcInfo.TargetVersion -and (Compare-Version -CurrentVersion $installed.x86Details.DisplayVersion -TargetVersion $vcInfo.TargetVersion)) {
                    Write-Host "        Status: UP TO DATE (will skip)" -ForegroundColor Cyan
                }
                else {
                    Write-Host "        Target Version: $($vcInfo.TargetVersion)" -ForegroundColor Gray
                    Write-Host "        Status: UPDATE AVAILABLE" -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "        Status: Will check latest version dynamically" -ForegroundColor Yellow
            }
        }
    }
    
    if ($installed.x64) {
        Write-Host "  [x64] INSTALLED" -ForegroundColor Green
        if ($installed.x64Details.DisplayVersion) {
            Write-Host "        Current Version: $($installed.x64Details.DisplayVersion)" -ForegroundColor Gray
            
            if ($vcInfo.IsEOL) {
                if ($vcInfo.TargetVersion -and (Compare-Version -CurrentVersion $installed.x64Details.DisplayVersion -TargetVersion $vcInfo.TargetVersion)) {
                    Write-Host "        Status: UP TO DATE (will skip)" -ForegroundColor Cyan
                }
                else {
                    Write-Host "        Target Version: $($vcInfo.TargetVersion)" -ForegroundColor Gray
                    Write-Host "        Status: UPDATE AVAILABLE" -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "        Status: Will check latest version dynamically" -ForegroundColor Yellow
            }
        }
    }
    
    if ($installed.arm64) {
        Write-Host "  [arm64] INSTALLED" -ForegroundColor Green
        if ($installed.arm64Details.DisplayVersion) {
            Write-Host "        Current Version: $($installed.arm64Details.DisplayVersion)" -ForegroundColor Gray
            
            if ($vcInfo.IsEOL) {
                if ($vcInfo.TargetVersion -and (Compare-Version -CurrentVersion $installed.arm64Details.DisplayVersion -TargetVersion $vcInfo.TargetVersion)) {
                    Write-Host "        Status: UP TO DATE (will skip)" -ForegroundColor Cyan
                }
                else {
                    Write-Host "        Target Version: $($vcInfo.TargetVersion)" -ForegroundColor Gray
                    Write-Host "        Status: UPDATE AVAILABLE" -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "        Status: Will check latest version dynamically" -ForegroundColor Yellow
            }
        }
    }
}

Write-Host ""
Write-Host "Total updates to process: $updateCount" -ForegroundColor Cyan
Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Beginning updates..." -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Temporary directory for downloads
$TempDir = $env:TEMP
$RebootRequired = $false
$downloadedFiles = @()
$redistCache = Load-RedistCache

# Silent installation arguments by version
$SilentArgsMap = @{
    "2005" = "/Q"
    "2008" = "/quiet", "/norestart"
    "2010" = "/quiet", "/norestart"
    "2012" = "/install", "/quiet", "/norestart"
    "2013" = "/install", "/quiet", "/norestart"
    "2015-2022" = "/install", "/quiet", "/norestart"
}

try {
    $currentUpdate = 0
    
    foreach ($version in $installedVersions.Keys | Sort-Object) {
        $vcInfo = $VCVersions[$version]
        $installed = $installedVersions[$version]
        
        Write-Host "Processing Visual C++ $version..." -ForegroundColor Yellow
        Write-Host ""
        
        # Update x86 if installed
        if ($installed.x86) {
            $currentUpdate++
            
            $currentVersion = $installed.x86Details.DisplayVersion
            do {
            
            if ($vcInfo.IsEOL) {
                $targetVersion = $vcInfo.TargetVersion
                
                Write-Host "  DEBUG: Current x86 version: '$currentVersion'" -ForegroundColor DarkGray
                Write-Host "  DEBUG: Target version: '$targetVersion'" -ForegroundColor DarkGray
                
                # For versions with KB numbers, check if KB is already installed
                if ($vcInfo.KB -match "KB\d+") {
                    $kbNumber = $vcInfo.KB
                    $kbInstalled = Test-KBInstalled -KBNumber $kbNumber
                    Write-Host "  DEBUG: Checking for $kbNumber installed: $kbInstalled" -ForegroundColor DarkGray
                    
                    if ($kbInstalled) {
                        Write-Host "[$currentUpdate/$updateCount] x86 $kbNumber already installed - Skipping" -ForegroundColor Cyan
                        break
                    }
                }
                
                # Also check version number
                if ($targetVersion -and $currentVersion) {
                    $isUpToDate = Compare-Version -CurrentVersion $currentVersion -TargetVersion $targetVersion
                    Write-Host "  DEBUG: Up to date check result: $isUpToDate" -ForegroundColor DarkGray
                    
                    if ($isUpToDate) {
                        Write-Host "[$currentUpdate/$updateCount] x86 version already up to date ($currentVersion) - Skipping" -ForegroundColor Cyan
                        break
                    }
                }
            }
            
            Write-Host "[$currentUpdate/$updateCount] Processing x86 version..." -ForegroundColor Cyan
            
            $url = $vcInfo.URLs.x86
            
            if ($vcInfo.ConfirmationPage -and $vcInfo.DownloadFileNames.x86) {
                $resolvedUrl = Resolve-DownloadUrl -ConfirmationPage $vcInfo.ConfirmationPage -FileName $vcInfo.DownloadFileNames.x86
                if ($resolvedUrl) {
                    $url = $resolvedUrl
                }
            }
            
            if (-not $vcInfo.IsEOL -and $url) {
                $remoteMeta = Get-RemoteFileMetadata -Url $url
                $cacheEntry = $null
                
                if ($redistCache.ContainsKey($version) -and ($redistCache[$version] -is [hashtable]) -and $redistCache[$version].ContainsKey("x86")) {
                    $cacheEntry = $redistCache[$version]["x86"]
                }
                
                if ($remoteMeta -and $cacheEntry) {
                    $updated = $false
                    if (-not $cacheEntry.ETag -and $remoteMeta.ETag) {
                        $cacheEntry.ETag = $remoteMeta.ETag
                        $updated = $true
                    }
                    if (-not $cacheEntry.LastModified -and $remoteMeta.LastModified) {
                        $cacheEntry.LastModified = $remoteMeta.LastModified
                        $updated = $true
                    }
                    if ($updated) {
                        $redistCache[$version]["x86"] = $cacheEntry
                        Save-RedistCache -Cache $redistCache
                    }
                }
                
                $metaMatches = $false
                if ($remoteMeta -and $cacheEntry) {
                    if ($remoteMeta.ETag -and $cacheEntry.ETag -and ($cacheEntry.ETag -eq $remoteMeta.ETag)) {
                        $metaMatches = $true
                    }
                    elseif ($remoteMeta.LastModified -and $cacheEntry.LastModified -and ($cacheEntry.LastModified -eq $remoteMeta.LastModified)) {
                        $metaMatches = $true
                    }
                }
                
                if ($metaMatches -and $cacheEntry.InstallerVersion -and $currentVersion -and
                    (Compare-Version -CurrentVersion $currentVersion -TargetVersion $cacheEntry.InstallerVersion)) {
                    Write-Host "[$currentUpdate/$updateCount] x86 latest installer unchanged and current version ($currentVersion) >= cached ($($cacheEntry.InstallerVersion)) - Skipping download" -ForegroundColor Cyan
                    break
                }
            }
            
            if (-not $url) {
                Write-Host "  NOTE: Visual C++ $version requires manual download" -ForegroundColor Yellow
                if ($vcInfo.DownloadPage) {
                    Write-Host "  Please visit: $($vcInfo.DownloadPage)" -ForegroundColor Yellow
                }
                Write-Host "  Skipping automated update for this version." -ForegroundColor Yellow
            }
            else {
                $installerPath = Join-Path $TempDir "vcredist_${version}_x86.exe"
                $downloadedFiles += $installerPath
                
                try {
                    Write-Host "  Downloading..."
                    $downloadResponse = Invoke-WebRequest -Uri $url -OutFile $installerPath -UseBasicParsing -ErrorAction Stop
                    Write-Host "  Download complete." -ForegroundColor Green
                    
                    if (Test-Path $installerPath) {
                        # Check installer version for both EOL and non-EOL versions
                        $installerVersion = Get-InstallerVersion -FilePath $installerPath
                        $etag = $null
                        $lastModified = $null
                        if ($remoteMeta) {
                            $etag = $remoteMeta.ETag
                            $lastModified = $remoteMeta.LastModified
                        }
                        elseif ($downloadResponse -and $downloadResponse.Headers) {
                            $etag = $downloadResponse.Headers.ETag
                            $lastModified = $downloadResponse.Headers.'Last-Modified'
                        }
                        
                        if (-not $vcInfo.IsEOL) {
                            if (-not $redistCache.ContainsKey($version)) {
                                $redistCache[$version] = @{}
                            }
                            $redistCache[$version]["x86"] = @{
                                ETag = $etag
                                LastModified = $lastModified
                                InstallerVersion = $installerVersion
                            }
                            Save-RedistCache -Cache $redistCache
                        }
                        
                        if ($installerVersion) {
                            Write-Host "  Downloaded installer version: $installerVersion" -ForegroundColor Gray
                            
                            if ($currentVersion -and (Compare-Version -CurrentVersion $currentVersion -TargetVersion $installerVersion)) {
                                Write-Host "  Current version ($currentVersion) is already same or newer than installer ($installerVersion) - Skipping installation" -ForegroundColor Cyan
                                break
                            }
                        }
                        
                        Write-Host "  Installing..."
                        $silentArgs = $SilentArgsMap[$version]
                        $Process = Start-Process -FilePath $installerPath -ArgumentList $silentArgs -Wait -PassThru -WindowStyle Hidden
                        
                        switch ($Process.ExitCode) {
                            0 { 
                                Write-Host "  Installation successful." -ForegroundColor Green
                                
                                # Verify what changed
                                if ($vcInfo.IsEOL) {
                                    Start-Sleep -Seconds 2
                                    $newCheck = Test-VCInstalled -DisplayNamePattern $vcInfo.DisplayName -Architecture "x86"
                                    if ($newCheck.Installed -and $newCheck.Details.DisplayVersion) {
                                        Write-Host "  Registry version after install: $($newCheck.Details.DisplayVersion)" -ForegroundColor Cyan
                                    }
                                    
                                    # Check if KB is now detected
                                    if ($vcInfo.KB -match "KB\d+") {
                                        $kbCheck = Test-KBInstalled -KBNumber $vcInfo.KB
                                        Write-Host "  $($vcInfo.KB) detected: $kbCheck" -ForegroundColor Cyan
                                    }
                                }
                            }
                            3010 { 
                                Write-Host "  Installation successful. Reboot required." -ForegroundColor Yellow
                                $RebootRequired = $true
                            }
                            default { 
                                Write-Warning "  Exit code: $($Process.ExitCode) (may indicate already updated or minor issue)"
                            }
                        }
                    }
                }
                catch {
                    Write-Warning "  Failed: $_"
                }
            }
            } while ($false)
            Write-Host ""
        }
        
        # Update x64 if installed
        if ($installed.x64) {
            $currentUpdate++
            
            $currentVersion = $installed.x64Details.DisplayVersion
            do {
            
            if ($vcInfo.IsEOL) {
                $targetVersion = $vcInfo.TargetVersion
                
                Write-Host "  DEBUG: Current x64 version: '$currentVersion'" -ForegroundColor DarkGray
                Write-Host "  DEBUG: Target version: '$targetVersion'" -ForegroundColor DarkGray
                
                # For versions with KB numbers, check if KB is already installed
                if ($vcInfo.KB -match "KB\d+") {
                    $kbNumber = $vcInfo.KB
                    $kbInstalled = Test-KBInstalled -KBNumber $kbNumber
                    Write-Host "  DEBUG: Checking for $kbNumber installed: $kbInstalled" -ForegroundColor DarkGray
                    
                    if ($kbInstalled) {
                        Write-Host "[$currentUpdate/$updateCount] x64 $kbNumber already installed - Skipping" -ForegroundColor Cyan
                        break
                    }
                }
                
                # Also check version number
                if ($targetVersion -and $currentVersion) {
                    $isUpToDate = Compare-Version -CurrentVersion $currentVersion -TargetVersion $targetVersion
                    Write-Host "  DEBUG: Up to date check result: $isUpToDate" -ForegroundColor DarkGray
                    
                    if ($isUpToDate) {
                        Write-Host "[$currentUpdate/$updateCount] x64 version already up to date ($currentVersion) - Skipping" -ForegroundColor Cyan
                        break
                    }
                }
            }
            
            Write-Host "[$currentUpdate/$updateCount] Processing x64 version..." -ForegroundColor Cyan
            
            $url = $vcInfo.URLs.x64
            
            if ($vcInfo.ConfirmationPage -and $vcInfo.DownloadFileNames.x64) {
                $resolvedUrl = Resolve-DownloadUrl -ConfirmationPage $vcInfo.ConfirmationPage -FileName $vcInfo.DownloadFileNames.x64
                if ($resolvedUrl) {
                    $url = $resolvedUrl
                }
            }
            
            if (-not $vcInfo.IsEOL -and $url) {
                $remoteMeta = Get-RemoteFileMetadata -Url $url
                $cacheEntry = $null
                
                if ($redistCache.ContainsKey($version) -and ($redistCache[$version] -is [hashtable]) -and $redistCache[$version].ContainsKey("x64")) {
                    $cacheEntry = $redistCache[$version]["x64"]
                }
                
                if ($remoteMeta -and $cacheEntry) {
                    $updated = $false
                    if (-not $cacheEntry.ETag -and $remoteMeta.ETag) {
                        $cacheEntry.ETag = $remoteMeta.ETag
                        $updated = $true
                    }
                    if (-not $cacheEntry.LastModified -and $remoteMeta.LastModified) {
                        $cacheEntry.LastModified = $remoteMeta.LastModified
                        $updated = $true
                    }
                    if ($updated) {
                        $redistCache[$version]["x64"] = $cacheEntry
                        Save-RedistCache -Cache $redistCache
                    }
                }
                
                $metaMatches = $false
                if ($remoteMeta -and $cacheEntry) {
                    if ($remoteMeta.ETag -and $cacheEntry.ETag -and ($cacheEntry.ETag -eq $remoteMeta.ETag)) {
                        $metaMatches = $true
                    }
                    elseif ($remoteMeta.LastModified -and $cacheEntry.LastModified -and ($cacheEntry.LastModified -eq $remoteMeta.LastModified)) {
                        $metaMatches = $true
                    }
                }
                
                if ($metaMatches -and $cacheEntry.InstallerVersion -and $currentVersion -and
                    (Compare-Version -CurrentVersion $currentVersion -TargetVersion $cacheEntry.InstallerVersion)) {
                    Write-Host "[$currentUpdate/$updateCount] x64 latest installer unchanged and current version ($currentVersion) >= cached ($($cacheEntry.InstallerVersion)) - Skipping download" -ForegroundColor Cyan
                    break
                }
            }
            
            if (-not $url) {
                Write-Host "  NOTE: Visual C++ $version requires manual download" -ForegroundColor Yellow
                if ($vcInfo.DownloadPage) {
                    Write-Host "  Please visit: $($vcInfo.DownloadPage)" -ForegroundColor Yellow
                }
                Write-Host "  Skipping automated update for this version." -ForegroundColor Yellow
            }
            else {
                $installerPath = Join-Path $TempDir "vcredist_${version}_x64.exe"
                $downloadedFiles += $installerPath
                
                try {
                    Write-Host "  Downloading..."
                    $downloadResponse = Invoke-WebRequest -Uri $url -OutFile $installerPath -UseBasicParsing -ErrorAction Stop
                    Write-Host "  Download complete." -ForegroundColor Green
                    
                    if (Test-Path $installerPath) {
                        # Check installer version for both EOL and non-EOL versions
                        $installerVersion = Get-InstallerVersion -FilePath $installerPath
                        $etag = $null
                        $lastModified = $null
                        if ($remoteMeta) {
                            $etag = $remoteMeta.ETag
                            $lastModified = $remoteMeta.LastModified
                        }
                        elseif ($downloadResponse -and $downloadResponse.Headers) {
                            $etag = $downloadResponse.Headers.ETag
                            $lastModified = $downloadResponse.Headers.'Last-Modified'
                        }
                        
                        if (-not $vcInfo.IsEOL) {
                            if (-not $redistCache.ContainsKey($version)) {
                                $redistCache[$version] = @{}
                            }
                            $redistCache[$version]["x64"] = @{
                                ETag = $etag
                                LastModified = $lastModified
                                InstallerVersion = $installerVersion
                            }
                            Save-RedistCache -Cache $redistCache
                        }
                        
                        if ($installerVersion) {
                            Write-Host "  Downloaded installer version: $installerVersion" -ForegroundColor Gray
                            
                            if ($currentVersion -and (Compare-Version -CurrentVersion $currentVersion -TargetVersion $installerVersion)) {
                                Write-Host "  Current version ($currentVersion) is already same or newer than installer ($installerVersion) - Skipping installation" -ForegroundColor Cyan
                                break
                            }
                        }
                        
                        Write-Host "  Installing..."
                        $silentArgs = $SilentArgsMap[$version]
                        $Process = Start-Process -FilePath $installerPath -ArgumentList $silentArgs -Wait -PassThru -WindowStyle Hidden
                        
                        switch ($Process.ExitCode) {
                            0 { 
                                Write-Host "  Installation successful." -ForegroundColor Green
                                
                                # Verify what changed
                                if ($vcInfo.IsEOL) {
                                    Start-Sleep -Seconds 2
                                    $newCheck = Test-VCInstalled -DisplayNamePattern $vcInfo.DisplayName -Architecture "x64"
                                    if ($newCheck.Installed -and $newCheck.Details.DisplayVersion) {
                                        Write-Host "  Registry version after install: $($newCheck.Details.DisplayVersion)" -ForegroundColor Cyan
                                    }
                                    
                                    # Check if KB is now detected
                                    if ($vcInfo.KB -match "KB\d+") {
                                        $kbCheck = Test-KBInstalled -KBNumber $vcInfo.KB
                                        Write-Host "  $($vcInfo.KB) detected: $kbCheck" -ForegroundColor Cyan
                                    }
                                }
                            }
                            3010 { 
                                Write-Host "  Installation successful. Reboot required." -ForegroundColor Yellow
                                $RebootRequired = $true
                            }
                            default { 
                                Write-Warning "  Exit code: $($Process.ExitCode) (may indicate already updated or minor issue)"
                            }
                        }
                    }
                }
                catch {
                    Write-Warning "  Failed: $_"
                }
            }
            } while ($false)
            Write-Host ""
        }

        # Update arm64 if installed
        if ($installed.arm64) {
            $currentUpdate++
            
            $currentVersion = $installed.arm64Details.DisplayVersion
            do {
            
            if ($vcInfo.IsEOL) {
                $targetVersion = $vcInfo.TargetVersion
                
                Write-Host "  DEBUG: Current arm64 version: '$currentVersion'" -ForegroundColor DarkGray
                Write-Host "  DEBUG: Target version: '$targetVersion'" -ForegroundColor DarkGray
                
                # For versions with KB numbers, check if KB is already installed
                if ($vcInfo.KB -match "KB\d+") {
                    $kbNumber = $vcInfo.KB
                    $kbInstalled = Test-KBInstalled -KBNumber $kbNumber
                    Write-Host "  DEBUG: Checking for $kbNumber installed: $kbInstalled" -ForegroundColor DarkGray
                    
                    if ($kbInstalled) {
                        Write-Host "[$currentUpdate/$updateCount] arm64 $kbNumber already installed - Skipping" -ForegroundColor Cyan
                        break
                    }
                }
                
                # Also check version number
                if ($targetVersion -and $currentVersion) {
                    $isUpToDate = Compare-Version -CurrentVersion $currentVersion -TargetVersion $targetVersion
                    Write-Host "  DEBUG: Up to date check result: $isUpToDate" -ForegroundColor DarkGray
                    
                    if ($isUpToDate) {
                        Write-Host "[$currentUpdate/$updateCount] arm64 version already up to date ($currentVersion) - Skipping" -ForegroundColor Cyan
                        break
                    }
                }
            }
            
            Write-Host "[$currentUpdate/$updateCount] Processing arm64 version..." -ForegroundColor Cyan
            
            $url = $null
            if ($vcInfo.URLs.ContainsKey("arm64")) {
                $url = $vcInfo.URLs.arm64
            }
            
            if ($vcInfo.ConfirmationPage -and $vcInfo.DownloadFileNames.arm64) {
                $resolvedUrl = Resolve-DownloadUrl -ConfirmationPage $vcInfo.ConfirmationPage -FileName $vcInfo.DownloadFileNames.arm64
                if ($resolvedUrl) {
                    $url = $resolvedUrl
                }
            }
            
            if (-not $vcInfo.IsEOL -and $url) {
                $remoteMeta = Get-RemoteFileMetadata -Url $url
                $cacheEntry = $null
                
                if ($redistCache.ContainsKey($version) -and ($redistCache[$version] -is [hashtable]) -and $redistCache[$version].ContainsKey("arm64")) {
                    $cacheEntry = $redistCache[$version]["arm64"]
                }
                
                if ($remoteMeta -and $cacheEntry) {
                    $updated = $false
                    if (-not $cacheEntry.ETag -and $remoteMeta.ETag) {
                        $cacheEntry.ETag = $remoteMeta.ETag
                        $updated = $true
                    }
                    if (-not $cacheEntry.LastModified -and $remoteMeta.LastModified) {
                        $cacheEntry.LastModified = $remoteMeta.LastModified
                        $updated = $true
                    }
                    if ($updated) {
                        $redistCache[$version]["arm64"] = $cacheEntry
                        Save-RedistCache -Cache $redistCache
                    }
                }
                
                $metaMatches = $false
                if ($remoteMeta -and $cacheEntry) {
                    if ($remoteMeta.ETag -and $cacheEntry.ETag -and ($cacheEntry.ETag -eq $remoteMeta.ETag)) {
                        $metaMatches = $true
                    }
                    elseif ($remoteMeta.LastModified -and $cacheEntry.LastModified -and ($cacheEntry.LastModified -eq $remoteMeta.LastModified)) {
                        $metaMatches = $true
                    }
                }
                
                if ($metaMatches -and $cacheEntry.InstallerVersion -and $currentVersion -and
                    (Compare-Version -CurrentVersion $currentVersion -TargetVersion $cacheEntry.InstallerVersion)) {
                    Write-Host "[$currentUpdate/$updateCount] arm64 latest installer unchanged and current version ($currentVersion) >= cached ($($cacheEntry.InstallerVersion)) - Skipping download" -ForegroundColor Cyan
                    break
                }
            }
            
            if (-not $url) {
                Write-Host "  NOTE: Visual C++ $version requires manual download" -ForegroundColor Yellow
                if ($vcInfo.DownloadPage) {
                    Write-Host "  Please visit: $($vcInfo.DownloadPage)" -ForegroundColor Yellow
                }
                Write-Host "  Skipping automated update for this version." -ForegroundColor Yellow
            }
            else {
                $installerPath = Join-Path $TempDir "vcredist_${version}_arm64.exe"
                $downloadedFiles += $installerPath
                
                try {
                    Write-Host "  Downloading..."
                    $downloadResponse = Invoke-WebRequest -Uri $url -OutFile $installerPath -UseBasicParsing -ErrorAction Stop
                    Write-Host "  Download complete." -ForegroundColor Green
                    
                    if (Test-Path $installerPath) {
                        # Check installer version for both EOL and non-EOL versions
                        $installerVersion = Get-InstallerVersion -FilePath $installerPath
                        $etag = $null
                        $lastModified = $null
                        if ($remoteMeta) {
                            $etag = $remoteMeta.ETag
                            $lastModified = $remoteMeta.LastModified
                        }
                        elseif ($downloadResponse -and $downloadResponse.Headers) {
                            $etag = $downloadResponse.Headers.ETag
                            $lastModified = $downloadResponse.Headers.'Last-Modified'
                        }
                        
                        if (-not $vcInfo.IsEOL) {
                            if (-not $redistCache.ContainsKey($version)) {
                                $redistCache[$version] = @{}
                            }
                            $redistCache[$version]["arm64"] = @{
                                ETag = $etag
                                LastModified = $lastModified
                                InstallerVersion = $installerVersion
                            }
                            Save-RedistCache -Cache $redistCache
                        }
                        
                        if ($installerVersion) {
                            Write-Host "  Downloaded installer version: $installerVersion" -ForegroundColor Gray
                            
                            if ($currentVersion -and (Compare-Version -CurrentVersion $currentVersion -TargetVersion $installerVersion)) {
                                Write-Host "  Current version ($currentVersion) is already same or newer than installer ($installerVersion) - Skipping installation" -ForegroundColor Cyan
                                break
                            }
                        }
                        
                        Write-Host "  Installing..."
                        $silentArgs = $SilentArgsMap[$version]
                        $Process = Start-Process -FilePath $installerPath -ArgumentList $silentArgs -Wait -PassThru -WindowStyle Hidden
                        
                        switch ($Process.ExitCode) {
                            0 { 
                                Write-Host "  Installation successful." -ForegroundColor Green
                                
                                # Verify what changed
                                if ($vcInfo.IsEOL) {
                                    Start-Sleep -Seconds 2
                                    $newCheck = Test-VCInstalled -DisplayNamePattern $vcInfo.DisplayName -Architecture "arm64"
                                    if ($newCheck.Installed -and $newCheck.Details.DisplayVersion) {
                                        Write-Host "  Registry version after install: $($newCheck.Details.DisplayVersion)" -ForegroundColor Cyan
                                    }
                                    
                                    # Check if KB is now detected
                                    if ($vcInfo.KB -match "KB\d+") {
                                        $kbCheck = Test-KBInstalled -KBNumber $vcInfo.KB
                                        Write-Host "  $($vcInfo.KB) detected: $kbCheck" -ForegroundColor Cyan
                                    }
                                }
                            }
                            3010 { 
                                Write-Host "  Installation successful. Reboot required." -ForegroundColor Yellow
                                $RebootRequired = $true
                            }
                            default { 
                                Write-Warning "  Exit code: $($Process.ExitCode) (may indicate already updated or minor issue)"
                            }
                        }
                    }
                }
                catch {
                    Write-Warning "  Failed: $_"
                }
            }
            } while ($false)
            Write-Host ""
        }
    }
    
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "Update process completed." -ForegroundColor Green
    
    if ($RebootRequired) {
        Write-Host ""
        Write-Host "IMPORTANT: A system reboot is required." -ForegroundColor Yellow
        Write-Host "Please restart your computer to complete the updates." -ForegroundColor Yellow
    }
    Write-Host "=============================================" -ForegroundColor Cyan
}
catch {
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Red
    Write-Error "An error occurred: $_"
    Write-Host "=============================================" -ForegroundColor Red
    exit 1
}
finally {
    Write-Host ""
    Write-Host "Cleaning up temporary files..."
    
    foreach ($file in $downloadedFiles) {
        if (Test-Path $file) {
            try {
                Remove-Item -Path $file -Force -ErrorAction Stop
                Write-Host "  Removed: $(Split-Path $file -Leaf)" -ForegroundColor Gray
            }
            catch {
                Write-Warning "  Could not remove: $(Split-Path $file -Leaf)"
            }
        }
    }
    
    Write-Host "Cleanup complete."
}
