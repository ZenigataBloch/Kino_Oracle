# Kino Oracle - launcher con aggiornamento automatico (Windows)
# - controlla se su GitHub ci sono nuovi commit; se si: git pull + build + deploy
# - avvia l'app da .run\ (cosi si puo ricompilare mentre l'app e aperta)
# - mentre l'app e aperta ricontrolla ogni N minuti e, se c'e un aggiornamento,
#   lo prepara in background e poi riavvia l'app.
param(
  [int]$CheckMinutes = 30,   # 0 = non controllare mentre l'app e aperta
  [switch]$NoUpdate          # salta ogni controllo aggiornamenti
)

$ErrorActionPreference = 'Continue'
$Root    = Split-Path $PSScriptRoot -Parent
$Release = Join-Path $Root 'build\windows\x64\runner\Release'
$RunDir  = Join-Path $Root '.run'
$Exe     = Join-Path $RunDir 'kino_oracle.exe'
$Log     = Join-Path $PSScriptRoot 'launcher.log'
Set-Location $Root

function Log($m) { ("{0}  {1}" -f (Get-Date -Format 's'), $m) | Out-File -FilePath $Log -Append -Encoding utf8 }

# Esegue un comando, ne scrive l'output nel log (UTF-8) e lo restituisce come testo.
# Il codice di uscita resta in $LASTEXITCODE.
function Run-Logged([string]$cmd, [string[]]$cmdArgs) {
  $out = & $cmd @cmdArgs 2>&1 | ForEach-Object { "$_" }
  $code = $LASTEXITCODE
  if ($out) { $out | Out-File -FilePath $Log -Append -Encoding utf8 }
  $global:LASTEXITCODE = $code
  return ($out -join "`n")
}

# Notifiche (fumetto nella barra delle applicazioni)
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$script:tray = New-Object System.Windows.Forms.NotifyIcon
$script:tray.Icon = [System.Drawing.SystemIcons]::Information
$script:tray.Visible = $true
function Notify($text, $icon = 'Info') {
  Log $text
  $script:tray.BalloonTipTitle = 'Kino Oracle'
  $script:tray.BalloonTipText  = $text
  $script:tray.BalloonTipIcon  = $icon
  $script:tray.ShowBalloonTip(6000)
}
function Close-Tray { $script:tray.Visible = $false; $script:tray.Dispose() }

# Se flutter non e nel PATH, prova le cartelle piu comuni
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  foreach ($d in 'C:\dev\flutter\bin', "$env:USERPROFILE\dev\flutter\bin", 'C:\src\flutter\bin') {
    if (Test-Path (Join-Path $d 'flutter.bat')) { $env:Path += ";$d"; break }
  }
}

function Test-UpdateAvailable {
  & git fetch --quiet origin *> $null
  if ($LASTEXITCODE -ne 0) { return $false }          # offline: non e un errore
  $behind = & git rev-list --count 'HEAD..@{u}'
  return ([int]$behind -gt 0)
}

function Pull-Latest {
  Run-Logged 'git' @('pull', '--ff-only') | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'git pull non riuscito (hai modifiche locali non salvate?)' }
}

function Build-App {
  Run-Logged 'flutter' @('pub', 'get') | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'flutter pub get non riuscito (vedi launcher.log)' }
  $buildArgs = @('build', 'windows', '--release')
  if (Test-Path (Join-Path $Root 'env.json')) { $buildArgs += '--dart-define-from-file=env.json' }
  $text = Run-Logged 'flutter' $buildArgs
  if ($LASTEXITCODE -ne 0) {
    if ($text -match 'symlink') {
      Start-Process 'ms-settings:developer'
      throw 'Attiva la Modalita sviluppatore di Windows (ho aperto le impostazioni), poi riavvia Kino Oracle.'
    }
    if ($text -match 'Visual Studio') {
      throw 'Manca Visual Studio con il carico "Sviluppo di applicazioni desktop con C++" (vedi launcher.log).'
    }
    throw 'flutter build non riuscito (vedi launcher.log)'
  }
}

function Deploy-App {
  & robocopy $Release $RunDir /MIR /NFL /NDL /NJH /NJS /NP *> $null
  if ($LASTEXITCODE -ge 8) { throw 'copia dei file fallita' }
  $global:LASTEXITCODE = 0
}

# --- Avvio ---------------------------------------------------------------------
if (Get-Process -Name kino_oracle -ErrorAction SilentlyContinue) {
  Log 'App gia in esecuzione: esco.'
  Close-Tray
  exit
}

try {
  $needBuild = -not (Test-Path $Exe)
  if (-not $NoUpdate -and (Test-UpdateAvailable)) {
    Notify 'Aggiornamento trovato: scarico e compilo, un attimo...'
    Pull-Latest
    $needBuild = $true
  } elseif ($needBuild) {
    Notify 'Prima installazione: compilazione in corso (qualche minuto)...'
  }
  if ($needBuild) { Build-App; Deploy-App }
} catch {
  Notify ("Errore: " + $_.Exception.Message) 'Error'
}

if (-not (Test-Path $Exe)) {
  Notify 'Impossibile avviare: nessuna versione compilata. Controlla launcher.log' 'Error'
  Start-Sleep -Seconds 8
  Close-Tray
  exit 1
}

$app = Start-Process -FilePath $Exe -WorkingDirectory $RunDir -PassThru

if ($NoUpdate -or $CheckMinutes -le 0) { Close-Tray; exit }

# --- Controllo periodico mentre l'app e aperta -------------------------------
$next = (Get-Date).AddMinutes($CheckMinutes)
while (-not $app.HasExited) {
  Start-Sleep -Seconds 5
  if ((Get-Date) -lt $next) { continue }
  $next = (Get-Date).AddMinutes($CheckMinutes)
  try {
    if (Test-UpdateAvailable) {
      Notify 'Nuova versione trovata: la preparo in background...'
      Pull-Latest
      Build-App
      Notify "Aggiornamento pronto: riavvio l'app."
      $app.CloseMainWindow() | Out-Null
      if (-not $app.WaitForExit(5000)) { $app.Kill(); $app.WaitForExit() }
      Deploy-App
      $app = Start-Process -FilePath $Exe -WorkingDirectory $RunDir -PassThru
    }
  } catch {
    Notify ("Aggiornamento non riuscito: " + $_.Exception.Message) 'Error'
  }
}
Close-Tray
