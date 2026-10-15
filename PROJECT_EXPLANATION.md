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

> **Status**: Feature 2 Completed (Campus Authentication, Session Management, and Hub Navigation)

---

## 9. Feature 2 Explanation: Authentication & Campus Student Session

### Purpose
In a campus Lost & Found application, **trust and accountability** are paramount. Strangers on the open internet cannot be allowed to claim items or contact students. Feature 2 introduces:
1. **Campus Domain Enforcement**: Automated verification ensuring accounts use verified academic emails (`.edu` or campus domain).
2. **Student Identity Model (`AppUser`)**: Encapsulates Student ID, full name, email, verification status, and registration timestamp.
3. **Repository Pattern with Offline/Mock Support (`AuthRepository`)**: Decouples the UI from Firebase so the application can run in offline demo mode, automated CI tests, and production Firebase Auth without changing a single UI line.
4. **Reactive Navigation Guards**: `GoRouter` listens to Riverpod's `authStateChangesProvider`. Logging in immediately routes to `/home`; logging out instantly revokes access and redirects to `/login`.
5. **Ergonomic Testing Utilities**: Pre-seeded demo student (`student@campus.edu` / `password123`) with one-tap auto-fill on the login screen.

---

## 10. File-by-File Breakdown (Feature 2)

### `lib/features/auth/domain/models/app_user.dart`
- **Purpose**: Pure domain representation of a campus student.
- **Responsibility**: Holds immutable user properties (`uid`, `email`, `displayName`, `studentId`, `isVerified`, `createdAt`) and provides JSON/Map serialization for Firestore.
- **Why It Exists**: Separates database schemas from UI logic.
- **Interactions**: Consumed by `auth_repository.dart`, `home_screen.dart`, and future claim/chat features.

### `lib/features/auth/data/auth_repository.dart`
- **Purpose**: Data layer handling login, registration, and active session streams.
- **Responsibility**: Provides the abstract `AuthRepository` contract, campus domain validation (`validateCampusEmail`), and the `InMemoryAuthRepository` implementation.
- **Why It Exists**: Following the Dependency Inversion Principle, UI controllers depend on an abstract interface rather than a concrete Firebase instance.
- **Interactions**: Consumed by `auth_controller.dart` and `app_router.dart`.

### `lib/features/auth/presentation/controllers/auth_controller.dart`
- **Purpose**: Manages UI action states for authentication.
- **Responsibility**: Extends Riverpod 3's `AsyncNotifier<void>` to track idle, loading, and error states during sign in and registration.
- **Why It Exists**: Keeps widget classes purely declarative by moving business logic and asynchronous try/catch blocks into a dedicated controller.
- **Interactions**: Consumed by `login_screen.dart`, `register_screen.dart`, and `home_screen.dart`.

### `lib/features/auth/presentation/screens/login_screen.dart`
- **Purpose**: Minimal, accessible student sign-in screen.
- **Responsibility**: Collects campus email and password, provides demo auto-fill for interview testing, and triggers `AuthController.signIn`.
- **Why It Exists**: Gives returning students immediate access to their claims, reports, and messages.
- **Interactions**: Navigates from `splash_screen.dart` and links to `register_screen.dart`.

### `lib/features/auth/presentation/screens/register_screen.dart`
- **Purpose**: Student onboarding and account registration screen.
- **Responsibility**: Collects Full Name, Student ID number, campus email, and password.
- **Why It Exists**: Ensures every new user is bound to their student ID number before submitting claims or lost reports.
- **Interactions**: Accessible from `login_screen.dart`.

### `lib/features/home/presentation/screens/home_screen.dart`
- **Purpose**: Authenticated dashboard landing screen.
- **Responsibility**: Displays current student's name, ID badge, verified campus status, and sign-out action.
- **Why It Exists**: Confirms successful authentication and acts as the mount point for Feature 3 (Browse & Feed).
- **Interactions**: Accessible only when authenticated; protected by `app_router.dart` guards.

---

## 11. Authentication Flow Diagram

```
[ Student Enters Credentials ]
               │
               ▼
[ LoginScreen / RegisterScreen ]
               │ (Calls ref.read(authControllerProvider.notifier).signIn())
               ▼
[ AuthController (AsyncNotifier) ]
         State = AsyncLoading()
               │ (Delegates to AuthRepository)
               ▼
[ AuthRepository ]
         Validates campus email domain (.edu)
         Authenticates against user registry
         Emits new AppUser on authStateChanges
               │
               ▼
[ appRouterProvider (GoRouter) ]
         Detects authStateChanges has user
         Redirect trigger: '/login' -> '/home'
               │
               ▼
[ HomeScreen (Verified Student Hub) ]
```

---

## 12. Interview Notes (Feature 2)

### Q1: Why did you create an abstract `AuthRepository` with an in-memory implementation instead of calling `FirebaseAuth.instance` directly in widgets?
**Answer**:
> *"Directly calling `FirebaseAuth.instance` inside UI widgets tightly couples the presentation layer to a third-party SDK. If we need to test widgets offline, run automated unit tests in CI, or switch providers, every screen breaks. By programming to an interface (`AuthRepository`), our UI only knows about `AppUser`. The concrete implementation can be swapped from in-memory to Firebase with zero changes to any UI screen."*

