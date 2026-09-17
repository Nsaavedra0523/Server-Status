#*****************************************************************************
# Nombre del Programa: TestServer
# Versión: 1.0
# Autor: Nicolas Santiago Saavedra Arciniegas
# Fecha de creación: 2025-01-29
#
# Descripción:
# ----------------------------------------------------------------------------
# Este script tiene como objetivo generar una prueba de conexion de host y 
# genera un archivo donde se presentara un documento con los resultados
# obtenidos (.LOG)
#
# Uso:
# ----------------------------------------------------------------------------
# .\TestServer.ps1
#
# Requisitos:
# ----------------------------------------------------------------------------
# - Habilitar la ejecución de scripts
# 		Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# 		Set-Executionpolicy unrestricted -scope CurrentUser
#
# Historial de cambios:
# Versión | Fecha       | Autor                          	   | Descripción
# 1.0     | 2025-01-29  | Nicolas Santiago Saavedra Arciniegas | Versión inicial
#
# Este programa está protegido por las leyes de derechos de autor.


$LOG_PATH = "C:\ServerMonitoring"
# Definir la ruta del archivo log
$LOG_FILE = "ServerStatus_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$LOG_FILE_FULLPATH = Join-Path -Path $LOG_PATH -ChildPath $LOG_FILE

# Crear directorio si no existe
if (-not (Test-Path -Path $LOG_PATH)) {
    New-Item -ItemType Directory -Path $LOG_PATH | Out-Null
}

# Define la lista de servidores y pantallas a validar
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

# Función para escribir en el log y consola
function Write-LogAndConsole {
    param(
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewLine
    )
    
    # Escribir al archivo log (sin colores)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    if ($NoNewLine) {
        $logMessage | Out-File -FilePath $LOG_FILE_FULLPATH -Append -NoNewline
    } else {
        $logMessage | Out-File -FilePath $LOG_FILE_FULLPATH -Append
    }
    
    # Escribir a la consola (con colores)
    if ($NoNewLine) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $Color
    }
}

# Función para validar un servidor con reintentos
function Test-ServerStatus {
    param(
        [string]$ServerName,
        [int]$MaxRetries = 3,
        [int]$RetryDelay = 5  # Segundos entre intentos
    )
    
    $results = @{
        ServerName = $ServerName
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Status = "FAIL"
        ResponseTime = $null
        Details = ""
        AttemptsMade = 0
    }
    
    Write-LogAndConsole "Iniciando prueba para servidor: $ServerName" -Color Cyan
    
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            Write-LogAndConsole "  Intento $attempt de $MaxRetries para $ServerName..." -Color Yellow -NoNewLine
            $ping = Test-Connection -ComputerName $ServerName -Count 1 -ErrorAction Stop
            
            if ($ping) {
                $results.Status = "OK"
                $results.ResponseTime = $ping.ResponseTime
                $results.Details = "Conectividad exitosa en el intento $attempt"
                $results.AttemptsMade = $attempt
                
                Write-LogAndConsole " [" -NoNewLine
                Write-LogAndConsole "OK" -Color Green -NoNewLine
                Write-LogAndConsole "] - $($ping.ResponseTime)ms"
                break
            }
        }
        catch {
            $results.Details = "Intento $attempt $($_.Exception.Message)"
            if ($attempt -eq $MaxRetries) {
                Write-LogAndConsole " [" -NoNewLine
                Write-LogAndConsole "FAIL" -Color Red -NoNewLine
                Write-LogAndConsole "]"
                Write-LogAndConsole "  Error: $($_.Exception.Message)" -Color Red
            } else {
                Write-LogAndConsole " Reintentando..." -Color Yellow
                Start-Sleep -Seconds $RetryDelay
            }
        }
        $results.AttemptsMade = $attempt
    }
    
    return New-Object PSObject -Property $results
}

# Función principal de monitoreo
function Start-ServerMonitoring {
    try {
        $startTime = Get-Date
        
        Write-LogAndConsole "`n=== Iniciando monitoreo de servidores ===" -Color Cyan
        Write-LogAndConsole "Fecha y hora de inicio: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -Color Cyan
        Write-LogAndConsole "Total de servidores a validar: $($SERVERS.Count)" -Color Cyan
        Write-LogAndConsole "----------------------------------------`n"
        
        # Array para almacenar resultados
        $ServerStatus = @()
        
        # Validar cada servidor
        foreach ($server in $SERVERS) {
            $status = Test-ServerStatus -ServerName $server
            $ServerStatus += $status
        }
        
        # Mostrar resumen
        Write-LogAndConsole "`n=== Resumen de resultados ===" -Color Cyan
        foreach ($status in $ServerStatus) {
            $statusColor = if ($status.Status -eq "OK") { "Green" } else { "Red" }
            $statusText = if ($status.Status -eq "OK") { 
                "OK   - $($status.ResponseTime)ms" 
            } else { 
                "FAIL - $($status.Details)" 
            }
            
            Write-LogAndConsole $status.ServerName.PadRight(15) -NoNewLine
            Write-LogAndConsole " [ " -NoNewLine
            Write-LogAndConsole $status.Status -Color $statusColor -NoNewLine
            Write-LogAndConsole " ] " -NoNewLine
            Write-LogAndConsole $statusText
        }
        
        # Mostrar estadísticas finales
        $totalServers = $SERVERS.Count
        $ServersOK = ($ServerStatus | Where-Object { $_.Status -eq "OK" }).Count
        $ServersFail = ($ServerStatus | Where-Object { $_.Status -eq "FAIL" }).Count
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        Write-LogAndConsole "`n=== Estadisticas Finales ===" -Color Cyan
        Write-LogAndConsole "Total de servidores : $totalServers"
        Write-LogAndConsole "Servidores OK      : $ServersOK" -Color Green
        Write-LogAndConsole "Servidores FAIL    : $ServersFail" -Color Red
        Write-LogAndConsole "Tiempo total       : $($duration.ToString('mm\:ss')) minutos"
        Write-LogAndConsole "----------------------------------------"
    }
    catch {
        $errorMessage = "Error en el monitoreo: $($_.Exception.Message)"
        Write-LogAndConsole $errorMessage -Color Red
    }
    finally {
        Write-LogAndConsole "`nLog file creado en: $LOG_FILE_FULLPATH" -Color Cyan
    }
}

# Iniciar el monitoreo una sola vez
Start-ServerMonitoring