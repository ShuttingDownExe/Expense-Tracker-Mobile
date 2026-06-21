# Local Setup

## Firebase configuration

The Firebase config files are intentionally **not committed** (they hold
project API keys / app IDs). After cloning, regenerate them locally:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=expense-tracker-a9ebd
```

This generates (all git-ignored):

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

If `firebase_options.dart` is missing the app still runs in **preview mode**
(sample data, no sign-in), so the UI works without Firebase configured.

## Environments

The target environment is selected with `--dart-define=APP_ENV=dev|test|prod`
(defaults to `dev`). It drives the API URL and whether email sign-in is shown:

| `APP_ENV` | API backend | Email sign-in | Transport |
|-----------|-------------|---------------|-----------|
| `dev` (default) | local `http://10.0.2.2:3000/api` | ✅ shown | HTTP (debug builds only) |
| `test` | `https://test--expense-tracker-a9ebd.us-east4.hosted.app/api` | ✅ shown | HTTPS |
| `prod` | `https://prod--expense-tracker-a9ebd.asia-east1.hosted.app/api` | ❌ Google only | HTTPS |

```bash
flutter pub get

flutter run                                            # dev (local API, email auth)
flutter run --dart-define=APP_ENV=test                 # point a dev device at the test backend
flutter build apk --release --dart-define=APP_ENV=test # test build for QA
flutter build apk --release --dart-define=APP_ENV=prod # production build (Google only)
```

Cleartext HTTP is enabled only in **debug** builds (via
`android/app/src/debug/`), so release test/prod builds enforce HTTPS.

Override the API URL ad hoc (e.g. a physical device on your LAN):

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:3000/api
```

## CI & test distribution

`.github/workflows/build.yml` builds and (for UAT) distributes automatically:

| Trigger | Build | Distributed to `uat-testers`? |
|---------|-------|-------------------------------|
| push to `UAT` | test | ✅ yes |
| push to `main` | prod | ❌ no (artifact only) |
| manual dispatch | your choice | per the `distribute` toggle |

Manual dispatch (Actions tab → Build APK → Run workflow) lets you build either
environment and choose whether to distribute.

Repository secrets:

Repository secrets — base64 of a file (`base64 -i <file>`):

| Secret | Source file |
|--------|-------------|
| `GOOGLE_SERVICES_JSON` | `android/app/google-services.json` |
| `FIREBASE_OPTIONS_DART` | `lib/firebase_options.dart` |
| `FIREBASE_SERVICE_ACCOUNT` | service-account JSON with the **Firebase App Distribution Admin** role |
| `ANDROID_KEYSTORE` | the release `.jks` keystore |

Repository secrets — plain values (release keystore credentials):

| Secret | Value |
|--------|-------|
| `ANDROID_KEYSTORE_PASSWORD` | keystore store password |
| `ANDROID_KEY_ALIAS` | key alias (e.g. `upload`) |
| `ANDROID_KEY_PASSWORD` | key password |

### Release signing (required for Google sign-in on distributed builds)

Google Sign-In authenticates the app by package name + signing SHA-1, so
distributed builds must be signed with a **stable** key whose SHA-1 is
registered in Firebase (the debug key differs per machine, including CI runners).

1. Generate a keystore (keep it safe and out of git):
   ```bash
   keytool -genkey -v -keystore ~/expense-tracker-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Get its fingerprints and register **SHA-1** (and SHA-256) on the
   `com.expensetracker.expense_tracker` app in Firebase Console:
   ```bash
   keytool -list -v -keystore ~/expense-tracker-upload.jks -alias upload
   ```
3. Re-download `google-services.json` (now includes the new OAuth client) and
   update the `GOOGLE_SERVICES_JSON` secret.
4. Add the four `ANDROID_*` secrets above (`base64 -i ~/expense-tracker-upload.jks`
   for `ANDROID_KEYSTORE`).

For a **signed release build locally**, create `android/key.properties`
(git-ignored):

```properties
storeFile=/absolute/path/to/expense-tracker-upload.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

Without `key.properties`, release builds fall back to debug signing (fine for
local testing, not for Google sign-in).

Testers are the **`uat-testers`** group in Firebase Console → App Distribution.
The current release APK is debug-signed, which App Distribution accepts — no
Play Store keystore required for testing.

The workflow uses only GitHub-first-party `actions/*`; Flutter is installed from
Google's official release tarball and distribution uses Google's Firebase CLI —
no third-party actions.
