# TCC User Mobile Client - Apple App Store Compliance Report

**Report Date:** February 6, 2026
**App Name:** TCC - The Community Coin
**Bundle ID:** com.tcc.app
**Version:** 1.0.0 (Build 3)
**Platform:** iOS 13.0+

---

## Executive Summary

This report analyzes the TCC User Mobile Client against the latest Apple App Store Review Guidelines (updated November 2025) and upcoming requirements for 2026. The application is a financial services platform offering wallet management, investments, bill payments, and money transfers targeting Sierra Leone and West Africa.

### Overall Status: ⚠️ NOT READY FOR SUBMISSION

| Category | Status |
|----------|--------|
| **Critical Blockers** | 4 issues |
| **High Priority Issues** | 3 issues |
| **Medium Priority Issues** | 5 issues |
| **Low Priority/Compliant** | 12 items |

---

## Part 1: Critical Blockers (Must Fix Before Submission)

### 1.1 Missing Account Deletion Feature ❌

**Guideline Reference:** 5.1.1(v)

> "If your app supports account creation, you must also offer account deletion within the app."

**Current Status:** NOT IMPLEMENTED

**Evidence:**
- No `/user/delete-account` endpoint found in `api_service.dart`
- No account deletion UI in settings or profile screens
- User can only "log out" but cannot delete their account

**Impact:** WILL CAUSE IMMEDIATE REJECTION

**Required Actions:**
1. Implement backend endpoint `/user/delete-account`
2. Add "Delete Account" option in Settings/Profile screen
3. Include confirmation dialog explaining data deletion
4. Handle cascading deletion (wallet balance, KYC documents, transaction history)
5. Provide 30-day grace period for account recovery (recommended)

---

### 1.2 Missing External Privacy Policy URL ❌

**Guideline Reference:** 5.1.1(i)

> "Apps must include a link to your privacy policy in the App Store Connect metadata field and within the app."

**Current Status:** INCOMPLETE

**Evidence:**
- `APP_STORE_SUBMISSION.md` contains placeholder URLs:
  ```
  Privacy Policy URL: https://tcc-app-ebb14.web.app/privacy-policy
  Terms of Service URL: https://tcc-app-ebb14.web.app/terms
  Support URL: https://tcc-app-ebb14.web.app/support
  ```
- Firebase Hosting configured but pages not deployed
- In-app privacy policy link points to non-existent URL

**Impact:** WILL CAUSE REJECTION

**Required Actions:**
1. Create privacy policy page covering:
   - Data collected (name, email, phone, government ID, financial info)
   - Firebase Analytics data collection
   - Stripe payment data handling
   - Third-party data sharing
   - Data retention periods
   - User rights (access, deletion, portability)
2. Create terms of service page
3. Create support/contact page
4. Deploy to `https://tcc-app-ebb14.web.app/`
5. Verify all links work before submission

---

### 1.3 Financial Services Entity Requirement ❌

**Guideline Reference:** 5.1.1(ix)

> "Apps facilitating financial services must be submitted by the legal entity providing the services, not by individual developers."

**Current Status:** UNCLEAR

**Evidence:**
- App handles real money (wallet deposits, withdrawals, transfers)
- Requires banking/financial licensing in Sierra Leone
- Apple Developer account type not verified

**Impact:** HIGH RISK OF REJECTION

**Required Actions:**
1. Verify Apple Developer account is **Organization** type (not Individual)
2. Ensure organization name matches licensed financial entity
3. Prepare documentation of financial licenses for Sierra Leone
4. Be ready to provide regulatory compliance documents if requested

---

### 1.4 Missing Demo Account for Review ❌

**Guideline Reference:** App Review Process

> "If your app requires sign-in, provide valid demo account credentials in App Store Connect."

**Current Status:** NOT PROVIDED

**Evidence:**
- `APP_STORE_SUBMISSION.md` shows:
  ```
  Demo Account Email: [Needs to be created]
  Demo Account Password: [Needs to be created]
  ```
- KYC verification required to access full functionality
- Reviewers cannot test without pre-verified account

**Impact:** WILL CAUSE REJECTION

**Required Actions:**
1. Create test account with email like `appreview@tcc.com`
2. Complete KYC verification for this account
3. Pre-fund wallet with test balance
4. Document in "Notes for Review":
   - Login credentials
   - Test card: `4242 4242 4242 4242` (Stripe test mode)
   - Available features to test

---

## Part 2: High Priority Issues

### 2.1 Cryptocurrency/Token Branding Concerns ⚠️

**Guideline Reference:** 3.1.5(ii), 3.1.5(ii)(a-d)

**Risk:** The name "The Community **Coin**" and "TCC" may trigger cryptocurrency review questions.

**Current Status:** AT RISK

