<#
.SYNOPSIS
    Bootstrap for Visual C++ Updater - provides URL-safe one-liner access.
.DESCRIPTION
    Downloads and runs the main visualc++updater.ps1 script.
    Use this file for reliable URL access (no special characters in filename).
#>
#Requires -RunAsAdministrator
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = 'https://raw.githubusercontent.com/monobrau/visualcplusplusupdater/main/visualc%2B%2Bupdater.ps1'
iex (Invoke-RestMethod -Uri $url -ErrorAction Stop)
