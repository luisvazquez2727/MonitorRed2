# ===============================================================
# ScanRed_v0.6.ps1
# MonitorRed2 - Escaneo /24 + Fabricante + SO + Puertos v6
# ===============================================================

param(
    [string]$BaseIP    = "192.168.100",
    [int]   $TimeoutMs = 1000
)

# ==========================
# DICCIONARIO OUI
# ==========================
$OUIMap = @{

    # Microcontroladores
    "FC:AA:14" = "Espressif Inc. (ESP32)"
    "24:6F:28" = "Espressif Inc. (ESP8266/ESP32)"
    "84:CC:A8" = "Espressif Inc."
    "DC:4F:22" = "Raspberry Pi Foundation"
    "B8:27:EB" = "Raspberry Pi Foundation"

    # Routers y telecom
    "00:1A:2B" = "Cisco Systems"
    "3C:5A:B4" = "TP-Link Technologies"
    "C0:25:E9" = "Ubiquiti Networks"
    "F0:9F:C2" = "Huawei Technologies"
    "C0:F6:C2" = "ARRIS Group, Inc."
    "EC:C1:AB" = "Foxconn (Hon Hai)"

    # PCs y móviles
    "BC:92:6B" = "Samsung Electronics"
    "F4:0F:24" = "Apple Inc."
    "28:E7:CF" = "Apple Inc."
    "04:E8:B9" = "Intel Corporation"
    "00:1C:B3" = "Dell Inc."
    "00:50:56" = "VMware Inc."
    "3C:07:54" = "LG Electronics"
    "F8:D0:27" = "AzureWave"

    # Otros
    "00:17:88" = "HP"
    "00:1D:D8" = "Sony Corporation"
    "00:21:5C" = "Microsoft Corporation"
    "00:0C:29" = "VMware Inc."
}

# ==========================
# FUNCIONES
# ==========================

function Get-HostName {
    param([string]$ip)
    try {
        $dns = Resolve-DnsName -Name $ip -ErrorAction Stop
        $ptr = $dns | Where-Object { $_.Type -eq 'PTR' } | Select-Object -First 1
        if ($ptr -and $ptr.NameHost) { return $ptr.NameHost }
    } catch {}

    try {
        $out = nbtstat -A $ip 2>$null
        foreach ($line in $out) {
            if ($line -match '^\s*(\S+)\s+<00>\s+UNIQUE') { return $Matches[1] }
        }
    } catch {}

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
                return ($mac -replace '-', ':' ).ToUpper()
            }
        }
    } catch {}
    return $null
}

function Get-Manufacturer {
    param([string]$mac)
    if (-not $mac) { return "N/A" }
    $prefix = ($mac -split ':')[0..2] -join ':'
    if ($OUIMap.ContainsKey($prefix)) { return $OUIMap[$prefix] }
    return "Desconocido"
}

function Detect-OS {
    param([string]$ttl)

    if (-not $ttl) { return "Desconocido" }
    $ttl = [int]$ttl

    if ($ttl -ge 100 -and $ttl -le 130) { return "Windows" }
    if ($ttl -ge 240 -and $ttl -le 255) { return "Linux" }
    return "Desconocido"
}

# ==========================
# ESCANEO RED /24 (V5)
# ==========================

function Escanear-Red {

    Clear-Host
    Write-Host "=== MonitorRed2 v0.6 - Escaneo /24 con SO y MAC ===" -ForegroundColor Cyan
    Write-Host "Red objetivo: $BaseIP.0/24`n"

    Write-Host "IP`tMAC Address`tFabricante`t`tSistema Operativo"

    for ($i = 1; $i -le 254; $i++) {

        $ip = "$BaseIP.$i"

        $reply = ping.exe -n 1 -w $TimeoutMs $ip | Select-String "TTL="

        if ($reply) {

            $ttl = ($reply -split "TTL=")[1] -split " " | Select-Object -First 1
            $so  = Detect-OS -ttl $ttl

            $mac = Get-MacFromArp -ip $ip
            $vendor = Get-Manufacturer -mac $mac

            Write-Host "$ip`t$mac`t$vendor`t`t$so"
        }
    }

    Write-Host "`nEscaneo completado.`n"
    Read-Host "ENTER para regresar al menú"
}

