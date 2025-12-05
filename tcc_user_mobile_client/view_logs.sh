#!/bin/bash

# Script to view Flutter app logs with color-coded output

echo "📱 Starting Flutter log viewer..."
echo "Press Ctrl+C to stop"
echo ""

# Use flutter logs with grep to filter for our custom log tags
flutter logs | grep -E "(TCCApp|AuthProvider|AuthService|ApiService|LoginScreen)" --color=always
