# ScanRed_v0.5.ps1 – v0.4 con Sistema Operativo agregado
param(
    [string]$BaseIP    = "192.168.100",
    [int]   $TimeoutMs = 1000
)

# Diccionario OUI (prefijos MAC -> fabricante)
$OUIMap = @{
    "FC:AA:14" = "Espressif Inc. (ESP32)"
    "24:6F:28" = "Espressif Inc. (ESP8266/ESP32)"
    "84:CC:A8" = "Espressif Inc."
    "DC:4F:22" = "Raspberry Pi Foundation"
    "B8:27:EB" = "Raspberry Pi Foundation"
    "00:1A:2B" = "Cisco Systems"
    "3C:5A:B4" = "TP-Link Technologies"
    "C0:25:E9" = "Ubiquiti Networks"
    "F0:9F:C2" = "Huawei Technologies"
    "C0:F6:C2" = "ARRIS Group, Inc."
    "EC:C1:AB" = "Hon Hai Precision (Foxconn)"
    "BC:92:6B" = "Samsung Electronics"
    "F4:0F:24" = "Apple Inc."
    "28:E7:CF" = "Apple Inc."
    "04:E8:B9" = "Intel Corporation"
    "00:1C:B3" = "Dell Inc."
    "00:50:56" = "VMware Inc."
    "3C:07:54" = "LG Electronics"
    "F8:D0:27" = "AzureWave Technology Inc."
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
        $arpLine = arp -a | Select-String -Pattern ("^\s*{0}\s" -f [regex]::Escape($ip))

        if ($arpLine) {
            $clean = ($arpLine.Line -replace "\s+", " ").Trim()
            $parts = $clean.Split(" ")

            # Busca patrón MAC xx-xx-xx-xx-xx-xx
            $mac = $parts | Where-Object { $_ -match "^([0-9A-F]{2}-){5}[0-9A-F]{2}$" }

            if ($mac) {
                return ($mac -replace "-", ":" ).ToUpper()
            }
        }
    } catch {}

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

function Detect-OS {
    param([string]$ttl)

    if ($ttl -ge 100 -and $ttl -le 130) { return "Linux" }
    if ($ttl -ge 50  -and $ttl -le 70 ) { return "Windows" }

    return "Desconocido"
}

Write-Host "Escaneando red $BaseIP.0/24..." -ForegroundColor Cyan

for ($i = 1; $i -le 254; $i++) {
    $ip = "$BaseIP.$i"

    $reply = ping.exe -n 1 -w $TimeoutMs $ip | Select-String "TTL="

    if ($reply) {

        # ===== NUEVO: extrae TTL =====
        $ttl = 0
        if ($reply -match "TTL=(\d+)") {
            $ttl = [int]$matches[1]
        }

        $os = Detect-OS -ttl $ttl

        $name = Get-HostName -ip $ip
        $mac  = Get-MacFromArp -ip $ip
        $vendor = Get-Manufacturer -mac $mac

        $msg = "Activo: {0}" -f $ip
        if ($name)   { $msg += (" ({0})" -f $name) }
        if ($mac)    { $msg += ("  MAC: {0}" -f $mac) }
        if ($vendor) { $msg += ("  Fabricante: {0}" -f $vendor) }

        # ===== NUEVO: mostrar SO =====
        $msg += ("  SO: {0}" -f $os)

        Write-Host $msg -ForegroundColor Green
    }
}

Write-Host "Escaneo completado." -ForegroundColor Yellow


