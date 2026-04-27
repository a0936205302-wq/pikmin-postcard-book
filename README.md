# pikmin_postcard_book

Pikmin Postcards is a Flutter app for Android, Web, and iPhone that stores
postcard images and coordinates directly in Firebase Firestore.

## Features

- Grid home page with 3 postcards per row
- Detail page with zoomable image and one-tap coordinate copy
- Add page for selecting an image, entering a name, and saving coordinates
- Shared Android / iPhone / Web upload flow using `XFile.readAsBytes()`
- Automatic image compression so the app can stay on Firebase's free tier
- Real-time updates through Firestore snapshots
- Shared postcard list with platform-specific owned status

## Project structure

```text
lib/
  main.dart
  firebase_options.dart
  models/
    postcard.dart
  services/
    postcard_service.dart
    map_launcher_service.dart
  pages/
    home_page.dart
    detail_page.dart
    add_postcard_page.dart
  widgets/
    postcard_grid_item.dart
    postcard_image.dart
ios/
  Podfile
  Runner/
  Runner.xcodeproj/
  Runner.xcworkspace/
```

## Firebase setup

This repo already contains generated Firebase options for:

- Android
- Web
- iOS

The app uses:

- Shared postcards: `postcards/{postcardId}`
- Platform-specific owned status:
  - `owned_status/android/items/{postcardId}`
  - `owned_status/ios/items/{postcardId}`
  - `owned_status/web/items/{postcardId}`

Recommended Firestore rules for this project:

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /postcards/{document=**} {
      allow read, write: if true;
    }

    match /owned_status/{platform} {
      allow read, write: if true;
    }

    match /owned_status/{platform}/items/{itemId} {
      allow read, write: if true;
    }
  }
}
```

## Run

Web:

```bash
flutter pub get
flutter run -d chrome
```

Android:

```bash
flutter run -d android
```

## iPhone setup on Mac

After cloning this repo on your Mac:

1. Run:

```bash
flutter pub get
```

2. Install iOS pods:

```bash
cd ios
pod install
cd ..
```

3. Open:

```text
ios/Runner.xcworkspace
```

You can also run the helper script from the repo root:

```bash
bash setup_ios_on_mac.sh
```

4. In Xcode:

- Select the `Runner` target
- Set your Apple Team under `Signing & Capabilities`
- Keep the bundle id as `com.admin.pikminPostcardBook` unless you plan to
  reconfigure Firebase
- Choose your iPhone device
- Press Run

If you change the iOS bundle id later, re-run FlutterFire for iOS so Firebase
stays matched.

## Notes

- Newly added postcards are stored in Firestore only, without Firebase
  Storage.
- The app keeps a fallback `imageUrl` reader for older documents, so previous
  data can still be shown if needed.
- BlueMap is Android-only. On iPhone, the Google Maps button works and the
  BlueMap action will show a friendly unsupported message.
