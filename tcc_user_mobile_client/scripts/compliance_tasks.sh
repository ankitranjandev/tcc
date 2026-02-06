#!/bin/bash

#===============================================================================
# TCC USER MOBILE CLIENT - COMPLIANCE & RELEASE TASK TRACKER
# Generated: February 6, 2026
#
# This script tracks all tasks needed for Apple App Store submission
# Run with: ./scripts/compliance_tasks.sh [category]
# Categories: all, critical, high, medium, low, status
#===============================================================================

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Task status file
TASK_STATUS_FILE="$(dirname "$0")/.task_status"

# Initialize status file if not exists
init_status_file() {
    if [ ! -f "$TASK_STATUS_FILE" ]; then
        cat > "$TASK_STATUS_FILE" << 'EOF'
# TCC Compliance Task Status
# Format: TASK_ID=STATUS (pending|in_progress|completed|blocked)
# Last updated: 2026-02-06

# CRITICAL TASKS
CRIT_01=pending
CRIT_02=pending
CRIT_03=pending
CRIT_04=pending
CRIT_05=pending

# HIGH PRIORITY TASKS
HIGH_01=pending
HIGH_02=pending
HIGH_03=pending
HIGH_04=pending
HIGH_05=pending
HIGH_06=pending
HIGH_07=pending
HIGH_08=pending

# MEDIUM PRIORITY TASKS
MED_01=pending
MED_02=pending
MED_03=pending
MED_04=pending
MED_05=pending
MED_06=pending
MED_07=pending
MED_08=pending
MED_09=pending
MED_10=pending

# LOW PRIORITY TASKS
LOW_01=pending
LOW_02=pending
LOW_03=pending
LOW_04=pending
LOW_05=pending
LOW_06=pending
LOW_07=pending
LOW_08=pending
EOF
    fi
}

# Load status
load_status() {
    if [ -f "$TASK_STATUS_FILE" ]; then
        source "$TASK_STATUS_FILE"
    fi
}

# Get status emoji
get_status_emoji() {
    case $1 in
        completed) echo "✅";;
        in_progress) echo "🔄";;
        blocked) echo "🚫";;
        *) echo "⬜";;
    esac
}

# Update task status
update_status() {
    local task_id=$1
    local new_status=$2

    if [ -f "$TASK_STATUS_FILE" ]; then
        if grep -q "^${task_id}=" "$TASK_STATUS_FILE"; then
            sed -i '' "s/^${task_id}=.*/${task_id}=${new_status}/" "$TASK_STATUS_FILE"
            echo -e "${GREEN}Updated ${task_id} to ${new_status}${NC}"
        else
            echo -e "${RED}Task ${task_id} not found${NC}"
        fi
    fi
}

# Print header
print_header() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║                    TCC APP STORE COMPLIANCE TASK LIST                        ║${NC}"
    echo -e "${BOLD}║                           February 2026                                      ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Print critical tasks
