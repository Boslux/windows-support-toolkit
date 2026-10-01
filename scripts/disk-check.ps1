$disk = Get-CimInstance Win32_LogicalDisk -Filter "DriveType = 3" | Select-Object -First 1

    Write-Host ""
    Write-Host "Disk Check" -ForegroundColor Green
    Write-Host "Drive: $($disk.DeviceID)"
    Write-Host "Total $([math]::Round($disk.Size /1GB,2)) GB"
    Write-Host "Free: $([math]::Round($disk.FreeSpace / 1GB, 2)) GB"
    Write-Host "Used: $([math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)) GB"