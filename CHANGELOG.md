# CHANGELOG – MonitorRed2

> Formato: SemVer (MAJOR.MINOR.PATCH)
> - **MAJOR**: cambios incompatibles.
> - **MINOR**: nuevas funcionalidades compatibles.
> - **PATCH**: correcciones.

## [v0.3.0] - 2025-12-08
### Añadido
- Muestra **MAC Address** (si está disponible en ARP tras el ping).
- Mantiene resolución de **nombre de equipo** (DNS/NetBIOS).
- Archivo: `scripts/ScanRed_v0.3.ps1`.

### Notas
- La MAC se obtiene de la tabla **ARP** local; solo válida para hosts en el mismo segmento de red (L2).


## [v0.2.0] - 2025-12-08
### Añadido
- Escaneo /24 muestra **nombre de equipo** (DNS/NetBIOS, si está disponible).
- Archivo: `scripts/ScanRed_v0.2.ps1`.

### Notas
- En algunas redes, DNS/NetBIOS pueden estar deshabilitados.

## [v0.1.0] - 2025-12-08
### Añadido
- Escaneo simple **/24** usando `ping.exe` con timeout configurable.
- Muestra IPs activas en consola.
- Archivo: `scripts/ScanRed_v0.1.ps1`.
