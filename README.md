# Kino Oracle

Gioco/oracolo di connessioni tra attori e film (stile Oracle of Bacon).

## Setup
```
git clone https://github.com/ZenigataBloch/Kino_Oracle.git
cd Kino_Oracle
flutter create --org it.zenigata --project-name kino_oracle --platforms=windows,android,web .
# copia qui sopra lib/ e pubspec.yaml di questo scheletro (sovrascrivendo)
flutter pub get
flutter run -d chrome --dart-define=TMDB_TOKEN=LA_TUA_CHIAVE
```
Senza `--dart-define` l'app usa Wikidata. La chiave TMDB puo essere il "Read Access Token" (v4) o la "API Key" (v3).
**Non scrivere mai la chiave nel codice e non committarla su GitHub.**

Su Android aggiungi in android/app/src/main/AndroidManifest.xml:
`<uses-permission android:name="android.permission.INTERNET"/>`

## Crediti (da mostrare nell'app)
- TMDB: "This product uses the TMDB API but is not endorsed or certified by TMDB." + logo TMDB.
- Wikidata (CC0); immagini da Wikimedia Commons, ciascuna con la propria licenza.

## Struttura
- lib/theme: stili grafici e impostazioni
- lib/data: DataSource (interfaccia), tmdb.dart, wikidata.dart
- lib/game: stato del tavolo e validazione dei collegamenti
- lib/ui: schermate e painter della mappa

## Avvio da menu Start con aggiornamento automatico (Windows)
```
powershell -ExecutionPolicy Bypass -File tools\install-shortcut.ps1          # menu Start
powershell -ExecutionPolicy Bypass -File tools\install-shortcut.ps1 -Desktop  # anche desktop
powershell -ExecutionPolicy Bypass -File tools\install-shortcut.ps1 -Remove   # rimuove
```
Il collegamento avvia `tools/launch.ps1`: a ogni avvio controlla GitHub, e se ci sono nuovi commit
fa `git pull`, ricompila (`flutter build windows --release`, con `env.json` se presente) e avvia l'app
da `.run/`. Mentre l'app e aperta ricontrolla ogni 30 minuti e, se serve, aggiorna e la riavvia.
Il log e in `tools/launcher.log`. Aggiungi a `.gitignore`: `.run/` e `tools/launcher.log`.

## Icona
Le immagini sono in `assets/icon/`. Per applicarle ad Android e Windows:
```
flutter pub get
dart run flutter_launcher_icons
```
(sovrascrive `windows/runner/resources/app_icon.ico` e le icone `mipmap` di Android).
