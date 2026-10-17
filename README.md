# Finders Keepers 🔍 — Campus Lost & Found Platform

> **A student-first campus Lost & Found mobile application with privacy-preserving approximate locations, anti-fraud ownership verification, and secure in-app messaging.**  
> Built for **CC-VIT 26-27 Promotional Cycle — Recruitment Task Sheet #12**.

Inspired by the calm, minimal design language of Apple, Linear, and Notion. Built with Flutter, Riverpod 3, and GoRouter.

---

## 📋 Task Sheet #12 Compliance Matrix

| # | Expected Functionality / Deliverable | Status | Implementation Details |
|---|---|:---:|---|
| **01** | Report lost and found items (descriptions, images, locations) | **✅ 100%** | Multi-step form with cross-platform `Uint8List` image picker, standardized campus landmarks, and custom secret question builder. |
| **02** | Searchable listing of reported items | **✅ 100%** | Real-time substring query matching across titles, descriptions, and landmarks with 7 category filter chips. |
| **03** | Approximate locations on a map | **✅ 100%** | Interactive custom vector canvas map rendering a fuzzed ~100m radius circle around landmarks to prevent predatory theft. |
| **04** | Submit ownership claims | **✅ 100%** | Dedicated `/items/:id/claim` flow where claimants must answer the finder's confidential questions. |
| **05** | Ownership verification process before handover | **✅ 100%** | Reporter review dashboard (`/items/:id/claims`) with **Approve** and **Reject** verification actions. |
| **06** | Track item states (lost, found, claimed, reunited) | **✅ 100%** | Domain lifecycle state machine (`open` → `inVerification` → `reunited`) with visual status progression timeline. |
| **07** | Interrupted submissions & unreliable network handling | **✅ 100%** | `OfflineService` draft auto-save and restoration, plus an offline submission queue that auto-syncs when reconnected. |
| **08** | Protect sensitive user information throughout | **✅ 100%** | No phone numbers or personal emails are shared. Identifying marks stay confidential behind challenge gates. |
| **Bonus 1** | Offline-first functionality | **✅ 100%** | Local persistence, cached feed browsing, and offline report queue with live connectivity toggle simulator. |
| **Bonus 2** | Push notifications for matching items | **✅ 100%** | In-app notification center dispatching smart match alerts when confidence exceeds threshold. |
| **Bonus 3** | Image and category similarity matching | **✅ 100%** | `MatchEngine` multi-factor scoring (category + location + keyword tokens + 48h time window). |
| **Bonus 4** | Location-based recommendations | **✅ 100%** | Recommends items found in the same or adjacent campus zones (Library, Dining, Recreation, Lab complexes). |
| **Bonus 5** | Administrative moderation interface | **✅ 100%** | Campus security dashboard (`/admin`) with recovery analytics KPI bar, item moderation, and claims audit inspection. |
| **Bonus 6** | Secure in-app messaging between users | **✅ 100%** | Private chat channel (`/chat/:claimId`) strictly unlocked post-verification to arrange safe campus handovers. |

---

## 🛡️ Anti-Fraud & Ownership Verification Mechanism

Traditional lost-and-found boards fail because public listings reveal unique identifiers (e.g., serial numbers, engravings, custom stickers), allowing dishonest users to falsely claim valuable electronics.

Finders Keepers uses a **Blind Proof-of-Ownership Challenge**:
1. **Reporter Challenge**: When a student reports finding an item (e.g. *AirPods Pro*), they specify secret verification questions (e.g., *"What initials are engraved on the lid?"*, *"What color is the protective case?"*). The expected answers are kept confidential.
2. **Claim Submission**: When a claimant taps *Claim This Item*, they must submit answers to the creator's secret questions.
3. **Finder Review**: The finder inspects the submitted answers on the `/items/:id/claims` dashboard and either **Approves** or **Rejects** the claim.
4. **Gated Handover Chat**: Only upon approval does the app advance item status to `inVerification` and unlock the private in-app chat (`/chat/:claimId`) for safe handover coordination.

---

## 🛠️ Architecture

```
lib/
├── core/                           # Shared infrastructure
│   ├── config/app_router.dart      # Central GoRouter routing & auth guards
│   ├── constants/                  # Design tokens (AppColors, AppSpacing)
│   ├── services/offline_service.dart # Draft recovery & offline sync queue
│   ├── theme/app_theme.dart        # Light and Dark theme specifications
│   └── widgets/                    # Reusable atoms (AppButton, AppCard, AppTextField)
└── features/                       # Self-contained domain modules
    ├── admin/                      # Campus security moderation & recovery metrics
    ├── auth/                       # .edu domain validation & student session
    ├── chat/                       # Gated post-verification peer-to-peer chat
    ├── claim/                      # Claim submission quiz & finder review dashboard
    ├── home/                       # Campus discovery feed, search, and category filters
    ├── item/                       # Item detail view, status timeline, privacy canvas map
    ├── notifications/              # Multi-factor smart matching engine & alerts
    ├── profile/                    # Student ID card & my reports/claims tracking
    └── report/                     # Lost/Found reporting form with photo attachment
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
# Run static analysis (0 issues)
flutter analyze

# Run complete test suite (16 passing tests)
flutter test
```

### 3. Launch on Live Devices

**On Android Emulator (Pixel 8):**
```bash
flutter run -d emulator-5554
```

**On Google Chrome (Web):**
```bash
flutter run -d chrome --web-port 8080
```

### 4. Build Standalone Android APK Deliverable
```bash
flutter build apk --debug
# Output binary: build/app/outputs/flutter-apk/app-debug.apk
```

---

## 📚 Technical Documentation
- **[PROJECT_EXPLANATION.md](PROJECT_EXPLANATION.md)**: Synchronized architecture document with file-by-file explanations and state flow diagrams.
- **`EXPLANATION.html`**: Comprehensive private interactive documentation portal with deep code explanations, interview cheat sheets, and live change history (local only, git-ignored).
