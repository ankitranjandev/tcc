#!/bin/bash
#===============================================================================
# CLAUDE MULTI-INSTANCE TASK RUNNER
# Usage: ./claude_runner.sh [all|critical|high|single TASK_ID]
#===============================================================================

WS="/Volumes/Extreme SSD/projects/tcc"
APP="$WS/tcc_user_mobile_client"
BE="$WS/tcc-backend"
LOGS="$APP/scripts/logs"
PARALLEL=3

mkdir -p "$LOGS"

# Claude executor with auto-continue
claude_run() {
  local id=$1 prompt=$2 log="$LOGS/$id.log"
  echo "[$(date +%H:%M:%S)] Starting $id"
  cd "$APP"
  if timeout 300 claude --dangerously-skip-permissions -p "$prompt" >"$log" 2>&1; then
    echo "✓ $id done"
  else
    echo "continue" | timeout 120 claude --dangerously-skip-permissions --continue >>"$log" 2>&1 || echo "⚠ $id needs review"
  fi
}

# Task definitions
declare -A CRITICAL=(
  [CRIT_01]="Implement account deletion in lib/screens/profile/account_screen.dart: add Delete Account button with confirmation dialog. In lib/services/auth_service.dart add deleteAccount() that calls DELETE /users/delete-account, clears SharedPreferences via prefs.clear(), and uses GoRouter to navigate to /login."
  [CRIT_02]="Create public/privacy-policy.html with comprehensive privacy policy for TCC financial app. Cover: data collected (personal, financial, KYC), third-party sharing (Stripe, Firebase, CurrencyBeacon), retention, user rights, contact info@tcc.com. Add link in account_screen.dart."
  [CRIT_05]="Create ios/Runner/PrivacyInfo.xcprivacy declaring NSPrivacyAccessedAPITypes for UserDefaults with reason CA92.1, NSPrivacyTracking false, and appropriate NSPrivacyCollectedDataTypes for financial app."
)

declare -A HIGH=(
  [HIGH_01]="Add investment disclaimers to lib/screens/investment/investment_product_detail_screen.dart and currency_purchase_screen.dart: 'Investments carry risk. Past performance does not guarantee future results. You may lose your capital.'"
  [HIGH_04]="Create public/terms-of-service.html for TCC. Add ToS and Privacy Policy checkboxes in register_screen.dart that must be checked before registration."
  [HIGH_05]="Add support section to account_screen.dart with ListTiles for: Email Support (launches mailto:support@tcc.com), Help Center, and Report a Problem."
  [HIGH_06]="Create lib/screens/help/faq_screen.dart with ExpansionTiles for common questions about wallet, transfers, KYC, investments. Add navigation from account_screen."
  [HIGH_07]="Add biometric auth: use local_auth package in login_screen.dart to offer Face ID/Touch ID login when user has previously logged in. Store auth preference in SharedPreferences."
)

declare -A MEDIUM=(
  [MED_01]="Add pull-to-refresh to wallet_screen.dart, transaction history, and portfolio screens using RefreshIndicator widget."
  [MED_02]="Improve error handling in api_service.dart with user-friendly messages. Add retry logic for network errors."
  [MED_03]="Add loading skeletons using shimmer package to home_screen.dart and wallet_screen.dart for better UX."
)

# Run task group in parallel
run_group() {
  local -n tasks=$1
  local pids=()
  for id in "${!tasks[@]}"; do
    claude_run "$id" "${tasks[$id]}" &
    pids+=($!)
    ((${#pids[@]} >= PARALLEL)) && { wait "${pids[0]}"; pids=("${pids[@]:1}"); }
  done
  wait
}

# Git push
git_push() {
  echo "=== Pushing to GitHub ==="
  cd "$APP"
  git checkout -B feature/compliance-$(date +%m%d) 2>/dev/null || true
  git add -A
  git diff --cached --quiet && { echo "No changes"; return; }
  git commit -m "feat: compliance tasks batch

$(ls "$LOGS"/*.log 2>/dev/null | xargs -I{} basename {} .log | tr '\n' ', ')

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
  git push -u origin HEAD --force-with-lease && echo "✓ Pushed"
}

# Backend restart
restart_be() {
  echo "=== Restarting Backend ==="
  cd "$BE" 2>/dev/null || { echo "Backend dir not found"; return; }
  pm2 restart all 2>/dev/null || docker-compose restart 2>/dev/null || echo "Manual restart needed"
}

# Main
case "${1:-all}" in
  critical) run_group CRITICAL ;;
  high)     run_group CRITICAL; run_group HIGH ;;
  all)      run_group CRITICAL; run_group HIGH; run_group MEDIUM ;;
  single)   [[ -n "${CRITICAL[$2]:-}" ]] && claude_run "$2" "${CRITICAL[$2]}" || \
            [[ -n "${HIGH[$2]:-}" ]] && claude_run "$2" "${HIGH[$2]}" || \
            [[ -n "${MEDIUM[$2]:-}" ]] && claude_run "$2" "${MEDIUM[$2]}" || \
            echo "Task $2 not found" ;;
  status)   echo "Logs:"; ls -la "$LOGS"/*.log 2>/dev/null || echo "No logs yet" ;;
  *)        echo "Usage: $0 [all|critical|high|single TASK_ID|status]"; exit 1 ;;
esac

git_push
restart_be
echo "✓ Complete! Logs: $LOGS"
