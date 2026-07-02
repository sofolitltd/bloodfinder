# Quality Assurance Guide — BloodFinder

> **Status:** No tests currently exist. This document outlines the QA strategy and practices to establish.
> **App version:** 1.0.0+5 | **Target:** Android & Web (Firebase)

---

## Table of Contents

1. [Overview & Principles](#1-overview--principles)
2. [Project Architecture & Testing Impact](#2-project-architecture--testing-impact)
3. [Testing Stack & Setup](#3-testing-stack--setup)
4. [Unit Tests](#4-unit-tests)
5. [Widget Tests](#5-widget-tests)
6. [Integration Tests](#6-integration-tests)
7. [Feature-by-Feature Coverage](#7-feature-by-feature-coverage)
8. [Manual QA Checklist](#8-manual-qa-checklist)
9. [Release Checklist](#9-release-checklist)
10. [Code Quality & Linting](#10-code-quality--linting)
11. [Firebase & Backend Testing](#11-firebase--backend-testing)
12. [Performance & Accessibility](#12-performance--accessibility)
13. [Test Naming & File Conventions](#13-test-naming--file-conventions)

---

## 1. Overview & Principles

### Why QA matters for BloodFinder

BloodFinder connects blood donors with people in urgent need. A crash, wrong data, or a failed notification can have real-world consequences. Testing is not optional — lives depend on this app working correctly.

### Testing philosophy

| Principle | Practice |
|---|---|
| **Shift left** | Write tests during development, not after |
| **Test behavior, not implementation** | Test what the widget/user sees, not internal state |
| **Feature isolation** | Each feature module should be testable in isolation |
| **Data layer coverage first** | Repositories and models are the highest-risk code |
| **Riverpod providers are the integration seam** | Test providers, not individual classes in isolation where possible |

### Current project state

- **143 Dart source files** across 14 feature modules
- **Zero tests** — `flutter_test` is a dev dependency but unused
- **No CI/CD pipeline** — GitHub Actions, Codemagic, or similar not configured
- **Development mode active** — Firestore collections use `_test` suffix

---

## 2. Project Architecture & Testing Impact

```
lib/
├── core/              → constants, theme, utils (pure Dart → unit test)
├── data/
│   ├── models/        → Freezed data classes (unit test: serialization)
│   ├── providers/     → Riverpod providers (widget test w/ ProviderScope)
│   ├── repositories/  → Firebase-dependent logic (mock Firebase → unit test)
│   └── services/      → FCM (integration test or mock)
├── features/
│   └── {feature}/
│       ├── models/        → Unit tests
│       ├── providers/     → ProviderScoped widget/provider tests
│       ├── repositories/  → Mock Firebase tests
│       └── presentation/
│           ├── pages/     → Widget tests (navigation, state → UI)
│           └── widgets/   → Widget tests (rendering, interaction)
├── routes/            → GoRouter config (integration test: navigation)
└── shared/            → Shared widgets (widget tests)
```

**Key testing notes:**
- **Riverpod + Freezed** means many serialization/state classes are code-generated and should be tested for boundary values
- **GoRouter** with `StatefulShellRoute` — test tab navigation and auth redirects
- **Firebase dependencies** — use `fake_cloud_firestore` and `firebase_auth_mocks` for unit testing
- **Flutter Map** — test with mock tile layers, verify markers render
- **App Links / Deep Links** — test via `Uri` parsing without real app_links

---

## 3. Testing Stack & Setup

### Recommended packages

Add to `pubspec.yaml` dev_dependencies:

```yaml
dev_dependencies:
  # Core testing
  flutter_test:
    sdk: flutter

  # Mocking
  mocktail: ^1.0.0              # or mockito: ^5.4.0
  # Mock Firebase (optional but recommended)
  fake_cloud_firestore: ^3.0.0
  firebase_auth_mocks: ^0.14.0

  # Test utilities
  riverpod_tester: ^1.0.0       # Riverpod-specific test helpers

  # Coverage
  very_good_analysis: ^6.0.0    # Lint rules (stricter)
```

### Running tests

```bash
# Run all tests
flutter test

# Run tests for a specific feature
flutter test test/features/blood_bank/

# Run a single test file
flutter test test/features/blood_bank/models/blood_bank_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Run with names filter
flutter test --name "blood bank"
```

### Test file organization

Tests should mirror `lib/` structure exactly:

```
test/
├── core/
│   ├── utils/
│   │   ├── geohash_test.dart
│   │   ├── phone_utils_test.dart
│   │   └── validators_test.dart
│   └── constants/
│       └── blood_groups_data_test.dart
├── data/
│   ├── models/
│   │   ├── user_model_test.dart
│   │   └── address_model_test.dart
│   └── repositories/
│       ├── auth_repository_test.dart
│       ├── user_repository_test.dart
│       └── ...
├── features/
│   ├── auth/
│   │   ├── providers/
│   │   │   └── registration_provider_test.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── login_page_test.dart
│   │       │   └── registration_page_test.dart
│   │       └── widgets/
│   │           └── registration_form_test.dart
│   ├── blood_bank/
│   │   ├── models/
│   │   │   └── blood_bank_test.dart
│   │   └── ...
│   └── {feature}/...
├── routes/
│   └── router_config_test.dart
└── shared/
    └── widgets/
        └── blood_request_card_test.dart
```

---

## 4. Unit Tests

### Priority order (highest risk first)

| Priority | Layer | Why |
|---|---|---|
| **P0** | `data/models/` | Freezed serialization — wrong JSON ↔ model mapping breaks everything |
| **P0** | `core/utils/` | Phone normalization, validation, geohash — used across features |
| **P1** | `data/repositories/` | Business logic wrapping Firebase — mock the Firestore layer |
| **P1** | Feature models | Each feature's model classes (BloodBank, Community, etc.) |
| **P2** | Feature providers | Riverpod providers — state transitions, error states |
| **P3** | Feature repositories | Firebase CRUD logic per feature |

### Model test example pattern

```dart
// test/data/models/user_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloodfinder/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson creates correct instance', () {
      final json = {
        'uid': 'abc123',
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '+8801712345678',
        'bloodGroup': 'A+',
        'district': 'Dhaka',
        'subDistrict': 'Mirpur',
        'isDonor': true,
        'createdAt': DateTime(2024).millisecondsSinceEpoch,
      };

      final user = UserModel.fromJson(json);

      expect(user.uid, 'abc123');
      expect(user.name, 'John Doe');
      expect(user.bloodGroup, 'A+');
      expect(user.isDonor, isTrue);
    });

    test('toJson produces correct map', () {
      final user = UserModel(
        uid: 'abc123',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '+8801712345678',
        bloodGroup: 'A+',
        district: 'Dhaka',
        subDistrict: 'Mirpur',
        isDonor: true,
        createdAt: DateTime(2024),
      );

      final json = user.toJson();

      expect(json['uid'], 'abc123');
      expect(json['bloodGroup'], 'A+');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'uid': 'abc123',
        'name': 'John Doe',
        'email': null,
        'phone': '+8801712345678',
        'bloodGroup': 'A+',
        'district': 'Dhaka',
        'subDistrict': null,
        'isDonor': false,
        'createdAt': DateTime(2024).millisecondsSinceEpoch,
      };

      final user = UserModel.fromJson(json);

      expect(user.email, isNull);
      expect(user.subDistrict, isNull);
      expect(user.isDonor, isFalse);
    });
  });
}
```

### Repository test example pattern

```dart
// test/data/repositories/auth_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
// ...

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late AuthRepository authRepository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    authRepository = AuthRepository(
      firestore: fakeFirestore,
      auth: mockAuth,
    );
  });

  group('AuthRepository', () {
    test('signOut clears local state', () async {
      await authRepository.signOut();
      expect(mockAuth.currentUser, isNull);
    });
  });
}
```

### Utility test — Phone Utils

```dart
// test/core/utils/phone_utils_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloodfinder/core/utils/phone_utils.dart';

void main() {
  group('PhoneUtils', () {
    test('normalizePhone removes spaces and prefixes', () {
      expect(PhoneUtils.normalizePhone('+880 1712 345678'), '+8801712345678');
      expect(PhoneUtils.normalizePhone('8801712345678'), '+8801712345678');
      expect(PhoneUtils.normalizePhone('01712345678'), '+8801712345678');
    });

    test('isValidBangladeshiPhone returns true for valid numbers', () {
      expect(PhoneUtils.isValidBangladeshiPhone('+8801712345678'), isTrue);
      expect(PhoneUtils.isValidBangladeshiPhone('01712345678'), isTrue);
    });

    test('isValidBangladeshiPhone returns false for invalid numbers', () {
      expect(PhoneUtils.isValidBangladeshiPhone('12345'), isFalse);
      expect(PhoneUtils.isValidBangladeshiPhone(''), isFalse);
    });
  });
}
```

---

## 5. Widget Tests

### When to write widget tests

- Every **page** that takes user input (forms, buttons)
- Every **shared widget** used across features
- **Bottom navigation** tab switching
- **Auth guard** redirect behavior
- **Dialog / bottom sheet** interactions

### Widget test pattern

```dart
// test/features/auth/presentation/widgets/registration_form_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ...

Widget createTestApp() {
  return ProviderScope(
    child: MaterialApp(
      home: RegistrationForm(),
    ),
  );
}

void main() {
  group('RegistrationForm', () {
    testWidgets('renders all required fields', (tester) async {
      await tester.pumpWidget(createTestApp());

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Blood Group'), findsOneWidget);
      expect(find.text('District'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
    });
  });
}
```

### Provider-scoped widget test

```dart
// test/features/blood_bank/presentation/widgets/blood_bank_card_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ...

void main() {
  testWidgets('BloodBankCard displays bank info', (tester) async {
    final bank = BloodBank(
      id: 'bank1',
      name: 'Sandhani Blood Bank',
      address: 'Dhaka Medical College',
      phone: '+8801712345678',
      bloodGroups: {'A+': 10, 'B+': 5},
      location: GeoPoint(23.7, 90.4),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: BloodBankCard(bank: bank),
        ),
      ),
    );

    expect(find.text('Sandhani Blood Bank'), findsOneWidget);
    expect(find.text('A+: 10'), findsOneWidget);
    expect(find.text('B+: 5'), findsOneWidget);
  });
}
```

### Navigation test (GoRouter)

```dart
// test/routes/router_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ...

void main() {
  testWidgets('unauthenticated user redirected to login', (tester) async {
    // Setup mock auth with no user
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override auth state provider to return unauthenticated
        ],
        child: MaterialApp.router(
          routerConfig: routerConfig,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
```

---

## 6. Integration Tests

Integration tests are lower priority until unit/widget coverage is solid. Focus on:

| Flow | Description | Priority |
|---|---|---|
| **Auth → Home** | Register → login → see home screen | P1 |
| **Blood request → Chat** | Post request → view in feed → start chat with donor | P1 |
| **Community** | Create → join → view members | P2 |
| **Profile** | Edit profile → persist across sessions | P2 |
| **Deep link** | Open shared community link from outside app | P2 |

### Integration test setup

```dart
// test/integration/auth_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth flow', () {
    testWidgets('user can register and see home', (tester) async {
      // Navigate to registration
      // Fill form
      // Submit
      // Verify redirected to home
    });
  });
}
```

> **Note:** Integration tests require `integration_test` package in dev_dependencies and a `test_driver/` directory. Start with E2E smoke tests after unit/widget coverage is established.

---

## 7. Feature-by-Feature Coverage

### Auth

| Test | Type | Priority |
|---|---|---|
| Login validation (empty fields, invalid email) | Widget | P0 |
| Login → error display (wrong credentials, no network) | Widget | P0 |
| Registration form → all fields, validation | Widget | P0 |
| Eligibility bottom sheet — donor flow | Widget | P1 |
| Forgot password flow | Widget | P1 |
| Auth guard — unauthenticated → login redirect | Widget | P0 |

### Blood Bank

| Test | Type | Priority |
|---|---|---|
| BloodBank model serialization | Unit | P0 |
| BloodBankCard renders correctly | Widget | P1 |
| Blood bank list — loading, empty, error states | Widget | P1 |
| Add blood bank form validation | Widget | P1 |
| Paginated bank list — load more | Widget | P2 |
| Location picker header — filter by district | Widget | P2 |

### Blood Request

| Test | Type | Priority |
|---|---|---|
| BloodRequest model serialization | Unit | P0 |
| Request form validation (group, contact, urgency) | Widget | P1 |
| Blood group selector → selection state | Widget | P1 |
| My requests list → states | Widget | P2 |
| District filter → correct results | Widget | P2 |

### Chat

| Test | Type | Priority |
|---|---|---|
| MessageBubble — sent/received styling | Widget | P1 |
| Chat input — send message, empty validation | Widget | P1 |
| Message list — scroll to latest | Widget | P2 |
| Chat archive page | Widget | P2 |

### Community

| Test | Type | Priority |
|---|---|---|
| Community model serialization | Unit | P0 |
| Community form validation | Widget | P1 |
| Join request sheet workflow | Widget | P1 |
| Member list — admin, member views | Widget | P2 |
| Group by blood type — filtering | Widget | P2 |
| Deep link community join | Integration | P2 |

### Donation

| Test | Type | Priority |
|---|---|---|
| Donation info card display | Widget | P1 |
| Certificate page rendering | Widget | P2 |
| Find donor → district and blood group filter | Widget | P1 |
| Donation poster card | Widget | P2 |

### Emergency Donor

| Test | Type | Priority |
|---|---|---|
| Add emergency donor form | Widget | P1 |
| Emergency donor list → refresh | Widget | P1 |
| Emergency donor model serialization | Unit | P0 |

### Events

| Test | Type | Priority |
|---|---|---|
| Event model serialization | Unit | P0 |
| Event detail page | Widget | P1 |
| Create event sheet | Widget | P1 |
| Events list — upcoming/past filter | Widget | P2 |

### Feed

| Test | Type | Priority |
|---|---|---|
| Feed page — content rendering | Widget | P1 |
| Feed provider — data fetching states | Unit | P1 |

### Feedback

| Test | Type | Priority |
|---|---|---|
| Feedback model serialization | Unit | P1 |
| Feedback repository — submit | Unit | P1 |

### Home

| Test | Type | Priority |
|---|---|---|
| Home actions — all action buttons | Widget | P1 |
| Custom autocomplete — search districts | Widget | P1 |
| Home requests — request cards | Widget | P1 |
| Home community — community preview | Widget | P2 |
| Home find donor — donor search card | Widget | P2 |

### My Circle

| Test | Type | Priority |
|---|---|---|
| MyCircleContact model serialization | Unit | P0 |
| Add contact sheet — phone input, validation | Widget | P1 |
| Contact list display | Widget | P2 |

### Notification

| Test | Type | Priority |
|---|---|---|
| Notification model serialization | Unit | P0 |
| Notification list page | Widget | P2 |
| FCM API — send notification | Unit | P2 |

### Profile

| Test | Type | Priority |
|---|---|---|
| Edit profile form validation | Widget | P1 |
| Avatar picker — image selection flow | Widget | P2 |
| Profile header — stats display | Widget | P1 |
| Address management section | Widget | P1 |

---

## 8. Manual QA Checklist

Run this checklist before every release.

### Authentication & Onboarding

- [ ] User can register with valid details
- [ ] Registration validation shows proper errors
- [ ] User can log in with registered credentials
- [ ] Login shows error for wrong credentials
- [ ] Forgot password sends reset email
- [ ] Eligibility screening flows correctly
- [ ] User can log out
- [ ] After logout, user cannot access protected pages

### Blood Requests

- [ ] User can post a blood request
- [ ] Blood request appears in feed
- [ ] User can view their own requests
- [ ] District filtering works on blood requests
- [ ] Contact info is displayed correctly
- [ ] "Urgent" flag is visually distinct

### Blood Banks

- [ ] Blood bank list loads with pagination
- [ ] District filter filters correctly
- [ ] Blood bank detail shows correct info
- [ ] Add blood bank form validates inputs
- [ ] Map markers appear at correct locations

### Chat

- [ ] User can start a chat from blood request
- [ ] Messages send and display in real time
- [ ] Message timestamps are correct
- [ ] Archived messages are accessible
- [ ] Unread messages are indicated

### Communities

- [ ] User can create a community
- [ ] User can join via deep link / app link
- [ ] Admin can approve/deny join requests
- [ ] Member list displays with blood groups
- [ ] Community info can be edited by admin
- [ ] Admins can remove members

### Donations

- [ ] User can log a donation
- [ ] Donation history shows correctly
- [ ] Certificate generates with correct info
- [ ] Find donor filters by district + blood group

### My Circle

- [ ] Add contact from phone contacts works
- [ ] Manual contact entry validates phone
- [ ] Contact list shows correctly
- [ ] Duplicate contacts are handled

### Notifications

- [ ] FCM notification received for blood requests
- [ ] Tapping notification opens correct screen
- [ ] Notification list shows history
- [ ] Local notifications work (chat messages)

### Profile

- [ ] Profile displays correct info
- [ ] Edit profile saves changes
- [ ] Avatar upload works
- [ ] Address management works
- [ ] Theme toggle (light/dark) works
- [ ] Logout works

### Navigation

- [ ] Bottom nav switches between 4 tabs
- [ ] Back navigation works correctly
- [ ] Deep links open the correct page
- [ ] Auth guard redirects unauthenticated users

### Device-Specific

- [ ] Android back button behavior is correct
- [ ] Keyboard doesn't overlap input fields
- [ ] Scroll behavior is smooth
- [ ] Pull-to-refresh works on list pages
- [ ] Screen rotation doesn't break layout *(if supported)*

### Edge Cases

- [ ] Empty states — no data messages shown
- [ ] Error states — retry buttons functional
- [ ] Offline — graceful degradation / error message
- [ ] Very long names/addresses — truncation or wrapping
- [ ] Rapid double-tap on submit buttons — no duplicate submission

---

## 9. Release Checklist

### Pre-Release

- [ ] **Production mode**: Verify `app_config.dart` uses `usersCollection = 'users'` (not `users_test`)
- [ ] **All Firestore collections**: Confirm `FirebaseDataSource.isDevMode = false`
- [ ] **Storage paths**: Confirm no `test/` prefix in Storage paths
- [ ] **Run full manual QA checklist** (section 8)
- [ ] **Run lint**: `flutter analyze` — zero issues
- [ ] **Run tests**: `flutter test` — all passing
- [ ] **Coverage check**: `flutter test --coverage` — review uncovered lines
- [ ] **Android build**: `flutter build apk --release` — builds successfully
- [ ] **Web build**: `flutter build web` — builds successfully
- [ ] **Version bump**: Update `version` in `pubspec.yaml`
- [ ] **Firebase index check**: Verify composite indexes are deployed
- [ ] **License check**: Confirm all assets have proper licenses

### Post-Release

- [ ] Smoke test on production Firebase data
- [ ] Monitor Firebase Crashlytics for new errors
- [ ] Verify Firebase Hosting deployment (web)
- [ ] Test deep links on production build
- [ ] Confirm FCM push notifications work

---

## 10. Code Quality & Linting

### Current configuration

- **Base:** `package:flutter_lints/flutter.yaml`
- **Added:** `custom_lint` + `riverpod_lint` (declared but may not be active)
- **Build config:** `explicit_to_json: true` in `build.yaml`

### Recommended additions to `analysis_options.yaml`

```yaml
analyzer:
  errors:
    invalid_annotation_target: ignore    # Freezed sometimes triggers this
  exclude:
    - "**/*.freezed.dart"
    - "**/*.g.dart"
    - "lib/**/*.g.dart"

linter:
  rules:
    - always_declare_return_types
    - avoid_print
    - prefer_const_constructors
    - prefer_single_quotes
    - sort_child_properties_last
    - unawaited_futures
    - use_key_in_widget_constructors
    - prefer_const_declarations
```

### Run quality checks

```bash
# Static analysis
flutter analyze

# Custom lint (riverpod_lint)
dart run custom_lint

# Formatting check
dart format --set-exit-if-changed lib/

# Dependency validator (optional)
dart run dependency_validator
```

### Code review checklist

- [ ] No `print()` statements — use `log()` or `debugPrint()` instead
- [ ] All async calls have error handling
- [ ] Dispose controllers and streams
- [ ] Keys are provided to widgets to preserve state
- [ ] No hardcoded strings — use `AppStrings` constants
- [ ] No magic numbers — use named constants
- [ ] API keys/secrets are not in source code
- [ ] Freezed classes include proper `fromJson`/`toJson`
- [ ] Riverpod providers use `.autoDispose` where appropriate
- [ ] All Firestore queries have proper indexes

---

## 11. Firebase & Backend Testing

### Development vs Production collections

| Environment | Collection prefix |
|---|---|
| **Dev/Test** | `_test` suffix (e.g. `users_test`) |
| **Production** | No suffix (e.g. `users`) |

Switch via `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  static const bool isDevMode = true;  // ← toggle before release
}
```

### Using Firebase Emulator Suite (recommended for local testing)

```bash
# Install and start emulators
firebase init emulators
firebase emulators:start

# In app, point to local emulator
// lib/data/datasources/remote/firebase_datasource.dart (development only)
FirebaseFirestore.instance.useEmulator('localhost', 8080);
FirebaseAuth.instance.useEmulator('localhost', 9099);
```

### Test data seeding

The project has `assets/data/bloodfinder.json` (gitignored) for seed data. For tests:

- Create seed helpers in `test/helpers/seed_data.dart`
- Use `fake_cloud_firestore` to insert test documents without touching real Firebase

### Common Firestore test scenarios

| Scenario | What to test |
|---|---|
| **Document not found** | Repository returns `null` or throws |
| **Permission denied** | Error state in provider |
| **Network timeout** | Timeout handling, retry logic |
| **Empty collection** | List widget shows empty state |
| **Real-time snapshot** | Stream provider updates on data change |
| **Batch writes** | Atomicity — partial failure doesn't corrupt |

---

## 12. Performance & Accessibility

### Performance targets

| Metric | Target | How to measure |
|---|---|---|
| App startup (cold) | < 3s on mid-range Android | `flutter run --trace-startup --profile` |
| Page transition | < 300ms jank-free | Flutter DevTools Timeline |
| List scroll (60fps) | Smooth scroll with 100+ items | DevTools Performance overlay |
| Memory usage | < 200MB steady state | DevTools Memory view |
| APK size | < 40MB release APK | `flutter build apk --release --analyze-size` |
| Build time | < 60s for clean build | Time with `flutter build apk` |

### Performance testing

```bash
# Profile mode (shows jank, GPU/CPU usage)
flutter run --profile

# Check build size
flutter build apk --release --analyze-size

# Check for unnecessarily rebuilt widgets
flutter run --track-widget-creation --profile
```

### Accessibility checklist

- [ ] All tappable elements have semantic labels (or are wrapped in `Semantics`)
- [ ] Screen readers can navigate the app (test with TalkBack on Android)
- [ ] Contrast ratios meet WCAG AA (4.5:1 for text)
- [ ] Font scaling doesn't break layouts (test at large font size)
- [ ] Touch targets are at least 48x48dp
- [ ] Loading states are announced to screen readers
- [ ] Error messages are associated with their inputs

### Performance anti-patterns to watch for

| Pattern | Impact | Fix |
|---|---|---|
| **Unbounded lists** | Memory OOM | Use pagination |
| **Rebuilding widgets unnecessarily** | Jank | Use `const` constructors, `Consumer` over `ConsumerWidget` |
| **Large images without caching** | Memory spikes | Already using `cached_network_image` — verify all images use it |
| **No `const` on widgets** | Extra rebuilds | Always use `const` where possible |
| **Heavy computation in build** | Frame drops | Move to isolate or compute |
| **Many StreamProviders** | Firestore read costs | Use `autoDispose` when leaving screens |

---

## 13. Test Naming & File Conventions

### Naming

```
test/                   → mirrors lib/ structure
  core/utils/           → mirrors lib/core/utils/
  data/models/          → mirrors lib/data/models/
  features/{feature}/   → mirrors lib/features/{feature}/
```

### Test group naming

```dart
// Test file: [feature]_test.dart
group('BloodBank', () {            // ← class/feature name
  test('fromJson works', () {});   // ← what it does
  test('toJson works', () {});
  test('handles null location', () {});
});
```

### Widget test naming

```dart
testWidgets('BloodBankCard displays name and blood groups', (tester) async {});
testWidgets('BloodBankCard shows zero stock for missing groups', (tester) async {});
testWidgets('BloodBankCard navigates to detail on tap', (tester) async {});
```

### File naming convention

| Type | Pattern | Example |
|---|---|---|
| Unit test | `{file_name}_test.dart` | `blood_bank_test.dart` |
| Widget test | `{widget_name}_test.dart` | `blood_bank_card_test.dart` |
| Provider test | `{provider_name}_test.dart` | `blood_bank_provider_test.dart` |
| Integration test | `{flow}_test.dart` | `auth_flow_test.dart` |

### Commenting tests

```dart
// GOOD — describes scenario and expectation
test('fromJson returns null when uid is missing', () { ... });

// GOOD — follows Given-When-Then
testWidgets('given empty list, shows "No blood banks found"', (tester) async { ... });
```

---

## Appendix: Key Contacts & Resources

- **Project:** BloodFinder — Donate blood, Save life
- **Firebase Console:** bloodfinder-bd (requires access)
- **App Version:** 1.0.0+5
- **Sentry/Crashlytics:** Firebase Crashlytics configured via `firebase_core`

---

*This QA guide is a living document. Update it as testing infrastructure is established, new features are added, or the architecture evolves. Start with P0 unit tests for data models, then build out widget tests for critical user flows.*
