$devices = Get-CimInstance Win32_PnPEntity |
    Where-Object { $_.Name -notmatch "Microsoft" -and $_.Name -notmatch "ACPI" } |
    Select-Object -First 20

    Write-Host ""
    Write-Host "Driver Check" -ForegroundColor Green

    foreach ($devices in $devices)
        {
            Write-Host "$($devices.name) - Status: $($devices.Status)"
        }