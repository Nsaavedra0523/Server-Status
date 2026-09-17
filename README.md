# TestServer

Script de PowerShell para monitorear la conectividad de un conjunto de servidores mediante `ping` (ICMP), con reintentos automáticos y generación de un log detallado con los resultados.

## Descripción

`Test_Servers.ps1` recorre una lista predefinida de servidores y verifica su disponibilidad en red usando `Test-Connection`. Por cada servidor:

- Realiza hasta 3 intentos de conexión (configurable).
- Espera 5 segundos entre reintentos fallidos (configurable).
- Registra el resultado (éxito o falla) junto con el tiempo de respuesta.

Al finalizar, imprime un resumen en consola (con colores) y estadísticas finales (total de servidores, cuántos respondieron OK, cuántos fallaron y el tiempo total de ejecución). Todo el proceso queda documentado en un archivo `.log`.

## Requisitos

- Windows con PowerShell.
- Permisos para ejecutar scripts. Si la ejecución está restringida, habilitarla con uno de los siguientes comandos:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# o
Set-ExecutionPolicy Unrestricted -Scope CurrentUser
```

## Uso

```powershell
.\Test_Servers.ps1
```

El script no recibe parámetros por línea de comandos; la configuración se edita directamente en el archivo (ver sección siguiente).

## Configuración

### Ruta y nombre del log

```powershell
$LOG_PATH = "C:\ServerMonitoring"
$LOG_FILE = "ServerStatus_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
```

- El directorio `$LOG_PATH` se crea automáticamente si no existe.
- Cada ejecución genera un archivo de log nuevo, con marca de fecha y hora en el nombre (formato `yyyyMMdd_HHmmss`).

### Lista de servidores

```powershell
$SERVERS = @(
    "dc01",
    "dc02",
    "dc03",
    "dc04",
    "dc05",
    "dc06",
    "l-car-003-b",
    "l-car-002-c",
    "l-car-001-c"
)
```

Editar este arreglo para agregar, quitar o cambiar los nombres/hosts a validar.

### Reintentos

Dentro de la función `Test-ServerStatus`:

```powershell
[int]$MaxRetries = 3
[int]$RetryDelay = 5  # segundos entre intentos
```

Ambos valores se pueden ajustar según la tolerancia deseada a fallos temporales de red.

## Salida

### En consola

- Progreso en tiempo real por servidor, con colores:
  - **Verde**: conexión exitosa (`OK`).
  - **Rojo**: fallo de conexión (`FAIL`).
  - **Amarillo/Cian**: mensajes informativos y de reintento.
- Un resumen final con el estado de cada servidor y las estadísticas totales (servidores OK, servidores FAIL y duración total del monitoreo).

### En archivo de log

Se genera un archivo de texto plano (sin colores) en `C:\ServerMonitoring\ServerStatus_<fecha_hora>.log` con el mismo contenido mostrado en consola, útil para auditoría o revisión posterior.

## Estructura del script

| Función                  | Descripción                                                                 |
|---------------------------|------------------------------------------------------------------------------|
| `Write-LogAndConsole`      | Escribe simultáneamente en consola (con color) y en el archivo de log.       |
| `Test-ServerStatus`        | Ejecuta la prueba de ping a un servidor específico, con reintentos.          |
| `Start-ServerMonitoring`   | Función principal: orquesta el monitoreo de todos los servidores y muestra el resumen y las estadísticas finales. |

## Notas

- El script se ejecuta una sola vez por invocación; para monitoreo continuo se puede programar como tarea (Task Scheduler) o incorporar un ciclo externo.
- El campo `Details` de cada resultado almacena el mensaje de error específico cuando una prueba falla, útil para diagnóstico.

## Autor

Nicolas Santiago Saavedra Arciniegas

## Historial de cambios

| Versión | Fecha       | Autor                                | Descripción      |
|---------|-------------|---------------------------------------|-------------------|
| 1.0     | 2025-01-29  | Nicolas Santiago Saavedra Arciniegas | Versión inicial   |
