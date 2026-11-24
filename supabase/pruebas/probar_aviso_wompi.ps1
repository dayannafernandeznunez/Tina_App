# Prueba si el secreto de eventos guardado en Supabase es el mismo que el de Wompi.
#
# Arma un aviso de mentira (para un pedido que no existe, TINA-9999-1), lo firma
# con el secreto que escribas aqui y se lo manda a la funcion wompi-eventos.
#   - Si la funcion lo ACEPTA, el secreto guardado en Supabase es el correcto.
#   - Si lo RECHAZA (401), el secreto guardado no es el que escribiste.
# No cambia nada de la tienda y el secreto no sale de tu computador: solo se manda
# la firma que resulta de usarlo.
#
# Como correrlo (en PowerShell, desde la carpeta del proyecto):
#   powershell -ExecutionPolicy Bypass -File .\supabase\pruebas\probar_aviso_wompi.ps1

param(
  [string]$Secreto = '',
  [string]$Url = 'https://nklkvmxqtipdvvmmmaan.supabase.co/functions/v1/wompi-eventos'
)

$ErrorActionPreference = 'Stop'

if ($Secreto -eq '') {
  Write-Host ''
  Write-Host 'En Wompi (modo de pruebas): Desarrolladores > fila "Eventos" > Mostrar.'
  $seguro = Read-Host 'Pega aqui el secreto de EVENTOS (no se ve al pegarlo)' -AsSecureString
  $Secreto = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($seguro))
}
$Secreto = $Secreto.Trim().Trim('"', "'").Trim()

# Si se pegaron los asteriscos del valor oculto, no hay nada que probar.
if ($Secreto -match '^[*]+$') {
  Write-Host ''
  Write-Host 'Lo que pegaste son ASTERISCOS (el valor oculto de Wompi), no el secreto.' -ForegroundColor Red
  Write-Host 'En Wompi, en la fila "Eventos", presiona primero "Mostrar": los asteriscos'
  Write-Host 'se cambian por el secreto de verdad, que empieza por test_events_.'
  Write-Host 'Copia ESE valor y vuelve a correr esta prueba.'
  exit 1
}

Write-Host ''
$empieza = $Secreto.Substring(0, [Math]::Min(12, $Secreto.Length))
Write-Host "El secreto que pegaste mide $($Secreto.Length) caracteres y empieza por: $empieza"
if (-not $Secreto.StartsWith('test_events_')) {
  Write-Host 'AVISO: el secreto de eventos de pruebas debe empezar por test_events_.'
}

$ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$texto = "PRUEBA-LOCAL-1APPROVED100$ts$Secreto"
$sha = [Security.Cryptography.SHA256]::Create()
$checksum = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($texto))).Replace('-', '')

$evento = @{
  event       = 'transaction.updated'
  data        = @{ transaction = @{
      id              = 'PRUEBA-LOCAL-1'
      status          = 'APPROVED'
      amount_in_cents = 100
      reference       = 'TINA-9999-1'
  } }
  environment = 'test'
  signature   = @{
    properties = @('transaction.id', 'transaction.status', 'transaction.amount_in_cents')
    checksum   = $checksum
  }
  timestamp   = $ts
  sent_at     = (Get-Date).ToUniversalTime().ToString('o')
} | ConvertTo-Json -Depth 6

try {
  $r = Invoke-WebRequest -Uri $Url -Method Post -ContentType 'application/json' -Body $evento -UseBasicParsing
  $codigo = [int]$r.StatusCode
  $cuerpo = $r.Content
} catch {
  $codigo = [int]$_.Exception.Response.StatusCode
  $lector = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())
  $cuerpo = $lector.ReadToEnd()
}

Write-Host ''
Write-Host "Respuesta de la funcion: $codigo  $cuerpo"
Write-Host ''
if ($codigo -eq 200) {
  Write-Host 'ACEPTADO: el secreto guardado en Supabase es el MISMO que escribiste.' -ForegroundColor Green
  Write-Host 'Si el secreto que escribiste es el de verdad (empieza por test_events_), ya esta bien.'
} elseif ($codigo -eq 401) {
  Write-Host 'RECHAZADO: el secreto guardado en Supabase NO es el que escribiste.' -ForegroundColor Red
  Write-Host 'Revisa en Supabase > Edge Functions > Secrets que el nombre sea exactamente'
  Write-Host 'WOMPI_EVENTS_SECRET y que el valor sea este mismo, sin espacios ni comillas.'
  Write-Host 'Despues de guardarlo, vuelve a correr esta prueba.'
} else {
  Write-Host 'Respuesta inesperada. Copiame la linea de "Respuesta de la funcion" de arriba.'
}
