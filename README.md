# Games Arena (গেমস এরিনা)
Flutter app — all classic games in one APK. Powered by Hasan.

## Build
Push to GitHub `main`; GitHub Actions (`.github/workflows/build-apk.yml`) builds the APK
and publishes it in Releases / Actions artifacts. The workflow generates the Android
scaffold automatically, so no local Flutter setup is needed.

## Phases
1 Home/UI (done) · 2 Ludo (done) · 3 Boards (done) · 4 Cards (done) · 5 Chess & Carrom (done) · 6 Online (done) + Snakes&Ladders · 3 Board games · 4 Card games · 5 Chess & Carrom · 6 Online + polish

## Online mode (Firebase Realtime Database, no SDK)
1. console.firebase.google.com → create project → Build → Realtime Database → Create (any location, *test mode*).
2. Rules tab: `{ "rules": { ".read": true, ".write": true } }` → Publish.
3. Copy the database URL (https://xxxx-default-rtdb....firebaseio.com) and paste it in the app's online lobby (or in `lib/config.dart`).
Online games: Ludo, Snakes&Ladders, Kori, Chess, 8/12/16 Gutti, Bagh-Bakri, Carrom (2 players).
