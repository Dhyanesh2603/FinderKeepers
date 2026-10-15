# Finders Keepers — Comprehensive Project Explanation

> **Platform**: Student Campus Lost & Found  
> **Tech Stack**: Flutter (3.38.5+), Riverpod, GoRouter, Firebase, Hive, Google Maps  
> **Status**: Feature 1 Completed (Architecture, Core Design System, and App Foundation)

---

## 1. Overall Architecture

Finders Keepers uses a **Feature-First Architecture** designed for clarity, testability, and ease of explanation.

```
lib/
├── core/                        <-- Shared infrastructure used across multiple features
│   ├── config/                  <-- Global routing (GoRouter) & environment configs
│   ├── constants/               <-- Color palette, spacing tokens, and typography
│   ├── theme/                   <-- Light and dark theme specifications
│   ├── utils/                   <-- Formatting and mathematical helpers
│   └── widgets/                 <-- Reusable design-system components (buttons, cards, inputs)
└── features/                    <-- Domain-specific modules
    ├── home/                    <-- Feed, browse, search, and splash landing
    ├── auth/                    <-- Campus student login & session management
    ├── report/                  <-- Reporting lost or found items with approximate geolocation
    ├── item/                    <-- Item details, status timeline, and photo inspection
    ├── claim/                   <-- Structured ownership verification flow
    ├── chat/                    <-- Private post-verification student communication
    ├── notifications/           <-- Item status change and claim alerts
    └── profile/                 <-- User profile, history, and active reports
```

### Why Feature-First over Layer-First?
In a traditional layer-first architecture (`controllers/`, `views/`, `models/`), adding or modifying a single feature requires jumping across widely separated folders. In **Feature-First**:
1. All files related to a specific domain (e.g. `claim/`) live together.
2. Code is easily modularized and discoverable.
3. Deleting or refactoring a feature only affects that folder.
4. Junior and senior developers can immediately locate where business logic lives.

---

## 2. Folder Structure

| Folder | Responsibility |
|---|---|
| `lib/core/config/` | Application routing with GoRouter, dependency overrides, and app constants. |
| `lib/core/constants/` | Pure design tokens: `app_colors.dart` and `app_spacing.dart`. No widget logic. |
| `lib/core/theme/` | `app_theme.dart` translating raw tokens into standard Flutter `ThemeData` (Light & Dark). |
| `lib/core/widgets/` | Foundational primitives: `AppButton`, `AppCard`, `AppTextField`. Pure presentation. |
| `lib/features/home/` | Initial landing experience, campus announcement banner, item feed and exploration. |
| `lib/features/auth/` | Student campus authentication, domain email verification, and auth state provider. |
| `lib/features/report/` | Form workflows for reporting lost or found items with photo attachments. |
| `lib/features/claim/` | Privacy-centric ownership quiz and verification handshake. |

---

## 3. Feature 1 Explanation: Core Architecture & Design System

### Purpose
Before writing any database queries or complex forms, an app needs a reliable visual language and ergonomic primitives. Feature 1 delivers:
1. **Design System**: A calm, high-contrast, startup-grade design language (charcoal, off-white, muted green, and muted amber) inspired by Apple, Linear, and Raycast.
2. **Standard Spacing Scale**: A mathematical spacing system (4px, 8px, 12px, 16px, 20px, 24px, 32px, 40px) preventing visual clutter and magic numbers.
3. **Responsive Primitives**: Reusable buttons (`AppButton`), cards (`AppCard`), and text inputs (`AppTextField`) that adapt automatically to light and dark modes.
4. **App Entry & Navigation**: ProviderScope injection with declarative routing via `GoRouter`.

---

## 4. File-by-File Breakdown (Feature 1)

### `lib/main.dart`
- **Purpose**: App entry point.
- **Responsibility**: Boots Flutter bindings and mounts the root `ProviderScope`.
- **How It Works**: Calls `WidgetsFlutterBinding.ensureInitialized()` and wraps `FindersKeepersApp` in `ProviderScope`. It watches `appRouterProvider` to feed GoRouter directly into `MaterialApp.router`.
- **Why It Exists**: In Riverpod, state lives in `ProviderContainer` managed by `ProviderScope`. Placing it at the root makes providers available throughout the entire widget tree without global singletons.
- **Interactions**: Imports `core/config/app_router.dart` and `core/theme/app_theme.dart`.

