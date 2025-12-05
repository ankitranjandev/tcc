# Sign In Debug Guide

## Comprehensive Logging Added

Extensive logging has been added throughout the authentication flow to help debug sign-in issues.

## Log Categories

All logs use emoji prefixes for easy identification:

- 🚀 **TCCApp**: App initialization and lifecycle
- 🔵 **AuthProvider**: Authentication state management
- 🟢 **Login Flow**: Login process tracking
- 🟡 **Profile Loading**: User profile fetching
- 📤 **AuthService Requests**: Outgoing authentication requests
- 📥 **AuthService Responses**: Incoming authentication responses
- 🔧 **ApiService Init**: API service initialization
- 💾 **Token Storage**: Token save/load operations
- 📡 **API Requests**: HTTP request details
- 🔍 **Response Handling**: Response processing
- 🔐 **LoginScreen**: UI interactions
- ✅ **Success**: Successful operations
- ⚠️ **Warning**: Warnings and validation issues
- ❌ **Error**: Errors and exceptions

## Viewing Logs

### Option 1: Using the helper script
```bash
./view_logs.sh
```

### Option 2: Flutter logs command
```bash
flutter logs
```

### Option 3: Filtered logs
```bash
flutter logs | grep -E "(TCCApp|AuthProvider|AuthService|ApiService|LoginScreen)"
```

### Option 4: ADB logcat (Android)
```bash
adb logcat | grep flutter
```

## Expected Log Flow for Successful Sign In

1. **App Start**
   ```
   🚀 TCCApp: Initializing app...
   🚀 TCCApp: Starting app initialization
   🔵 AuthProvider: Starting initialization
   🔧 ApiService: Initializing...
   🔧 ApiService: Base URL: http://localhost:3000/v1
   🔧 ApiService: Token exists: false, RefreshToken exists: false
   🔵 AuthProvider: No token found
   🔵 AuthProvider: Initialization complete. isAuthenticated: false
   🚀 TCCApp: AuthProvider initialized. isAuthenticated: false
   🚀 TCCApp: App initialization complete
   ```

2. **User Clicks Sign In**
   ```
   🔐 LoginScreen: Login button pressed
   🔐 LoginScreen: Form validated, proceeding with login
   🔐 LoginScreen: AuthProvider obtained, calling login()
   🟢 AuthProvider: Login started for email: user@example.com
   🟢 AuthProvider: Calling authService.login()
   ```

3. **API Request**
   ```
   📤 AuthService: Login request for email: user@example.com
   📤 AuthService: Sending POST request to /auth/login
   📡 ApiService: POST http://localhost:3000/v1/auth/login
   📡 ApiService: RequiresAuth: false, HasToken: false
   📡 ApiService: Request body: [email, password]
   ```

4. **API Response**
   ```
   📡 ApiService: Response status: 200
   🔍 ApiService: Handling response with status 200
   ✅ ApiService: Success response
   ✅ ApiService: Response keys: [token, refreshToken, user]
   📥 AuthService: Login response received: {...}
   📥 AuthService: Tokens found in response, storing them
   💾 ApiService: Storing tokens
   💾 ApiService: Tokens stored successfully
   ✅ AuthService: Tokens stored successfully
   ```

5. **Load User Profile**
   ```
   🟢 AuthProvider: Login result received: true
   🟢 AuthProvider: Login successful, loading user profile
   🟡 AuthProvider: Loading user profile
   📤 AuthService: Fetching user profile
   📡 ApiService: GET http://localhost:3000/v1/users/profile
   📡 ApiService: RequiresAuth: true, HasToken: true
   📡 ApiService: Response status: 200
   📥 AuthService: Profile response: {...}
   🟡 AuthProvider: Profile result: true
   🟡 AuthProvider: User data received: true
   🟡 AuthProvider: User profile loaded successfully. User: user@example.com
   🟢 AuthProvider: Login complete. isAuthenticated: true
   ```

6. **Navigation**
   ```
   🔐 LoginScreen: Login result: true
   🔐 LoginScreen: Login successful, navigating to /dashboard
   ```

## Common Issues to Look For

### 1. Network Connection Issues
Look for:
```
❌ ApiService: SocketException: ...
❌ ApiService: HttpException: ...
```

**Solution**: Check network connectivity and ensure the backend is running.

### 2. Wrong API URL
Look for:
```
🔧 ApiService: Base URL: http://localhost:3000/v1
```

**Issue**: `localhost` won't work on physical devices or emulators.

**Solutions**:
- For Android Emulator: Use `http://10.0.2.2:3000/v1`
- For Physical Device: Use your computer's IP address (e.g., `http://192.168.1.100:3000/v1`)
- Update `lib/config/app_constants.dart`

### 3. Invalid Credentials
Look for:
```
📡 ApiService: Response status: 401
🔴 AuthProvider: Login failed: Invalid credentials
```

**Solution**: Verify email and password are correct.

### 4. Backend Not Running
Look for:
```
❌ ApiService: SocketException: Connection refused
```

**Solution**: Start your backend server.

### 5. Token Storage Issues
Look for:
```
⚠️ AuthService: No tokens in response
```

**Solution**: Check backend is returning `token` and `refreshToken` in the response.

### 6. Profile Loading Failure
Look for:
```
🔴 AuthProvider: Failed to load profile: ...
```

**Solution**: Verify `/users/profile` endpoint is working and returns correct data.

## Testing the Flow

1. Install the app:
   ```bash
   flutter install
   ```

2. Open log viewer in a separate terminal:
   ```bash
   ./view_logs.sh
   ```

3. Open the app and attempt to sign in

4. Watch the logs to see exactly where the process fails

## Quick Fixes

### Update API Base URL
Edit `lib/config/app_constants.dart`:

```dart
// For Android Emulator
static const String baseUrl = 'http://10.0.2.2:3000/v1';

// For iOS Simulator (use your computer's local IP)
static const String baseUrl = 'http://192.168.1.100:3000/v1';

// For Physical Device (use your computer's local IP)
static const String baseUrl = 'http://192.168.1.100:3000/v1';
```

### Clear App Data
If tokens are corrupted:
```bash
flutter run --clear-cache
# Or uninstall and reinstall the app
```

## Additional Debug Commands

### Check if backend is reachable
```bash
curl http://localhost:3000/v1/auth/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### View all Flutter logs
```bash
flutter logs --verbose
```

### Clear device logs
```bash
adb logcat -c  # Android
```

## Need More Help?

If sign in is still not working after checking the logs:

1. Share the logs from app start through the sign-in attempt
2. Verify the backend is running and accessible
3. Test the API endpoint directly with curl/Postman
4. Check that the API response format matches what the app expects
