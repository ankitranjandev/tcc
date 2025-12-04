#!/bin/bash

# Script to fix all hardcoded colors for dark mode compatibility

echo "Fixing dark mode issues across all screens..."

# Update portfolio screen
echo "Updating portfolio screen..."
find lib/screens/dashboard/portfolio_screen.dart -type f -exec sed -i.bak \
  -e 's/Colors\.black/Theme.of(context).textTheme.titleLarge?.color/g' \
  -e 's/Colors\.grey\[600\]/Theme.of(context).textTheme.bodySmall?.color/g' \
  -e 's/Colors\.grey\[500\]/Theme.of(context).textTheme.caption?.color/g' \
  -e 's/Colors\.grey\[400\]/Theme.of(context).disabledColor/g' \
  -e 's/Colors\.grey\[50\]/Theme.of(context).cardColor/g' \
  {} \;

# Update investment screens
echo "Updating investment screens..."
find lib/screens/investments -type f -name "*.dart" -exec sed -i.bak \
  -e 's/color: Colors\.black/color: Theme.of(context).textTheme.titleLarge?.color/g' \
  -e 's/Colors\.grey\[600\]/Theme.of(context).textTheme.bodySmall?.color/g' \
  -e 's/Colors\.grey\[700\]/Theme.of(context).textTheme.bodySmall?.color/g' \
  -e 's/Colors\.grey\[300\]/Theme.of(context).dividerColor/g' \
  -e 's/Colors\.grey\[200\]/Theme.of(context).dividerColor/g' \
  -e 's/Colors\.grey\[50\]/Theme.of(context).cardColor/g' \
  {} \;

# Update portfolio detail screen
echo "Updating portfolio detail screen..."
find lib/screens/portfolio -type f -name "*.dart" -exec sed -i.bak \
  -e 's/color: Colors\.black/color: Theme.of(context).textTheme.titleLarge?.color/g' \
  -e 's/Colors\.grey\[600\]/Theme.of(context).textTheme.bodySmall?.color/g' \
  -e 's/Colors\.grey\[700\]/Theme.of(context).textTheme.bodySmall?.color/g' \
  -e 's/Colors\.grey\[400\]/Theme.of(context).disabledColor/g' \
  -e 's/Colors\.grey\[200\]/Theme.of(context).dividerColor/g' \
  -e 's/Colors\.grey\[50\]/Theme.of(context).cardColor/g' \
  {} \;

# Update auth screens
echo "Updating auth screens..."
find lib/screens/auth -type f -name "*.dart" -exec sed -i.bak \
  -e 's/AppColors\.black/Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black/g' \
  -e 's/AppColors\.gray600/Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey/g' \
  {} \;

# Update profile/account screens
echo "Updating profile screens..."
find lib/screens/profile -type f -name "*.dart" -exec sed -i.bak \
  -e 's/color: Colors\.black/color: Theme.of(context).textTheme.titleLarge?.color/g' \
  -e 's/Colors\.grey\[600\]/Theme.of(context).textTheme.bodySmall?.color/g' \
  -e 's/Colors\.grey\[500\]/Theme.of(context).textTheme.caption?.color/g' \
  -e 's/Colors\.grey\[300\]/Theme.of(context).dividerColor/g' \
  {} \;

# Update transaction screens (already done but double check)
echo "Updating transaction screens..."
find lib/screens/dashboard/transactions_screen.dart -type f -exec sed -i.bak \
  -e 's/Colors\.grey\[600\]/Theme.of(context).textTheme.bodySmall?.color/g' \
  -e 's/Colors\.grey\[400\]/Theme.of(context).disabledColor/g' \
  {} \;

# Clean up backup files
find lib -name "*.bak" -delete

echo "Dark mode fixes completed!"
echo "Please run 'flutter analyze' to check for any issues."