# Finders Keepers 🔍 — Campus Lost & Found Platform

[![Download Android APK](https://img.shields.io/badge/Download_APK-Finders_Keepers_v1.0.0-2E7D52?style=for-the-badge&logo=android&logoColor=white)](https://github.com/Dhyanesh2603/FinderKeepers/releases/download/v1.0.0/app-debug.apk)
[![GitHub Repository](https://img.shields.io/badge/GitHub-Dhyanesh2603%2FFinderKeepers-181717?style=for-the-badge&logo=github)](https://github.com/Dhyanesh2603/FinderKeepers)
[![Tests Passing](https://img.shields.io/badge/Tests-24%20Passing-2E7D52?style=for-the-badge&logo=flutter)](https://github.com/Dhyanesh2603/FinderKeepers)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)

### 📲 [📥 Direct Android APK Download (v1.0.0)](https://github.com/Dhyanesh2603/FinderKeepers/releases/download/v1.0.0/app-debug.apk)
> **Instant Deliverable Installation**: Tap the download badge or [click here to download `app-debug.apk`](https://github.com/Dhyanesh2603/FinderKeepers/releases/download/v1.0.0/app-debug.apk) to install and run the standalone application immediately on any physical Android device or emulator without needing to build from source.

---

> **A student-first campus Lost & Found mobile application with privacy-preserving approximate locations, anti-fraud ownership verification, Google Maps location tagging, and secure in-app messaging.**  
> Built for **CC-VIT 26-27 Promotional Cycle — Recruitment Task Sheet #12**.

Inspired by the calm, minimal design language of Apple, Linear, and Notion. Built with **Flutter**, **Riverpod**, and **GoRouter**.

---

## 📋 Task Sheet #12 Compliance Matrix

| # | Expected Functionality / Deliverable | Status | Implementation Details |
|---|---|:---:|---|
| **01** | Report lost and found items (descriptions, images, locations) | **✅ 100%** | Multi-step form with cross-platform `Uint8List` image picker, standardized campus landmarks, Google Maps location pin dropper, and custom secret question builder. |
| **02** | Searchable listing of reported items | **✅ 100%** | Real-time substring query matching across titles, descriptions, and landmarks with 7 category filter chips. |
| **03** | Display approximate locations on a map | **✅ 100%** | Custom vector canvas map rendering a fuzzed ~100m radius circle around landmarks to prevent predatory theft, plus Google Map pin tagger with GPS coordinates. |
| **04** | Submit ownership claims | **✅ 100%** | Dedicated `/items/:id/claim` flow where claimants answer the finder's confidential questions with strict **one-active-claim-per-student** anti-spam enforcement. |
| **05** | Ownership verification process before handover | **✅ 100%** | Reporter review dashboard (`/items/:id/claims`) with **Approve** and **Reject** verification actions. Rejection allows claimants to revise their submission. |
| **06** | Track item states (lost, found, claimed, reunited) | **✅ 100%** | Domain lifecycle state machine (`open` → `inVerification` → `reunited`) with visual status progression timeline. |
| **07** | Interrupted submissions & unreliable network handling | **✅ 100%** | `OfflineService` draft auto-save and restoration, plus an offline submission queue that auto-syncs when reconnected. |
| **08** | Protect sensitive user information throughout | **✅ 100%** | Zero phone number or personal email exposure. Identifying marks stay confidential behind challenge gates. |
| **Bonus 1** | Offline-first functionality | **✅ 100%** | Automatic local persistence via `SharedPreferences`, cached feed browsing, and offline report queue with live connectivity toggle simulator. |
| **Bonus 2** | Push notifications for matching items | **✅ 100%** | In-app notification center dispatching smart match alerts when confidence exceeds threshold. |
| **Bonus 3** | Image and category similarity matching | **✅ 100%** | `MatchEngine` multi-factor scoring (category + location + keyword tokens + 48h time window). |
| **Bonus 4** | Location-based recommendations | **✅ 100%** | Recommends items found in the same or adjacent campus zones (Library, Dining, Recreation, Lab complexes). |
| **Bonus 5** | Administrative moderation interface | **✅ 100%** | Campus security dashboard (`/admin`) with recovery analytics KPI bar, item moderation, and claims audit inspection. |
| **Bonus 6** | Secure in-app messaging between users | **✅ 100%** | Private chat channel (`/chat/:claimId`) and embedded in-page handover chat strictly unlocked post-verification to arrange safe campus handovers. |
| **Extra** | Student Profile Activity Separation | **✅ 100%** | Dedicated 3-tab profile activity dashboard (**Things I Lost**, **Things I Found**, **My Claims**) with 4-metric KPI recovery statistics and direct claim review buttons. |

---

## 🛡️ Anti-Fraud & Ownership Verification Mechanism

Traditional lost-and-found boards fail because public listings reveal unique identifiers (e.g., serial numbers, engravings, custom stickers), allowing dishonest users to falsely claim valuable electronics.

Finders Keepers uses a **Blind Proof-of-Ownership Challenge**:
1. **Reporter Challenge**: When a student reports finding an item (e.g. *AirPods Pro*), they specify secret verification questions (e.g., *"What initials are engraved on the lid?"*, *"What color is the protective case?"*). The expected answers are kept confidential.
2. **Claim Submission**: When a claimant taps *Claim This Item*, they must submit answers to the creator's secret questions. The system strictly enforces a **single active claim per user** to prevent brute-force answer guessing.
3. **Finder Review**: The finder inspects the submitted answers on the `/items/:id/claims` dashboard and either **Approves** or **Rejects** the claim.
4. **Gated Handover Chat**: Only upon approval does the app advance item status to `inVerification` and unlock the private in-app chat (`/chat/:claimId` or embedded chat) for safe handover coordination at a campus security desk.

---

## 📍 Google Maps Location Tagger & Privacy-Fuzzed Map Explorer

1. **Google Map Pin Dropper**: Finders can precisely tag the physical campus spot on a satellite or vector map interface, automatically computing GPS latitude and longitude while snapping to official campus landmarks.
2. **Privacy Fuzzing**: For public listings, the app renders a fuzzed ~100m approximate radius circle around the landmark rather than exact pin coordinates, preventing malicious individuals from rushing to seize lost items.
3. **Directions Launcher**: Verified owners can tap "Open in Google Maps" on the item detail screen to launch native navigation directions.

---

## 👤 Student Profile & Activity Hub

The student profile screen (`/profile`) provides a dedicated 3-tab activity center backed by permanent `SharedPreferences` storage:
- **Things I Lost**: Tracks all items the student misplaced, displaying current recovery status and match alerts.
- **Things I Found**: Displays all items the student picked up, showing a live counter of claims received and a direct **"Review Claims (N)"** button to inspect student answers.
- **My Claims**: Shows all ownership claims submitted by the student with live status badges (`PENDING REVIEW`, `APPROVED ✓`, `REJECTED`) and an **"Open Handover Chat"** button once approved.
- **KPI Metrics**: Instant overview of Lost, Found, Claims, and Reunited counts.

---

## 🛠️ Architecture

```
lib/
├── core/                                   # Shared infrastructure
│   ├── config/app_router.dart              # Central GoRouter routing & auth guards
│   ├── constants/app_colors.dart           # Design tokens (charcoal, muted semantic accents)
│   ├── constants/app_spacing.dart          # Spatial rhythm tokens
│   ├── services/offline_service.dart       # Draft recovery & offline sync queue
│   ├── theme/app_theme.dart                # Light and Dark theme specifications
│   └── widgets/                            # Reusable atoms (AppButton, AppCard, AppTextField)
└── features/                               # Self-contained domain modules
    ├── admin/                              # Campus security moderation & recovery metrics
    ├── auth/                               # .edu domain validation & student session
    ├── chat/                               # Gated handover chat & embedded in-page messaging
    ├── claim/                              # Claim quiz, one-claim rule & finder review
    ├── home/                               # Campus discovery feed, search, category filters
    ├── item/                               # Item detail view, status timeline, campus map explorer, Google map tagger
    ├── notifications/                      # Multi-factor smart matching engine & alerts
    ├── profile/                            # Student ID card, 3-tab activity hub, and KPI stats
    └── report/                             # Lost/Found reporting form with photo & GPS pin tagger
```

---

## 🚀 Setup & Execution Guide

### Prerequisites
- Flutter SDK 3.38+ / Dart 3.10+
- Android Studio with Android SDK 36 (or Pixel 8 Emulator)
- Google Chrome (for web testing)

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Verify Code Quality & Automated Tests
```bash
# Run static analysis (0 issues found)
flutter analyze

# Run complete test suite (24 passing unit & widget tests)
flutter test
```

### 3. Launch on Live Devices

**On Android Emulator / Physical Device:**
```bash
flutter run
```

**On Google Chrome (Web):**
```bash
flutter run -d chrome --web-port 8080
```

### 4. Standalone Android APK Deliverable
```bash
flutter build apk --debug
# Output binary: build/app/outputs/flutter-apk/app-debug.apk
```
Direct download link: [**Download Pre-Compiled APK**](https://github.com/Dhyanesh2603/FinderKeepers/releases/download/v1.0.0/app-debug.apk)

---

## 📚 Technical Documentation
- **[PROJECT_EXPLANATION.md](PROJECT_EXPLANATION.md)**: Synchronized architecture document with file-by-file explanations and state flow diagrams.
- **`EXPLANATION.html`**: Comprehensive private interactive documentation portal with deep code explanations, interview cheat sheets, and live change history (strictly local, git-ignored).
