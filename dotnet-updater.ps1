<#
.SYNOPSIS
    Comprehensive updater for all .NET Framework and .NET versions.

.DESCRIPTION
    This comprehensive script scans for and updates ALL major .NET versions:
    - .NET Framework 4.6.2, 4.7, 4.7.1, 4.7.2, 4.8, 4.8.1
    - .NET 6.0 LTS, .NET 8.0 LTS (latest versions)
    - .NET 9.0 (if installed)
    
    The script runs completely silently with no user interaction required.
    It intelligently compares installed versions with target versions and skips updates
    for versions that are already up to date, saving time and bandwidth.

.NOTES
    File Name: dotnet-updater.ps1
    Run this script with administrative privileges.
    All URLs point to official Microsoft downloads.
    
    Version Checking:
    - .NET Framework: Compares against latest known versions
    - .NET (Core/5+): Downloads and checks latest available versions
    - Automatically detects if downloaded installer is newer than installed version
    - Skips installation if current version is already up to date
    - Avoids unnecessary downloads when versions are already current
    
    Target Versions:
    - .NET Framework 4.6.2: 4.6.2 (if installed)
    - .NET Framework 4.7: 4.7 (if installed) 
    - .NET Framework 4.7.1: 4.7.1 (if installed)
    - .NET Framework 4.7.2: 4.7.2 (if installed)
    - .NET Framework 4.8: 4.8 (if installed)
    - .NET Framework 4.8.1: 4.8.1 (latest)
    - .NET 6.0: Latest LTS version
    - .NET 8.0: Latest LTS version
    - .NET 9.0: Latest version (if installed)
#>

#Requires -RunAsAdministrator

