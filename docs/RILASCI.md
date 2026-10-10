# Rilasci e aggiornamenti

## Come si pubblica una versione
1. Aggiorna `version:` in `pubspec.yaml` (facoltativo: la CI usa il nome del tag).
2. Crea e invia un tag:
   ```
   git tag v0.2.0
   git push origin v0.2.0
   ```
3. GitHub Actions (`.github/workflows/release.yml`) compila:
   - **Android**: `KinoOracle-<versione>.apk`
   - **Windows**: `KinoOracle-Setup-<versione>.exe` (installer) e `KinoOracle-windows-<versione>.zip` (portatile)

   e pubblica tutto nella pagina **Releases** del repository. Si può avviare anche a mano dalla scheda *Actions* (in quel caso i file restano negli *artifact* del run).

Ogni push su `main` e ogni pull request eseguono `flutter analyze` e `flutter test` (`ci.yml`).

## Secret da configurare (Settings → Secrets and variables → Actions)
| Secret | A cosa serve |
|---|---|
| `TMDB_TOKEN` | chiave TMDB incorporata nell'app (se manca, l'app usa Wikidata) |
| `ANDROID_KEYSTORE_BASE64` | keystore di firma, codificato in base64 |
| `ANDROID_KEYSTORE_PASSWORD` | password del keystore |
| `ANDROID_KEY_PASSWORD` | password della chiave |
| `ANDROID_KEY_ALIAS` | alias della chiave |

Il token TMDB incorporato in un'app distribuita si può estrarre: usa un token di sola lettura e rigeneralo se serve.

### Chiave di firma Android (una volta sola)
```
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias kino
base64 -w0 upload-keystore.jks    # su Windows PowerShell: [Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks"))
```
Incolla il risultato in `ANDROID_KEYSTORE_BASE64`. **Conserva il file `.jks` e le password in un posto sicuro**: se perdi la chiave, gli utenti non potranno più aggiornare l'app sopra la versione installata (dovranno disinstallarla). Senza questi secret l'APK viene firmato con la chiave di debug, che cambia a ogni build, e l'aggiornamento sopra una versione precedente fallisce.

## Piano per gli aggiornamenti via GitHub
1. **Subito (già pronto):** si scarica l'ultima versione dalla pagina Releases. Android aggiorna l'APK installandolo sopra (stessa firma, `build-number` crescente = numero del run). Windows: si esegue il nuovo installer, che sostituisce la versione precedente.
2. **Controllo in-app (da fare):** all'avvio, `GET https://api.github.com/repos/ZenigataBloch/Kino_Oracle/releases/latest`, confronto tra `tag_name` e la versione installata (pacchetto `package_info_plus`) e, se più nuova, una finestra "Aggiornamento disponibile" con il link alla release (`url_launcher`). Il pacchetto `http` è già nelle dipendenze.
3. **Windows senza compilare (da fare):** il launcher `tools/launch.ps1` oggi fa `git pull` + `flutter build`, quindi richiede Flutter e Visual Studio sul PC. Con le release si può sostituire quel passaggio con: scarica l'ultimo installer dalla release e lancialo con `/SILENT /CLOSEAPPLICATIONS`.
4. **Android in-app (facoltativo):** scaricare l'APK e avviare l'installazione richiede il permesso `REQUEST_INSTALL_PACKAGES` e l'autorizzazione dell'utente; il semplice link alla release è molto più semplice e affidabile.