### `lib/core/constants/app_colors.dart`
- **Purpose**: Centralized design token repository for all application colors.
- **Responsibility**: Houses constants for light and dark backgrounds, charcoal accents, semantic status colors (muted green for found/reunited, muted amber for lost/pending, muted red for rejected), and border tokens.
- **How It Works**: Exposes `static const Color` fields so the compiler inlines values with zero runtime overhead.
- **Why It Exists**: Eliminates hardcoded hex codes (`Color(0xFF...)`) in widgets. Changing a color brand token in this single file immediately refreshes the entire application.
- **Interactions**: Consumed by `app_theme.dart`, `app_button.dart`, `app_card.dart`, `app_text_field.dart`, and screens.

### `lib/core/constants/app_spacing.dart`
- **Purpose**: Standardization of margins, paddings, gaps, and corner radii.
- **Responsibility**: Provides fixed geometric scale: `xxs` (4), `xs` (8), `s` (12), `m` (16), `l` (20), `xl` (24), `xxl` (32), `radiusSmall` (8), `radiusMedium` (14), `radiusLarge` (20).
- **How It Works**: Pure constants and `BorderRadius` helpers.
- **Why It Exists**: Prevents UI inconsistencies where different screens have mismatched padding (e.g. 13px vs 17px).
- **Interactions**: Consumed across all UI widgets and layout builders.

### `lib/core/theme/app_theme.dart`
- **Purpose**: Builds Flutter's official `ThemeData` for Light and Dark modes.
- **Responsibility**: Integrates `GoogleFonts.plusJakartaSans` typography with `AppColors`, zero-elevation transparent AppBars, and clean divider themes.
- **How It Works**: Reads brightness and sets `ColorScheme`, `TextTheme`, `AppBarTheme`, and `ScaffoldBackgroundColor`.
- **Why It Exists**: Centralizing the theme guarantees that built-in widgets (like `Text`, `AppBar`, `Divider`) inherit the startup aesthetic automatically.
- **Interactions**: Read by `main.dart` during app launch.

### `lib/core/widgets/app_button.dart`
- **Purpose**: Reusable button component.
- **Responsibility**: Renders primary (solid charcoal/white), secondary (tinted surface), and outline buttons with built-in loading indicator, touch inkwell feedback, and disabled states.
- **How It Works**: Uses `Material` with `RoundedRectangleBorder` (avoiding illegal duplicate `borderRadius` properties) and `InkWell` for native ripple ergonomics.
- **Why It Exists**: Eliminates duplicate `ElevatedButton` boilerplate and ensures consistent button height (52px) and typography across the product.
- **Interactions**: Consumed by screens needing user action (e.g. `splash_screen.dart`, auth screens).

### `lib/core/widgets/app_card.dart`
- **Purpose**: Base container for items, summaries, and notifications.
- **Responsibility**: Wraps child widgets in a clean, rounded container with a subtle 1px border, light-mode soft shadow, and dark-mode slate surface.
- **How It Works**: Uses `BoxDecoration` with `Border.all` and optional `InkWell` when `onTap` is supplied.
- **Why It Exists**: Avoids heavy Material elevation and cards with aggressive shadows, maintaining the Apple/Linear minimal aesthetic.
- **Interactions**: Consumed by feeds, dashboards, and item detail lists.

### `lib/core/widgets/app_text_field.dart`
- **Purpose**: Standard form input field.
- **Responsibility**: Renders text inputs with optional label, hint text, prefix icon, password toggle suffix, and focused charcoal borders.
- **How It Works**: Wraps Flutter's `TextField` inside a `Column` with custom `InputDecoration`.
- **Why It Exists**: Encapsulates consistent input ergonomics and border styling for login, search, and item report forms.
- **Interactions**: Consumed by authentication and report features.

### `lib/core/config/app_router.dart`
- **Purpose**: Declarative application routing configuration.
- **Responsibility**: Maps URL paths (e.g. `/`, `/auth`, `/items/:id`) to screen widgets using `GoRouter`.
- **How It Works**: Declared as a Riverpod `Provider<GoRouter>` so it can listen to auth changes in future steps.
- **Why It Exists**: Declarative routing prevents navigation spaghetti (`Navigator.push(context, ...)`) and provides deep linking, web support, and back-button consistency.
- **Interactions**: Consumed by `main.dart`.

### `lib/features/home/presentation/screens/splash_screen.dart`
- **Purpose**: The welcome screen presenting the brand and core philosophy.
- **Responsibility**: Introduces campus students to the platform's privacy-first model (approximate locations, ownership verification).
- **How It Works**: Uses `LayoutBuilder`, `SingleChildScrollView`, and `ConstrainedBox` with `IntrinsicHeight` so content breathes on large devices but scrolls without RenderFlex overflows on smaller phones.
- **Why It Exists**: Acts as the initial screen and proves the design tokens, fonts, and responsive layout primitives work end-to-end.
- **Interactions**: Linked from `app_router.dart`.

