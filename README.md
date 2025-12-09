# MonitorRed2

Herramienta sencilla para escanear redes IPv4 /24 en Windows PowerShell 5.1.

## Versiones
- **v0.1.0**: IPs activas (ping simple), `scripts/ScanRed_v0.1.ps1`
- **v0.2.0**: (opcional) IP + nombre de equipo, `scripts/ScanRed_v0.2.ps1`
- **v0.3.0**: (opcional) IP + nombre de equipo + mas address, `scripts/ScanRed_v0.3.ps1

## Uso
```powershell
# v0.1 (ping simple)
.\scripts\ScanRed_v0.1.ps1 192.168.100

# v0.2 (IP + nombre)
.\scripts\ScanRed_v0.2.ps1 192.168.100

# v0.3 (IP + nombre + mac address)
.\scripts\ScanRed_v0.3.ps1 192.168.100
```

## Requisitos
- Windows PowerShell 5.1
- Permisos para ejecutar scripts:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```
