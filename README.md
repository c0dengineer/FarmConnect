# FarmConnect

FarmConnect is a Flutter marketplace for buying fresh produce directly from nearby farms. Customers discover farms and products, place pickup or delivery orders, and review completed purchases. Farmers manage a farm profile, listings, availability, orders, and harvest alerts.

## What the app does

### Customers

- Create an account, sign in, and manage a profile and saved addresses.
- Browse produce, search and filter listings, view farms on a map, and choose a delivery location.
- See estimated farm distance and a harvest-based freshness score.
- Save favourites, add products to a single-farm cart, and place delivery or pickup orders.
- Pay by cash or transfer directly to a farm using UPI. UPI payments are confirmed manually by the farmer; the app is not a payment processor.
- Review delivered orders, follow farms, and view their harvest alerts.
- Find discounted “Ugly but Fresh” items to help reduce food waste.

### Farmers

- Create a farm profile with location, contact details, and delivery/pickup options.
- Add products, photos, prices, stock, harvest and shelf-life details, pre-orders, and “Ugly but Fresh” discounts.
- View and update orders, confirm UPI payments, and post harvest alerts for followers.

### Admin

An admin route is included for basic marketplace administration. Assigning an admin role is a trusted operation and must be done outside public sign-up; review the Firestore rules before granting access.

## Technology stack

| Area | Technology |
| --- | --- |
| App | Flutter / Dart (Dart SDK `>=3.3.0 <4.0.0`) |
| Navigation | `go_router` |
| App state | Riverpod (`flutter_riverpod`) |
| Authentication | Firebase Authentication (Email/Password) |
| Database | Cloud Firestore |
| Push messaging | Firebase Cloud Messaging (`firebase_messaging`) |
| Maps | `flutter_map`, OpenStreetMap tiles, and `latlong2` |
| Location | `geolocator` and `geocoding` |
| Product and farm images | Cloudinary unsigned image uploads; URLs are stored in Firestore |
| Other app packages | `image_picker`, `url_launcher`, `qr_flutter`, `google_fonts`, `http`, and `uuid` |
| Backend automation | Optional Firebase Cloud Functions (Node.js 20, Firebase Admin SDK) |
| Tests/lints | Flutter Test and `flutter_lints` |

Dependency version constraints are maintained in [`pubspec.yaml`](pubspec.yaml); the resolved Flutter dependency versions are pinned in [`pubspec.lock`](pubspec.lock). Functions dependencies are in [`functions/package.json`](functions/package.json).

## Requirements