---

## 5. Data Flow (Feature 1)

```
[ main.dart ]
     │ (Wraps app in ProviderScope)
     ▼
[ FindersKeepersApp (ConsumerWidget) ]
     │ (ref.watch(appRouterProvider))
     ▼
[ appRouterProvider (GoRouter) ]
     │ (Navigates to '/')
     ▼
[ SplashScreen ]
     │ (Applies AppTheme, AppColors, AppSpacing)
     ▼
[ AppCard & AppButton ]
     │ (Rendered on Pixel 8 Emulator)
```

---

## 6. Firebase Structure (Architecture Preview)

*Note: Initialized in upcoming Feature 2.*

```
users/ (collection)
  └── {userId} (document)
        ├── uid: String
        ├── email: String (Must end in campus domain, e.g. @university.edu)
        ├── displayName: String
        ├── photoUrl: String
        └── createdAt: Timestamp

items/ (collection)
  └── {itemId} (document)
        ├── title: String
        ├── category: String (Electronics, Keys, Wallets, IDs, Books, Other)
        ├── type: String ("lost" | "found")
        ├── status: String ("open" | "claim_pending" | "reunited")
        ├── description: String
        ├── approximateLocation: String (e.g., "North Campus Library - 2nd Floor")
        ├── geoPoint: GeoPoint (Approximate fuzzing applied for privacy)
        ├── photoUrls: List<String>
        ├── reporterId: String (UID)
        ├── secretVerificationAnswers: Map (Hidden from public read)
        └── createdAt: Timestamp

claims/ (collection)
  └── {claimId} (document)
        ├── itemId: String
        ├── claimantId: String
        ├── submittedAnswers: Map<String, dynamic>
        ├── status: String ("pending" | "approved" | "rejected")
        └── createdAt: Timestamp

chats/ (collection)
  └── {chatId} (document)
        ├── itemId: String
        ├── participants: [reporterId, claimantId]
        └── lastMessage: Timestamp
```

---

## 7. State Management: Why Riverpod?

1. **Compile-time Safety**: Unlike `Provider` which can throw `ProviderNotFoundException` at runtime, Riverpod providers are top-level global constants analyzed at compile time.
2. **No BuildContext Dependency**: Providers can be read, watched, and invalidated outside widget trees (e.g., inside route guards or background workers).
3. **Auto-disposal**: `ref.watch(provider.autoDispose)` automatically frees memory when widgets unmount.
4. **Mockability**: During unit and widget testing, providers can be overridden using `ProviderScope(overrides: [...])` without complex mocking frameworks.

---

## 8. Interview Notes (Feature 1)

### Q1: Why did you choose Feature-First architecture over Layer-First?
**Answer**:
> *"Layer-first groups files by technical type (`models/`, `views/`, `controllers/`). As an application grows to dozens of features, developers must navigate across completely different folders to make a simple change to the 'Claim' or 'Chat' flow. Feature-first groups files by domain capability (`features/claim/`), making boundaries explicit, reducing cognitive load, and keeping the codebase maintainable as teams grow."*

### Q2: What is the purpose of `ProviderScope` in Riverpod?
**Answer**:
> *"Riverpod stores provider state inside an internal object called a `ProviderContainer`. The `ProviderScope` widget stores this container in the widget tree. By placing it at the root in `main.dart`, all providers become accessible throughout the entire app without requiring singleton patterns."*

### Q3: Why use `GoRouter` instead of `Navigator.push`?
**Answer**:
> *"Declarative routing decouples the action of navigating from widget trees. With GoRouter, all routes are centrally registered in an `appRouterProvider`. This enables deep linking, URL parsing on web/desktop, route-level redirect guards (such as kicking unauthenticated users to `/login`), and clean unit testing of navigation flows."*

### Q4: Common Mistake in Flutter Layouts:
**Mistake**: Using `Spacer()` or `Expanded()` inside an unconstrained vertical `SingleChildScrollView`.  
**Why it fails**: `SingleChildScrollView` grants its children infinite vertical constraints. An `Expanded` or `Spacer` demands to fill remaining space, leading to an infinite-height assertion crash.  
**How we solved it**: In `splash_screen.dart`, we used `LayoutBuilder` paired with `ConstrainedBox(minHeight: constraints.maxHeight - padding)` and `IntrinsicHeight`. This guarantees the layout occupies at least the full screen while retaining scrollability on small screens.

---

## 9. Next Steps
- Await approval from user.
- Feature 2: Authentication & User Session (Campus email validation, Riverpod Auth Repository, and Login/Register screens).
