# Firebase Ad Configuration Setup

This app loads **all ad settings** from Firestore document  
`ad_configuration/ios`, with **local fallbacks** from `AppConstants.Ads` when Firebase is missing, offline, or a field is omitted.

---

## 1. Add Firebase to the Xcode project (one-time)

1. In Xcode: **File → Add Package Dependencies…**
2. URL: `https://github.com/firebase/firebase-ios-sdk`
3. Add products to the **CricketApp** target:
   - `FirebaseCore`
   - `FirebaseFirestore`
4. Download **GoogleService-Info.plist** from Firebase Console → Project settings → Your iOS app (`com.vivekmalani.cricketapp`).
5. Drag `GoogleService-Info.plist` into the **CricketApp** target (Copy items if needed, target membership checked).

The app already calls `FirebaseBootstrap.configureIfNeeded()` at launch.

---

## 2. Firestore structure (create in Firebase Console)

**Collection ID:** `ad_configuration`  
**Document ID:** `ios`

Paste / create fields:

| Field | Type | Example | Notes |
|-------|------|---------|--------|
| `isShowAds` | boolean | `true` | Master kill switch |
| `adaptiveBannerAdUnitId` | string | `ca-app-pub-xxx/yyy` | Production banner unit |
| `interstitialAdUnitId` | string | `ca-app-pub-xxx/yyy` | Production interstitial unit |
| `nativeAdUnitId` | string | `ca-app-pub-xxx/yyy` | Production native unit |
| `openAdUnitId` | string | `ca-app-pub-xxx/yyy` | App Open unit (cold start + resume) |
| `homeNativeAdEveryMatchCards` | number | `4` | Native after every N home match cards |
| `homeNativeAdMaxPerSection` | number | `3` | Max natives per home section |
| `fixturesNativeAdEveryMatchCards` | number | `4` | Native after every N fixtures cards |
| `fixturesNativeAdMaxPerSection` | number | `5` | Max natives per fixtures group |
| `oversNativeAdEveryCards` | number | `10` | Native after every N over cards |
| `oversNativeAdMax` | number | `3` | Max natives on Overs screen |
| `interstitialEveryMatchCardTaps` | number | `10` | Interstitial every N match-card opens (`0` = off) |
| `interstitialEveryScorecardTaps` | number | `10` | Interstitial every N scorecard opens |
| `interstitialEveryCommentaryTaps` | number | `10` | Interstitial every N commentary opens |
| `interstitialEveryOversTaps` | number | `10` | Interstitial every N overs opens |

### Example JSON (Firebase Console → Add document → or import)

```json
{
  "isShowAds": true,
  "adaptiveBannerAdUnitId": "ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx",
  "interstitialAdUnitId": "ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx",
  "nativeAdUnitId": "ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx",
  "openAdUnitId": "ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx",
  "homeNativeAdEveryMatchCards": 4,
  "homeNativeAdMaxPerSection": 3,
  "fixturesNativeAdEveryMatchCards": 4,
  "fixturesNativeAdMaxPerSection": 5,
  "oversNativeAdEveryCards": 10,
  "oversNativeAdMax": 3,
  "interstitialEveryMatchCardTaps": 10,
  "interstitialEveryScorecardTaps": 10,
  "interstitialEveryCommentaryTaps": 10,
  "interstitialEveryOversTaps": 10
}
```

### Firestore rules (start locked; open only what you need)

Public **read** is enough for this client load (no writes from the app):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /ad_configuration/{docId} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

---

## 3. Fallback behavior (production-safe)

| Situation | What happens |
|-----------|----------------|
| Config already fetched **today** | Uses on-disk daily cache — **no Firestore call** |
| First open of a **new calendar day** | Fresh Firestore fetch, then saves for the rest of that day |
| Field missing in Firestore | That field uses `AppConstants.Ads` default |
| Fetch error (offline / rules) | Uses last saved cache (even from a prior day), else DEBUG/Release fallback below |
| **DEBUG** fallback | Sample Google test units + local frequencies (if `enableAdsInDebugWithoutRemoteConfig`) |
| **Release** fallback | Ads only if `enableAdsInReleaseWithoutRemoteConfig == true` **and** real unit IDs are set in `AppConstants.Ads` (never sample IDs) |

Tune local defaults anytime in:

`CricketApp/Core/Constants/AppConstants.swift` → `enum Ads`

---

## 4. Quick checklist

- [ ] Firebase packages linked (`FirebaseCore`, `FirebaseFirestore`)
- [ ] `GoogleService-Info.plist` in app target
- [ ] Document `ad_configuration/ios` created with unit IDs + frequencies
- [ ] Firestore rules allow client read
- [ ] Production AdMob unit IDs (not sample) in Firestore
- [ ] Optional: fill `AppConstants.Ads` unit IDs + set `enableAdsInReleaseWithoutRemoteConfig = true` for offline Release fallback
