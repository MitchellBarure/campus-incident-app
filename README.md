# ALU Campus Incidents

A Flutter app where students report campus issues (leaks, broken furniture,
electrical faults, safety hazards...) and staff track and resolve them.

Built for the Mobile Application Development module.

**Demo video:** https://youtu.be/WkBNH1X_d20

## Features

| Students | Staff |
| --- | --- |
| Sign up / log in with an ALU email, verified by email link | Staff dashboard with counts by status |
| Report an issue: category, title, description, location, optional photo | Every report, newest first, with search and filters |
| Home: greeting, report banner, summary cards, recent reports | Update a report's status with an optional note |
| Browse all reports with search, status and category filters | Same details screen, plus an **Update Status** button |
| My Reports with stats and status filter | |
| Edit or delete your own report while it is still Submitted | |
| Report details with photo, status timeline and staff notes | |

Every screen that loads data has loading, error (with retry) and empty states.
All data updates live (Firestore streams), so there is no pull-to-refresh.

## Tech stack

- **Flutter** (Material 3, ALU brand colours, Poppins font)
- **Riverpod** (`flutter_riverpod`, no code generation) for state management
- **go_router** with a redirect based on login state and role
- **Firebase Authentication** (email + password, ALU emails only, email verification)
- **Cloud Firestore** for all data, protected by security rules
- **Photos** are compressed and stored as base64 in Firestore (see below)

## Project structure

```
lib/
  main.dart, app.dart        App start-up, Firebase init, router + theme
  core/                      Theme (colours), router, validators, formatters, filters
  models/                    AppUser, Incident, IncidentCategory, IncidentStatus, StatusChange
  services/                  AuthRepository, IncidentRepository, ImageService, seed data
  providers/                 Riverpod providers (auth, incidents, filters)
  screens/                   auth/, student/, shared/, staff/
  widgets/                   Reusable UI: cards, chips, timeline, empty/error/loading views
test/                        Unit and widget tests
firestore.rules              Security rules
firestore.indexes.json       Composite index for "My Reports"
```

## Setup

### 1. Requirements

- Flutter (stable) with Dart 3.13 or newer
- An Android emulator or device
- Node.js, for the Firebase CLI (`npm install -g firebase-tools`)

### 2. Firebase project

This repo is already connected to the Firebase project
`campus-incident-app-9d1f2` (see `lib/firebase_options.dart`). To use your own
project instead, run `flutterfire configure` and update `.firebaserc`.

In the [Firebase Console](https://console.firebase.google.com/):

1. **Build → Authentication → Sign-in method → Email/Password → Enable → Save.**
   Verification emails use the default template under **Authentication →
   Templates**; they sometimes land in spam.
2. **Build → Firestore Database → Create database** (if it doesn't exist yet).

### 3. Deploy the security rules and index

```bash
firebase login
firebase deploy --only firestore:rules,firestore:indexes
```

This uploads `firestore.rules` and creates the `reporterId + createdAt`
index used by My Reports. The index can take a few minutes to build.

### 4. Run the app

```bash
flutter pub get
flutter run
```

## Making a staff account

Everyone signs up as a **student**; the security rules don't let anyone make
themselves staff. To promote a user:

1. Sign up in the app with the account you want to be staff (an
   `@alueducation.com` or `@alustudent.com` email) and verify it.
2. Firebase Console → **Firestore Database → Data → `users`**.
3. Click the document whose `email` matches that account.
4. Click the `role` field's value, change `student` to `staff`, click **Update**.
5. The app switches to the Staff Dashboard straight away (no restart needed).

## Sample data

In **debug** builds, the Profile screen has an **Add 8 sample reports** button
(hidden in release builds). Use it while logged in as **staff** to get reports
in every status with timeline notes; as a student, all 8 are "Submitted".

## Photos and the Spark (free) plan

Since February 2026 Firebase Storage requires the paid Blaze plan, so photos are
stored in Firestore instead:

- The photo is resized to 1024px wide and compressed to JPEG (≤ 700 KB, because a
  Firestore document is limited to 1 MiB and base64 adds about 33%).
- The full photo is saved in `incident_images/{incidentId}` and only loaded on the
  details screen. A ~200px thumbnail is stored on the incident for list cards.
- A complete Firebase Storage implementation (`FirebaseStorageImageService`) is
  included but switched off. Set `useFirebaseStorage = true` in
  `lib/core/constants.dart` to use it on a Blaze project.
- Its security rules are in `storage.rules`: verified ALU users can read; only the
  incident's reporter can upload, once, as a JPEG under 700 KB. Deploy them on a
  Blaze project with `firebase deploy --only storage` after adding
  `"storage": { "rules": "storage.rules" }` to `firebase.json`.

## Security rules summary

Only users signed in with a **verified** `@alustudent.com` or
`@alueducation.com` email can read or write incidents and photos.

- **users**: read your own profile (staff can read all); create your own only as a
  `student` with an ALU email; never change your own role.
- **incidents**: any verified ALU user can read. Create only as yourself with status
  `submitted` and valid fields. Only staff can change `status`, `statusHistory`
  and `updatedAt` (one new timeline entry at a time). The reporter can edit the
  title, description, category and location, or delete the report, only while
  it is still `submitted`.
- **incident_images**: verified ALU users can read; only the incident's reporter can add the
  photo (under ~1 MB) or delete it with the report while it is `submitted`.

## Tests

```bash
flutter test
```

| File | What it covers |
| --- | --- |
| `validators_test.dart` | Sign-up (incl. ALU email only) and report form validation |
| `app_user_test.dart`, `incident_model_test.dart` | Models' `fromMap` / `toMap` |
| `auth_redirect_test.dart` | Role-based routing, email verification redirect, friendly auth errors |
| `incident_repository_test.dart` | Create, stream, update, edit and delete incidents (fake Firestore) |
| `image_compression_test.dart` | Photo resizing, thumbnails and the size limit |
| `filter_logic_test.dart`, `filter_providers_test.dart` | Search, filters and status counts |
| `status_timeline_test.dart` | Timeline steps and timeline widget |
| `report_form_test.dart` | Report form validation, submit and edit mode (widget test) |
| `update_status_test.dart` | Update Status for staff only; Edit/Delete for the reporter only (widget test) |
| `seed_data_test.dart` | Sample data helper |

## Screenshots

Screenshots of each screen are in [`docs/screenshots/`](docs/screenshots/).