print_critical() {
    echo -e "${RED}${BOLD}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}${BOLD}  🚨 CRITICAL BLOCKERS - Must Fix Before Submission${NC}"
    echo -e "${RED}${BOLD}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo ""

    load_status

    echo -e "${BOLD}CRIT-01: Implement Account Deletion Feature${NC}"
    echo -e "  Status: $(get_status_emoji ${CRIT_01:-pending}) ${CRIT_01:-pending}"
    echo -e "  Guideline: 5.1.1(v) - Apps with account creation must provide deletion"
    echo -e "  Priority: ${RED}BLOCKER${NC}"
    echo -e "  Files to modify:"
    echo -e "    - lib/screens/profile/account_screen.dart"
    echo -e "    - lib/services/auth_service.dart"
    echo -e "  Implementation:"
    echo -e "    1. Add 'Delete Account' button in AccountScreen"
    echo -e "    2. Create confirmation dialog with warnings"
    echo -e "    3. Implement DELETE /users/delete-account API call"
    echo -e "    4. Clear all local data (SharedPreferences, tokens)"
    echo -e "    5. Navigate to login screen after deletion"
    echo -e "    6. Handle deletion request even if user is offline (queue)"
    echo ""

    echo -e "${BOLD}CRIT-02: Create and Host Privacy Policy${NC}"
    echo -e "  Status: $(get_status_emoji ${CRIT_02:-pending}) ${CRIT_02:-pending}"
    echo -e "  Guideline: 5.1.1(i), 2.3 - Privacy policy required"
    echo -e "  Priority: ${RED}BLOCKER${NC}"
    echo -e "  Tasks:"
    echo -e "    1. Draft comprehensive privacy policy covering:"
    echo -e "       - Personal data collected (name, email, phone, KYC docs)"
    echo -e "       - Financial data collected (transactions, balance)"
    echo -e "       - Third-party sharing (Stripe, Firebase, CurrencyBeacon)"
    echo -e "       - Data retention periods"
    echo -e "       - User rights (access, deletion, portability)"
    echo -e "       - Contact information for privacy inquiries"
    echo -e "    2. Host at public URL (e.g., https://tcc.com/privacy)"
    echo -e "    3. Add URL to App Store Connect"
    echo -e "    4. Add link in app's AccountScreen/Settings"
    echo ""

    echo -e "${BOLD}CRIT-03: Create Demo Account for Apple Reviewers${NC}"
    echo -e "  Status: $(get_status_emoji ${CRIT_03:-pending}) ${CRIT_03:-pending}"
    echo -e "  Guideline: 2.1 - Demo account required for review"
    echo -e "  Priority: ${RED}BLOCKER${NC}"
    echo -e "  Tasks:"
    echo -e "    1. Create test account on production backend"
    echo -e "    2. Pre-approve KYC verification"
    echo -e "    3. Pre-load wallet with test funds"
    echo -e "    4. Ensure account has access to all features"
    echo -e "    5. Document credentials for App Store Connect review notes"
    echo -e "    6. Test login flow works correctly"
    echo -e "  Credentials format for review notes:"
    echo -e "    Email: apple-review@tcc.com"
    echo -e "    Password: [secure password]"
    echo -e "    OTP: [static test OTP or bypass instructions]"
    echo ""

    echo -e "${BOLD}CRIT-04: Verify Licensed Entity Submission${NC}"
    echo -e "  Status: $(get_status_emoji ${CRIT_04:-pending}) ${CRIT_04:-pending}"
    echo -e "  Guideline: 3.2.1(viii) - Financial apps must be from licensed entity"
    echo -e "  Priority: ${RED}BLOCKER${NC}"
    echo -e "  Tasks:"
    echo -e "    1. Verify Apple Developer account is under TCC's legal entity"
    echo -e "    2. Ensure entity has required financial services license"
    echo -e "    3. Update App Store Connect organization info if needed"
    echo -e "    4. Prepare license documentation for Apple if requested"
    echo -e "  Note: Individual developer accounts CANNOT submit financial apps"
    echo ""

    echo -e "${BOLD}CRIT-05: Fix Age Rating in App Store Connect${NC}"
    echo -e "  Status: $(get_status_emoji ${CRIT_05:-pending}) ${CRIT_05:-pending}"
    echo -e "  Guideline: 2.3 - Accurate age rating required"
    echo -e "  Priority: ${RED}BLOCKER${NC}"
    echo -e "  Deadline: January 31, 2026 (respond to updated questions)"
    echo -e "  Tasks:"
    echo -e "    1. Log into App Store Connect"
    echo -e "    2. Go to App Information > Age Rating"
    echo -e "    3. Answer updated questionnaire"
    echo -e "    4. Set rating to 17+ (financial services, real money)"
    echo -e "    5. Submit rating update"
    echo ""
}

