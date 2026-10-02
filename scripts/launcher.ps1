[CmdletBinding()]
param(
    [ValidateSet('System','Disk','Network','Services','Drivers','Printers','Events','Diagnostics')]
    [string[]]$Check,
    [string]$OutputPath,
    [string[]]$ServiceName = @('WinRM','Spooler','MpsSvc'),
    [string[]]$Target = @(),
    [ValidateRange(1,30)][int]$EventDays = 7,
    [ValidateRange(1,500)][int]$EventLimit = 100
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'SupportToolkit.psm1') -Force

function Show-ReportSection {
    param([Parameter(Mandatory)]$Report, [Parameter(Mandatory)][string]$Key, [Parameter(Mandatory)][string]$Title)
    $value = $Report.Checks.PSObject.Properties[$Key].Value
    Write-Section -Title $Title -Data $value
}

function Invoke-InteractiveMenu {
    while ($true) {
        Clear-Host
        Write-Host '====================================' -ForegroundColor Cyan
        Write-Host '   Windows Support Toolkit' -ForegroundColor Cyan
        Write-Host '====================================' -ForegroundColor Cyan
        Write-Host '1. System Info'
        Write-Host '2. Network Info'
        Write-Host '3. Disk Check'
        Write-Host '4. Service Check'
        Write-Host '5. Driver / Device Problems'
        Write-Host '6. Full Support Report (JSON or HTML; identifiers omitted)'
        Write-Host '7. Network Diagnostics'
        Write-Host '8. Recent System Errors'
        Write-Host '9. Query Services'
        Write-Host '10. Printer Queues'
        Write-Host '11. Exit'
        $choice = Read-Host 'Choose an option'
        switch ($choice) {
            '1' { $r = New-SupportReport -Checks System; Show-ReportSection $r System 'System Info' }
            '2' { $r = New-SupportReport -Checks Network; Show-ReportSection $r NetworkAdapters 'Network Adapters' }
            '3' { $r = New-SupportReport -Checks Disk; Show-ReportSection $r Disks 'Disk Check' }
            '4' { $names = @(Read-Host 'Service names (comma separated; blank for WinRM,Spooler,MpsSvc)'); if (-not $names[0]) { $names = @('WinRM','Spooler','MpsSvc') } else { $names = @($names[0] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }; $r = New-SupportReport -Checks Services -Service $names; Show-ReportSection $r Services 'Service Check' }
            '5' { $r = New-SupportReport -Checks Drivers; Show-ReportSection $r DeviceProblems 'Device Problems' }
            '6' {
                $path = Read-Host 'Output file (.json or .html; default support-report-<timestamp>.html)'
                if (-not $path) { $path = Join-Path (Get-Location) ("support-report-{0}.html" -f (Get-Date -Format 'yyyyMMdd-HHmmss')) }
                $r = New-SupportReport -Service $ServiceName -Target $Target -EventDays $EventDays -EventLimit $EventLimit
                $saved = Export-SupportReport $r $path
                Write-Host "Report saved: $saved" -ForegroundColor Green
            }
            '7' { $destinations = @(Read-Host 'Optional host:port targets, comma separated (default port 443)'); $targets = if ($destinations[0]) { @($destinations[0] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) } else { @() }; $r = New-SupportReport -Checks Diagnostics -Target $targets; Show-ReportSection $r NetworkDiagnostics 'Network Diagnostics' }
            '8' { $daysText = Read-Host 'Look back how many days? (default 7)'; $days = if ($daysText -match '^\d+$') { [int]$daysText } else { 7 }; $r = New-SupportReport -Checks Events -EventDays $days; Show-ReportSection $r SystemErrors 'Recent System Errors' }
            '9' { $entered = Read-Host 'Service names (comma separated)'; $names = if ($entered) { @($entered -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) } else { $ServiceName }; $r = New-SupportReport -Checks Services -Service $names; Show-ReportSection $r Services 'Service Check' }
            '10' { $r = New-SupportReport -Checks Printers; Show-ReportSection $r Printers 'Printer Queues' }
            '11' { return }
            default { Write-Host 'Invalid option.' -ForegroundColor Red }
        }
        if ($choice -ne '11') { [void](Read-Host 'Press Enter to continue') }
    }
}

if ($PSBoundParameters.Count -eq 0) { Invoke-InteractiveMenu; return }

$checksToRun = if ($Check) { $Check } else { @('System','Disk','Network','Services','Drivers','Printers','Events','Diagnostics') }
$report = New-SupportReport -Checks $checksToRun -Service $ServiceName -Target $Target -EventDays $EventDays -EventLimit $EventLimit
foreach ($property in $report.Checks.PSObject.Properties) {
    Write-Section -Title $property.Name -Data $property.Value
}
if ($OutputPath) {
    $savedPath = Export-SupportReport -Report $report -Path $OutputPath
    Write-Host "Report saved: $savedPath" -ForegroundColor Green
}
