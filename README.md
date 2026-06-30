<div align="center">
  <br />
  <h1>🩸 Blood Finder</h1>
  <p>
    <strong>Donate Blood · Save Life</strong>
  </p>
  <p>
    <img src="https://img.shields.io/badge/Flutter-3.12+-02569B?style=flat&logo=flutter" alt="Flutter" />
    <img src="https://img.shields.io/badge/Dart-3.12+-0175C2?style=flat&logo=dart" alt="Dart" />
    <img src="https://img.shields.io/badge/Firebase-FFCA28?style=flat&logo=firebase" alt="Firebase" />
    <img src="https://img.shields.io/badge/platform-android%20%7C%20ios-lightgrey" alt="Platform" />
  </p>
  <br />
</div>

---

## Overview

Blood Finder connects blood donors with those in need. Built with Flutter and Firebase, it provides real-time request matching, emergency alerts, community management, and a complete donor lifecycle — from registration and eligibility verification to donation tracking and certification.

## Features

### 🔴 Blood Requests
Post and browse blood requests filtered by blood group, district, and subdistrict. Track request status in real time (active / fulfilled / cancelled).

### 👥 My Circle
Import device contacts and see which ones are already on the app. Avoid duplicates with built-in phone number matching. Call or message app-user contacts directly. Contacts that join the app later are linked automatically.

### 💬 Chat & Messaging
Real-time one-on-one chat with push notification delivery. Chat archive and message status tracking.

### 🏘️ Communities
Create and join location-based donor communities. Membership management with role approval. Search by blood group and proximity. Deep-link sharing for invites.

### 🩸 Donation Management
Log donations with date, type, recipient, and hospital. Automatic badge progression: First Hero → Bronze → Silver → Gold → Legend. Generate shareable donation certificates.

### 🆘 Emergency Donor
Register with geo-location. Search nearby emergency donors by blood group. One-tap chat to coordinate urgently.

### 📅 Events
Create and discover donation events. RSVP tracking with real-time attendee count.

### 🏥 Blood Banks
Directory of blood banks with contact details and proximity search.

### 📬 Notifications
Firebase Cloud Messaging with real-time push for messages, community updates, and events. In-app notification history with read tracking.

## Architecture

```
lib/
├── core/                 # Config, constants, theme, utilities
│   ├── config/           # AppConfig (collection switching, dev mode)
│   ├── constants/        # App strings, district data, route paths
│   ├── theme/            # Light / dark theme definitions
│   └── utils/            # Geohash, PhoneUtils, helpers
├── data/                 # Data layer
│   ├── datasources/      # FirebaseDataSource wrapper
│   ├── models/           # UserModel, AddressModel (json_serializable)
│   ├── providers/        # Riverpod providers
│   └── repositories/     # Firebase repository implementations
├── features/             # 14 feature modules
│   ├── auth/             # Login, registration, forgot password
│   ├── blood_bank/       # Blood bank directory
│   ├── blood_request/    # Request posting & browsing
│   ├── chat/             # Real-time messaging
│   ├── community/        # Community management
│   ├── donation/         # Donation logging & certificates
│   ├── emergency_donor/  # Emergency donor registry
│   ├── events/           # Event creation & RSVP
│   ├── feed/             # Feed & social content
│   ├── feedback/         # In-app feedback
│   ├── home/             # Home dashboard
│   ├── my_circle/        # Contact management
│   ├── notification/     # Notification center
│   └── profile/          # User profile & settings
├── routes/               # GoRouter config (auth guard, deep links)
├── scripts/              # One-time migrations
└── shared/               # Shared widgets (chat button, map picker, etc.)
```

### Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.12+ / Dart 3.12+ |
| State Management | Riverpod 3.x |
| Routing | GoRouter 17.x |
| Backend | Firebase (Firestore, Auth, Messaging, Storage) |
| Maps | Flutter Map (OpenStreetMap) |
| Contacts | flutter_contacts |
| Icons | Phosphor Icons |

### Firestore Collections

| Collection | Type | Purpose |
|---|---|---|
| `users` | Top-level | User profiles, donor status, geo-location |
| `donations` | Top-level | Donation records (per user via `uid` field) |
| `blood_requests` | Top-level | Blood request posts with status |
| `communities` | Top-level | Community groups |
| `community_members` | Top-level | Community membership (doc ID: `{communityId}_{uid}`) |
| `chats` | Top-level | Chat conversations |
| `chat_messages` | Subcollection | Messages within a chat |
| `notifications` | Top-level | Push & in-app notifications |
| `contacts` | Top-level | User circle contacts |
| `events` | Top-level | Donation events |
| `event_rsvps` | Top-level | Event RSVPs (doc ID: `{eventId}_{uid}`) |
| `blood_bank` | Top-level | Blood bank directory |
| `emergency_donor` | Top-level | Emergency donor flags |
| `feedbacks` | Top-level | User feedback |
| `admin` | Top-level | Admin flags |
| `settings` | Top-level | App-wide counters & config |

> Dev mode appends `_test` to all collection paths automatically when `isDevMode` is enabled in `FirebaseDataSource`, keeping development data isolated from production.

## Getting Started

### Prerequisites

- Flutter SDK 3.12+
- Dart 3.12+
- Firebase project with Authentication (Email/Password), Cloud Firestore, Cloud Messaging, and Storage enabled

### Setup

```bash
# 1. Clone
git clone https://github.com/your-org/bloodfinder.git
cd bloodfinder

# 2. Install dependencies
flutter pub get

# 3. Firebase configuration
#    Android: Place google-services.json in android/app/
#    iOS:     Place GoogleService-Info.plist in ios/Runner/

# 4. Run
flutter run
```

### Firestore Indexes

Proximity queries and filtered listings require composite indexes. Firestore returns a clickable error link the first time a query runs without its index. The required indexes are:

| Collection | Fields |
|---|---|
| `communities` | `geohash` ASC, `name` DESC |
| `blood_requests` | `district` ASC, `createdAt` DESC |
| `notifications` | `uid` ASC, `createdAt` DESC |
| `community_members` | `communityId` ASC, `member` ASC, `__name__` ASC |
| `events` | `geohash` ASC, `eventDate` DESC |
| `blood_bank` | `geohash` ASC, `name` ASC |

## License

Proprietary — all rights reserved.
