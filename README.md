# Finders Keepers 🔍

> **A student-first campus Lost & Found platform with privacy-preserving approximate locations and structured ownership verification.**

Inspired by the calm, minimal design language of Apple, Linear, and Notion. Built with Flutter, Riverpod, GoRouter, Firebase, and Hive.

---

## ✨ Key Principles

- **Privacy-First Approximate Locations**: Public maps only display fuzzified approximate zones (e.g. "Library 2nd Floor") until a claim is verified. Exact details are never leaked.
- **Structured Ownership Verification**: Claims require answering owner-defined verification questions or identifying hidden attributes before any private chat or handover occurs.
- **Offline-Ready**: Local caching with Hive ensures students can draft reports and browse cached items even in campus network dead zones.
- **Calm, Minimal Design**: Monochrome base (charcoal, off-white) with soft status accents (muted green for found/reunited, muted amber for lost/pending).

---

## 🛠️ Architecture

Finders Keepers uses a **Feature-First Architecture**:

```
lib/
├── core/
│   ├── config/          # Central GoRouter navigation
│   ├── constants/       # AppColors and AppSpacing dimensional scale
│   ├── theme/           # Light & Dark Plus Jakarta Sans ThemeData
│   ├── utils/           # Helper formatters and location calculators
│   └── widgets/         # Reusable minimal components (AppButton, AppCard, AppTextField)
└── features/
    ├── home/            # Browse feed, category filters, search, and splash
    ├── auth/            # Student campus login & session management
    ├── report/          # Report lost/found items with photo upload
    ├── item/            # Detailed inspection & status tracking
    ├── claim/           # Structured verification question quiz
    ├── chat/            # Verified private student messaging
    ├── notifications/   # Realtime updates and claim alerts
    └── profile/         # Student report history and settings
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.38+ / Dart 3.10+
- Android Studio with Android SDK 36 (API 36)
- Connected Android device or running Emulator

### Installation

```bash
# 1. Clone repository
git clone https://github.com/your-username/finders-keepers.git
cd finders-keepers

# 2. Get dependencies
flutter pub get

# 3. Run static analysis & tests
flutter analyze
flutter test

# 4. Launch on connected device or emulator
flutter run
```

---

## 📚 Documentation

- [PROJECT_EXPLANATION.md](file:///d:/new_code/PROJECT_EXPLANATION.md): Deep-dive into architecture, state management, security, and interview question guides.
- [FILE_GUIDE.md](file:///d:/new_code/FILE_GUIDE.md): Master table of every source file, dependencies, classes, and interview takeaways.
