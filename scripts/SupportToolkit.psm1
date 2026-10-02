Set-StrictMode -Version Latest

function Get-SystemInfo {
    $os = Get-CimInstance Win32_OperatingSystem -Property Caption,Version,BuildNumber -ErrorAction Stop
    $computer = Get-CimInstance Win32_ComputerSystem -Property NumberOfLogicalProcessors,TotalPhysicalMemory -ErrorAction Stop
    $uptimeSeconds = (Get-CimInstance Win32_PerfFormattedData_PerfOS_System -Property SystemUpTime -ErrorAction Stop).SystemUpTime
    [pscustomobject]@{
        Windows = $os.Caption
        Version = $os.Version
        Build = $os.BuildNumber
        LogicalProcessors = $computer.NumberOfLogicalProcessors
        MemoryGB = [math]::Round($computer.TotalPhysicalMemory / 1GB, 2)
        UptimeDays = [math]::Round($uptimeSeconds / 86400, 1)
    }
}

function Get-DiskInfo {
    @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType = 3' -Property Size,FreeSpace -ErrorAction Stop | ForEach-Object {
        $freePercent = if ($_.Size -gt 0) { [math]::Round(100 * $_.FreeSpace / $_.Size, 1) } else { 0 }
        [pscustomobject]@{ SizeGB = [math]::Round($_.Size / 1GB, 2); FreeGB = [math]::Round($_.FreeSpace / 1GB, 2); FreePercent = $freePercent; Health = if ($freePercent -lt 10) { 'Warning: low free space' } else { 'OK' } }
    })
}

function Get-NetworkInfo {
    $adapters = @(Get-CimInstance Win32_NetworkAdapter -Filter 'NetEnabled = TRUE' -Property NetEnabled -ErrorAction Stop)
    [pscustomobject]@{ EnabledAdapterCount = $adapters.Count }
}

function Get-ServiceInfo {
    [CmdletBinding()]
    param([string[]]$Name = @('WinRM', 'Spooler', 'MpsSvc'))
    $queryNumber = 0
    foreach ($serviceName in $Name) {
        $queryNumber++
        try {
            $service = Get-CimInstance Win32_Service -Filter "Name='$($serviceName.Replace("'", "''"))'" -Property State,StartMode -ErrorAction Stop
            if ($service) {
                [pscustomobject]@{ QueryNumber = $queryNumber; Status = $service.State; StartMode = $service.StartMode; Health = if ($service.State -eq 'Running') { 'Running' } else { 'Not running' } }
            } else { [pscustomobject]@{ QueryNumber = $queryNumber; Status = 'Not found'; StartMode = $null; Health = 'Not found' } }
        } catch { [pscustomobject]@{ QueryNumber = $queryNumber; Status = 'Query failed'; StartMode = $null; Health = 'Service query unavailable.' } }
    }
}

function Get-DriverInfo {
    $devices = @(Get-CimInstance Win32_PnPEntity -Property ConfigManagerErrorCode -ErrorAction Stop)
    $problemDevices = @($devices | Where-Object { $_.ConfigManagerErrorCode -and $_.ConfigManagerErrorCode -ne 0 })
    [pscustomobject]@{ DevicesWithProblems = $problemDevices.Count; ProblemCodes = @($problemDevices | Group-Object ConfigManagerErrorCode | ForEach-Object { [pscustomobject]@{ Code = [int]$_.Name; Count = $_.Count } }) }
}

function Get-PrinterInfo {
    try {
        $printers = @(Get-CimInstance Win32_Printer -Property PrinterStatus -ErrorAction Stop)
        [pscustomobject]@{ ConfiguredPrinterCount = $printers.Count; StatusCounts = @($printers | Group-Object PrinterStatus | ForEach-Object { [pscustomobject]@{ Status = $_.Name; Count = $_.Count } }) }
    } catch {
        [pscustomobject]@{ ConfiguredPrinterCount = $null; StatusCounts = @(); Details = 'Printer status query unavailable.' }
    }
}

function Get-NetworkDiagnostics {
    [CmdletBinding()]
    param([string[]]$Target = @())
    $results = [System.Collections.Generic.List[object]]::new()
    try {
        Resolve-DnsName -Name 'www.microsoft.com' -Type A -DnsOnly -ErrorAction Stop | Out-Null
        $results.Add([pscustomobject]@{ Check = 'DNS lookup'; Status = 'Resolved' })
    } catch { $results.Add([pscustomobject]@{ Check = 'DNS lookup'; Status = 'Failed'; Guidance = 'Check adapter DNS settings and VPN.' }) }
    foreach ($targetName in $Target) {
        $hostName = $targetName; $port = 443
        if ($targetName -match '^\[([^\]]+)\]:(\d+)$') { $hostName = $Matches[1]; $port = [int]$Matches[2] }
        elseif ($targetName -match '^([^:]+):(\d+)$') { $hostName = $Matches[1]; $port = [int]$Matches[2] }
        try { $probe = Test-NetConnection -ComputerName $hostName -Port $port -WarningAction SilentlyContinue -ErrorAction Stop; $connected = [bool]$probe.TcpTestSucceeded }
        catch { $connected = $false }
        $results.Add([pscustomobject]@{ Check = 'TCP endpoint'; Status = if ($connected) { 'Connected' } else { 'Failed' }; Guidance = if ($connected) { 'TCP connection succeeded for the supplied endpoint.' } else { 'Check DNS resolution, routing, firewall rules and whether the destination port is listening.' } })
    }
    return $results.ToArray()
}

