# Cloudinary photo uploads

FarmConnect uploads farm and product photos to Cloudinary. It stores the returned HTTPS image URLs in Firestore. The app does not use Firebase Storage.

## Set up an unsigned upload preset

1. Create or sign in to a Cloudinary account.
2. In the Cloudinary console, open **Settings > Upload > Upload presets**.
3. Create an **unsigned** preset. Restrict it to image formats and set reasonable file size limits (the app rejects files larger than 5 MB).
4. Copy the account's **cloud name** and the new **preset name**.

The cloud name and unsigned preset are public identifiers. Never put a Cloudinary API secret in the Flutter app, a Dart define, or a committed file. Restrict the preset because unsigned uploads can be attempted outside this app. Check Cloudinary's current quotas before relying on uploads in production.

## Run with uploads enabled

In Windows **Command Prompt**, run this as one line from the project folder:

```bat
flutter run -d chrome --dart-define=CLOUDINARY_CLOUD_NAME=YOUR_CLOUD_NAME --dart-define=CLOUDINARY_UPLOAD_PRESET=YOUR_UNSIGNED_PRESET
```

Replace both placeholders with the values from your Cloudinary account. For another device, get its ID with `flutter devices` and replace `chrome` with that ID. Include both defines on every run and build; Flutter does not save them between commands.

For a release web build:

```bat
flutter build web --release --dart-define=CLOUDINARY_CLOUD_NAME=YOUR_CLOUD_NAME --dart-define=CLOUDINARY_UPLOAD_PRESET=YOUR_UNSIGNED_PRESET
```

For Android APK builds after Android platform setup:

```bat
flutter build apk --release --dart-define=CLOUDINARY_CLOUD_NAME=YOUR_CLOUD_NAME --dart-define=CLOUDINARY_UPLOAD_PRESET=YOUR_UNSIGNED_PRESET
```

If either value is missing or invalid, the farmer forms show an actionable message and photos cannot be uploaded. Do not paste credentials into the source code or README; supply them only to the local run/build command.
