# TinyWins Backend Configuration Guide

This guide explains how to switch between local-only and Firebase cloud sync modes.

---

## Quick Start

Open `TinyWins/App/AppConfiguration.swift` and find line 34:

```swift
static let backendMode: BackendMode = .localOnly  // <-- CHANGE THIS
```

Change to:
- `.localOnly` — All data stays on device, no sign-in
- `.firebase` — Cloud sync with co-parent features

---

## Mode Comparison

| Feature | Local Only | Firebase |
|---------|------------|----------|
| Data storage | Device only | Cloud + device cache |
| Sign-in required | No | Optional (Apple Sign-In) |
| Co-parent sync | Not available | Available |
| Partner dashboard | Hidden | Visible |
| Works offline | Yes | Yes (auto-syncs later) |
| Multiple devices | No | Yes (when signed in) |

---

## Local-Only Mode (Default)

```swift
static let backendMode: BackendMode = .localOnly
```

**Best for:**
- Development and testing
- Users who don't need cloud sync
- Privacy-focused users

**What happens:**
- All data stored in local JSON file
- No network requests
- Co-parent features hidden from UI
- App works 100% offline

---

## Firebase Mode

```swift
static let backendMode: BackendMode = .firebase
```

**Requirements before enabling:**
1. Add Firebase SPM packages (FirebaseAuth, FirebaseFirestore)
2. Add `GoogleService-Info.plist` to project
3. Ensure bundle ID matches (`com.tinywins.app`)

**What happens:**
- Firebase configured at app launch
- Sign-in option appears in Settings
- Co-parent sync features enabled
- 100MB offline cache for seamless offline use

---

## Firebase Setup Checklist

### 1. Add Firebase SDK via Swift Package Manager

In Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Select these packages:
   - `FirebaseAuth`
   - `FirebaseFirestore`
4. Add to TinyWins target

### 2. Add GoogleService-Info.plist

1. Download from Firebase Console → Project Settings → iOS app
2. Drag into `TinyWins/` folder in Xcode
3. Ensure "Copy items if needed" is checked
4. Ensure TinyWins target is selected

### 3. Verify Bundle ID

Your `GoogleService-Info.plist` must have:
```
BUNDLE_ID = com.tinywins.app
```

This must match your app's bundle identifier in Xcode.

### 4. Enable Apple Sign-In

In Xcode:
1. Select TinyWins target
2. Signing & Capabilities
3. Click "+ Capability"
4. Add "Sign in with Apple"

In Firebase Console:
1. Authentication → Sign-in method
2. Enable "Apple"

---

## Offline Behavior (Firebase Mode)

When Firebase is enabled, the app works seamlessly offline:

| Scenario | Behavior |
|----------|----------|
| No internet | Read/write to local cache |
| Internet restored | Auto-syncs in background |
| Airplane mode | Full functionality from cache |
| First launch offline | Works with empty data |

**Cache size:** 100MB (configurable in `AppConfiguration.swift`)

---

## Feature Gating in Code

To conditionally show UI based on backend mode:

```swift
// Hide view when Firebase is disabled
NavigationLink("Co-Parent Settings") {
    CoParentSettingsView()
}
.coParentOnly()

// Show placeholder when Firebase is disabled
PremiumFeatureView()
    .firebaseOnly {
        Text("Sign in to enable this feature")
    }

// Check in code
if AppConfiguration.isFirebaseEnabled {
    // Firebase-specific logic
}

if AppConfiguration.isSignedIn {
    // User is authenticated
}
```

---

## Troubleshooting

### "Firebase SDK not installed" message
- Add FirebaseAuth and FirebaseFirestore via SPM
- Clean build folder (Cmd+Shift+K)
- Rebuild

### "Bundle ID mismatch" error
- Check `GoogleService-Info.plist` has correct BUNDLE_ID
- Verify Xcode target bundle identifier matches

### Co-parent features not showing
- Ensure `backendMode = .firebase` in AppConfiguration.swift
- Rebuild after changing

### Data not syncing
- Check Firebase Console → Firestore → Data
- Verify Firestore security rules allow read/write
- Check device has internet connection

---

## Security Rules (Firestore)

Add these rules in Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Families - only members can read/write
    match /families/{familyId} {
      allow read, write: if request.auth != null
        && request.auth.uid in resource.data.memberIds;

      // Allow create if user is creating their own family
      allow create: if request.auth != null
        && request.auth.uid in request.resource.data.memberIds;

      // Subcollections inherit family access
      match /{subcollection}/{docId} {
        allow read, write: if request.auth != null
          && request.auth.uid in get(/databases/$(database)/documents/families/$(familyId)).data.memberIds;
      }
    }
  }
}
```

---

## File Reference

| File | Purpose |
|------|---------|
| `App/AppConfiguration.swift` | Main backend switch & feature flags |
| `App/TinyWinsApp.swift` | App entry point, calls configuration |
| `Services/FirebaseAuthService.swift` | Apple Sign-In with Firebase |
| `Services/FirebaseSyncBackend.swift` | Firestore data sync |
| `Services/BackendModeDetector.swift` | Runtime backend detection |
| `GoogleService-Info.plist` | Firebase project credentials |
