
# ScanRed_v0.2.ps1 - Escaneo simple /24: IP + nombre de equipo (DNS/NetBIOS)
param([string]$BaseIP = "192.168.100", [int]$TimeoutMs = 1000)

function Get-HostName {
    param([string]$ip)
    # 1) DNS PTR
    try {
        $dns = Resolve-DnsName -Name $ip -ErrorAction Stop
        $ptr = $dns | Where-Object { $_.Type -eq 'PTR' } | Select-Object -First 1
        if ($ptr -and $ptr.NameHost) { return $ptr.NameHost }
    } catch { }
    # 2) NetBIOS
    try {
        $out = nbtstat -A $ip 2>$null
        foreach ($line in $out) {
            if ($line -match '^\s*(\S+)\s+<00>\s+UNIQUE') { return $Matches[1] }
        }
    } catch { }
    return $null
}

Write-Host "Escaneando red $BaseIP.0/24..." -ForegroundColor Cyan
for ($i = 1; $i -le 254; $i++) {
    $ip = "$BaseIP.$i"
    $reply = ping.exe -n 1 -w $TimeoutMs $ip | Select-String "TTL="
    if ($reply) {
        $name = Get-HostName -ip $ip
        if ($name) { Write-Host ("Activo: {0} ({1})" -f $ip, $name) -ForegroundColor Green }
        else       { Write-Host ("Activo: {0}" -f $ip) -ForegroundColor Green }
    }
}
Write-Host "Escaneo completado." -ForegroundColor Yellow