# Print high priority tasks
print_high() {
    echo -e "${YELLOW}${BOLD}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}${BOLD}  ⚠️  HIGH PRIORITY - Should Fix Before Submission${NC}"
    echo -e "${YELLOW}${BOLD}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo ""

    load_status

    echo -e "${BOLD}HIGH-01: Add Investment Risk Disclaimers${NC}"
    echo -e "  Status: $(get_status_emoji ${HIGH_01:-pending}) ${HIGH_01:-pending}"
    echo -e "  Guideline: 3.2 - Financial transparency"
    echo -e "  Files to modify:"
    echo -e "    - lib/screens/investment/investment_product_detail_screen.dart"
    echo -e "    - lib/screens/investment/investment_opportunity_detail_screen.dart"
    echo -e "    - lib/screens/currency/currency_purchase_screen.dart"
    echo -e "  Implementation:"
    echo -e "    Add disclaimer text:"
    echo -e "    'Investments carry risk. Past performance does not guarantee future results.'"
    echo -e "    'You may lose some or all of your invested capital.'"
    echo ""

    echo -e "${BOLD}HIGH-02: Add Third-Party Data Sharing Disclosure${NC}"
    echo -e "  Status: $(get_status_emoji ${HIGH_02:-pending}) ${HIGH_02:-pending}"
    echo -e "  Guideline: 5.1.2 - Data sharing transparency"
    echo -e "  Files to modify:"
    echo -e "    - lib/screens/profile/account_screen.dart (add disclosure link)"
    echo -e "    - Privacy policy (include full details)"
    echo -e "  Services to disclose:"
    echo -e "    - Stripe: Payment processing, customer data"
    echo -e "    - Firebase: Analytics, push notifications"
    echo -e "    - CurrencyBeacon: Currency exchange rates"
    echo -e "    - CloudFront: Content delivery"
    echo ""

    echo -e "${BOLD}HIGH-03: Clarify Non-Cryptocurrency Status${NC}"
    echo -e "  Status: $(get_status_emoji ${HIGH_03:-pending}) ${HIGH_03:-pending}"
    echo -e "  Guideline: 3.1.5 - Cryptocurrency clarity"
    echo -e "  Risk: 'Coin' branding may confuse Apple reviewers"
    echo -e "  Tasks:"
    echo -e "    1. Update App Store description to include:"
    echo -e "       'TCC (The Community Coin) is a regulated digital wallet backed by"
    echo -e "        real currency (USD), not a cryptocurrency. It enables secure"
    echo -e "        payments, transfers, and bill payments in Sierra Leone.'"
    echo -e "    2. Add clarification in app onboarding/FAQ"
    echo -e "    3. Prepare explanation for Apple reviewers in review notes"
    echo ""

    echo -e "${BOLD}HIGH-04: Add Terms of Service Link${NC}"
    echo -e "  Status: $(get_status_emoji ${HIGH_04:-pending}) ${HIGH_04:-pending}"
    echo -e "  Guideline: 5.1 - Legal compliance"
    echo -e "  Files to modify:"
    echo -e "    - lib/screens/profile/account_screen.dart"
    echo -e "    - lib/screens/auth/register_screen.dart (checkbox)"
    echo -e "  Tasks:"
    echo -e "    1. Create Terms of Service document"
    echo -e "    2. Host at public URL"
    echo -e "    3. Add link in AccountScreen"
    echo -e "    4. Add acceptance checkbox during registration"
    echo ""

    echo -e "${BOLD}HIGH-05: Implement Privacy Manifest (PrivacyInfo.xcprivacy)${NC}"
    echo -e "  Status: $(get_status_emoji ${HIGH_05:-pending}) ${HIGH_05:-pending}"
    echo -e "  Guideline: Required for listed APIs since May 2024"
    echo -e "  File to create: ios/Runner/PrivacyInfo.xcprivacy"
    echo -e "  APIs to declare:"
    echo -e "    - NSUserDefaults (SharedPreferences)"
    echo -e "    - File timestamp APIs (if used)"
    echo -e "    - System boot time APIs (if used)"
    echo -e "  Reference: developer.apple.com/documentation/bundleresources/privacy_manifest_files"
    echo ""

    echo -e "${BOLD}HIGH-06: Add Support Contact Information${NC}"
    echo -e "  Status: $(get_status_emoji ${HIGH_06:-pending}) ${HIGH_06:-pending}"
    echo -e "  Guideline: 1.5 - Developer information"
    echo -e "  Files to modify:"
    echo -e "    - lib/screens/profile/account_screen.dart"
    echo -e "  Tasks:"
    echo -e "    1. Add support email link"
    echo -e "    2. Add support phone number (optional)"
    echo -e "    3. Add FAQ/Help section"
    echo -e "    4. Add in-app chat support (optional)"
    echo ""

    echo -e "${BOLD}HIGH-07: Add Consent Dialogs for Data Collection${NC}"
    echo -e "  Status: $(get_status_emoji ${HIGH_07:-pending}) ${HIGH_07:-pending}"
    echo -e "  Guideline: 5.1.1 - Explicit consent required"
    echo -e "  Files to modify:"
    echo -e "    - lib/screens/auth/register_screen.dart"
    echo -e "    - lib/screens/kyc/kyc_verification_screen.dart"
    echo -e "  Tasks:"
    echo -e "    1. Add checkbox: 'I agree to the Privacy Policy'"
    echo -e "    2. Add checkbox: 'I agree to the Terms of Service'"
    echo -e "    3. Add consent for KYC data collection"
    echo -e "    4. Store consent timestamps"
    echo ""

    echo -e "${BOLD}HIGH-08: Check App Tracking Transparency Requirement${NC}"
    echo -e "  Status: $(get_status_emoji ${HIGH_08:-pending}) ${HIGH_08:-pending}"
    echo -e "  Guideline: 5.1.2 - ATT required for tracking"
    echo -e "  Tasks:"
    echo -e "    1. Audit if IDFA is collected (check Firebase Analytics config)"
    echo -e "    2. If IDFA used, implement ATT prompt"
    echo -e "    3. Add NSUserTrackingUsageDescription to Info.plist"
    echo -e "    4. Use app_tracking_transparency package if needed"
    echo ""
}

