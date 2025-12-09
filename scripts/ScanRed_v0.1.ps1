
# ScanRed.ps1 - Escaneo simple IPv4 /24 usando ping.exe (compatible con Windows PowerShell 5.1)
param(
    [string]$BaseIP    = "192.168.100",
    [int]   $TimeoutMs = 1000   # timeout por host en milisegundos (1s)
)

Write-Host "Escaneando red $BaseIP.0/24..." -ForegroundColor Cyan

for ($i = 1; $i -le 254; $i++) {
    $ip = "$BaseIP.$i"
    # -n 1 => 1 eco; -w => timeout en ms; filtramos por 'TTL=' para detectar respuesta
    $reply = ping.exe -n 1 -w $TimeoutMs $ip | Select-String "TTL="
    if ($reply) {
        Write-Host "Activo: $ip" -ForegroundColor Green
    }
}

Write-Host "Escaneo completado." -ForegroundColor Yellow