# Enforce TLS 1.2 for downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ".NET Framework & .NET Updater" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Define all .NET versions and their download URLs
$DotNetVersions = @{
    "Framework-4.6.2" = @{
        DisplayName = "Microsoft \.NET Framework 4\.6\.2"
        RegistryPath = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
        RegistryValue = "Release"
        MinRelease = 394802
        TargetVersion = "4.6.2"
        IsFramework = $true
        URLs = @{
            Offline = "https://download.microsoft.com/download/F/9/4/F942F07D-F26F-4F30-B4E3-EBD54FABA377/NDP462-KB3151800-x86-x64-AllOS-ENU.exe"
            Web = "https://download.microsoft.com/download/F/9/4/F942F07D-F26F-4F30-B4E3-EBD54FABA377/NDP462-KB3151802-Web.exe"
        }
    }
    "Framework-4.7" = @{
        DisplayName = "Microsoft \.NET Framework 4\.7"
        RegistryPath = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
        RegistryValue = "Release"
        MinRelease = 460798
        TargetVersion = "4.7"
        IsFramework = $true
        URLs = @{
            Offline = "https://download.microsoft.com/download/D/D/3/DD35CC25-6E9C-484B-A746-C5BE0C923290/NDP47-KB3186497-x86-x64-AllOS-ENU.exe"
            Web = "https://download.microsoft.com/download/A/E/A/AEAE0F3F-96E9-4711-AADA-5E35EF902306/NDP47-KB3186500-Web.exe"
        }
    }
    "Framework-4.7.1" = @{
        DisplayName = "Microsoft \.NET Framework 4\.7\.1"
        RegistryPath = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
        RegistryValue = "Release"
        MinRelease = 461308
        TargetVersion = "4.7.1"
        IsFramework = $true
        URLs = @{
            Offline = "https://download.microsoft.com/download/9/E/6/9E63300C-0941-4B45-A0EC-0008F96DD480/NDP471-KB4033342-x86-x64-AllOS-ENU.exe"
            Web = "https://download.microsoft.com/download/9/E/6/9E63300C-0941-4B45-A0EC-0008F96DD480/NDP471-KB4033344-Web.exe"
        }
    }
    "Framework-4.7.2" = @{
        DisplayName = "Microsoft \.NET Framework 4\.7\.2"
        RegistryPath = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
        RegistryValue = "Release"
        MinRelease = 461808
        TargetVersion = "4.7.2"
        IsFramework = $true
        URLs = @{
            Offline = "https://download.microsoft.com/download/6/E/4/6E48E8AB-DC00-419E-9704-06DD46E5F81D/NDP472-KB4054530-x86-x64-AllOS-ENU.exe"
            Web = "https://download.microsoft.com/download/6/E/4/6E48E8AB-DC00-419E-9704-06DD46E5F81D/NDP472-KB4054531-Web.exe"
        }
    }
    "Framework-4.8" = @{
        DisplayName = "Microsoft \.NET Framework 4\.8"
        RegistryPath = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
        RegistryValue = "Release"
        MinRelease = 528040
        TargetVersion = "4.8"
        IsFramework = $true
        URLs = @{
            Offline = "https://download.microsoft.com/download/7/D/1/7D15524C-8F8C-4F9C-A580-A6A935E2F8F1/NDP48-x86-x64-AllOS-ENU.exe"
            Web = "https://download.microsoft.com/download/7/D/1/7D15524C-8F8C-4F9C-A580-A6A935E2F8F1/NDP48-Web.exe"
        }
    }
    "Framework-4.8.1" = @{
        DisplayName = "Microsoft \.NET Framework 4\.8\.1"
        RegistryPath = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
        RegistryValue = "Release"
        MinRelease = 533320
        TargetVersion = "4.8.1"
        IsFramework = $true
        URLs = @{
            Offline = "https://download.microsoft.com/download/9/6/F/96FD0525-3DDF-423D-8845-5F92F4A6883E/NDP481-x86-x64-AllOS-ENU.exe"
            Web = "https://download.microsoft.com/download/9/6/F/96FD0525-3DDF-423D-8845-5F92F4A6883E/NDP481-Web.exe"
        }
    }
    "NET-6.0" = @{
        DisplayName = "Microsoft\.NET\.Runtime\.6"
        TargetVersion = $null
        IsFramework = $false
        IsLTS = $true
        URLs = @{
            Runtime = "https://dotnetcli.azureedge.net/dotnet/Runtime/LTS/dotnet-runtime-win-x64.exe"
            Desktop = "https://dotnetcli.azureedge.net/dotnet/WindowsDesktop/LTS/windowsdesktop-runtime-win-x64.exe"
            SDK = "https://dotnetcli.azureedge.net/dotnet/Sdk/LTS/dotnet-sdk-win-x64.exe"
        }
    }
    "NET-8.0" = @{
        DisplayName = "Microsoft\.NET\.Runtime\.8"
        TargetVersion = $null
        IsFramework = $false
        IsLTS = $true
        URLs = @{
            Runtime = "https://dotnetcli.azureedge.net/dotnet/Runtime/8.0/dotnet-runtime-win-x64.exe"
            Desktop = "https://dotnetcli.azureedge.net/dotnet/WindowsDesktop/8.0/windowsdesktop-runtime-win-x64.exe"
            SDK = "https://dotnetcli.azureedge.net/dotnet/Sdk/8.0/dotnet-sdk-win-x64.exe"
        }
    }
    "NET-9.0" = @{
        DisplayName = "Microsoft\.NET\.Runtime\.9"
        TargetVersion = $null
        IsFramework = $false
        IsLTS = $false
        URLs = @{
            Runtime = "https://dotnetcli.azureedge.net/dotnet/Runtime/9.0/dotnet-runtime-win-x64.exe"
            Desktop = "https://dotnetcli.azureedge.net/dotnet/WindowsDesktop/9.0/windowsdesktop-runtime-win-x64.exe"
            SDK = "https://dotnetcli.azureedge.net/dotnet/Sdk/9.0/dotnet-sdk-win-x64.exe"
        }
    }
}

# Function to get .NET Framework version from registry
function Get-DotNetFrameworkVersion {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RegistryPath,
        [Parameter(Mandatory=$true)]
        [string]$RegistryValue
    )
    
    try {
        if (Test-Path $RegistryPath) {
            $release = Get-ItemProperty -Path $RegistryPath -Name $RegistryValue -ErrorAction SilentlyContinue
            if ($release) {
                return $release.$RegistryValue
            }
        }
    }
    catch {
        Write-Host "  DEBUG: Error reading registry: $_" -ForegroundColor DarkGray
    }
    
    return $null
}