# Print medium priority tasks
print_medium() {
    echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}${BOLD}  📋 MEDIUM PRIORITY - Recommended Before Submission${NC}"
    echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo ""

    load_status

    echo -e "${BOLD}MED-01: Add Sign in with Apple${NC}"
    echo -e "  Status: $(get_status_emoji ${MED_01:-pending}) ${MED_01:-pending}"
    echo -e "  Guideline: 4.8 - Login services"
    echo -e "  Note: Not required since app uses own email/phone auth"
    echo -e "  Benefits: Better UX, increased trust, faster onboarding"
    echo -e "  Package: sign_in_with_apple"
    echo ""

    echo -e "${BOLD}MED-02: Add Biometric Authentication${NC}"
    echo -e "  Status: $(get_status_emoji ${MED_02:-pending}) ${MED_02:-pending}"
    echo -e "  Guideline: Recommended for financial apps"
    echo -e "  Files to modify:"
    echo -e "    - lib/screens/auth/login_screen.dart"
    echo -e "    - lib/services/auth_service.dart"
    echo -e "  Package: local_auth"
    echo -e "  Features: Face ID, Touch ID for login and transactions"
    echo ""

    echo -e "${BOLD}MED-03: Verify Apple Pay Button Styling${NC}"
    echo -e "  Status: $(get_status_emoji ${MED_03:-pending}) ${MED_03:-pending}"
    echo -e "  Guideline: 4.9 - Apple Pay branding"
    echo -e "  Tasks:"
    echo -e "    1. Verify Apple Pay button follows HIG"
    echo -e "    2. Check button styling on Payment Sheet"
    echo -e "    3. Test on physical device"
    echo ""

    echo -e "${BOLD}MED-04: Update App Store Screenshots${NC}"
    echo -e "  Status: $(get_status_emoji ${MED_04:-pending}) ${MED_04:-pending}"
    echo -e "  Guideline: 2.3 - Accurate metadata"
    echo -e "  Tasks:"
    echo -e "    1. Capture screenshots of all major features"
    echo -e "    2. Show actual app usage (not splash screens)"
    echo -e "    3. Include wallet, payments, investments, bills"
    echo -e "    4. Create for all required device sizes"
    echo ""

    echo -e "${BOLD}MED-05: Improve Error Messages${NC}"
    echo -e "  Status: $(get_status_emoji ${MED_05:-pending}) ${MED_05:-pending}"
    echo -e "  Guideline: UX best practices"
    echo -e "  Tasks:"
    echo -e "    1. Audit all error messages for clarity"
    echo -e "    2. Add user-friendly messages for network errors"
    echo -e "    3. Add recovery suggestions where possible"
    echo ""

    echo -e "${BOLD}MED-06: Add In-App FAQ/Help Section${NC}"
    echo -e "  Status: $(get_status_emoji ${MED_06:-pending}) ${MED_06:-pending}"
    echo -e "  Guideline: 1.5 - User support"
    echo -e "  Files to create:"
    echo -e "    - lib/screens/help/faq_screen.dart"
    echo -e "  Content:"
    echo -e "    - How to add money"
    echo -e "    - How to send/receive"
    echo -e "    - KYC verification process"
    echo -e "    - Investment information"
    echo -e "    - Contact support"
    echo ""

    echo -e "${BOLD}MED-07: Verify All Deep Links Work${NC}"
    echo -e "  Status: $(get_status_emoji ${MED_07:-pending}) ${MED_07:-pending}"
    echo -e "  Guideline: 2.1 - All URLs functional"
    echo -e "  Tasks:"
    echo -e "    1. Test tccapp:// URL scheme"
    echo -e "    2. Test Stripe redirect: tccapp://stripe-redirect"
    echo -e "    3. Test all external links"
    echo ""

    echo -e "${BOLD}MED-08: Add Transaction Receipt Improvements${NC}"
    echo -e "  Status: $(get_status_emoji ${MED_08:-pending}) ${MED_08:-pending}"
    echo -e "  Guideline: Financial transparency"
    echo -e "  Tasks:"
    echo -e "    1. Ensure all transactions have downloadable receipts"
    echo -e "    2. Include all fee breakdowns"
    echo -e "    3. Add share functionality"
    echo ""

    echo -e "${BOLD}MED-09: Verify iPad Compatibility${NC}"
    echo -e "  Status: $(get_status_emoji ${MED_09:-pending}) ${MED_09:-pending}"
    echo -e "  Guideline: 2.4.1 - iPhone apps should run on iPad"
    echo -e "  Tasks:"
    echo -e "    1. Test on iPad simulator"
    echo -e "    2. Check layout on larger screens"
    echo -e "    3. Verify all features work correctly"
    echo ""

    echo -e "${BOLD}MED-10: Add Network Connectivity Handling${NC}"
    echo -e "  Status: $(get_status_emoji ${MED_10:-pending}) ${MED_10:-pending}"
    echo -e "  Guideline: 2.1 - App completeness"
    echo -e "  Package: connectivity_plus"
    echo -e "  Tasks:"
    echo -e "    1. Add offline mode indicator"
    echo -e "    2. Queue failed requests for retry"
    echo -e "    3. Show appropriate offline messages"
    echo ""
}