### Q2: How does GoRouter handle reactive authentication redirects with Riverpod?
**Answer**:
> *"We pass `authStateChangesProvider` into `appRouterProvider`. Whenever the stream emits a new user (login) or null (logout), GoRouter re-evaluates its `redirect` function. If an unauthenticated user tries to navigate to a protected route like `/home`, GoRouter automatically intercepts and redirects them to `/login`. When they sign in, it redirects them into `/home`."*

### Q3: What is the benefit of `AsyncValue.guard()` in Riverpod?
**Answer**:
> *"Instead of writing repetitive `try { state = AsyncData(...) } catch (err, stack) { state = AsyncError(...) }` boilerplate in every controller method, `AsyncValue.guard()` automatically executes the asynchronous callback, catches any thrown exceptions, and cleanly populates `state.error` while setting `state.isLoading` to false."*

---

## 13. Feature 3 Explanation: Campus Feed & Item Discovery

### Purpose
The Campus Feed is the centerpiece of Finders Keepers. It enables students to browse, filter, and search for lost or found items across campus. Feature 3 introduces:
1. **Item Domain Model (`Item`)**: Encapsulates `id`, `title`, `description`, `type` (`lost`/`found`), `status` (`open`/`claimPending`/`reunited`), `category`, `approximateLocation`, and `verificationQuestionsCount`.
2. **Item Repository (`ItemRepository`)**: Abstract contract with an in-memory implementation seeded with realistic campus items (headphones, wallets, keys, books).
3. **Multi-Criteria Filtering (`feed_controller.dart`)**:
   - `selectedTypeFilterProvider`: Segmented toggle (`All`, `Lost`, `Found`).
   - `selectedCategoryFilterProvider`: Horizontal chips for 7 campus categories.
   - `searchQueryProvider`: Real-time substring search matching title, description, and campus location.
   - `filteredItemsProvider`: Derived provider computing the filtered list reactively.
4. **ItemCard Component**: Minimal, spacious card displaying color-coded type badge, category tag, relative timestamp, and approximate landmark location.
5. **Empty & Loading States**: Clean fallback UI when search or filters return zero matches.

---

## 14. Feed Data Flow

```
[ User Interaction ] (Search text, Type pill tab, Category chip)
         │
         ▼
[ Feed Notifiers ] (SelectedTypeNotifier, SelectedCategoryNotifier, SearchQueryNotifier)
         │
         ▼
[ filteredItemsProvider ]
   (Watches itemsStreamProvider + filter notifiers)
   (Computes matches without re-fetching from repository)
         │
         ▼
[ HomeScreen ListView.separated ]
   (Renders ItemCard widgets with smooth scrolling)
```

---

## 15. Feature 4 Explanation: Item Reporting Flow (`/report`)
- **Image Picker Support**: Students can select photos from device camera or photo gallery.
- **Landmark Geolocation**: Selection among standardized campus landmarks (Library, Student Center, Sports Arena, Cafeteria, Dorms).
- **Anti-Fraud Challenge Builder**: Reporters can define dynamic secret verification questions (e.g., "What color is the keychain?", "What initials are engraved?") only known to the real owner.
- **Local Persistence**: Interrupted reports and offline drafts are safely buffered.

---

## 16. Feature 5 Explanation: Approximate Location & Privacy Map (`/items/:id`)
- **Privacy Protection**: Exact GPS coordinates are never publicly rendered. Instead, an approximate ~100m fuzzed radius circle on a custom vector map preserves user privacy and eliminates predatory pickups.
- **Status Lifecycle Indicator**: Timeline tracker visually displaying item progression: `Open` -> `In Verification` -> `Claimed` -> `Reunited`.
- **Confidential Challenge Shield**: Indicates the presence of verification questions without exposing their expected answers.

---

## 17. Feature 6 Explanation: Anti-Fraud Ownership Claims (`/items/:id/claim` & `/items/:id/claims`)
- **Claim Submission**: Claimants must answer the finder's specific verification questions.
- **Finder Review Dashboard**: The student who reported the item can view submitted claims, inspect the answers, and either `Approve` or `Reject`.
- **Automated Lifecycle Update**: Approving a claim advances item status to `In Verification` or `Reunited` and unlocks the secure chat channel.

---

## 18. Feature 7 Explanation: Post-Verification Handover Chat (`/chat/:claimId`)
- **Restricted Access**: The chat channel is completely locked until a claim is verified and approved.
- **Zero Personal Data Leak**: Students do not need to share phone numbers, social media handles, or personal email addresses.
- **Campus Handover Coordination**: Real-time messaging stream to agree on safe campus meeting spots (e.g., Student Union desk, campus security office).

---

## 19. Feature 8 Explanation: Student Profile & Claims History (`/profile`)
- **Identity Card**: Verified student ID, campus email, and department badge.
- **Dual Tabs**:
  - `My Reports`: View and manage all items reported by the student.
  - `My Claims`: Track the live approval status of claims submitted by the student with one-tap navigation to the post-verification chat.

---

## 20. Verification & Test Suite Summary
- **Static Analysis**: `flutter analyze` passes with **0 issues**.
- **Automated Tests**: 12/12 unit and widget tests passing across auth, feed, claims, and chat modules.
- **Emulator Verification**: Running and hot-reloaded on Pixel 8 API 36 (`emulator-5554`).

