# Free image uploads with Cloudinary

FarmConnect keeps Firebase Authentication and Firestore. Farm and product
photos are uploaded directly to Cloudinary, and the returned HTTPS URLs are
saved in Firestore. Firebase Storage is no longer required by the app.

## Configure the free account

1. Create a Cloudinary account and open **Settings → Upload → Upload presets**.
2. Add an **unsigned** upload preset. Restrict it to image formats and set a
   conservative maximum file size (for example, 5 MB). Keep transformations
   and other optional processing minimal to preserve the free allowance.
3. Copy the cloud name and preset name. They are public upload identifiers;
   never put an API secret in Flutter code or `--dart-define`.
4. Run the app with both values configured:

```powershell
flutter run -d chrome `
  --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name `
  --dart-define=CLOUDINARY_UPLOAD_PRESET=your_unsigned_preset
```

For Android, replace `chrome` with the connected device ID. Use the same
`--dart-define` flags for release builds. If either setting is missing, upload
shows an actionable configuration error instead of failing at Firebase Storage.

Unsigned upload presets can be called outside the app, so strict upload preset
limits matter. Cloudinary's free allowance is quota-limited and can change;
check the provider dashboard before relying on it for production traffic.
