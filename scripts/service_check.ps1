$services = "WinRM", "Spooler", "MpsSvc"

Write-Host ""
Write-Host "Service Check" -ForegroundColor Green
foreach ($serviceName in $services) {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

    if ($service) {
        Write-Host "$($service.Name) - Status: $($service.Status)"
    }
    else {
        Write-Host "$serviceName - Not found"
    }
}