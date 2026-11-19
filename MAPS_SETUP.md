# Google Maps SDK setup

This replaces the free OpenStreetMap map with the real Google Maps SDK.
Google requires a billing account on the project, but Maps SDK usage for
a portfolio-sized project stays well inside the **$200/month free credit**
— you won't be charged unless you go far beyond normal testing volume.

## 1. Create API keys (Google Cloud Console)

1. Go to https://console.cloud.google.com/ and create (or pick) a project.
2. **Billing** → link a billing account (required even to stay in the free tier).
3. **APIs & Services → Library** → enable:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
4. **APIs & Services → Credentials → Create credentials → API key.**
   Create **two separate keys** (one per platform) and restrict each:
   - Android key → restrict to "Android apps", add this app's package
     name (`com.example.mini_foodpanda`, or whatever you rename it to)
     and its SHA-1 fingerprint (`cd android && ./gradlew signingReport`).
   - iOS key → restrict to "iOS apps", add this app's bundle ID.

   Restricting each key stops anyone who reads your app's binary from
   using your key on their own project.

## 2. Add the keys to the project

- **Android** — `android/app/src/main/AndroidManifest.xml` already has a
  placeholder:
  ```xml
  <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_ANDROID_MAPS_API_KEY"/>
  ```
  Replace `YOUR_ANDROID_MAPS_API_KEY` with your Android key.

- **iOS** — `ios/Runner/AppDelegate.swift` already has:
  ```swift
  GMSServices.provideAPIKey("YOUR_IOS_MAPS_API_KEY")
  ```
  Replace `YOUR_IOS_MAPS_API_KEY` with your iOS key.

Never commit real keys to a public repo — for a portfolio project on
GitHub, either keep the repo private, or load the key from an
un-committed `local.properties` / `.xcconfig` file instead (Google's
`google_maps_flutter` docs show both patterns).

## 3. Install

```
flutter pub get
cd ios && pod install && cd ..
```

## What still uses free services

- The **road route line** drawn on the map still comes from the free
  OSRM API (`lib/services/route_service.dart`) — swapping this for
  Google's Directions API is optional and would add another billed API.
- Firebase Auth/Firestore/GPS tracking are unchanged.

## Note on markers

Markers use Google's built-in colored pins (`BitmapDescriptor.defaultMarkerWithHue`)
rather than custom icons, to keep this update focused on wiring in the
real SDK. Swap in `BitmapDescriptor.fromAssetImage` with your own icon
assets any time you want branded pins.

## Web (Chrome)

The Android/iOS keys above do **not** apply to web. Without extra setup the
app shows a "map available in the mobile apps" placeholder (no crash).

To get real maps on web:

1. Cloud Console -> **APIs & Services -> Library** -> enable **Maps JavaScript API**.
2. Create a third API key, restrict it to *HTTP referrers* (e.g. `localhost:*`
   while developing, your domain in production).
3. In `web/index.html`, uncomment the `<script ... maps/api/js?key=...>` tag and
   paste the key.
4. Run with: `flutter run -d chrome --web-port=5000 --dart-define=WEB_MAPS=true`
