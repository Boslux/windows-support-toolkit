Import-Module (Join-Path $PSScriptRoot 'SupportToolkit.psm1') -Force
Write-Section -Title 'Disk Check' -Data (Get-DiskInfo)
