# TCC User Mobile Client - Multi-Platform Support Guide

## Overview
This Flutter application now supports the following platforms:
- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

## Platform Status

### 1. Android ✅
**Status**: Fully configured and tested
- Build command: `flutter build apk --release`
- APK available: `TCC-User-App.apk`
- Min SDK: 21
- Target SDK: Latest

### 2. iOS ✅
**Status**: Fully configured and tested
- Build command: `flutter build ios --release`
- Requires: Xcode 15.0+ and valid signing certificate
- Developer identity: Apple Development: ankit ranjan (NXD8X62F7K)

### 3. Web ✅
**Status**: Fully configured and tested
- Build command: `flutter build web --release`
- Output directory: `build/web`
- Successfully builds with WASM warnings (non-critical)
- Note: Some packages (share_plus, permission_handler) have limited web functionality

**Web-Specific Notes:**
- dart:ffi packages (like win32) show WASM compatibility warnings but don't affect web builds
- To disable WASM warnings: `flutter build web --no-wasm-dry-run`
- Icon tree-shaking reduces bundle size by 98%+

### 4. macOS ✅
**Status**: Fully configured and tested
- Build command: `flutter build macos --release`
- Output: `build/macos/Build/Products/Release/tcc_user_mobile_client.app`
- Build size: ~54.4MB
- CocoaPods version: 1.13.0 (1.16.2 recommended)

**macOS-Specific Requirements:**
- Xcode 15.0+
- CocoaPods installed
- Update CocoaPods: `sudo gem install cocoapods`

### 5. Windows ⚠️
**Status**: Platform files generated, ready for Windows build
- Build command: `flutter build windows --release`
- Requires: Windows OS with Visual Studio 2019+ and C++ development tools
- Platform files location: `windows/`

**Windows Build Requirements:**
- Windows 10/11
- Visual Studio 2019 or later with "Desktop development with C++" workload
- Windows 10 SDK

### 6. Linux ⚠️
**Status**: Platform files generated, ready for Linux build
- Build command: `flutter build linux --release`
- Requires: Linux OS with appropriate build tools
- Platform files location: `linux/`

**Linux Build Requirements:**
- Clang or GCC compiler
- GTK development libraries
- Install dependencies: `sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev`

## Building for Each Platform

### Quick Build Commands

```bash
# Android
flutter build apk --release

# iOS (requires macOS)
flutter build ios --release

# Web
flutter build web --release

# macOS (requires macOS)
flutter build macos --release

# Windows (requires Windows)
flutter build windows --release

# Linux (requires Linux)
flutter build linux --release
```

### Running in Debug Mode

```bash
# Specify device with -d flag
flutter run -d chrome          # Web
flutter run -d macos          # macOS
flutter run -d windows        # Windows
flutter run -d linux          # Linux
flutter run -d <device-id>    # Android/iOS device
```

## Android Studio File Display Issues - RESOLVED ✅

The Android Studio file display issues have been fixed by:
1. Regenerating IDE project files with `flutter create`
2. Ensuring proper module configuration in `.idea/modules.xml`
3. Adding all platform support simultaneously

**If you still experience issues:**
1. Close Android Studio
2. Delete `.idea` folder and `.iml` files
3. Run `flutter clean`
4. Run `flutter pub get`
5. Reopen project in Android Studio
6. File > Invalidate Caches / Restart

## Package Compatibility Notes

### Packages with Platform Limitations:

1. **permission_handler** - Limited on web, requires platform-specific setup
2. **path_provider** - Works on all platforms with platform-specific implementations
3. **share_plus** - Limited functionality on web (uses Web Share API)
4. **url_launcher** - Works on all platforms
5. **pdf** - Works on all platforms
6. **flutter_svg** - Works on all platforms

### Recommended Package Updates:
Run `flutter pub outdated` to see available updates. Some packages have newer versions but may require dependency constraint updates.

## Platform-Specific Configurations

### Android Manifest Permissions
Location: `android/app/src/main/AndroidManifest.xml`
- Internet permission
- Camera permission
- Storage permissions
- Location permissions (if needed)

### iOS Info.plist Permissions
Location: `ios/Runner/Info.plist`
- Camera usage description
- Photo library usage description
- Location usage descriptions

### macOS Entitlements
Location: `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`
- Network client/server entitlements
- Camera access (if needed)
- File access permissions

### Web
Location: `web/index.html`
- Splash screen configured
- Meta tags for mobile web
- PWA manifest available

## Testing on Different Platforms

### Automated Testing
```bash
# Run tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Manual Testing Checklist
- [ ] Authentication flow works
- [ ] API calls function properly
- [ ] Image loading works
- [ ] Navigation is smooth
- [ ] File downloads/sharing work
- [ ] Responsive UI on different screen sizes
- [ ] Dark mode support
- [ ] Offline functionality (if applicable)

## Known Issues and Limitations

### Web Platform
- File system access is limited
- Native device features may not work
- Performance may be slower than native apps
- No support for dart:ffi packages

### Desktop Platforms (Windows/Linux/macOS)
- Some mobile-specific plugins may not work
- Window management is different from mobile
- File paths are platform-specific

### Mobile Platforms
- iOS requires code signing for device deployment
- Android requires proper permissions in manifest

## Development Workflow

### For Cross-Platform Development:
1. Develop primarily on target platform
2. Test frequently on web for quick iterations
3. Test on mobile devices regularly
4. Build for desktop platforms before releases
5. Use responsive design principles

### Best Practices:
- Use platform checks when needed: `Platform.isIOS`, `kIsWeb`, etc.
- Use conditional imports for platform-specific code
- Test on actual devices, not just simulators/emulators
- Handle platform-specific permissions gracefully
- Provide fallbacks for unsupported features

## Troubleshooting

### Build Failures
1. Run `flutter clean`
2. Run `flutter pub get`
3. Delete build folders
4. Check Flutter doctor: `flutter doctor -v`

### IDE Issues
1. Restart IDE
2. Invalidate caches
3. Reimport project
4. Check plugin installation (Flutter & Dart plugins)

### Platform-Specific Issues
- **Android**: Check Gradle version and Android SDK
- **iOS**: Check Xcode version and certificates
- **Web**: Clear browser cache
- **macOS**: Update CocoaPods
- **Windows**: Check Visual Studio installation
- **Linux**: Verify all dependencies installed

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Platform-specific code](https://docs.flutter.dev/platform-integration/platform-channels)
- [Desktop support](https://docs.flutter.dev/desktop)
- [Web support](https://docs.flutter.dev/platform-integration/web)

## Next Steps

1. Test the application on Windows machine
2. Test the application on Linux machine
3. Optimize build sizes for each platform
4. Set up CI/CD for multi-platform builds
5. Create platform-specific app icons and splash screens
6. Configure platform-specific features (notifications, deep links, etc.)

---

**Last Updated**: December 11, 2025
**Flutter Version**: 3.35.7
**Dart Version**: 3.9.2