# Print low priority tasks
print_low() {
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  💡 LOW PRIORITY - Nice to Have / Future Improvements${NC}"
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo ""

    load_status

    echo -e "${BOLD}LOW-01: Add Dark Mode Support${NC}"
    echo -e "  Status: $(get_status_emoji ${LOW_01:-pending}) ${LOW_01:-pending}"
    echo -e "  Note: ThemeToggle exists but may need polish"
    echo ""

    echo -e "${BOLD}LOW-02: Add Haptic Feedback${NC}"
    echo -e "  Status: $(get_status_emoji ${LOW_02:-pending}) ${LOW_02:-pending}"
    echo -e "  Package: haptic_feedback or vibration"
    echo -e "  Use cases: Button taps, successful transactions, errors"
    echo ""

    echo -e "${BOLD}LOW-03: Add Pull-to-Refresh on All Lists${NC}"
    echo -e "  Status: $(get_status_emoji ${LOW_03:-pending}) ${LOW_03:-pending}"
    echo -e "  Screens: Transaction history, portfolio, bill history"
    echo ""

    echo -e "${BOLD}LOW-04: Add Skeleton Loading States${NC}"
    echo -e "  Status: $(get_status_emoji ${LOW_04:-pending}) ${LOW_04:-pending}"
    echo -e "  Package: shimmer or skeletonizer"
    echo -e "  Better UX than plain loading spinners"
    echo ""

    echo -e "${BOLD}LOW-05: Add Transaction Search/Filter${NC}"
    echo -e "  Status: $(get_status_emoji ${LOW_05:-pending}) ${LOW_05:-pending}"
    echo -e "  Features: Date range, amount, type, status"
    echo ""

    echo -e "${BOLD}LOW-06: Add Widget for Home Screen${NC}"
    echo -e "  Status: $(get_status_emoji ${LOW_06:-pending}) ${LOW_06:-pending}"
    echo -e "  Package: home_widget"
    echo -e "  Features: Quick balance view, recent transactions"
    echo ""

    echo -e "${BOLD}LOW-07: Add Siri Shortcuts${NC}"
    echo -e "  Status: $(get_status_emoji ${LOW_07:-pending}) ${LOW_07:-pending}"
    echo -e "  Guideline: 2.5.1 - SiriKit integration"
    echo -e "  Features: 'Check my TCC balance', 'Send money to...' "
    echo ""

    echo -e "${BOLD}LOW-08: Localization (Multi-language)${NC}"
    echo -e "  Status: $(get_status_emoji ${LOW_08:-pending}) ${LOW_08:-pending}"
    echo -e "  Languages: English, Krio (Sierra Leone)"
    echo -e "  Package: flutter_localizations"
    echo ""
}

