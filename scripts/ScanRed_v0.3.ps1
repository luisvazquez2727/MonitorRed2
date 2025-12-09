
# ScanRed_v0.3.ps1 - Escaneo /24: IP activa + Nombre (opcional) + MAC (ARP)
# Compatible con Windows PowerShell 5.1
param(
    [string]$BaseIP    = "192.168.100",
    [int]   $TimeoutMs = 1000
)

function Get-HostName {
    param([string]$ip)
    # 1) DNS PTR
    try {
        $dns = Resolve-DnsName -Name $ip -ErrorAction Stop
        $ptr = $dns | Where-Object { $_.Type -eq 'PTR' } | Select-Object -First 1
        if ($ptr -and $ptr.NameHost) { return $ptr.NameHost }
    } catch { }
    # 2) NetBIOS (Windows)
    try {
        $out = nbtstat -A $ip 2>$null
        foreach ($line in $out) {
            if ($line -match '^\s*(\S+)\s+<00>\s+UNIQUE') { return $Matches[1] }
        }
    } catch { }
    return $null
}

function Get-MacFromArp {
    param([string]$ip)
    # Consultar ARP; requiere que el host haya sido contactado (ping) y esté en el mismo segmento L2
    try {
        $arp = arp -a | Select-String -Pattern ("^\s*{0}\s" -f [regex]::Escape($ip))
        if ($arp) {
            # Formatos típicos: 192.168.1.10   aa-bb-cc-dd-ee-ff   dinámica
            # o                 192.168.1.10   aa:bb:cc:dd:ee:ff   dynamic
            $line = $arp.Line.Trim()
            # Extraer la segunda columna (MAC) por espacios múltiples
            $parts = ($line -split '\s+')
            if ($parts.Length -ge 2) {
                $mac = $parts[1]
                # Normalizar a formato AA:BB:CC:DD:EE:FF
                $mac = ($mac -replace '-', ':' ).ToUpper()
                return $mac
            }
        }
    } catch { }
    return $null
}

Write-Host "Escaneando red $BaseIP.0/24..." -ForegroundColor Cyan

for ($i = 1; $i -le 254; $i++) {
    $ip = "$BaseIP.$i"

    # 1 eco, timeout configurable
    $reply = ping.exe -n 1 -w $TimeoutMs $ip | Select-String "TTL="
    if ($reply) {
        # Intentar resolver nombre (puede fallar si DNS/NetBIOS no están disponibles)
        $name = Get-HostName -ip $ip

        # Consultar MAC en ARP después del ping
        $mac  = Get-MacFromArp -ip $ip

        # Mostrar resultado
        $msg = "Activo: {0}" -f $ip
        if ($name) { $msg += (" ({0})" -f $name) }
        if ($mac)  { $msg += ("  MAC: {0}" -f $mac) }
        Write-Host $msg -ForegroundColor Green
    }
}

Write-Host "Escaneo completado." -ForegroundColor Yellow