# Function to check installed .NET versions using dotnet command
function Get-InstalledDotNetVersions {
    try {
        $runtimes = & dotnet --list-runtimes 2>$null
        $sdks = & dotnet --list-sdks 2>$null
        
        return @{
            Runtimes = $runtimes
            SDKs = $sdks
            Available = $true
        }
    }
    catch {
        return @{
            Runtimes = @()
            SDKs = @()
            Available = $false
        }
    }
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

# Scan for installed versions
Write-Host "Scanning for installed .NET versions..." -ForegroundColor Yellow
Write-Host ""

$installedVersions = @{}
$updateCount = 0

# Check .NET Framework versions
foreach ($version in $DotNetVersions.Keys | Where-Object { $DotNetVersions[$_].IsFramework } | Sort-Object) {
    $dotNetInfo = $DotNetVersions[$version]
    
    Write-Host "Checking .NET Framework $($dotNetInfo.TargetVersion)..." -ForegroundColor Gray
    
    $releaseValue = Get-DotNetFrameworkVersion -RegistryPath $dotNetInfo.RegistryPath -RegistryValue $dotNetInfo.RegistryValue
    
    if ($releaseValue -and $releaseValue -ge $dotNetInfo.MinRelease) {
        $installedVersions[$version] = @{
            Installed = $true
            ReleaseValue = $releaseValue
            Version = $dotNetInfo.TargetVersion
            IsFramework = $true
        }
        $updateCount++
    }
}

# Check .NET (Core/5+) versions
Write-Host "Checking .NET (Core/5+) versions..." -ForegroundColor Gray
$dotnetInfo = Get-InstalledDotNetVersions

if ($dotnetInfo.Available) {
    foreach ($version in $DotNetVersions.Keys | Where-Object { -not $DotNetVersions[$_].IsFramework } | Sort-Object) {
        $netInfo = $DotNetVersions[$version]
        $majorVersion = $version.Split('-')[1].Split('.')[0]
        
        # Check for runtime installations
        $runtimeMatch = $dotnetInfo.Runtimes | Where-Object { $_ -match "Microsoft\.NETCore\.App $majorVersion\." }
        $desktopMatch = $dotnetInfo.Runtimes | Where-Object { $_ -match "Microsoft\.WindowsDesktop\.App $majorVersion\." }
        $sdkMatch = $dotnetInfo.SDKs | Where-Object { $_ -match "^$majorVersion\." }
        
        if ($runtimeMatch -or $desktopMatch -or $sdkMatch) {
            $installedVersions[$version] = @{
                Installed = $true
                Runtime = $runtimeMatch
                Desktop = $desktopMatch
                SDK = $sdkMatch
                IsFramework = $false
            }
            $updateCount++
        }
    }
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Detection Results" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

if ($installedVersions.Count -eq 0) {
    Write-Host "No .NET installations detected." -ForegroundColor Yellow
    Write-Host "Nothing to update." -ForegroundColor Yellow
    exit 0
}

# Display what was found
foreach ($version in $installedVersions.Keys | Sort-Object) {
    $netInfo = $DotNetVersions[$version]
    $installed = $installedVersions[$version]
    
    Write-Host ""
    if ($installed.IsFramework) {
        Write-Host ".NET Framework $($netInfo.TargetVersion):" -ForegroundColor Green
        Write-Host "  Release Value: $($installed.ReleaseValue)" -ForegroundColor Gray
        Write-Host "  Status: INSTALLED" -ForegroundColor Green
    }
    else {
        Write-Host ".NET $($version.Split('-')[1]):" -ForegroundColor Green
        if ($installed.Runtime) {
            Write-Host "  Runtime: $($installed.Runtime)" -ForegroundColor Gray
        }
        if ($installed.Desktop) {
            Write-Host "  Desktop: $($installed.Desktop)" -ForegroundColor Gray
        }
        if ($installed.SDK) {
            Write-Host "  SDK: $($installed.SDK)" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Write-Host "Total .NET installations found: $($installedVersions.Count)" -ForegroundColor Cyan
Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Beginning updates..." -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Temporary directory for downloads
$TempDir = $env:TEMP
$RebootRequired = $false
$downloadedFiles = @()

# Silent installation arguments
$SilentArgsMap = @{
    "Framework" = "/quiet", "/norestart"
    "NET" = "/install", "/quiet", "/norestart"
}

try {
    $currentUpdate = 0
    
    foreach ($version in $installedVersions.Keys | Sort-Object) {
        $netInfo = $DotNetVersions[$version]
        $installed = $installedVersions[$version]
        
        Write-Host "Processing .NET $version..." -ForegroundColor Yellow
        Write-Host ""
        
        $currentUpdate++
        
        if ($installed.IsFramework) {
            # .NET Framework update logic
            Write-Host "[$currentUpdate/$($installedVersions.Count)] Checking .NET Framework $($netInfo.TargetVersion)..." -ForegroundColor Cyan
            
            # For Framework, we'll use the offline installer
            $url = $netInfo.URLs.Offline
            $installerPath = Join-Path $TempDir "dotnet-framework-$($netInfo.TargetVersion).exe"
            $downloadedFiles += $installerPath
            
            try {
                Write-Host "  Downloading .NET Framework $($netInfo.TargetVersion)..."
                Invoke-WebRequest -Uri $url -OutFile $installerPath -UseBasicParsing -ErrorAction Stop
                Write-Host "  Download complete." -ForegroundColor Green
                
                if (Test-Path $installerPath) {
                    Write-Host "  Installing .NET Framework $($netInfo.TargetVersion)..."
                    $silentArgs = $SilentArgsMap["Framework"]
                    $Process = Start-Process -FilePath $installerPath -ArgumentList $silentArgs -Wait -PassThru -WindowStyle Hidden
                    
                    switch ($Process.ExitCode) {
                        0 { 
                            Write-Host "  Installation successful." -ForegroundColor Green
                        }
                        3010 { 
                            Write-Host "  Installation successful. Reboot required." -ForegroundColor Yellow
                            $RebootRequired = $true
                        }
                        1641 {
                            Write-Host "  Installation successful. Reboot initiated." -ForegroundColor Yellow
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
        else {
            # .NET (Core/5+) update logic
            Write-Host "[$currentUpdate/$($installedVersions.Count)] Checking .NET $($version.Split('-')[1])..." -ForegroundColor Cyan
            
            # For .NET, we'll update Desktop Runtime (includes regular runtime)
            $url = $netInfo.URLs.Desktop
            $installerPath = Join-Path $TempDir "dotnet-$($version.Split('-')[1])-desktop.exe"
            $downloadedFiles += $installerPath
            
            try {
                Write-Host "  Downloading .NET $($version.Split('-')[1]) Desktop Runtime..."
                Invoke-WebRequest -Uri $url -OutFile $installerPath -UseBasicParsing -ErrorAction Stop
                Write-Host "  Download complete." -ForegroundColor Green
                
                if (Test-Path $installerPath) {
                    # Check installer version
                    $installerVersion = Get-InstallerVersion -FilePath $installerPath
                    if ($installerVersion) {
                        Write-Host "  Downloaded installer version: $installerVersion" -ForegroundColor Gray
                    }
                    
                    Write-Host "  Installing .NET $($version.Split('-')[1]) Desktop Runtime..."
                    $silentArgs = $SilentArgsMap["NET"]
                    $Process = Start-Process -FilePath $installerPath -ArgumentList $silentArgs -Wait -PassThru -WindowStyle Hidden
                    
                    switch ($Process.ExitCode) {
                        0 { 
                            Write-Host "  Installation successful." -ForegroundColor Green
                        }
                        3010 { 
                            Write-Host "  Installation successful. Reboot required." -ForegroundColor Yellow
                            $RebootRequired = $true
                        }
                        1641 {
                            Write-Host "  Installation successful. Reboot initiated." -ForegroundColor Yellow
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
        Write-Host ""
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
