Write-Host "=== MonitorRed2 v0.7 - Validación de Direcciones ==="
$red = "192.168.100"
$ips = 1..254

# Tabla final
$resultados = @()

# Diccionarios para validar duplicados
$seenMAC = @{}
$seenIP = @{}

function DetectSO {
    param($ttl)

    if ($ttl -ge 100 -and $ttl -le 130) { return "Windows" }
    elseif ($ttl -ge 240) { return "Linux/Unix" }
    else { return "Desconocido" }
}

foreach ($i in $ips) {

    $host = "$red.$i"
    
    # Ping y TTL
    $ping = Test-Connection -Quiet -Count 1 -TTL 128 -TargetName $host 2>$null
    if (-not $ping) { continue }

    $ttl = (Test-Connection -Count 1 $host -ErrorAction SilentlyContinue).IPV4Address.TTL
    $so = DetectSO $ttl

    # MAC vía ARP
    $arp = arp -a $host 2>$null | Select-String $host
    if ($arp) {
        $mac = ($arp.ToString().Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries))[1]
    } else {
        $mac = "N/A"
    }

    # Validar duplicados
    $ipDuplicada = $seenIP.ContainsKey($host)
    $macDuplicada = $seenMAC.ContainsKey($mac)

    if (-not $seenIP.ContainsKey($host)) { $seenIP[$host] = $true }
    if (-not $seenMAC.ContainsKey($mac)) { $seenMAC[$mac] = $true }

    # Guardar en tabla
    $resultados += [PSCustomObject]@{
        IP          = $host
        MAC         = $mac
        SistemaOS   = $so
        IP_Dupl     = if ($ipDuplicada) { "Sí" } else { "No" }
        MAC_Dupl    = if ($macDuplicada) { "Sí" } else { "No" }
    }
}

$resultados | Format-Table -AutoSize