**Evidence:**
- App name contains "Coin"
- Currency referred to as "TCC" throughout
- Could be misunderstood as cryptocurrency/blockchain token

**Mitigation Actions:**
1. In "Notes for Review," explicitly clarify:
   - TCC is fiat-backed (Sierra Leone Leone equivalent)
   - NOT a cryptocurrency or blockchain token
   - Wallet balance represents real currency held in custodial account
   - Regulated by Sierra Leone financial authorities
2. Consider terminology changes:
   - "TCC Balance" → "Wallet Balance"
   - "TCC Coin" → "TCC Funds" or "TCC Credits"

---

### 2.2 Stripe vs. In-App Purchase Justification ⚠️

**Guideline Reference:** 3.1.1, 3.1.3(d), 3.1.3(e)

**Current Status:** ACCEPTABLE (with documentation)

**Evidence:**
- App uses Stripe for wallet top-ups (not Apple IAP)
- Funds used for:
  - Bill payments (real-world services)
  - Person-to-person transfers
  - Investment purchases
  - Currency trading

**Justification per Guidelines:**
- **3.1.3(d):** Person-to-person money transfers are exempt from IAP
- **3.1.3(e):** Goods/services consumed outside the app are exempt

**Required Documentation:**
Include in "Notes for Review":
```
This app uses Stripe for wallet funding because:
1. Funds are used for real-world bill payments (electricity, water, internet)
2. Person-to-person money transfers (exempt per 3.1.3(d))
3. Physical goods/services consumed outside the app (3.1.3(e))
4. The wallet balance represents fiat currency, not digital goods
```

---

### 2.3 Support Contact Information ⚠️

**Guideline Reference:** 5.1.1(v), App Store Connect Requirements

**Current Status:** PLACEHOLDER VALUES

**Evidence:**
- `APP_STORE_SUBMISSION.md`:
  ```
  Support Email: support@tcc.com (placeholder)
  Support Phone: +232 123 456 789 (placeholder)
  ```

**Required Actions:**
1. Set up working support email address
2. Set up support phone number
3. Ensure support channels are staffed
4. Add in-app support/contact feature

---

## Part 3: Medium Priority Issues

### 3.1 Firebase Analytics Data Disclosure ⚠️

**Guideline Reference:** 5.1.2(i)

> "Apps that collect user data must disclose what data is collected and how it's used."

**Current Status:** INCOMPLETE

**Evidence:**
- `firebase_analytics` SDK included
- Analytics data collection not disclosed in privacy policy
- App Store Privacy Nutrition Labels may be incomplete

**Required Actions:**
1. Update privacy policy to include:
   - Firebase Analytics usage
   - Types of analytics data collected
   - Purpose of collection
2. Complete App Store Connect Privacy Nutrition Labels:
   - Usage Data: Analytics (linked to user)
   - Device ID (if collected)

---

### 3.2 Push Notification Consent Flow ⚠️

**Guideline Reference:** 4.5.4

> "Push Notifications should not be required for the app to function, and should not be used for advertising, promotions, or direct marketing purposes."

**Current Status:** NEEDS VERIFICATION

**Evidence:**
- FCM configured with multiple channels including `tcc_user_promotions`
- Notification permission requested at app startup

**Required Actions:**
1. Ensure push permission is **not required** for core functionality
2. Provide opt-out for promotional notifications
3. Verify promotional channel has separate consent

---

### 3.3 Sensitive Data in Logs ⚠️

**Guideline Reference:** 5.1 (Security Best Practices)

**Current Status:** DEVELOPMENT LOGGING ENABLED

**Evidence:**
- `api_service.dart` logs token previews:
  ```dart
  developer.log('Token preview: ${token.substring(0, 20)}...');
  ```
- Request/response bodies logged

**Required Actions:**
1. Disable verbose logging in production builds
2. Use `kReleaseMode` to conditionally disable:
   ```dart
   if (!kReleaseMode) {
     developer.log('Debug info...');
   }
   ```
3. Never log tokens, even partially

---

### 3.4 API Key Exposure ⚠️

**Current Status:** KEYS IN SOURCE CODE

**Evidence:**
- `app_constants.dart`:
  ```dart
  static const currencyBeaconApiKey = '9Snsrfa8QPSNMuq7GY5xtLDWmvs0cxXt';
  ```
- Stripe publishable key is public (acceptable)

**Required Actions:**
1. Move sensitive API keys to environment variables
2. Use `--dart-define` for build-time injection
3. Consider backend proxy for currency API calls

---

### 3.5 APK File in Repository ⚠️

**Current Status:** BINARY IN SOURCE CONTROL

**Evidence:**
- Large APK file found in repository (57MB)

