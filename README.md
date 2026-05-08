# Pronote — Flutter (Android, iOS later)

Native Flutter rewrite of the Pronote AI Medical Scribe mobile app. Replaces
the Capacitor wrapper with a true native build to avoid the WebView, version
code, and Play Console policy issues that were costing entire days during the
production submission.

The Flutter app talks to the **same backend** as the web app
(`https://pronote-ai-medical-scribe.onrender.com/api`), so any account that
works on the web works here.

---

## Requirements

- **Flutter 3.22+** with the Dart SDK 3.4+
- **Android Studio** with Android SDK 35 + build-tools 35.0.0
- **JDK 17** (set `JAVA_HOME` to the JDK 17 path)
- A real device or emulator running Android 7.0 (API 24) or newer

### Install Flutter (Windows)

```powershell
# Download the latest stable Flutter SDK ZIP and extract to C:\flutter
# (https://docs.flutter.dev/get-started/install/windows/mobile)

# Add C:\flutter\bin to your PATH (System → Environment Variables)
# Restart your terminal, then verify:
flutter doctor
```

`flutter doctor` will list anything missing — install whatever it complains
about. Most common: Android Studio + Android SDK platform 35.

---

## Project structure

```
lib/
├── main.dart                       # App entry, Riverpod root, theme injection
├── core/
│   ├── theme/app_theme.dart        # Dark slate + emerald/teal theme matching web
│   ├── router/app_router.dart      # go_router with auth-gated redirect
│   ├── api/
│   │   ├── api_client.dart         # Dio + auth-token interceptor
│   │   └── auth_api.dart           # /auth/{login,signup,me,...} bindings
│   └── models/
│       └── user.dart               # User model (mirrors web's User type)
└── features/
    ├── splash/                     # Bootstrap splash while auth restores
    ├── auth/                       # Login, Signup, ForgotPassword
    │   ├── auth_controller.dart    # Riverpod state notifier
    │   └── widgets/auth_scaffold.dart
    └── dashboard/                  # Authenticated home screen
```

Phases not yet built (next iterations):

- `features/capture/` — audio recording with 2-hour cap + foreground service
- `features/dictation/` — live speech-to-text dictation
- `features/upload/` — pick + upload audio files
- `features/notes/` — list + editor + sign + export
- `features/patients/` — patient list, longitudinal context
- `features/templates/` — built-ins + custom template editor
- `features/settings/` — account, billing, danger zone (delete account)
- `features/subscription/` — locked / upgrade / trial countdown

---

## Running locally

```bash
# 1. Install dependencies
flutter pub get

# 2. Connect a real Android phone (USB debugging on) OR start an emulator
flutter devices

# 3. Run in debug mode (hot reload enabled)
flutter run

# Or just for Android specifically:
flutter run -d android
```

---

## Building a release APK / AAB

### Debug APK (no signing required, for sideload testing)

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK (signed)

You need a release keystore first. One-time setup:

```bash
keytool -genkey -v -keystore android/app/pronote-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias pronote-release
```

Then create `android/key.properties` (gitignored):

```
storeFile=pronote-release.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=pronote-release
keyPassword=YOUR_KEY_PASSWORD
```

Now build:

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab  ← upload to Play Store
```

---

## Backend

Backend lives in the [Pronote-AI-Medical-Scribe](https://github.com/sheharyar-shafique/Pronote-AI-Medical-Scribe)
repo. The Flutter app points at the production Render deployment by default —
override with `--dart-define=API_BASE_URL=...` if you spin up a local backend.

To switch to a local backend:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001/api
```

(`10.0.2.2` is the Android emulator's loopback to your host machine.)

---

## Next steps

After verifying the auth + dashboard scaffold runs end-to-end:

1. Add `MainActivity.kt` in `android/app/src/main/kotlin/com/pronoteai/scribe/`
   (Flutter generates this when you run `flutter create .` over the project)
2. Generate launcher icons via `flutter_launcher_icons` from the existing
   Pronote logo
3. Build out `features/capture/` (next phase)
