# MonitorRed2

Herramienta sencilla para escanear redes IPv4 /24 en Windows PowerShell 5.1.

## Versiones
- **v0.1.0**: IPs activas (ping simple), `scripts/ScanRed_v0.1.ps1`
- **v0.2.0**: (opcional) IP + nombre de equipo, `scripts/ScanRed_v0.2.ps1`
- **v0.3.0**: (opcional) IP + nombre de equipo + mas address, `scripts/ScanRed_v0.3.ps1`
- **v0.4.0**: IP + nombre + MAC + fabricante, `scripts/ScanRed_v0.4.ps1`
- **v0.5.0: IP + nombre + MAC + fabricante + detección de sistema operativo (TTL),      `scripts/ScanRed_v0.5.ps1`

## Uso
```powershell
# v0.1 (ping simple)
.\scripts\ScanRed_v0.1.ps1

# v0.2 (IP + nombre)
.\scripts\ScanRed_v0.2.ps1 

todos siguen la misma logica

```

## Requisitos
- Windows PowerShell 5.1
- Permisos para ejecutar scripts:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```
