Import-Module (Join-Path $PSScriptRoot 'SupportToolkit.psm1') -Force
Write-Section -Title 'Network Adapters' -Data (Get-NetworkInfo)
