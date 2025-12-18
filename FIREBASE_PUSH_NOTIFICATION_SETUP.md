# Firebase Push Notification Setup Guide

This guide will help you complete the Firebase Push Notification integration for all three TCC apps.

## Overview

Firebase push notifications have been integrated into:
- **tcc_agent_client** - Agent mobile app
- **tcc_admin_client** - Admin web/mobile app
- **tcc_user_mobile_client** - User mobile app

## What Has Been Done

### 1. Dependencies Added
All necessary Firebase packages have been added to `pubspec.yaml` for each app:
- `firebase_core` - Core Firebase functionality
- `firebase_messaging` - Push notification service
- `firebase_analytics` - Analytics tracking
- `flutter_local_notifications` - Local notification display

### 2. NotificationService Created
A complete `NotificationService` has been created for each app with:
- FCM token management
- Foreground and background message handling
- Local notification display
- Notification channel configuration (Android)
- Topic subscription support
- Navigation handling from notifications

### 3. Platform Configuration
**Android:**
- Google Services plugin added to `build.gradle.kts`
- FCM permissions added to `AndroidManifest.xml`
- Notification service configured

**iOS:**
- Background modes enabled in `Info.plist`
- AppDelegate configured for notifications
- Notification handling implemented

## What You Need to Do

### Step 1: Create Firebase Projects

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create three Firebase projects (or use one project with three apps):
   - TCC Agent
   - TCC Admin
   - TCC User

### Step 2: Add Android Apps

For **each** app (Agent, Admin, User):

1. In Firebase Console, click "Add app" → Select Android
2. Enter the package name:
   - Agent: `com.example.tcc_agent_client`
   - Admin: `com.example.tcc_admin_client`
   - User: `com.tcc.tcc_user_mobile_client`
3. Download `google-services.json`
4. Place the file in the appropriate location:
   ```
   tcc_agent_client/android/app/google-services.json
   tcc_admin_client/android/app/google-services.json
   tcc_user_mobile_client/android/app/google-services.json
   ```

### Step 3: Add iOS Apps

For **each** app (Agent, Admin, User):

1. In Firebase Console, click "Add app" → Select iOS
2. Enter the bundle ID (you can find this in the Xcode project or use):
   - Agent: `com.example.tccAgentClient`
   - Admin: `com.example.tccAdminClient`
   - User: `com.tcc.tccUserMobileClient`
3. Download `GoogleService-Info.plist`
4. Add the file to your iOS project:
   - Open the iOS project in Xcode: `open tcc_[app_name]/ios/Runner.xcworkspace`
   - Drag and drop `GoogleService-Info.plist` into the `Runner` folder in Xcode
   - Make sure "Copy items if needed" is checked
   - Make sure the target "Runner" is selected

   Or manually place it here and add to Xcode:
   ```
   tcc_agent_client/ios/Runner/GoogleService-Info.plist
   tcc_admin_client/ios/Runner/GoogleService-Info.plist
   tcc_user_mobile_client/ios/Runner/GoogleService-Info.plist
   ```

### Step 4: Install Dependencies

Run the following commands for each app:

```bash
# Agent Client
cd tcc_agent_client
flutter pub get
cd ios && pod install && cd ..

# Admin Client
cd tcc_admin_client
flutter pub get
cd ios && pod install && cd ..

# User Mobile Client
cd tcc_user_mobile_client
flutter pub get
cd ios && pod install && cd ..
```

### Step 5: Configure Firebase Cloud Messaging in Firebase Console

1. In Firebase Console, go to **Cloud Messaging** section
2. For iOS apps, upload your APNs certificate or key:
   - Go to Project Settings → Cloud Messaging → iOS app configuration
   - Upload your APNs Authentication Key or Certificate

### Step 6: Test the Integration

#### Testing on Android:
```bash
cd tcc_agent_client  # or any app
flutter run
```

Watch the logs for:
- "Firebase initialized successfully"
- "Notification service initialized successfully"
- "FCM Token: [your-token]"

#### Testing on iOS:
```bash
cd tcc_agent_client  # or any app
flutter run
```

Watch for permission prompts and FCM token in logs.

#### Send a Test Notification:
1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter title and message
4. Click "Send test message"
5. Paste the FCM token from your app logs
6. Click "Test"

## Using the NotificationService

### Get FCM Token
```dart
final token = await NotificationService().getToken();
print('FCM Token: $token');
// TODO: Send this token to your backend
```

### Subscribe to Topics
```dart
await NotificationService().subscribeToTopic('all_users');
await NotificationService().subscribeToTopic('promotions');
```

### Show Manual Notification (for testing)
```dart
await NotificationService().showNotification(
  title: 'Test Notification',
  body: 'This is a test message',
  data: {'type': 'test', 'id': '123'},
);
```

### Check Notification Status
```dart
final enabled = await NotificationService().areNotificationsEnabled();
if (!enabled) {
  // Show UI to prompt user to enable notifications
}
```

## Backend Integration

To send notifications from your backend, you'll need to:

1. Save FCM tokens when users log in (see TODO in `notification_service.dart`)
2. Use Firebase Admin SDK or FCM REST API to send notifications
3. Include notification payload with:
   - `title` and `body` for the notification
   - `data` with `type` and `id` for navigation

Example notification payload:
```json
{
  "notification": {
    "title": "New Order",
    "body": "You have a new payment order"
  },
  "data": {
    "type": "order",
    "id": "12345"
  },
  "token": "user-fcm-token"
}
```

## Notification Types by App

### Agent Client
- `transaction` - Transaction updates
- `order` - Payment orders
- `commission` - Commission updates
- `system` - System announcements

### Admin Client
- `agent` - Agent verification updates
- `user` - User-related notifications
- `system` - System announcements

### User Client
- `investment` - Investment maturity/returns
- `transaction` - Transaction confirmations
- `promotion` - Promotional offers
- `system` - System announcements

## Customizing Notifications

### Update Notification Channels
Edit the channel configurations in `notification_service.dart`:
- Channel IDs
- Importance levels
- Sound/vibration settings

### Update Navigation Handling
Implement the `_handleNotificationNavigation` method in `notification_service.dart` to navigate to appropriate screens based on notification type.

## Troubleshooting

### Android Issues
- **Notifications not appearing**: Check that `google-services.json` is in the correct location
- **Build fails**: Ensure Google Services plugin is applied in `build.gradle.kts`
- **Token is null**: Check internet connection and Firebase configuration

### iOS Issues
- **Notifications not appearing**: Ensure APNs certificate is uploaded to Firebase Console
- **Build fails**: Run `pod install` in the iOS directory
- **Permission not requested**: Check `Info.plist` has correct background modes

### General Issues
- **Firebase initialization fails**: Verify config files are correctly placed
- **No FCM token**: Check internet connection and wait a few seconds after app start
- **Background notifications not working**: Ensure background modes are enabled (iOS) and app is not battery-optimized (Android)

## Next Steps

1. ✅ Add Firebase configuration files (`google-services.json` and `GoogleService-Info.plist`)
2. ✅ Run `flutter pub get` and `pod install`
3. ✅ Test notifications on both platforms
4. ✅ Implement backend API to save/update FCM tokens
5. ✅ Implement notification navigation logic
6. ✅ Test different notification types
7. ✅ Configure APNs for iOS production

## Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Local Notifications Plugin](https://pub.dev/packages/flutter_local_notifications)
