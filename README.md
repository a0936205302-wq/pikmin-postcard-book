# pikmin_postcard_book

Pikmin Postcards is a Flutter app for Android and Web that stores postcard
images and coordinates directly in Firebase Firestore.

## Features

- Grid home page with 3 postcards per row
- Detail page with zoomable image and one-tap coordinate copy
- Add page for selecting an image, entering a name, and saving lat/lng
- Shared Android/Web upload flow using `XFile.readAsBytes()`
- Automatic image compression so the app can stay on Firebase's free tier
- Real-time updates through Firestore snapshots

## Project structure

```text
lib/
  main.dart
  firebase_options.dart
  models/
    postcard.dart
  services/
    postcard_service.dart
  pages/
    home_page.dart
    detail_page.dart
    add_postcard_page.dart
  widgets/
    postcard_grid_item.dart
    postcard_image.dart
```

## Firebase setup

This project intentionally does **not** hard-code fake Firebase credentials.
Before running the app, generate the real `lib/firebase_options.dart` with the
official FlutterFire flow.

1. Install the FlutterFire CLI if needed.
2. Create a Firebase project in the Firebase console.
3. Enable Firestore.
4. In this project folder, run:

```bash
flutterfire configure
```

When asked for platforms, choose at least:

- Android
- Web

## Suggested Firestore structure

Collection:

```text
postcards
```

Document fields:

```json
{
  "name": "string",
  "lat": 0,
  "lng": 0,
  "imageBytes": "Blob",
  "createdAt": "Timestamp"
}
```

## Run

```bash
flutter pub get
flutter run -d chrome
```

or

```bash
flutter run -d android
```

## Notes

- Newly added postcards are stored in Firestore only, without Firebase
  Storage.
- The app keeps a fallback `imageUrl` reader for older documents, so previous
  data can still be shown if needed.
- The app code is ready for future iPhone support because the upload flow uses
  `XFile` and does not rely on `dart:io File`.
