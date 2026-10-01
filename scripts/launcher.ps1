Clear-Host

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "   Windows Support Toolkit" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. System Info"
Write-Host "2. Network Info"
Write-Host "3. Disk Check"
Write-Host "4. Service Check"
Write-Host "5. Driver Check"
Write-Host "6. Exit"
Write-Host ""

$choice = Read-Host "Choose an option"

switch ($choice) {
    "1" {
        Write-Host "Running System Info..."
        . "$PSScriptRoot\system-info.ps1"
    }
    "2" {
        Write-Host "Running Network Info..."
        . "$PSScriptRoot\network-info.ps1"
    }
    "3" {
        Write-Host "Running Disk Check..."
        . "$PSScriptRoot\disk-check.ps1"
    }
    "4" {
        Write-Host "Running Service Check..."
        . "$PSScriptRoot\service_check.ps1"
    }
    "5" {
        Write-Host "Running Driver Check..."
        . "$PSScriptRoot\driver-check.ps1"
    }
    "6" {
        Write-Host "Exiting..."
        exit
    }
    default {
        Write-Host "Invalid option." -ForegroundColor Red
    }
}