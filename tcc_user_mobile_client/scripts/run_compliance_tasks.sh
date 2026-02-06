#!/bin/bash
#
# TCC App Store Compliance Task Runner
# Executes critical blocker tasks in parallel using Claude Code
#

set -e

# Configuration
PROJECT_DIR="/Volumes/Extreme SSD/projects/tcc"
CLIENT_DIR="$PROJECT_DIR/tcc_user_mobile_client"
LOG_DIR="$CLIENT_DIR/scripts/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
STATE_FILE="$LOG_DIR/task_state_$TIMESTAMP.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Create directories
mkdir -p "$LOG_DIR"

# Initialize state file
cat > "$STATE_FILE" << 'EOF'
{"tasks":{}}
EOF

log() { echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

update_state() {
    local task=$1 status=$2
    python3 -c "
import json
with open('$STATE_FILE', 'r+') as f:
    data = json.load(f)
    data['tasks']['$task'] = '$status'
    f.seek(0); json.dump(data, f); f.truncate()
" 2>/dev/null || true
}

check_state() {
    local task=$1
    python3 -c "
import json
with open('$STATE_FILE') as f:
    data = json.load(f)
    print(data.get('tasks', {}).get('$task', 'pending'))
" 2>/dev/null || echo "pending"
}

run_claude() {
    local name=$1 prompt=$2 log_file="$LOG_DIR/${name}_$TIMESTAMP.log"

    if [[ $(check_state "$name") == "completed" ]]; then
        success "$name already completed, skipping"
        return 0
    fi

    update_state "$name" "running"
    log "Starting: $name"

    if claude -p "$prompt" \
        --dangerously-skip-permissions \
        --output-format stream-json \
        > "$log_file" 2>&1; then
        update_state "$name" "completed"
        success "$name completed"
        return 0
    else
        update_state "$name" "failed"
        error "$name failed - check $log_file"
        return 1
    fi
}

run_claude_bg() {
    local name=$1 prompt=$2
    run_claude "$name" "$prompt" &
}

wait_for_tasks() {
    log "Waiting for background tasks..."
    wait
    success "All parallel tasks completed"
}

# Trap for cleanup and auto-continue
cleanup() {
    warn "Interrupted! State saved to $STATE_FILE"
    warn "Re-run script to continue from last checkpoint"
    exit 1
}
trap cleanup SIGINT SIGTERM

#=============================================================================
# PHASE 1: Parallel - Account Deletion Backend + Legal Pages Content
#=============================================================================
phase1() {
    log "═══ PHASE 1: Backend API + Legal Content (Parallel) ═══"

    # Task 5: Account deletion API
    run_claude_bg "task5_delete_api" "
You are working in: $CLIENT_DIR

TASK: Add account deletion API endpoint call (Task #5)

Requirements:
1. In lib/services/api_service.dart, add a deleteAccount() method
2. In lib/services/auth_service.dart, add deleteUserAccount() that calls the API
3. Use minimal code - just add the essential methods

Implementation:
- Endpoint: DELETE /user/delete-account or /auth/delete-account
- Return success/failure response
- Follow existing code patterns in the file

Do NOT create new files. Only edit existing service files.
Keep changes minimal and focused.
"

    # Task 9, 10, 11: Legal pages (can run in parallel with backend)
    run_claude_bg "task9_privacy_policy" "
You are working in: $CLIENT_DIR

TASK: Create privacy policy HTML page (Task #9)

Create public/privacy-policy.html with a complete privacy policy for TCC financial app.

Must cover:
- Company: TCC (The Community Coin) - Sierra Leone financial services
- Data collected: name, email, phone, government ID, photos, financial info
- Third parties: Stripe (payments), Firebase (analytics/notifications), AWS (hosting)
- User rights: access, deletion, portability
- Contact: support@tcc.com

Use clean, minimal HTML with inline CSS. Single file, no external dependencies.
"

    run_claude_bg "task10_terms" "
You are working in: $CLIENT_DIR

TASK: Create terms of service HTML page (Task #10)

Create public/terms.html with terms of service for TCC financial app.

Cover: account terms, wallet usage, prohibited activities, liability limits,
governing law (Sierra Leone), dispute resolution.

Use clean, minimal HTML with inline CSS matching privacy-policy.html style.
"

    run_claude_bg "task11_support" "
You are working in: $CLIENT_DIR

TASK: Create support/contact HTML page (Task #11)

Create public/support.html with:
- Support email: support@tcc.com
- Support hours
- FAQ section (account issues, payments, KYC, transfers)
- Physical address placeholder

Use clean, minimal HTML with inline CSS matching other legal pages.
"

    wait_for_tasks
}

#=============================================================================
# PHASE 2: Account Deletion UI (depends on Phase 1 backend)
#=============================================================================
phase2() {
    log "═══ PHASE 2: Account Deletion UI ═══"

    # Task 6, 7, 8: UI components
    run_claude "task6_7_8_deletion_ui" "
You are working in: $CLIENT_DIR

TASK: Create account deletion UI with confirmation (Tasks #6, #7, #8)

Requirements:
1. Find the settings or profile screen in lib/screens/
2. Add a 'Delete Account' option (red/warning styled)
3. Create a confirmation dialog that:
   - Warns about data deletion (wallet, KYC, history)
   - Has Cancel and Delete buttons
   - Calls the deleteUserAccount() from auth_service.dart
4. On success: clear local storage, logout, navigate to login screen

Keep code minimal. Use existing app patterns and theme.
Do NOT create unnecessary new files - add to existing screens.
"
}

#=============================================================================
# PHASE 3: Deploy Legal Pages to Firebase
#=============================================================================
phase3() {
    log "═══ PHASE 3: Deploy to Firebase Hosting ═══"

    run_claude "task12_deploy" "
You are working in: $CLIENT_DIR

TASK: Configure and prepare Firebase Hosting deployment (Task #12)

1. Check/update firebase.json to serve the public/ directory
2. Ensure hosting config routes:
   - /privacy-policy -> privacy-policy.html
   - /terms -> terms.html
   - /support -> support.html
3. Verify .firebaserc has correct project ID

After configuration, run: firebase deploy --only hosting

If firebase CLI not available, just prepare the config files.
"
}

#=============================================================================
# MANUAL TASKS REMINDER
#=============================================================================
manual_tasks() {
    echo ""
    log "═══ MANUAL TASKS REQUIRED ═══"
    warn "The following tasks require manual action:"
    echo ""
    echo "  📋 Task #3: Verify Financial Services Entity"
    echo "     └─ #13: Check Apple Developer account is Organization type"
    echo "     └─ #14: Gather financial licenses from Bank of Sierra Leone"
    echo ""
    echo "  📋 Task #4: Create Demo Account for Apple Review"
    echo "     └─ #15: Create appreview@tcc.com account"
    echo "     └─ #16: Complete KYC verification"
    echo "     └─ #17: Add wallet balance"
    echo "     └─ #18: Document in App Store Connect Notes"
    echo ""
}

#=============================================================================
# MAIN
#=============================================================================
main() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║     TCC App Store Compliance Task Runner                      ║"
    echo "║     Auto-executing critical blocker subtasks                  ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    log "Project: $CLIENT_DIR"
    log "Logs: $LOG_DIR"
    log "State: $STATE_FILE"
    echo ""

    phase1  # Backend API + Legal pages (parallel)
    phase2  # Deletion UI
    phase3  # Firebase deploy

    manual_tasks

    echo ""
    success "═══ AUTOMATED TASKS COMPLETED ═══"
    echo ""
    log "Check logs in: $LOG_DIR"
    log "Review changes with: git diff"
    echo ""
}

# Auto-continue support
if [[ -n "$CONTINUE_FROM" ]]; then
    STATE_FILE="$CONTINUE_FROM"
    log "Continuing from: $STATE_FILE"
fi

main "$@"
