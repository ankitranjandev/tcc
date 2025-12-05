#!/bin/bash

# Script to configure backend URL for different environments

echo "🔧 Backend Configuration Tool"
echo "=============================="
echo ""
echo "Select your environment:"
echo "1) Android Emulator (use 10.0.2.2)"
echo "2) iOS Simulator (use 127.0.0.1)"
echo "3) Physical Device (enter custom IP)"
echo "4) Show current configuration"
echo ""
read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo "Configuring for Android Emulator..."
        # Already configured by default for Android
        echo "✅ Android Emulator will use: http://10.0.2.2:3000/v1"
        echo "Make sure your backend is running on port 3000!"
        ;;
    2)
        echo "Configuring for iOS Simulator..."
        echo "✅ iOS Simulator will use: http://127.0.0.1:3000/v1"
        echo "Make sure your backend is running on port 3000!"
        ;;
    3)
        echo "Configuring for Physical Device..."
        echo ""
        echo "To find your computer's IP address:"
        echo "  macOS: ifconfig | grep 'inet ' | grep -v 127.0.0.1"
        echo "  Linux: hostname -I"
        echo "  Windows: ipconfig"
        echo ""
        read -p "Enter your computer's IP address: " ip_address

        if [[ -z "$ip_address" ]]; then
            echo "❌ No IP address provided"
            exit 1
        fi

        echo "You'll need to manually update lib/config/app_constants.dart"
        echo "Replace the return values with: 'http://$ip_address:3000/v1'"
        echo ""
        echo "Or add a check for physical devices in the code."
        ;;
    4)
        echo "Current configuration in app_constants.dart:"
        echo ""
        grep -A 15 "static String get baseUrl" lib/config/app_constants.dart
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "📱 Backend Configuration Complete!"
echo ""
echo "Next steps:"
echo "1. Make sure your backend is running: npm start (or equivalent)"
echo "2. Build and install the app: flutter run"
echo "3. View logs: ./view_logs.sh (in another terminal)"
