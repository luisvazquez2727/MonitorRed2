
# ScanRed_v0.8.ps1 - Escaneo /24 + Validación de direcciones (IP/MAC)
# Compatible con Windows PowerShell 5.1
param(
    [string]$BaseIP         = "192.168.100",           # Base de /24: 192.168.100.x
    [int]$TimeoutMs         = 500,                      # tiempo de espera en ms
    [string]$OutputDir      = "$env:ProgramData\MonitorRed",
    [string]$StatePath      = "$env:ProgramData\MonitorRed\inventory.json",
    [switch]$VerboseScan                                # muestra progreso detallado
)

# ------------------------
# Utilidades y tablas OUI
# ------------------------
function Ensure-Dir($path) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}
$OUIMap = @{
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
function Normalize-MAC([string]$mac) {
    if (-not $mac) { return $null }
    return ($mac.Trim() -replace '-', ':' -replace '\.', ':' ).ToUpper()
}
function Get-VendorFromMAC([string]$mac) {
    if (-not $mac) { return "Desconocido" }
    $mac = Normalize-MAC $mac
    $oui = ($mac.Split(':') | Select-Object -First 3) -join ':'
    if ($OUIMap.ContainsKey($oui)) { return $OUIMap[$oui] }
    return "Desconocido"
}
function Get-HostName([string]$ip) {
    try {
        $entry = [System.Net.Dns]::GetHostEntry($ip)
        if ($entry.HostName) { return $entry.HostName }
    } catch { }
    # Fallback NetBIOS (nbtstat) — puede no resolver en todas las redes
    try {
        $nb = nbtstat -A $ip | Select-String '<00>' | Select-Object -First 1
        if ($nb) {
            $parts = $nb.ToString().Split(' ') | Where-Object { $_ -and $_ -ne '' }
            return $parts[0]
        }
    } catch { }
    return $null
}
function Get-MACFromARP([string]$ip) {
    # Primero intenta Get-NetNeighbor (Win10/11)
    try {
        $n = Get-NetNeighbor -AddressFamily IPv4 -ErrorAction Stop | Where-Object { $_.IPAddress -eq $ip -and $_.LinkLayerAddress -and $_.State -ne 'Unreachable' }
        if ($n) { return Normalize-MAC $n.LinkLayerAddress }
    } catch { }
    # Fallback: arp -a
    try {
        $arp = arp -a | Select-String "^\s*$ip\s+([0-9a-f\.-:]+)\s+"
        if ($arp) {
            $m = [regex]::Match($arp.ToString(), "^\s*$ip\s+([0-9a-f\.-:]+)\s+")
            if ($m.Success) { return Normalize-MAC $m.Groups[1].Value }
        }
    } catch { }
    return $null
}

# ------------------------
# Escaneo principal
# ------------------------
$results = New-Object System.Collections.Generic.List[object]
$aliveCount = 0

Write-Host "Escaneando red $BaseIP.0/24..." -ForegroundColor Cyan
for ($i = 1; $i -le 254; $i++) {
    $ip = "$BaseIP.$i"
    # Hacemos ping; si responde, consideramos el host activo
    $reply = ping.exe -n 1 -w $TimeoutMs $ip
    if ($reply -match "TTL=") {
        $aliveCount++
        if ($VerboseScan) { Write-Host ("Activo: {0}" -f $ip) -ForegroundColor Green }
        # Hostname
        $hn  = Get-HostName $ip
        # MAC (ARP se llena tras ping)
        $mac = Get-MACFromARP $ip
        # Fabricante por OUI
        $ven = Get-VendorFromMAC $mac

        $obj = [PSCustomObject]@{
            IP         = $ip
            Hostname   = $hn
            MAC        = $mac
            Fabricante = $ven
        }
        $results.Add($obj)
    } else {
        if ($VerboseScan) { Write-Host ("Sin respuesta: {0}" -f $ip) -ForegroundColor DarkGray }
    }
}

# ------------------------
# Validación de duplicados (en el mismo escaneo)
# ------------------------
function Find-Conflicts($devices) {
    $conflicts = [PSCustomObject]@{
        DuplicadosMAC = @()  # misma MAC con hostnames distintos
        DuplicadosIP  = @()  # misma IP con MAC distintas
        FaltantesMAC  = @()  # hosts activos sin MAC (ARP no resolvió)
    }

    # Índices
    $byMAC = @{}
    $byIP  = @{}

    foreach ($d in $devices) {
        if ($d.MAC) {
            if (-not $byMAC.ContainsKey($d.MAC)) { $byMAC[$d.MAC] = New-Object System.Collections.Generic.List[object] }
            $byMAC[$d.MAC].Add($d)
        } else {
            $conflicts.FaltantesMAC += $d
        }
        if (-not $byIP.ContainsKey($d.IP)) { $byIP[$d.IP] = New-Object System.Collections.Generic.List[object] }
        $byIP[$d.IP].Add($d)
    }

    foreach ($mac in $byMAC.Keys) {
        $hosts = ($byMAC[$mac] | Select-Object -ExpandProperty Hostname | Where-Object { $_ }) | Sort-Object -Unique
        if ($hosts.Count -gt 1) {
            $conflicts.DuplicadosMAC += [PSCustomObject]@{
                MAC      = $mac
                Hostnames= $hosts
                Count    = $hosts.Count
            }
        }
    }

    foreach ($ip in $byIP.Keys) {
        $macs = ($byIP[$ip] | Select-Object -ExpandProperty MAC | Where-Object { $_ }) | Sort-Object -Unique
        if ($macs.Count -gt 1) {
            $conflicts.DuplicadosIP += [PSCustomObject]@{
                IP    = $ip
                MACs  = $macs
                Count = $macs.Count
            }
        }
    }

    return $conflicts
}

$conflicts = Find-Conflicts $results

# ------------------------
# Comparación con escaneos previos (estado persistente)
# ------------------------
Ensure-Dir $StatePath
if (Test-Path $StatePath) {
    try { $prev = Get-Content $StatePath -Raw | ConvertFrom-Json } catch { $prev = $null }
} else { $prev = $null }

# Estructura de estado: por MAC y por IP
$state = [PSCustomObject]@{
    Timestamp = (Get-Date).ToString("s")
    ByMAC = @{}  # MAC -> { Hostnames[], IPs[] }
    ByIP  = @{}  # IP  -> { MACs[], Hostnames[] }
}
foreach ($d in $results) {
    if ($d.MAC) {
        if (-not $state.ByMAC.ContainsKey($d.MAC)) { $state.ByMAC[$d.MAC] = [PSCustomObject]@{ Hostnames=@(); IPs=@() } }
        if ($d.Hostname -and -not ($state.ByMAC[$d.MAC].Hostnames -contains $d.Hostname)) { $state.ByMAC[$d.MAC].Hostnames += $d.Hostname }
        if (-not ($state.ByMAC[$d.MAC].IPs -contains $d.IP)) { $state.ByMAC[$d.MAC].IPs += $d.IP }
    }
    if (-not $state.ByIP.ContainsKey($d.IP)) { $state.ByIP[$d.IP] = [PSCustomObject]@{ MACs=@(); Hostnames=@() } }
    if ($d.MAC -and -not ($state.ByIP[$d.IP].MACs -contains $d.MAC)) { $state.ByIP[$d.IP].MACs += $d.MAC }
    if ($d.Hostname -and -not ($state.ByIP[$d.IP].Hostnames -contains $d.Hostname)) { $state.ByIP[$d.IP].Hostnames += $d.Hostname }
}

# Heurística de conflictos cross-scan (opcionales)
$historicos = [PSCustomObject]@{
    MAC_CambioHostname = @()   # misma MAC con nuevo hostname que no estaba antes
    IP_CambioMAC       = @()   # misma IP con MAC distinta vs escaneo anterior
}
if ($prev) {
    foreach ($mac in $state.ByMAC.Keys) {
        if ($prev.ByMAC.$mac) {
            $newHosts = $state.ByMAC.$mac.Hostnames | Where-Object { -not ($prev.ByMAC.$mac.Hostnames -contains $_) }
            if ($newHosts.Count -gt 0) {
                $historicos.MAC_CambioHostname += [PSCustomObject]@{ MAC=$mac; NuevosHostnames=$newHosts }
            }
        }
    }
    foreach ($ip in $state.ByIP.Keys) {
        if ($prev.ByIP.$ip) {
            $newMACs = $state.ByIP.$ip.MACs | Where-Object { -not ($prev.ByIP.$ip.MACs -contains $_) }
            if ($newMACs.Count -gt 0) {
                $historicos.IP_CambioMAC += [PSCustomObject]@{ IP=$ip; NuevasMACs=$newMACs }
            }
        }
    }
}

# Persistir estado y salidas
Ensure-Dir "$OutputDir\scan.json"
Ensure-Dir "$OutputDir\validation.json"

($state | ConvertTo-Json -Depth 5) | Set-Content $StatePath -Encoding UTF8

$scanOut = [PSCustomObject]@{
    Timestamp   = (Get-Date).ToString("s")
    Subred      = "$BaseIP.0/24"
    Activos     = $aliveCount
    Dispositivos= $results
}
($scanOut | ConvertTo-Json -Depth 5) | Set-Content "$OutputDir\scan.json" -Encoding UTF8

$validationOut = [PSCustomObject]@{
    Timestamp      = (Get-Date).ToString("s")
    Subred         = "$BaseIP.0/24"
    DuplicadosMAC  = $conflicts.DuplicadosMAC
    DuplicadosIP   = $conflicts.DuplicadosIP
    FaltantesMAC   = $conflicts.FaltantesMAC
    Historicos     = $historicos
}
($validationOut | ConvertTo-Json -Depth 5) | Set-Content "$OutputDir\validation.json" -Encoding UTF8

# Resumen en pantalla
Write-Host "Activos: $aliveCount" -ForegroundColor Green
Write-Host "Duplicados MAC: $($conflicts.DuplicadosMAC.Count) | Duplicados IP: $($conflicts.DuplicadosIP.Count) | Faltantes MAC: $($conflicts.FaltantesMAC.Count)" -ForegroundColor Yellow

# Fin: retorna JSON (útil si se invoca desde otra app)
