# ScanRed_v0.4.ps1 - Escaneo /24: IP activa + Nombre + MAC (ARP) + Fabricante
# Compatible con Windows PowerShell 5.1
param(
    [string]$BaseIP    = "192.168.100",
    [int]   $TimeoutMs = 1000
)

# Diccionario OUI (prefijos MAC -> fabricante)
$OUIMap = @{
    # Microcontroladores y IoT
    "FC:AA:14" = "Espressif Inc. (ESP32)"
    "24:6F:28" = "Espressif Inc. (ESP8266/ESP32)"
    "84:CC:A8" = "Espressif Inc."
    "DC:4F:22" = "Raspberry Pi Foundation"
    "B8:27:EB" = "Raspberry Pi Foundation"

    # Redes y telecomunicaciones
    "00:1A:2B" = "Cisco Systems"
    "3C:5A:B4" = "TP-Link Technologies"
    "C0:25:E9" = "Ubiquiti Networks"
    "F0:9F:C2" = "Huawei Technologies"
    "C0:F6:C2" = "ARRIS Group, Inc."
    "EC:C1:AB" = "Hon Hai Precision (Foxconn)"

    # Computadoras y móviles
    "BC:92:6B" = "Samsung Electronics"
    "F4:0F:24" = "Apple Inc."
    "28:E7:CF" = "Apple Inc."
    "04:E8:B9" = "Intel Corporation"   # Tu dispositivo
    "00:1C:B3" = "Dell Inc."
    "00:50:56" = "VMware Inc."
    "3C:07:54" = "LG Electronics"
    "F8:D0:27" = "AzureWave Technology Inc."


    # Otros fabricantes frecuentes
    "00:17:88" = "Hewlett Packard (HP)"
    "00:1D:D8" = "Sony Corporation"
    "00:21:5C" = "Microsoft Corporation"
    "00:0C:29" = "VMware Inc."
}

function Get-HostName {
    param([string]$ip)
    try {
        $dns = Resolve-DnsName -Name $ip -ErrorAction Stop
        $ptr = $dns | Where-Object { $_.Type -eq 'PTR' } | Select-Object -First 1
        if ($ptr -and $ptr.NameHost) { return $ptr.NameHost }
    } catch { }
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
    try {
        $arp = arp -a | Select-String -Pattern ("^\s*{0}\s" -f [regex]::Escape($ip))
        if ($arp) {
            $line = $arp.Line.Trim()
            $parts = ($line -split '\s+')
            if ($parts.Length -ge 2) {
                $mac = $parts[1]
                $mac = ($mac -replace '-', ':' ).ToUpper()
                return $mac
            }
        }
    } catch { }
    return $null
}

function Get-Manufacturer {
    param([string]$mac)
    if (-not $mac) { return $null }
    $prefix = ($mac -split ':')[0..2] -join ':'
    if ($OUIMap.ContainsKey($prefix)) {
        return $OUIMap[$prefix]
    } else {
        return "Desconocido"
    }
}

Write-Host "Escaneando red $BaseIP.0/24..." -ForegroundColor Cyan

for ($i = 1; $i -le 254; $i++) {
    $ip = "$BaseIP.$i"

    $reply = ping.exe -n 1 -w $TimeoutMs $ip | Select-String "TTL="
    if ($reply) {
        $name = Get-HostName -ip $ip
        $mac  = Get-MacFromArp -ip $ip
        $vendor = Get-Manufacturer -mac $mac

        $msg = "Activo: {0}" -f $ip
        if ($name)   { $msg += (" ({0})" -f $name) }
        if ($mac)    { $msg += ("  MAC: {0}" -f $mac) }
        if ($vendor) { $msg += ("  Fabricante: {0}" -f $vendor) }
        Write-Host $msg -ForegroundColor Green
    }
}

Write-Host "Escaneo completado." -ForegroundColor Yellow