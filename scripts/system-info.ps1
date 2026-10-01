$computerName = $env:COMPUTERNAME
$os = Get-CimInstance Win32_OperatingSystem
$computer = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
$cpu = Get-CimInstance Win32_Processor
$memory = Get-CimInstance Win32_ComputerSystem
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DriveType = 3" | Select-Object -First 1

Write-Host ""
Write-Host "System Info" -ForegroundColor Green
Write-Host "=== Windows Support Toolkit - System Info ==="
Write-Host "Computer Name: $computerName"
Write-Host "Windows Version: $($os.Version)"
Write-Host "Caption: $($os.Caption)"
Write-Host "Manufacturer: $($computer.Manufacturer)"
Write-Host "Model: $($computer.Model)"
Write-Host "Serial Number: $($bios.SerialNumber)"
Write-Host "CPU: $($cpu.Name)"
Write-Host "RAM: $([math]::Round($memory.TotalPhysicalMemory / 1GB, 2)) GB"
Write-Host "Disk: $($disk.DeviceID) - Free: $([math]::Round($disk.FreeSpace / 1GB, 2)) GB / Total: $([math]::Round($disk.Size / 1GB, 2)) GB"
