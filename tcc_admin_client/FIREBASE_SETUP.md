# Firebase Setup Guide for TCC Admin Client

This guide will walk you through setting up Firebase for the TCC Admin Client web application.

## Prerequisites

- A Google account
- Access to [Firebase Console](https://console.firebase.google.com/)

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or "Create a project"
3. Enter your project name (e.g., "tcc-admin")
4. (Optional) Enable Google Analytics for your project
5. Click "Create project" and wait for it to be created

## Step 2: Register Your Web App

1. In your Firebase project, click the web icon (`</>`) to add a web app
2. Register your app with a nickname (e.g., "TCC Admin Client")
3. (Optional) Check "Also set up Firebase Hosting" if you plan to use Firebase Hosting
4. Click "Register app"

## Step 3: Get Your Firebase Configuration

After registering your app, you'll see a Firebase configuration object that looks like this:

```javascript
const firebaseConfig = {
  apiKey: "AIza...",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc123",
  measurementId: "G-ABC123XYZ"
};
```

## Step 4: Configure Your Environment

1. Open the `.env` file in the project root
2. Replace the placeholder values with your Firebase configuration:

```env
# Firebase Configuration
FIREBASE_API_KEY=AIza...
FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
FIREBASE_PROJECT_ID=your-project
FIREBASE_STORAGE_BUCKET=your-project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=123456789
FIREBASE_APP_ID=1:123456789:web:abc123
FIREBASE_MEASUREMENT_ID=G-ABC123XYZ
```

3. Update `web/index.html` and replace the placeholders with actual values:

```javascript
window.firebaseConfig = {
  apiKey: "AIza...",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc123",
  measurementId: "G-ABC123XYZ"
};
```

## Step 5: Enable Firebase Services

### Authentication

1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Enable the sign-in methods you want to use:
   - Email/Password
   - Google
   - Other providers as needed

### Firestore Database

1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose a location for your database
4. Start in "Test mode" for development (you'll need to configure security rules later)

### Firebase Storage

1. In Firebase Console, go to "Storage"
2. Click "Get started"
3. Start in "Test mode" for development
4. Choose a location for your storage bucket

### Analytics (Optional)

Analytics is automatically enabled if you enabled it during project creation.

## Step 6: Configure Security Rules

### Firestore Security Rules

In Firebase Console > Firestore Database > Rules, add appropriate security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Admin users only
    match /{document=**} {
      allow read, write: if request.auth != null &&
        get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### Storage Security Rules

In Firebase Console > Storage > Rules, add appropriate security rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null &&
        firestore.get(/databases/(default)/documents/admins/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## Step 7: Test Your Setup

1. Run your Flutter web app:
   ```bash
   flutter run -d chrome
   ```

2. Check the browser console for Firebase initialization messages
3. You should see "Firebase initialized successfully"

## Running the App with Firebase Configuration

### For Development

```bash
flutter run -d chrome --dart-define=FIREBASE_API_KEY=your_api_key --dart-define=FIREBASE_AUTH_DOMAIN=your_auth_domain --dart-define=FIREBASE_PROJECT_ID=your_project_id --dart-define=FIREBASE_STORAGE_BUCKET=your_storage_bucket --dart-define=FIREBASE_MESSAGING_SENDER_ID=your_sender_id --dart-define=FIREBASE_APP_ID=your_app_id --dart-define=FIREBASE_MEASUREMENT_ID=your_measurement_id
```

### For Production Build

```bash
flutter build web --dart-define=FIREBASE_API_KEY=your_api_key --dart-define=FIREBASE_AUTH_DOMAIN=your_auth_domain --dart-define=FIREBASE_PROJECT_ID=your_project_id --dart-define=FIREBASE_STORAGE_BUCKET=your_storage_bucket --dart-define=FIREBASE_MESSAGING_SENDER_ID=your_sender_id --dart-define=FIREBASE_APP_ID=your_app_id --dart-define=FIREBASE_MEASUREMENT_ID=your_measurement_id
```

## Using Firebase in Your Code

### Getting Firebase Service Instance

```dart
import 'package:tcc_admin_client/services/firebase_service.dart';

// Get the Firebase service instance
final firebaseService = FirebaseService.instance;

// Check if initialized
if (firebaseService.isInitialized) {
  // Use Firebase services
}
```

### Using Firebase Auth

```dart
// Get auth instance
final auth = firebaseService.auth;

// Sign in
await auth.signInWithEmailAndPassword(
  email: email,
  password: password,
);

// Get current user
final user = firebaseService.currentUser;

// Listen to auth state changes
firebaseService.authStateChanges.listen((user) {
  if (user != null) {
    print('User is signed in');
  } else {
    print('User is signed out');
  }
});
```

### Using Firestore

```dart
// Get Firestore instance
final firestore = firebaseService.firestore;

// Read data
final doc = await firestore.collection('users').doc(userId).get();

// Write data
await firestore.collection('users').doc(userId).set({
  'name': 'John Doe',
  'email': 'john@example.com',
});

// Query data
final querySnapshot = await firestore
    .collection('users')
    .where('role', isEqualTo: 'admin')
    .get();
```

### Using Firebase Storage

```dart
// Get Storage instance
final storage = firebaseService.storage;

// Upload file
final ref = storage.ref().child('uploads/file.jpg');
await ref.putData(fileBytes);

// Get download URL
final url = await ref.getDownloadURL();
```

### Using Firebase Analytics

```dart
// Log event
await firebaseService.logEvent(
  name: 'button_click',
  parameters: {'button_name': 'submit'},
);

// Set current screen
await firebaseService.setCurrentScreen(
  screenName: 'home_screen',
);
```

## Troubleshooting

### Firebase not initializing

- Verify all environment variables are set correctly in `.env`
- Check that `web/index.html` has the correct Firebase config
- Make sure you ran `flutter pub get` after adding Firebase dependencies
- Check browser console for error messages

### Authentication errors

- Verify you enabled the authentication method in Firebase Console
- Check that your security rules allow the operation
- Ensure the user's email is verified if required

### Firestore permission denied

- Check your Firestore security rules
- Verify the user is authenticated
- Ensure the user has the required role/permissions

### Storage permission denied

- Check your Storage security rules
- Verify the user is authenticated
- Ensure the file path is correct

## Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)

## Next Steps

1. Configure security rules for production
2. Set up Firebase Hosting (optional)
3. Configure Firebase Functions (if needed)
4. Set up Firebase Remote Config (optional)
5. Enable Firebase Crashlytics (optional)
