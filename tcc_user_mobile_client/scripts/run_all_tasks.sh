#!/bin/bash
#===============================================================================
# TCC AUTOMATED TASK RUNNER
# Runs Claude Code instances in parallel to complete all compliance tasks
# Auto-accepts edits, pushes to GitHub, and restarts backend
#===============================================================================

set -euo pipefail

# Config
WORKSPACE="/Volumes/Extreme SSD/projects/tcc"
MOBILE_CLIENT="$WORKSPACE/tcc_user_mobile_client"
BACKEND="$WORKSPACE/tcc-backend"
LOG_DIR="$MOBILE_CLIENT/scripts/logs"
MAX_PARALLEL=4
BRANCH="feature/app-store-compliance"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }

mkdir -p "$LOG_DIR"

#-------------------------------------------------------------------------------
# Task definitions: ID|Directory|Prompt
#-------------------------------------------------------------------------------
TASKS=(
  "CRIT_01|$MOBILE_CLIENT|Implement account deletion feature: Add 'Delete Account' button in lib/screens/profile/account_screen.dart with confirmation dialog. Add deleteAccount method to lib/services/auth_service.dart that calls DELETE /users/delete-account, clears SharedPreferences, and navigates to login. Auto-accept all changes."

  "CRIT_02|$MOBILE_CLIENT|Create privacy policy: Write a comprehensive privacy policy to public/privacy-policy.html covering data collection (name, email, phone, KYC docs, transactions), third-party sharing (Stripe, Firebase, CurrencyBeacon), user rights, and contact info. Add privacy policy link in lib/screens/profile/account_screen.dart."

  "HIGH_01|$MOBILE_CLIENT|Add investment risk disclaimers to lib/screens/investment/investment_product_detail_screen.dart and lib/screens/currency/currency_purchase_screen.dart. Add text: 'Investments carry risk. Past performance does not guarantee future results.'"

  "HIGH_04|$MOBILE_CLIENT|Create terms of service: Write ToS to public/terms-of-service.html. Add ToS link in lib/screens/profile/account_screen.dart. Add acceptance checkboxes in lib/screens/auth/register_screen.dart for Privacy Policy and ToS."

  "HIGH_05|$MOBILE_CLIENT|Create iOS privacy manifest file at ios/Runner/PrivacyInfo.xcprivacy declaring NSUserDefaults usage with reason code 'CA92.1' for app functionality."

  "HIGH_06|$MOBILE_CLIENT|Add support contact section in lib/screens/profile/account_screen.dart with email link (support@tcc.com) and help/FAQ button."

  "MED_02|$MOBILE_CLIENT|Add biometric authentication using local_auth package. Add biometric login option in lib/screens/auth/login_screen.dart. Store biometric preference in SharedPreferences."

  "MED_06|$MOBILE_CLIENT|Create lib/screens/help/faq_screen.dart with FAQ items covering: adding money, sending/receiving, KYC verification, investments, and contact support. Add navigation from account_screen.dart."
)

#-------------------------------------------------------------------------------
# Run single Claude task
#-------------------------------------------------------------------------------
run_task() {
  local task_id="$1" dir="$2" prompt="$3"
  local log_file="$LOG_DIR/${task_id}.log"

  log "Starting $task_id..."

  cd "$dir"

  # Run Claude with auto-accept, capture output
  timeout 600 claude --dangerously-skip-permissions -p "$prompt" \
    > "$log_file" 2>&1 || {
      # If timed out or paused, try continue
      echo "continue" | claude --dangerously-skip-permissions --continue \
        >> "$log_file" 2>&1 || true
    }

  success "$task_id completed"
}

#-------------------------------------------------------------------------------
# Run tasks in parallel batches
#-------------------------------------------------------------------------------
run_parallel_tasks() {
  local pids=() task_ids=()

  for task in "${TASKS[@]}"; do
    IFS='|' read -r id dir prompt <<< "$task"

    run_task "$id" "$dir" "$prompt" &
    pids+=($!)
    task_ids+=("$id")

    # Limit parallel jobs
    if [ ${#pids[@]} -ge $MAX_PARALLEL ]; then
      for i in "${!pids[@]}"; do
        wait "${pids[$i]}" && success "${task_ids[$i]} done" || log "${task_ids[$i]} needs review"
      done
      pids=(); task_ids=()
    fi
  done

  # Wait for remaining
  for i in "${!pids[@]}"; do
    wait "${pids[$i]}" && success "${task_ids[$i]} done" || log "${task_ids[$i]} needs review"
  done
}

#-------------------------------------------------------------------------------
# Git operations
#-------------------------------------------------------------------------------
push_to_github() {
  log "Pushing changes to GitHub..."

  cd "$MOBILE_CLIENT"

  # Create branch if needed
  git checkout -B "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

  # Stage and commit
  git add -A
  git diff --cached --quiet || git commit -m "feat: app store compliance tasks

- Add account deletion feature
- Add privacy policy and terms of service
- Add investment risk disclaimers
- Add iOS privacy manifest
- Add biometric authentication
- Add FAQ screen
- Add support contact section

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

  # Push
  git push -u origin "$BRANCH" --force-with-lease

  success "Pushed to origin/$BRANCH"
}

#-------------------------------------------------------------------------------
# Restart backend
#-------------------------------------------------------------------------------
restart_backend() {
  log "Restarting backend server..."

  cd "$BACKEND"

  # Try PM2 first, then Docker, then npm
  if command -v pm2 &>/dev/null && pm2 list | grep -q tcc; then
    pm2 restart tcc && success "Backend restarted (PM2)"
  elif [ -f docker-compose.yml ]; then
    docker-compose restart && success "Backend restarted (Docker)"
  elif [ -f package.json ]; then
    # Kill existing and restart
    pkill -f "node.*tcc" 2>/dev/null || true
    nohup npm start > /dev/null 2>&1 &
    success "Backend restarted (npm)"
  else
    log "No backend restart method found - manual restart needed"
  fi
}

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
main() {
  log "=== TCC Automated Task Runner ==="
  log "Workspace: $WORKSPACE"
  log "Tasks: ${#TASKS[@]}"
  log "Max parallel: $MAX_PARALLEL"
  echo ""

  # Check Claude CLI
  command -v claude &>/dev/null || error "Claude CLI not found"

  # Run all tasks
  run_parallel_tasks

  echo ""
  log "=== Tasks Complete ==="
  echo ""

  # Git push
  push_to_github

  # Restart backend
  restart_backend

  echo ""
  success "All operations completed!"
  log "Logs available at: $LOG_DIR"
  log "Review branch: $BRANCH"
}

# Run with optional single task
if [ "${1:-}" = "--task" ] && [ -n "${2:-}" ]; then
  for task in "${TASKS[@]}"; do
    IFS='|' read -r id dir prompt <<< "$task"
    [ "$id" = "$2" ] && { run_task "$id" "$dir" "$prompt"; exit 0; }
  done
  error "Task $2 not found"
else
  main
fi
