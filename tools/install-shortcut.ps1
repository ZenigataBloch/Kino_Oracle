# Crea (o rimuove) il collegamento "Kino Oracle" nel menu Start.
#   Installa:           powershell -ExecutionPolicy Bypass -File tools\install-shortcut.ps1
#   Anche sul desktop:  ... -Desktop
#   Rimuovi:            ... -Remove
param([switch]$Desktop, [switch]$Remove)

$Root     = Split-Path $PSScriptRoot -Parent
$Launcher = Join-Path $PSScriptRoot 'launch.ps1'
$StartDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'

$targets = @((Join-Path $StartDir 'Kino Oracle.lnk'))
if ($Desktop) { $targets += (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Kino Oracle.lnk') }

if ($Remove) {
  foreach ($t in $targets) { Remove-Item $t -ErrorAction SilentlyContinue }
  Write-Host 'Collegamenti rimossi.'
  return
}

$icon  = Join-Path $Root 'windows\runner\resources\app_icon.ico'
$shell = New-Object -ComObject WScript.Shell
foreach ($t in $targets) {
  $lnk = $shell.CreateShortcut($t)
  $lnk.TargetPath       = (Get-Command powershell.exe).Source
  $lnk.Arguments        = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Launcher`""
  $lnk.WorkingDirectory = $Root
  $lnk.Description      = 'Kino Oracle'
  if (Test-Path $icon) { $lnk.IconLocation = $icon }
  $lnk.Save()
  Write-Host "Creato: $t"
}
Write-Host 'Fatto. Cerca "Kino Oracle" nel menu Start (tasto destro > Aggiungi a Start per fissarlo).'
