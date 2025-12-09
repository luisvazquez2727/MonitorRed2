# CHANGELOG – MonitorRed2

> Formato: SemVer (MAJOR.MINOR.PATCH)
> - **MAJOR**: cambios incompatibles.
> - **MINOR**: nuevas funcionalidades compatibles.
> - **PATCH**: correcciones.

## [v0.5.0] - 2025-12-xx
### Añadido
- Detección del **Sistema Operativo (OS)** por análisis de **TTL**.
- Ahora cada host muestra: IP, nombre, MAC, fabricante y sistema operativo.
- Archivo: `scripts/ScanRed_v0.5.ps1`.

### Notas
- La detección de SO por TTL es aproximada, no exacta.
- Los valores TTL dependen de routers intermedios

## [v0.4.0] - 2025-12-08
### Añadido
- Obtiene el **fabricante** (Vendor) de la MAC usando la base OUI.
- Muestra **IP + nombre de equipo + MAC + fabricante**.
- Archivo: `scripts/ScanRed_v0.4.ps1`.

### Notas
- El fabricante depende de la tabla OUI cargada localmente.
- Solo visible si la MAC se pudo obtener desde ARP.

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
