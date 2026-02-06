#!/bin/bash
# Quick single-command compliance runner
# Usage: ./quick_run.sh [task_number|all]

CD="/Volumes/Extreme SSD/projects/tcc/tcc_user_mobile_client"
CLAUDE="claude -p --dangerously-skip-permissions --max-turns 30"

case "${1:-all}" in
  5|api)
    $CLAUDE "In $CD, add deleteAccount() method to lib/services/api_service.dart that calls DELETE /user/delete-account. Add corresponding method in auth_service.dart. Minimal code only."
    ;;
  6|ui)
    $CLAUDE "In $CD, add Delete Account option to settings screen with confirmation dialog. On confirm: call delete API, clear storage, logout. Edit existing files only, minimal code."
    ;;
  9|privacy)
    $CLAUDE "In $CD, create public/privacy-policy.html for TCC financial app. Cover: data collected, Stripe/Firebase, user rights. Minimal HTML."
    ;;
  10|terms)
    $CLAUDE "In $CD, create public/terms.html with terms of service. Cover: accounts, wallet, liability. Minimal HTML."
    ;;
  11|support)
    $CLAUDE "In $CD, create public/support.html with contact info (support@tcc.com) and FAQ. Minimal HTML."
    ;;
  12|deploy)
    $CLAUDE "In $CD, configure firebase.json for hosting public/ with routes for legal pages, then run firebase deploy --only hosting"
    ;;
  all)
    echo "Running all tasks in parallel..."
    $CLAUDE "In $CD, add deleteAccount() to api_service.dart and auth_service.dart. Minimal." &
    $CLAUDE "In $CD, create public/privacy-policy.html for financial app. Minimal HTML." &
    $CLAUDE "In $CD, create public/terms.html with terms of service. Minimal HTML." &
    $CLAUDE "In $CD, create public/support.html with FAQ. Minimal HTML." &
    wait
    $CLAUDE "In $CD, add Delete Account to settings with confirmation dialog, call API on confirm. Minimal."
    $CLAUDE "In $CD, configure firebase.json and deploy: firebase deploy --only hosting"
    ;;
  *)
    echo "Usage: $0 [5|api|6|ui|9|privacy|10|terms|11|support|12|deploy|all]"
    ;;
esac
