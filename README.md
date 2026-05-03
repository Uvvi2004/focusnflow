# FocusNFlow

FocusNFlow is a Flutter app for students who want one place to manage tasks, study rooms, group sessions, and notifications. The app uses Firebase for authentication, Firestore for live data, Storage for profile images, and Cloud Messaging for push notifications.

## What It Does

- Student sign in and sign up with `@student.gsu.edu` emails
- Task creation with priority scoring based on deadline, course weight, and estimated work
- Live study room updates with open, occupied, and reserved status
- Study group creation, joining, leaving, and session scheduling
- Shared Pomodoro timer for group study sessions
- Profile management with avatar uploads and notification preferences
- Push notifications plus in app notification history

## Firebase Services Used

- Firebase Authentication for account creation and login
- Cloud Firestore for users, tasks, rooms, groups, and notifications
- Firebase Storage for profile avatar uploads
- Firebase Cloud Messaging for device tokens and push notification delivery

## Main Screens

- Login screen for sign in and sign up
- Home dashboard with task summary and notification bell
- Tasks screen for adding, sorting, and completing tasks
- Rooms screen for viewing and updating study space availability
- Groups screen for creating and managing study groups
- Profile screen for avatar upload, settings, and sign out
- Schedule screen for weekly planning
- Pomodoro screen for focused group study sessions

## Project Structure

- `lib/main.dart` app startup, Firebase initialization, and notification setup
- `lib/models` data models for users, tasks, rooms, and groups
- `lib/services` shared Firebase logic for auth, Firestore, storage, and messaging
- `lib/screens` UI for login, home, tasks, rooms, groups, profile, schedule, and Pomodoro
- `firestore.rules` security rules for database access control
- `firestore.indexes.json` composite indexes for Firestore queries

## Setup

1. Install Flutter and ensure your Firebase project is connected.
2. Run `flutter pub get`.
3. Add your Firebase configuration files if needed.
4. Run the app with `flutter run`.

## Testing

Run the available widget and model tests with:

```bash
flutter test
```
## Build

To create a debug APK:

```bash
flutter build apk --debug
```

## License

This project is for coursework and class presentation use.