# Print status summary
print_status() {
    echo -e "${PURPLE}${BOLD}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}${BOLD}  📊 TASK STATUS SUMMARY${NC}"
    echo -e "${PURPLE}${BOLD}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo ""

    load_status

    local critical_done=0
    local critical_total=5
    local high_done=0
    local high_total=8
    local medium_done=0
    local medium_total=10
    local low_done=0
    local low_total=8

    # Count completed critical
    [[ "${CRIT_01}" == "completed" ]] && ((critical_done++))
    [[ "${CRIT_02}" == "completed" ]] && ((critical_done++))
    [[ "${CRIT_03}" == "completed" ]] && ((critical_done++))
    [[ "${CRIT_04}" == "completed" ]] && ((critical_done++))
    [[ "${CRIT_05}" == "completed" ]] && ((critical_done++))

    # Count completed high
    [[ "${HIGH_01}" == "completed" ]] && ((high_done++))
    [[ "${HIGH_02}" == "completed" ]] && ((high_done++))
    [[ "${HIGH_03}" == "completed" ]] && ((high_done++))
    [[ "${HIGH_04}" == "completed" ]] && ((high_done++))
    [[ "${HIGH_05}" == "completed" ]] && ((high_done++))
    [[ "${HIGH_06}" == "completed" ]] && ((high_done++))
    [[ "${HIGH_07}" == "completed" ]] && ((high_done++))
    [[ "${HIGH_08}" == "completed" ]] && ((high_done++))

    # Count completed medium
    for i in {01..10}; do
        var="MED_${i}"
        [[ "${!var}" == "completed" ]] && ((medium_done++))
    done

    # Count completed low
    for i in {01..08}; do
        var="LOW_${i}"
        [[ "${!var}" == "completed" ]] && ((low_done++))
    done

    local total_done=$((critical_done + high_done + medium_done + low_done))
    local total_tasks=$((critical_total + high_total + medium_total + low_total))

    echo -e "  ${RED}🚨 Critical:${NC}  $critical_done / $critical_total completed"
    echo -e "  ${YELLOW}⚠️  High:${NC}      $high_done / $high_total completed"
    echo -e "  ${BLUE}📋 Medium:${NC}    $medium_done / $medium_total completed"
    echo -e "  ${GREEN}💡 Low:${NC}       $low_done / $low_total completed"
    echo ""
    echo -e "  ${BOLD}Total Progress: $total_done / $total_tasks ($(( (total_done * 100) / total_tasks ))%)${NC}"
    echo ""

    if [ $critical_done -eq $critical_total ]; then
        echo -e "  ${GREEN}✅ All critical blockers resolved! Ready for submission review.${NC}"
    else
        echo -e "  ${RED}❌ $(($critical_total - $critical_done)) critical blockers remaining. NOT ready for submission.${NC}"
    fi
    echo ""

    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}  📅 UPCOMING DEADLINES${NC}"
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ⏰ April 28, 2026 - iOS 26 SDK required (Xcode 26)"
    echo -e "  ⏰ Ongoing - Age rating questionnaire updates"
    echo ""
}

# Print usage
print_usage() {
    echo ""
    echo -e "${BOLD}Usage:${NC} $0 [command]"
    echo ""
    echo -e "${BOLD}Commands:${NC}"
    echo "  all       - Show all tasks (default)"
    echo "  critical  - Show critical blockers only"
    echo "  high      - Show high priority tasks only"
    echo "  medium    - Show medium priority tasks only"
    echo "  low       - Show low priority tasks only"
    echo "  status    - Show progress summary"
    echo "  update    - Update task status (interactive)"
    echo "  help      - Show this help message"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  $0 critical         # Show critical blockers"
    echo "  $0 status           # Show progress summary"
    echo "  $0 update CRIT_01 completed  # Mark task as done"
    echo ""
}

# Main
init_status_file

case "${1:-all}" in
    all)
        print_header
        print_critical
        print_high
        print_medium
        print_low
        print_status
        ;;
    critical)
        print_header
        print_critical
        ;;
    high)
        print_header
        print_high
        ;;
    medium)
        print_header
        print_medium
        ;;
    low)
        print_header
        print_low
        ;;
    status)
        print_header
        print_status
        ;;
    update)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: $0 update TASK_ID STATUS"
            echo "Example: $0 update CRIT_01 completed"
            echo "Status options: pending, in_progress, completed, blocked"
            exit 1
        fi
        update_status "$2" "$3"
        ;;
    help|--help|-h)
        print_usage
        ;;
    *)
        echo "Unknown command: $1"
        print_usage
        exit 1
        ;;
esac

echo ""
