; Installer Windows di Kino Oracle (Inno Setup 6).
; Uso locale:  iscc /DAppVersion=0.2.0 installer\kino_oracle.iss  (dopo flutter build windows --release)
#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

[Setup]
AppId={{8F6C2B52-3E0B-4B7A-9C1D-4B1F5A3E7C21}
AppName=Kino Oracle
AppVersion={#AppVersion}
AppPublisher=Zenigata
DefaultDirName={autopf}\Kino Oracle
DefaultGroupName=Kino Oracle
OutputDir=..\dist
OutputBaseFilename=KinoOracle-Setup-{#AppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\kino_oracle.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
; Installazione per l'utente corrente: non servono i permessi di amministratore.
PrivilegesRequired=lowest

[Tasks]
Name: "desktopicon"; Description: "Crea un'icona sul desktop"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Kino Oracle"; Filename: "{app}\kino_oracle.exe"
Name: "{autodesktop}\Kino Oracle"; Filename: "{app}\kino_oracle.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\kino_oracle.exe"; Description: "Avvia Kino Oracle"; Flags: nowait postinstall skipifsilent