function Get-RecentSystemErrors {
    [CmdletBinding()]
    param([ValidateRange(1,30)][int]$Days = 7, [ValidateRange(1,500)][int]$Limit = 100)
    $start = (Get-Date).AddDays(-$Days)
    try {
        @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = @(1,2); StartTime = $start } -MaxEvents $Limit -ErrorAction Stop | ForEach-Object {
            [pscustomobject]@{
                Time = $_.TimeCreated
                Level = $_.LevelDisplayName
                Provider = $_.ProviderName
                EventId = $_.Id
                MachineName = $_.MachineName
                UserId = $_.UserId
                RecordId = $_.RecordId
                ProcessId = $_.ProcessId
                ThreadId = $_.ThreadId
                Task = $_.TaskDisplayName
                Opcode = $_.OpcodeDisplayName
                Message = $_.Message
                EventData = @($_.Properties | ForEach-Object { $_.Value })
            }
        })
    } catch {
        if ($_.FullyQualifiedErrorId -match 'NoMatchingEventsFound') { @() }
        else { @([pscustomobject]@{ Time = Get-Date; Level = 'Unavailable'; EventId = $null; ErrorType = $_.Exception.GetType().Name; Details = $_.Exception.Message }) }
    }
}

function New-SupportReport {
    [CmdletBinding()]
    param([string[]]$Service = @('WinRM','Spooler','MpsSvc'), [string[]]$Target = @(), [ValidateRange(1,30)][int]$EventDays = 7, [ValidateRange(1,500)][int]$EventLimit = 100, [string[]]$Checks = @('System','Disk','Network','Services','Drivers','Events','Diagnostics'))
    $report = [ordered]@{ GeneratedAt = (Get-Date).ToString('o'); Checks = [ordered]@{} }
    foreach ($check in $Checks) {
        try {
            switch ($check.ToLowerInvariant()) {
                'system' { $report.Checks.System = Get-SystemInfo }
                'disk' { $report.Checks.Disks = Get-DiskInfo }
                'network' { $report.Checks.NetworkAdapters = Get-NetworkInfo }
                'services' { $report.Checks.Services = @(Get-ServiceInfo -Name $Service) }
                'drivers' { $report.Checks.DeviceProblems = @(Get-DriverInfo) }
                'printers' { $report.Checks.Printers = @(Get-PrinterInfo) }
                'events' { $report.Checks.SystemErrors = @(Get-RecentSystemErrors -Days $EventDays -Limit $EventLimit) }
                'diagnostics' { $report.Checks.NetworkDiagnostics = @(Get-NetworkDiagnostics -Target $Target) }
                default { throw "Unknown check '$check'. Valid values: System, Disk, Network, Services, Drivers, Events, Diagnostics." }
            }
        } catch {
            $report.Checks["${check}Error"] = [pscustomobject]@{ Details = 'Check unavailable.' }
        }
    }
    return [pscustomobject]@{ GeneratedAt = $report.GeneratedAt; Checks = [pscustomobject]$report.Checks }
}

function Export-SupportReport {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Report, [Parameter(Mandatory)][string]$Path)
    $data = $Report
    $fullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $parent = Split-Path -Parent $fullPath
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $extension = [IO.Path]::GetExtension($fullPath).ToLowerInvariant()
    if ($extension -eq '.json') {
        ConvertTo-Json -InputObject $data -Depth 12 | Set-Content -LiteralPath $fullPath -Encoding UTF8
    } elseif ($extension -in @('.html','.htm')) {
        $sections = foreach ($section in $data.Checks.PSObject.Properties) {
            $items = @($section.Value)
            if ($items.Count -eq 0) { $rows = "<h2>$($section.Name)</h2><p>No issues found.</p>" }
            else { $rows = @($items | ConvertTo-Html -Fragment -PreContent "<h2>$($section.Name)</h2>") -join "`n" }
            $rows
        }
        $title = [System.Net.WebUtility]::HtmlEncode('Windows Support Report')
        $html = "<!doctype html><html><head><meta charset='utf-8'><title>$title</title><style>body{font:14px Segoe UI,Arial;margin:2rem;color:#222}h1,h2{color:#075985}table{border-collapse:collapse;margin-bottom:2rem}th,td{border:1px solid #ddd;padding:.45rem;text-align:left}th{background:#eef6fa}pre{white-space:pre-wrap}</style></head><body><h1>$title</h1><p>Generated: $([System.Net.WebUtility]::HtmlEncode($data.GeneratedAt))</p><p>This report contains summarized diagnostic data.</p>$($sections -join "`n")</body></html>"
        Set-Content -LiteralPath $fullPath -Value $html -Encoding UTF8
    } else { throw 'Output path must end in .json, .html or .htm.' }
    return $fullPath
}

function Write-Section { param([string]$Title, $Data) Write-Host "`n=== $Title ===" -ForegroundColor Green; if ($null -eq $Data -or @($Data).Count -eq 0) { Write-Host 'No results.'; return }; $Data | Format-Table -AutoSize -Wrap | Out-Host }

Export-ModuleMember -Function Get-SystemInfo,Get-DiskInfo,Get-NetworkInfo,Get-ServiceInfo,Get-DriverInfo,Get-PrinterInfo,Get-NetworkDiagnostics,Get-RecentSystemErrors,New-SupportReport,Export-SupportReport,Write-Section