- Flutter SDK with Dart, on the stable channel. Install instructions: [Flutter for Windows](https://docs.flutter.dev/get-started/install/windows).
- Git.
- Chrome for the configured web target.
- Node.js 20 only if you will deploy Cloud Functions; Node.js LTS and the Firebase CLI are also needed to deploy Firebase configuration.
- Android Studio and the Android SDK if you are setting up an Android build.
- Firebase and Cloudinary accounts for a working marketplace with data and image uploads.

Check your toolchain in Command Prompt:

```bat
flutter doctor
flutter devices
```

## Get started (Windows Command Prompt)

Run these commands from the repository root:

```bat
cd /d C:\Users\navya\Desktop\PROJECTS\FarmConnect
flutter pub get
flutter run -d chrome
```

This project includes web and Android Firebase options. The Cloudinary defines are optional for browsing and UI work, but required to upload farm or product photos. To run with uploads configured, use a **single line** in Command Prompt:

```bat
flutter run -d chrome --dart-define=CLOUDINARY_CLOUD_NAME=YOUR_CLOUD_NAME --dart-define=CLOUDINARY_UPLOAD_PRESET=YOUR_UNSIGNED_PRESET
```

For another target, find its ID with `flutter devices` and replace `chrome` with that ID. Do not type the angle-bracket placeholder literally. Command Prompt does not use PowerShell's backtick line continuation.

### Android setup

The repository includes the generated `android/` platform project and Android Firebase options. Install Android Studio and its SDK, then from the project root connect a device or start an emulator and run:

```bat
flutter devices
flutter run -d YOUR_DEVICE_ID
```

Replace the device placeholder with a real ID. Before using GPS or notifications, add the permissions from [`android_setup/AndroidManifest_snippets.xml`](android_setup/AndroidManifest_snippets.xml) inside the `<manifest>` element in `android/app/src/main/AndroidManifest.xml`. Allow location permission on the device if using GPS; the map pin picker can be used without GPS.

Use Cloudinary defines on Android as well:

```bat
flutter run -d YOUR_DEVICE_ID --dart-define=CLOUDINARY_CLOUD_NAME=YOUR_CLOUD_NAME --dart-define=CLOUDINARY_UPLOAD_PRESET=YOUR_UNSIGNED_PRESET
```

The map uses OpenStreetMap and does not require a Google Maps API key. Android builds still need the platform-specific Firebase Messaging and notification setup before push notifications work.

## Firebase setup

The checked-in Firebase configuration currently targets project **`farm-connect-92ccd`**:

- [`lib/firebase_options.dart`](lib/firebase_options.dart) contains Flutter Firebase client options for web and Android.
- [`.firebaserc`](.firebaserc) selects the Firebase CLI project alias.
- [`firebase.json`](firebase.json) points Firebase CLI to the Firestore rules and Cloud Functions source.
- [`firestore.rules`](firestore.rules) defines Firestore access.

In the [Firebase Console](https://console.firebase.google.com/), confirm that this project has:

1. Email/Password enabled in **Authentication → Sign-in method**.
2. A Cloud Firestore database created.
3. The latest Firestore rules from this repository deployed.

Install and authenticate the CLI in Command Prompt if needed:

```bat
npm install --global firebase-tools
firebase login
firebase use farm-connect-92ccd
firebase deploy --only firestore:rules
```

Check the project shown by `firebase use` before deployment. Firestore rules are required for app data access; a rules change in the local file does not affect the live Firebase project until deployed.

### Use a different Firebase project

Use a Firebase project you own or are authorized to administer, then configure the CLI and regenerate Flutter options for the platforms you use:

```bat
firebase use --add
dart pub global activate flutterfire_cli
dart pub global run flutterfire_cli:flutterfire configure
```

Review the project ID and platform options in `.firebaserc`, `firebase.json`, and `lib/firebase_options.dart` before running or deploying. Keep `lib/firebase_options.dart` in the repository: it contains client configuration required by this app, not a Firebase Admin credential. Never place service-account credentials in the Flutter app.

The app stores users, farms, products, orders, reviews, harvest alerts, and search logs in Firestore. Firebase Storage is **not used** by the current app; farm and product photo URLs point to Cloudinary.

## Cloudinary photo uploads

Photo uploads need a Cloudinary account and an **unsigned upload preset**:

1. In Cloudinary, find your cloud name and create an unsigned preset under **Settings → Upload → Upload presets**.
2. Restrict the preset to images and set appropriate size/format limits.
3. Supply the cloud name and preset as `--dart-define` values in each `flutter run` or release build command.

See [`CLOUDINARY_SETUP.md`](CLOUDINARY_SETUP.md) for more detail. The cloud name and preset name are client-side identifiers. Never use a Cloudinary API secret in Flutter, a Dart define, or a committed file. Unsigned presets can be called outside the app, so configure restrictions and monitor Cloudinary quotas.

If either define is missing, image upload is unavailable and the farmer forms show a setup message. Build-time Dart defines are not stored by Flutter for the next run; include them every time you launch or build.

## Maps, location, distance, and delivery

The app renders OpenStreetMap tiles with `flutter_map`; map tiles require internet access. It can request GPS location or use a manually selected map point. Reverse geocoding displays a place name when available. Farm distance is calculated from coordinates.

The current delivery estimate is:

```text
₹20 base fee + ₹3 × distance in kilometres
```

Pickup has no delivery fee. Delivery requires the farm to offer delivery and the customer address to be within the farm's configured delivery radius. This is an app estimate, not a carrier quote.

## Orders and payments

Orders are placed against one farm at a time. Stock is checked and updated as orders are placed. Farmers update order status from their dashboard. A customer can review an order once it is delivered.

UPI is a direct transfer from the customer to the farmer. The farmer must add a UPI ID, the customer completes payment using their UPI app, and the farmer verifies and confirms receipt manually. FarmConnect does not process or automatically verify the payment and does not handle refunds. Cash on delivery or pickup is also available where supported.

## Harvest alerts and push notifications

Harvest alerts are saved in Firestore and shown in the followed-farms feed and customer Home. The app also requests Firebase Messaging permission and listens for foreground messages. These in-app/foreground behaviors depend on Firestore and platform support.

The `functions/` directory contains optional push triggers for harvest alerts and order updates, plus a scheduled product-expiry task. Push delivery requires Firebase Cloud Messaging to be configured for the target platform and Cloud Functions to be deployed. Cloud Functions deployment requires the Firebase **Blaze** plan and may incur charges. Do not deploy functions or upgrade billing unless you intend to enable them and have reviewed the costs.

To deploy the functions, from the repository root:

```bat
cd functions
npm install
cd ..
firebase deploy --only functions
```

## Development and verification

From the repository root:

```bat
dart format lib test
flutter analyze
flutter test
flutter build web
```

Build an Android APK after Android platform setup:

```bat
flutter build apk --release --dart-define=CLOUDINARY_CLOUD_NAME=YOUR_CLOUD_NAME --dart-define=CLOUDINARY_UPLOAD_PRESET=YOUR_UNSIGNED_PRESET
```

The project includes unit tests for freshness/distance calculations and startup error handling. `flutter clean` removes generated build artifacts and can be followed by `flutter pub get` to recreate the package configuration.

## Project structure

```text
lib/
  app/          App theme, constants, and role-aware routing
  core/         Shared services, utilities, and reusable widgets
  features/     Auth, customer, farmer, admin, and shared screens
  models/       User, farm, product, order, review, and alert models
  providers/    Riverpod providers and app state
  repositories/ Firebase Authentication and Firestore access
  main.dart     Firebase initialization and app entry point
  firebase_options.dart
functions/      Optional Node.js Cloud Functions
test/           Flutter tests
web/            Flutter web entry point and manifest
android_setup/  Android manifest permission notes
firestore.rules Firestore security rules
```

## Troubleshooting

- **Firebase startup or permission error:** Check the Firebase project and enabled services, then verify the relevant rules are deployed with `firebase deploy --only firestore:rules`.
- **Review permission denied:** The delivered-order review rules must be deployed. Confirm the order is delivered and has not already been reviewed.
- **Photo upload says it is not configured:** Include both Cloudinary Dart defines in the current run/build command and restart the app.
- **Cloudinary rejects an upload:** Check the cloud name, unsigned preset, file restrictions, size limits, and account quota.
- **Map tiles are blank:** Check internet access to OpenStreetMap tile servers. GPS permission is separate from map tile loading.
- **Location is unavailable:** Enable device location and grant permission, or place the pin manually.
- **No farms or products appear:** Check that a farmer profile and available, in-stock products exist in Firestore, and inspect the app logs and deployed rules.
- **Push messages do not arrive:** Verify platform Firebase Messaging setup, notification permission, followed-farm state, and deployed Cloud Functions. A foreground snackbar does not mean background push is configured.
