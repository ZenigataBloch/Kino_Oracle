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