**Required Actions:**
1. Remove APK from git repository
2. Add to `.gitignore`:
   ```
   *.apk
   *.ipa
   build/
   ```

---

## Part 4: Compliance Status by Guideline Section

### Section 1: Safety

| Requirement | Status | Notes |
|-------------|--------|-------|
| 1.1 Objectionable Content | ✅ Compliant | Financial app, no user-generated content |
| 1.2 User Generated Content | N/A | Not applicable |
| 1.3 Kids Category | N/A | Not targeting children |
| 1.4 Physical Harm | ✅ Compliant | No medical claims |
| 1.5 Developer Information | ⚠️ Verify | Must be legal entity |

### Section 2: Performance

| Requirement | Status | Notes |
|-------------|--------|-------|
| 2.1 App Completeness | ⚠️ Pending | Demo account needed |
| 2.2 Beta Testing | ✅ Compliant | Not beta |
| 2.3 Accurate Metadata | ✅ Compliant | Descriptions accurate |
| 2.4 Hardware Compatibility | ✅ Compliant | Standard iOS features |
| 2.5 Software Requirements | ✅ Compliant | iOS 13+ |

### Section 3: Business

| Requirement | Status | Notes |
|-------------|--------|-------|
| 3.1.1 In-App Purchase | ⚠️ Justify | Document Stripe usage |
| 3.1.3 Reader Apps | N/A | Not applicable |
| 3.2 Other Business Issues | ✅ Compliant | No prohibited practices |
| 3.2.2 Loan Apps | ✅ Compliant | Not a loan app |

### Section 4: Design

| Requirement | Status | Notes |
|-------------|--------|-------|
| 4.1 Copycats | ✅ Compliant | Original design |
| 4.2 Minimum Functionality | ✅ Compliant | Full-featured app |
| 4.3 Spam | ✅ Compliant | Single purpose app |
| 4.5.4 Push Notifications | ⚠️ Review | Verify promotional opt-in |
| 4.8 Sign in with Apple | ✅ Compliant | Not using third-party social login |

### Section 5: Legal

| Requirement | Status | Notes |
|-------------|--------|-------|
| 5.1.1(i) Privacy Policy | ❌ Missing | Need external URL |
| 5.1.1(v) Account Deletion | ❌ Missing | Must implement |
| 5.1.1(ix) Financial Entity | ⚠️ Verify | Must be org account |
| 5.1.2 Data Use | ⚠️ Incomplete | Analytics disclosure needed |
| 5.2 Intellectual Property | ✅ Compliant | Original content |
| 5.3 Gaming/Gambling | N/A | Not applicable |

---

## Part 5: iOS Configuration Review

### 5.1 Info.plist Analysis

| Key | Value | Status |
|-----|-------|--------|
| NSCameraUsageDescription | KYC verification, profile pictures | ✅ Appropriate |
| NSContactsUsageDescription | Gift transfers, recipient selection | ✅ Appropriate |
| NSPhotoLibraryUsageDescription | Save payment receipts | ✅ Appropriate |
| NSPhotoLibraryAddUsageDescription | Save payment receipts | ✅ Appropriate |
| UIBackgroundModes | fetch, remote-notification | ✅ Justified |
| LSApplicationQueriesSchemes | mailto, tel, https, whatsapp | ✅ Appropriate |

### 5.2 Entitlements Review

| Entitlement | Purpose | Status |
|-------------|---------|--------|
| Apple Pay | `merchant.com.tcc.app` | ✅ Configured |
| Push Notifications | FCM delivery | ✅ Configured |

### 5.3 SDK Versions

| SDK | Version | Latest | Status |
|-----|---------|--------|--------|
| Firebase Core | 3.8.1 | Current | ✅ |
| Firebase Messaging | 15.1.3 | Current | ✅ |
| Firebase Analytics | 11.3.8 | Current | ✅ |
| Flutter Stripe | 11.2.0 | Current | ✅ |
| permission_handler | 11.3.1 | Current | ✅ |

---

## Part 6: Upcoming Requirements (2026)

### 6.1 SDK Requirements (Effective April 28, 2026)

> Apps must be built with iOS 26 SDK or later.

**Current Status:** Using iOS 13.0 minimum deployment target

**Action Required:**
- Update to Xcode with iOS 26 SDK before April 28, 2026
- Test app compatibility with iOS 26

### 6.2 Age Rating Questionnaire (Deadline January 31, 2026)

> Developers must complete the updated age rating questionnaire.

**Current Status:** ⚠️ Verify completion

**Action Required:**
- Complete updated age rating questionnaire in App Store Connect
- Recommended rating: **4+** (financial services, no objectionable content)

### 6.3 AI Transparency (Effective November 2025)

> Apps must clearly inform users if personal data is shared with third-party AI services.

**Current Status:** ✅ Not applicable (no AI features detected)

