
param([string]$BaseIP = "192.168.100")
Write-Host "Escaneando red $BaseIP.0/24..." -ForegroundColor Cyan
for ($i = 1; $i -le 254; $i++) {
    $ip = "$BaseIP.$i"
    if (Test-Connection -ComputerName $ip -Count 1 -Quiet -TimeoutSeconds 1) {
        Write-Host "Activo: $ip" -ForegroundColor Green
    }
}
Write-Host "Escaneo completado." -ForegroundColor Yellow
