# CricketApp

Production-oriented SwiftUI cricket application scaffold for iOS 17 and newer.

## API Scope

This project intentionally uses only the APIs requested in the brief:

- Cricket.com.au fixtures, scorecard, and comments endpoints.
- Cricnet rankings endpoint.
- Apple iTunes Lookup API.
- Firebase Firestore for remote ad configuration when the SDK is linked.
- Google Mobile Ads SDK surfaces when the SDK is linked.

See [docs/FIREBASE_AD_CONFIG.md](docs/FIREBASE_AD_CONFIG.md) for the Firestore document shape, fallbacks, and console setup steps.

SportsTiger APIs, models, and networking are intentionally absent.

## Build

Open `CricketApp.xcodeproj` in Xcode 17 or newer and build the `CricketApp` scheme. The Firebase and Google Mobile Ads adapters compile as no-op fallbacks until those SDKs are added to the app target.
