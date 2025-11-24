<div align="center">

# Bayankonek

Community services and issue-reporting app built with Flutter and Firebase.

</div>

---

## Overview

Bayankonek streamlines how residents interact with their local government. Users can request official documents, report community issues with geotagged photos, and keep track of their activity in one unified experience. The project targets Android first, but it is structured to support iOS, Web, Windows, macOS, and Linux builds via Flutter’s multiplatform toolchain.

## Feature Highlights

- **Document Requests** – Guided forms, recent-request cards with status colors, and a detailed timeline view for each submission.
- **Issue Reporting** – Category picker, OpenStreetMap-based location pinning, photo uploads to Firebase Storage, and confirmation screens.
- **Recent Activity Feed** – Combines document requests and issue reports, sorted chronologically, with deep links to detail pages.
- **Authentication** – Phone number verification plus optional Facebook Login for quicker onboarding.
- **Secure Storage** – Firestore for structured data and Firebase Storage for media, with rules scoped to each authenticated user.

## Tech Stack

- **Framework:** Flutter 3.x, Dart
- **Backend:** Firebase Authentication, Cloud Firestore, Firebase Storage
- **Location & Maps:** `geolocator`, `geocoding`, `flutter_map` (OpenStreetMap tiles)
- **Media:** `image_picker`, Firebase Storage uploads
- **Auth Integrations:** `firebase_auth`, `flutter_facebook_auth`

## Getting Started

1. **Install dependencies**
   - Flutter SDK (3.24+ recommended)
   - Android Studio or Xcode command-line tools
   - Firebase CLI: `npm install -g firebase-tools`
   - FlutterFire CLI: `dart pub global activate flutterfire_cli`

2. **Clone and bootstrap**
   ```bash
   git clone https://github.com/<your-org>/bayankonek.git
   cd bayankonek
   flutter pub get
   ```

3. **Configure Firebase**
   - Run `flutterfire configure` and select the appropriate Firebase project (e.g., `bayankonek2`).
   - Copy the generated `google-services.json` to `android/app/` and `GoogleService-Info.plist` to `ios/Runner/`.
   - `lib/firebase_options.dart` is generated automatically and **should remain committed**; it only contains public Firebase identifiers required by the SDK.

4. **Protect Firebase resources**
   - Publish Firestore/Storage security rules that restrict actions to authenticated users and enforce ownership (`userId` matches, document status transitions, etc.).
   - Consider enabling App Check for device attestation and rate limiting to mitigate abuse.

5. **Facebook Login (Android)**
   - Add the following entries to `android/local.properties` (gitignored):
     ```
     facebook.appId=YOUR_APP_ID
     facebook.clientToken=YOUR_CLIENT_TOKEN
     ```
   - Provide the debug/release key hashes to the Meta developer console. Use `keytool -exportcert ... | openssl sha1 -binary | openssl base64` or grab the hash from `adb logcat` when login fails.
   - Without these values, the “Continue with Facebook” button remains disabled.

6. **Environment variables**
   - Create a `.env` file in the project root for any additional secrets (third-party APIs, feature flags, etc.). The file is already ignored by Git; load it at runtime using your preferred config package if needed.

## Running the App

```bash
flutter run             # Debug build on the default device/emulator
flutter run --release   # Release build (configure signing keys first)
```

## Testing

```bash
flutter test
```

Add widget/integration tests as new flows are introduced (document submission, issue reporting, auth, etc.) to keep regression coverage high.

## Project Structure

- `lib/main.dart` – Entry point, landing page, and auth routing.
- `lib/screens/` – UI screens (requests, reports, details, services, login, etc.).
- `lib/services/auth_service.dart` – Centralized authentication helpers (phone + Facebook).
- `android/`, `ios/`, `macos/`, `windows/`, `linux/`, `web/` – Platform-specific wrappers and Firebase configs.
- `.gitignore` already excludes builds, `local.properties`, and `.env`.

## Deployment & Security Notes

- GitHub secret scanning may flag Firebase Web API keys. Close those alerts as “intended” and document that they’re required client identifiers.
- Monitor Firebase usage (Auth, Firestore, Storage) and set quota alerts to catch abnormal spikes early.
- Keep `local.properties` and `.env` out of version control; they store per-developer secrets like Facebook tokens or future API keys.

---

Happy coding! Open issues or discussions if you have questions or ideas for new features.**
