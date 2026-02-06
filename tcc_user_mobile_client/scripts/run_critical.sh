#!/bin/bash
#===============================================================================
# TCC CRITICAL TASKS ONLY - Fastest path to App Store submission
#===============================================================================

set -euo pipefail

WS="/Volumes/Extreme SSD/projects/tcc"
APP="$WS/tcc_user_mobile_client"
BE="$WS/tcc-backend"

run() { cd "$APP" && claude --dangerously-skip-permissions -p "$1" || echo "continue" | claude --dangerously-skip-permissions --continue; }

echo "=== Running Critical Tasks ==="

# CRIT-01: Account Deletion
run "Add account deletion: 1) In lib/screens/profile/account_screen.dart add Delete Account ListTile with red icon that shows confirmation dialog. 2) In lib/services/auth_service.dart add deleteAccount() method calling DELETE /users/delete-account, clearing prefs, navigating to /login. Use existing patterns." &

# CRIT-02: Privacy Policy
run "Create public/privacy-policy.html with TCC privacy policy covering: personal data (name,email,phone), financial data, KYC docs, third-parties (Stripe,Firebase), user rights, contact. Add link in account_screen.dart." &

# HIGH-05: Privacy Manifest
run "Create ios/Runner/PrivacyInfo.xcprivacy with NSPrivacyAccessedAPITypes for NSUserDefaults (reason CA92.1) and NSPrivacyCollectedDataTypes for identifiers and financial info." &

wait

echo "=== Pushing to GitHub ==="
cd "$APP"
git checkout -B feature/critical-compliance 2>/dev/null || true
git add -A
git diff --cached --quiet || git commit -m "feat: critical app store compliance

- Account deletion (5.1.1v)
- Privacy policy (5.1.1i)
- iOS privacy manifest

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
git push -u origin feature/critical-compliance --force-with-lease

echo "=== Restarting Backend ==="
cd "$BE" && (pm2 restart tcc 2>/dev/null || docker-compose restart 2>/dev/null || (pkill -f "node.*tcc"; npm start &)) || echo "Manual restart needed"

echo "✓ Done! Review: feature/critical-compliance"
