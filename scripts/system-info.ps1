Import-Module (Join-Path $PSScriptRoot 'SupportToolkit.psm1') -Force
Write-Section -Title 'System Info' -Data (Get-SystemInfo)
