$nic = Get-CimInstance Win32_NetworkAdapterConfiguration |
    Where-Object { $_.IPAddress -ne $null -and $_.IPEnabled -eq $true } |
    Select-Object -First 1

Write-Host ""
Write-Host "Network Info" -ForegroundColor Green
Write-Host "IPv4: $($nic.IPAddress[0])"
Write-Host "Gateway: $($nic.DefaultIPGateway -join ', ')"
Write-Host "DNS: $($nic.DNSServerSearchOrder -join ', ')"