# =======================================================
#   MÓDULO v6 – ESCANEO DE PUERTOS (TCP/UDP)
# =======================================================
function Escanear-Puertos {

    Clear-Host
    Write-Host "`n===== ESCANEO DE PUERTOS IMPORTANTES (TCP + UDP) =====`n"

    $ListaPuertos = @(
        @{Puerto=21; Protocolo="TCP"; Servicio="FTP Control"}
        @{Puerto=22; Protocolo="TCP"; Servicio="SSH"}
        @{Puerto=23; Protocolo="TCP"; Servicio="Telnet"}
        @{Puerto=25; Protocolo="TCP"; Servicio="SMTP"}
        @{Puerto=80; Protocolo="TCP"; Servicio="HTTP"}
        @{Puerto=110; Protocolo="TCP"; Servicio="POP3"}
        @{Puerto=135; Protocolo="TCP"; Servicio="RPC"}
        @{Puerto=139; Protocolo="TCP"; Servicio="NetBIOS Session"}
        @{Puerto=143; Protocolo="TCP"; Servicio="IMAP"}
        @{Puerto=443; Protocolo="TCP"; Servicio="HTTPS"}
        @{Puerto=445; Protocolo="TCP"; Servicio="SMB"}
        @{Puerto=465; Protocolo="TCP"; Servicio="SMTPS"}
        @{Puerto=587; Protocolo="TCP"; Servicio="SMTP Submission"}
        @{Puerto=993; Protocolo="TCP"; Servicio="IMAPS"}
        @{Puerto=995; Protocolo="TCP"; Servicio="POP3S"}
        @{Puerto=1433; Protocolo="TCP"; Servicio="SQL Server"}
        @{Puerto=1521; Protocolo="TCP"; Servicio="Oracle DB"}
        @{Puerto=3306; Protocolo="TCP"; Servicio="MySQL"}
        @{Puerto=3389; Protocolo="TCP"; Servicio="RDP"}
        @{Puerto=5432; Protocolo="TCP"; Servicio="PostgreSQL"}
        @{Puerto=5900; Protocolo="TCP"; Servicio="VNC"}
        @{Puerto=8080; Protocolo="TCP"; Servicio="HTTP-ALT"}

        # ========= UDP =========
        @{Puerto=53;    Protocolo="UDP"; Servicio="DNS"}
        @{Puerto=67;    Protocolo="UDP"; Servicio="DHCP Server"}
        @{Puerto=68;    Protocolo="UDP"; Servicio="DHCP Client"}
        @{Puerto=69;    Protocolo="UDP"; Servicio="TFTP"}
        @{Puerto=123;   Protocolo="UDP"; Servicio="NTP"}
        @{Puerto=137;   Protocolo="UDP"; Servicio="NetBIOS NS"}
        @{Puerto=138;   Protocolo="UDP"; Servicio="NetBIOS DS"}
        @{Puerto=161;   Protocolo="UDP"; Servicio="SNMP"}
        @{Puerto=162;   Protocolo="UDP"; Servicio="SNMP Trap"}
        @{Puerto=514;   Protocolo="UDP"; Servicio="Syslog"}
        @{Puerto=520;   Protocolo="UDP"; Servicio="RIP Routing"}
        @{Puerto=1812;  Protocolo="UDP"; Servicio="RADIUS Auth"}
        @{Puerto=1813;  Protocolo="UDP"; Servicio="RADIUS Accounting"}
        @{Puerto=1900;  Protocolo="UDP"; Servicio="SSDP"}
        @{Puerto=4500;  Protocolo="UDP"; Servicio="IPSec NAT-T"}
        @{Puerto=5353;  Protocolo="UDP"; Servicio="mDNS"}
    )

    $Resultados = foreach ($item in $ListaPuertos) {

        if ($item.Protocolo -eq "TCP") {

            $PuertoEstado = Get-NetTCPConnection -LocalPort $item.Puerto -ErrorAction SilentlyContinue

        } else {

            $PuertoEstado = netstat -ano | Select-String ":$($item.Puerto)" | Select-String "UDP"
        }

        if ($PuertoEstado) {
            [PSCustomObject]@{
                Puerto    = $item.Puerto
                Protocolo = $item.Protocolo
                Servicio  = $item.Servicio
                Estado    = "ABIERTO"
            }
        }
        else {
            [PSCustomObject]@{
                Puerto    = $item.Puerto
                Protocolo = $item.Protocolo
                Servicio  = $item.Servicio
                Estado    = "CERRADO"
            }
        }
    }

    Write-Host "`n===== RESULTADOS =====`n"
    $Resultados | Format-Table -AutoSize

    Write-Host "`nPresiona ENTER para volver al menú..."
    Read-Host
}

# ==========================
# MENÚ PRINCIPAL
# ==========================

do {
    Clear-Host
    Write-Host "=== MONITORRED2 - MENU ===`n"
    Write-Host "1) Escanear red /24 (MAC + SO)"
    Write-Host "6) Escaneo de puertos importantes"
    Write-Host "0) Salir"
    Write-Host ""
    $op = Read-Host "Selecciona una opción"

    switch ($op) {
        1 { Escanear-Red }
        6 { Escanear-Puertos }
        0 { break }
        default { Write-Host "Opción inválida"; Start-Sleep 1 }
    }

} while ($true)