---

## Part 7: App Store Privacy Nutrition Labels

Based on code analysis, the following data disclosure is required:

### Data Linked to User Identity

| Data Type | Collected | Purpose |
|-----------|-----------|---------|
| Name | ✅ Yes | Account registration, KYC |
| Email | ✅ Yes | Login, notifications |
| Phone Number | ✅ Yes | Registration, transfers, OTP |
| Government ID | ✅ Yes | KYC verification |
| Financial Info | ✅ Yes | Payments, wallet |
| Photos | ✅ Yes | KYC selfie, profile |
| Contacts | ✅ Yes | Gift transfers |
| User ID | ✅ Yes | Account identification |
| Usage Data | ✅ Yes | Firebase Analytics |

### Data NOT Collected

| Data Type | Status |
|-----------|--------|
| Location | ❌ Not collected |
| Browsing History | ❌ Not collected |
| Search History | ❌ Not collected |
| Health Data | ❌ Not collected |
| Advertising Data | ❌ Not collected |

### Third-Party SDKs Data Collection

| SDK | Data Collected |
|-----|----------------|
| Firebase Analytics | Usage data, device info, crash logs |
| Stripe | Payment card info (PCI compliant) |

---

## Part 8: Recommended Submission Timeline

### Week 1: Critical Fixes
- [ ] Implement account deletion feature
- [ ] Create and deploy privacy policy
- [ ] Verify Apple Developer Organization account

### Week 2: High Priority Items
- [ ] Create demo account with verified KYC
- [ ] Set up working support channels
- [ ] Prepare "Notes for Review" documentation

### Week 3: Code Quality
- [ ] Disable production logging
- [ ] Remove sensitive data from repository
- [ ] Complete code security audit

### Week 4: Submission Preparation
- [ ] Complete App Store Privacy Nutrition Labels
- [ ] Finalize app screenshots and metadata
- [ ] Submit for review

---

## Part 9: Notes for Apple Review (Template)

```
NOTES FOR APPLE REVIEW
======================

Demo Account Credentials:
- Email: appreview@tcc.com
- Password: [secure password]
- This account has completed KYC verification

Testing Payments:
- Use Stripe test card: 4242 4242 4242 4242
- Any future expiry date and CVC

About TCC:
TCC (The Community Coin) is a regulated financial services app
operating in Sierra Leone. The "TCC" balance represents fiat
currency (Sierra Leone Leone) held in a custodial account, NOT
cryptocurrency or blockchain tokens.

Payment Method Justification:
We use Stripe (not Apple IAP) because:
1. Funds are used for real-world bill payments (exempt per 3.1.3(e))
2. Person-to-person transfers (exempt per 3.1.3(d))
3. The wallet represents fiat currency, not digital goods

Regulatory Information:
- Licensed by: [Bank of Sierra Leone / relevant authority]
- Organization: [Legal entity name]
- Contact: [support email]
```

---

## Appendix A: Files Requiring Changes

| File | Change Required |
|------|-----------------|
| `lib/screens/settings/settings_screen.dart` | Add account deletion UI |
| `lib/services/api_service.dart` | Add delete account endpoint |
| `lib/services/api_service.dart` | Disable production logging |
| `lib/config/app_constants.dart` | Move API keys to env vars |
| `ios/Runner/Info.plist` | Verify all descriptions |
| `firebase.json` | Deploy privacy policy |
| `.gitignore` | Add APK/IPA exclusions |

---

## Appendix B: Compliance Checklist

### Before Submission
- [ ] Account deletion implemented and tested
- [ ] Privacy policy live at external URL
- [ ] Terms of service live at external URL
- [ ] Support page live at external URL
- [ ] Demo account created and verified
- [ ] App Store Privacy Labels completed
- [ ] Age rating questionnaire completed
- [ ] Screenshots prepared (all required sizes)
- [ ] App description finalized
- [ ] Keywords optimized
- [ ] Notes for Review prepared

### Code Quality
- [ ] Production logging disabled
- [ ] API keys secured
- [ ] APK removed from repository
- [ ] No placeholder/test data in production

### Legal/Business
- [ ] Organization account verified
- [ ] Financial licenses documented
- [ ] Support channels operational

---

## Sources

- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple Developer News - Updated Guidelines (November 2025)](https://developer.apple.com/news/?id=9txfddzf)
- [Upcoming Requirements - Apple Developer](https://developer.apple.com/news/upcoming-requirements/)
- [App Store Review Guidelines 2026 Best Practices](https://crustlab.com/blog/ios-app-store-review-guidelines/)
- [App Store Review Checklist 2025](https://appinstitute.com/app-store-review-checklist/)

---

*Report generated: February 6, 2026*
*Next review recommended: Before each submission*
