[CmdletBinding()]
param([string[]]$Name = @('WinRM','Spooler','MpsSvc'))
Import-Module (Join-Path $PSScriptRoot 'SupportToolkit.psm1') -Force
Write-Section -Title 'Service Check (read only)' -Data (Get-ServiceInfo -Name $Name)
