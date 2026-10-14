# FarmConnect

Flutter + Firebase farm-to-customer marketplace. Customers browse fresh produce with a **Freshness Score**,
**distance**, an **"Ugly but Fresh"** discount section and **harvest alerts**. Farmers list produce and manage orders.
An optional admin panel verifies farms and moderates products and users.

## What is included

| Area | Highlights |
|---|---|
| Auth | Email + password, role at signup (customer / farmer), password reset, blocked-account screen |
| Customer | Home with recommendations, search + filters + sort, map of farms, product and farm pages, cart (one farm at a time), checkout (delivery / pickup, COD), order tracking timeline, cancel, reviews, favourites, follow farms, saved addresses, impact stats |
| Farmer | Dashboard (orders, earnings, demand insights, low-stock and aging warnings), farm profile with map pin, product CRUD with photos, harvest date, shelf life, Ugly but Fresh, pre-orders, order workflow (accept, pack, deliver), harvest alerts |
| Admin | Stats, verify farms, hide or delete products, block users, latest orders |
| Backend | Firestore + Storage rules, optional Cloud Functions (push notifications, expiry job) |

## 1. Prerequisites

- Flutter SDK 3.22 or newer, VS Code (Flutter + Dart extensions), Android Studio (for the emulator / SDK)
- Node.js 20 and the Firebase CLI: `npm i -g firebase-tools`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`
- A Google account (Firebase) and a Google Cloud project with billing enabled for Maps (free monthly credit)

## 2. Create the Flutter shell and copy this code in

```bash
flutter create --org com.farmconnect --project-name farmconnect farmconnect_app
cd farmconnect_app
```

Now copy these from this folder into `farmconnect_app`, overwriting what exists:

- `lib/` (replace the whole folder)
- `test/freshness_test.dart` (delete the default `test/widget_test.dart`)
- `pubspec.yaml`, `analysis_options.yaml`
- `firestore.rules`, `storage.rules`, `firebase.json`, `functions/` (optional)

Then:

```bash
flutter pub get
```

## 3. Firebase setup

1. Go to https://console.firebase.google.com and create a project.
2. Enable **Authentication > Sign-in method > Email/Password**.
3. Create **Firestore Database** (production mode) and **Storage**.
4. In the project root run `flutterfire configure`, pick the project and the Android (and iOS) platforms.
   This generates `lib/firebase_options.dart` (replacing the placeholder) and wires up Gradle.
5. Deploy the rules: `firebase login` then `firebase deploy --only firestore:rules,storage`.

### Android settings

- Open `android/app/build.gradle` (or `build.gradle.kts`) and set **minSdk to 23**
  (`minSdk = 23` or `minSdkVersion 23`).
- Add the permissions and the Maps key shown in `android_setup/AndroidManifest_snippets.xml`
  to `android/app/src/main/AndroidManifest.xml`.
- Google Maps key: Google Cloud Console > APIs & Services > enable **Maps SDK for Android**, create an API key,
  and restrict it to your package name and SHA-1 (`cd android && ./gradlew signingReport`).

### iOS (optional)

Add `NSLocationWhenInUseUsageDescription` and `NSPhotoLibraryUsageDescription` to `ios/Runner/Info.plist`,
and call `GMSServices.provideAPIKey("KEY")` in `AppDelegate.swift`. Push on iOS also needs an APNs key in Firebase.

## 4. Run it

```bash
flutter run
```

Use an Android emulator with Google Play services (Pixel image) and set a location in the emulator's
Extended Controls > Location.

## 5. Try the whole flow

1. Sign up as a **Farmer**, open Profile > Create farm profile, pin the location, save.
2. Products > Add product with a photo and today's harvest date. Add one with **Ugly but Fresh** on.
3. Sign out, sign up as a **Customer**, allow location. Browse, add to cart, check out (add an address first), place the order.
4. Sign in as the farmer again, Orders > accept > packed > out for delivery > delivered.
5. As the customer, rate the order.

### Making an admin

Sign up normally, then in the Firestore console open `users/<uid>` and change `role` to `admin`.

## 6. Optional: push notifications (Cloud Functions)

Needs the Blaze plan (free tier is plenty for a demo).

```bash
cd functions && npm install && cd ..
firebase deploy --only functions
```

This sends: new order to the farmer, status changes to the customer, harvest alerts to followers, and a nightly
job that hides expired produce. The app works without it; you simply will not get pushes.

## 7. Project structure

```
lib/
  main.dart, firebase_options.dart, all.dart (barrel)
  app/            theme.dart, constants.dart, router.dart (role-based redirects)
  core/           utils (freshness, distance, formatters), services (location, storage, notifications), widgets
  models/         app_user, farm, product, order, review, harvest_alert
  repositories/   auth, farm, product, order, review, alert  (the only code that talks to Firebase)
  providers/      Riverpod providers + cart state
  features/       auth, customer, farmer, common, admin
functions/        Cloud Functions (optional)
firestore.rules, storage.rules
```

Design system: one palette and one card style (`AppCard`), 14-16 px radii, Inter font, Material 3. Every
screen reuses the shared widgets in `core/widgets/widgets.dart`, so the UI stays consistent.

## 8. Design decisions and known limits

- **Queries avoid composite indexes**: lists are filtered by one field and sorted on the client. Fine for a
  college project or MVP; for thousands of products add pagination and geohash queries.
- **Distance** is computed on the device (Haversine). Nearby filtering is client-side too.
- **Stock safety**: ordering, cancelling and rejecting use Firestore transactions so stock cannot be oversold.
- **Rules trade-off**: customers may update only `quantityAvailable`, `totalSold` and rating fields on products
  (needed for stock and reviews without Cloud Functions). Move these into Functions before a public launch.
- **Payments**: Cash on delivery / pickup only. UPI / cards are shown as "coming soon"; Razorpay is the easiest add-on.
- **Phone OTP** login is not included to keep setup simple; Email auth works with zero extra configuration.
- The code could not be compiled in the environment it was written in, so if `flutter analyze` reports a small
  issue after `pub get` (for example a version-specific API), it is a one-line fix.

## 9. Useful commands

```bash
flutter analyze          # static checks
flutter test             # unit tests (freshness + distance)
flutter build apk --release
firebase emulators:start # optional local backend
```
