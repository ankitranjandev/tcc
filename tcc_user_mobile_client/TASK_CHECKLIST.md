# TCC App Store Submission - Task Checklist
**Generated:** February 6, 2026
**Target:** Apple App Store Submission

---

## 🚨 CRITICAL BLOCKERS (Must Complete)

> These items will cause immediate rejection if not addressed

- [ ] **CRIT-01: Implement Account Deletion Feature**
  - Guideline: 5.1.1(v)
  - Files: `lib/screens/profile/account_screen.dart`, `lib/services/auth_service.dart`
  - Tasks:
    - [ ] Add "Delete Account" button in AccountScreen
    - [ ] Create confirmation dialog with data deletion warning
    - [ ] Implement `DELETE /users/delete-account` API call
    - [ ] Clear all local data (SharedPreferences, tokens)
    - [ ] Navigate to login screen after deletion
    - [ ] Test deletion flow end-to-end

- [ ] **CRIT-02: Create and Host Privacy Policy**
  - Guideline: 5.1.1(i), 2.3
  - Tasks:
    - [ ] Draft privacy policy covering:
      - [ ] Personal data collected (name, email, phone, KYC docs)
      - [ ] Financial data (transactions, balance, investments)
      - [ ] Third-party sharing (Stripe, Firebase, CurrencyBeacon)
      - [ ] Data retention periods
      - [ ] User rights (access, deletion, portability)
      - [ ] Contact information
    - [ ] Host at public URL (e.g., `https://tcc.com/privacy`)
    - [ ] Add URL to App Store Connect
    - [ ] Add link in app's AccountScreen

- [ ] **CRIT-03: Create Demo Account for Apple Reviewers**
  - Guideline: 2.1
  - Tasks:
    - [ ] Create test account on production backend
    - [ ] Pre-approve KYC verification
    - [ ] Pre-load wallet with test funds (~$100 TCC)
    - [ ] Ensure access to all features (investments, transfers, bills)
    - [ ] Document credentials for App Store Connect
    - [ ] Test login flow works correctly
  - Credentials to provide:
    ```
    Email: apple-review@tcc.com
    Password: [secure password]
    OTP Instructions: [static code or bypass method]
    ```

- [ ] **CRIT-04: Verify Licensed Entity Submission**
  - Guideline: 3.2.1(viii)
  - Tasks:
    - [ ] Verify Apple Developer account is under TCC's legal entity
    - [ ] Confirm entity has Sierra Leone financial services license
    - [ ] Update App Store Connect organization info if needed
    - [ ] Prepare license documentation for Apple if requested
  - ⚠️ **Individual developer accounts CANNOT submit financial apps**

- [ ] **CRIT-05: Update Age Rating in App Store Connect**
  - Guideline: 2.3
  - Deadline: January 31, 2026 (respond to questionnaire)
  - Tasks:
    - [ ] Log into App Store Connect
    - [ ] Go to App Information → Age Rating
    - [ ] Answer updated questionnaire
    - [ ] Set rating to 17+ (financial services, real money)
    - [ ] Submit rating update

---

## ⚠️ HIGH PRIORITY (Should Complete Before Submission)

- [ ] **HIGH-01: Add Investment Risk Disclaimers**
  - Files: Investment screens
  - Add: *"Investments carry risk. Past performance does not guarantee future results."*

- [ ] **HIGH-02: Add Third-Party Data Sharing Disclosure**
  - Disclose: Stripe, Firebase, CurrencyBeacon, CloudFront
  - Add disclosure in privacy policy and app settings

- [ ] **HIGH-03: Clarify Non-Cryptocurrency Status**
  - Update App Store description:
    > "TCC (The Community Coin) is a regulated digital wallet backed by real currency (USD), not a cryptocurrency."
  - Add clarification in review notes for Apple

- [ ] **HIGH-04: Add Terms of Service**
  - [ ] Create ToS document
  - [ ] Host at public URL
  - [ ] Add link in AccountScreen
  - [ ] Add acceptance checkbox during registration

