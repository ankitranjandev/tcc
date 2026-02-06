#!/bin/bash
#
# TCC Compliance Tasks - Advanced Parallel Executor
# Uses multiple Claude instances with optimal parallelization
#

PROJECT_DIR="/Volumes/Extreme SSD/projects/tcc"
CLIENT_DIR="$PROJECT_DIR/tcc_user_mobile_client"
SCRIPT_DIR="$CLIENT_DIR/scripts"
LOG_DIR="$SCRIPT_DIR/logs"
STATE_FILE="$SCRIPT_DIR/.task_state"

mkdir -p "$LOG_DIR"

# Colors and formatting
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m' C='\033[0;36m' NC='\033[0m'
log() { echo -e "${B}[$(date +%H:%M:%S)]${NC} $*"; }
ok() { echo -e "${G}✓${NC} $*"; }
err() { echo -e "${R}✗${NC} $*"; }
info() { echo -e "${C}→${NC} $*"; }

# State management for auto-continue
mark_done() { echo "$1" >> "$STATE_FILE"; }
is_done() { grep -qxF "$1" "$STATE_FILE" 2>/dev/null; }
reset_state() { rm -f "$STATE_FILE"; log "State reset"; }

# Parse args
[[ "$1" == "--reset" ]] && reset_state && exit 0
[[ "$1" == "--status" ]] && { cat "$STATE_FILE" 2>/dev/null || echo "No tasks completed"; exit 0; }

# Trap for graceful shutdown
PIDS=()
cleanup() {
    echo ""
    log "Interrupted - killing background tasks..."
    for pid in "${PIDS[@]}"; do kill "$pid" 2>/dev/null; done
    log "State saved. Run again to continue."
    exit 1
}
trap cleanup SIGINT SIGTERM

# Run Claude task
run_task() {
    local id=$1 name=$2 prompt=$3
    local logfile="$LOG_DIR/${id}_$(date +%H%M%S).log"

    if is_done "$id"; then
        ok "$id: $name (cached)"
        return 0
    fi

    info "$id: $name"

    if claude -p "$prompt" \
        --dangerously-skip-permissions \
        --max-turns 50 \
        > "$logfile" 2>&1; then
        mark_done "$id"
        ok "$id: $name"
        return 0
    else
        err "$id: $name (see $logfile)"
        return 1
    fi
}

# Background task wrapper
bg_task() {
    run_task "$@" &
    PIDS+=($!)
}

wait_all() {
    local failed=0
    for pid in "${PIDS[@]}"; do
        wait "$pid" || ((failed++))
    done
    PIDS=()
    return $failed
}

#=============================================================================
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  TCC Compliance Parallel Executor                          ║"
echo "║  Auto-accept | Parallel | Auto-continue                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
#=============================================================================

cd "$CLIENT_DIR" || exit 1
log "Working directory: $CLIENT_DIR"
echo ""

#-----------------------------------------------------------------------------
log "━━━ WAVE 1: Backend + Content (4 parallel tasks) ━━━"
#-----------------------------------------------------------------------------

bg_task "T5" "Delete Account API" "
Working in: $CLIENT_DIR

Add account deletion to the app. Minimal code only.

1. Edit lib/services/api_service.dart - add:
   Future<Map<String, dynamic>> deleteAccount() async {
     return await delete('/user/delete-account');
   }

2. Edit lib/services/auth_service.dart - add method to call deleteAccount and handle response.

Only edit these 2 files. Keep changes minimal.
"

bg_task "T9" "Privacy Policy" "
Working in: $CLIENT_DIR

Create public/privacy-policy.html - privacy policy for TCC financial app (Sierra Leone).

Include: data collection (name, email, phone, ID, financial), third parties (Stripe, Firebase),
user rights (access, delete), contact info. Minimal HTML with inline CSS.
"

bg_task "T10" "Terms of Service" "
Working in: $CLIENT_DIR

Create public/terms.html - terms of service for TCC app.

Include: acceptance, account rules, wallet terms, prohibited use, liability, Sierra Leone law.
Minimal HTML with inline CSS.
"

bg_task "T11" "Support Page" "
Working in: $CLIENT_DIR

Create public/support.html - support page with contact info and FAQ.

Email: support@tcc.com, FAQ for: accounts, payments, KYC, transfers.
Minimal HTML with inline CSS.
"

wait_all || err "Some Wave 1 tasks failed"
echo ""

#-----------------------------------------------------------------------------
log "━━━ WAVE 2: Frontend UI (depends on Wave 1 backend) ━━━"
#-----------------------------------------------------------------------------

run_task "T6-8" "Account Deletion UI" "
Working in: $CLIENT_DIR

Add account deletion UI to the app. Find the settings screen and add:

1. 'Delete Account' button/tile (red/warning color) at bottom of settings
2. Confirmation dialog warning about data loss
3. On confirm: call auth service delete method, clear storage, go to login

Search for settings screen in lib/screens/, edit existing file.
Use existing theme/patterns. Minimal code only.
"

echo ""

#-----------------------------------------------------------------------------
log "━━━ WAVE 3: Firebase Config ━━━"
#-----------------------------------------------------------------------------

run_task "T12" "Firebase Hosting" "
Working in: $CLIENT_DIR

Configure firebase.json for hosting the legal pages:

1. Update firebase.json hosting config to serve public/ directory
2. Add rewrites for /privacy-policy, /terms, /support to their .html files
3. Verify configuration is correct

Then run: firebase deploy --only hosting

If firebase CLI fails, just ensure config is correct.
"

echo ""

#-----------------------------------------------------------------------------
log "━━━ SUMMARY ━━━"
#-----------------------------------------------------------------------------

echo ""
echo "Automated tasks completed. Review with: git diff"
echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  MANUAL TASKS STILL REQUIRED:                               │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│  □ Verify Apple Developer account is Organization type      │"
echo "│  □ Gather financial licenses (Bank of Sierra Leone)         │"
echo "│  □ Create demo account: appreview@tcc.com                   │"
echo "│  □ Complete KYC for demo account                            │"
echo "│  □ Fund demo account wallet                                 │"
echo "│  □ Add credentials to App Store Connect Notes               │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""
log "Logs: $LOG_DIR"
log "State: $STATE_FILE (run with --reset to clear)"