- [ ] **HIGH-05: Implement Privacy Manifest**
  - File: `ios/Runner/PrivacyInfo.xcprivacy`
  - Required for NSUserDefaults and other listed APIs
  - Reference: [Apple Privacy Manifest Docs](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)

- [ ] **HIGH-06: Add Support Contact Information**
  - Add support email in AccountScreen
  - Add FAQ/Help section link
  - Verify support URL in App Store Connect

- [ ] **HIGH-07: Add Consent Dialogs**
  - [ ] Privacy Policy checkbox on registration
  - [ ] Terms of Service checkbox on registration
  - [ ] KYC data collection consent
  - [ ] Store consent timestamps

- [ ] **HIGH-08: Check App Tracking Transparency**
  - Audit if IDFA is collected
  - If yes, implement ATT prompt
  - Add `NSUserTrackingUsageDescription` to Info.plist

---

## 📋 MEDIUM PRIORITY (Recommended)

- [ ] **MED-01:** Add Sign in with Apple
- [ ] **MED-02:** Add Biometric Authentication (Face ID/Touch ID)
- [ ] **MED-03:** Verify Apple Pay button styling follows HIG
- [ ] **MED-04:** Create App Store screenshots (all device sizes)
- [ ] **MED-05:** Improve error messages for clarity
- [ ] **MED-06:** Add in-app FAQ/Help section
- [ ] **MED-07:** Verify all deep links work (tccapp://)
- [ ] **MED-08:** Add transaction receipt improvements
- [ ] **MED-09:** Test iPad compatibility
- [ ] **MED-10:** Add network connectivity handling

---

## 💡 LOW PRIORITY (Future Improvements)

- [ ] **LOW-01:** Polish dark mode support
- [ ] **LOW-02:** Add haptic feedback
- [ ] **LOW-03:** Add pull-to-refresh on all lists
- [ ] **LOW-04:** Add skeleton loading states
- [ ] **LOW-05:** Add transaction search/filter
- [ ] **LOW-06:** Add iOS home screen widget
- [ ] **LOW-07:** Add Siri Shortcuts
- [ ] **LOW-08:** Add multi-language support (Krio)

---

## 📅 Upcoming Deadlines

| Date | Requirement |
|------|-------------|
| ~~Jan 31, 2026~~ | Age rating questionnaire (PAST DUE) |
| **Apr 28, 2026** | iOS 26 SDK / Xcode 26 required |

---

## 🔧 Backend Tasks (Separate Team)

- [ ] **BE-01:** Implement `DELETE /users/delete-account` endpoint
- [ ] **BE-02:** Set up Apple Pay in Stripe Dashboard
- [ ] **BE-03:** Configure Apple Developer Portal (Merchant ID, certificates)
- [ ] **BE-04:** Create static OTP bypass for Apple reviewer account
- [ ] **BE-05:** Ensure production API is stable and monitored

---

## 📱 App Store Connect Checklist

- [ ] Privacy Policy URL added
- [ ] Support URL added
- [ ] Marketing URL added (optional)
- [ ] Age Rating set to 17+
- [ ] App Review notes with demo credentials
- [ ] All screenshots uploaded (6.5", 5.5" iPhone, iPad)
- [ ] App description clarifies non-crypto nature
- [ ] Keywords optimized
- [ ] What's New text prepared
- [ ] Build uploaded and processed
- [ ] Export compliance answered

---

## 📊 Progress Tracking

```
Critical:  [ ] [ ] [ ] [ ] [ ]  (0/5)
High:      [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ]  (0/8)
Medium:    [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ]  (0/10)
Low:       [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ]  (0/8)

Overall: 0/31 tasks completed (0%)
```

**Submission Ready:** ❌ NO (Critical blockers remaining)

---

## Quick Commands

```bash
# Run the interactive task tracker
./scripts/compliance_tasks.sh

# Show only critical blockers
./scripts/compliance_tasks.sh critical

# Show progress summary
./scripts/compliance_tasks.sh status

# Mark a task as completed
./scripts/compliance_tasks.sh update CRIT_01 completed
```

---

*Last updated: February 6, 2026*
