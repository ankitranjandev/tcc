# App Store Review Guidelines - Compliance Report

**App:** TCC (The Community Coin)
**Version:** 1.0.0 (Build 3)
**Platform:** iOS 13.0+
**Date:** February 5, 2026
**Project:** `/Volumes/Extreme SSD/projects/tcc/tcc_user_mobile_client`

---

## Executive Summary

| Category | Status | Blockers |
|----------|--------|----------|
| 1. Safety | PASS | None |
| 2. Performance | REVIEW NEEDED | Demo account / metadata completeness |
| 3. Business | FAIL | Stripe for digital wallet (IAP question), financial licensing |
| 4. Design | PASS | None |
| 5. Legal / Privacy | FAIL | No account deletion, no external privacy policy URL |

**Critical Blockers (will cause rejection):**
1. No account deletion feature (Guideline 5.1.1(v))
2. No external privacy policy URL (Guideline 5.1.1(i))
3. Stripe used for digital wallet top-up — may require In-App Purchase (Guideline 3.1.1)
4. Financial services app — must be submitted by licensed entity (Guideline 3.2.1(viii))

---

## 1. SAFETY

### 1.1 Objectionable Content — PASS
No objectionable content found. App is a financial services platform.

### 1.2 User-Generated Content — PASS (with caveat)
- **Voting/Elections feature** (`elections_screen.dart`, `election_details_screen.dart`) exists but does not appear to allow free-form user-generated content.
- No chat, comments, or public posting features found.
- If elections allow user-submitted candidates or descriptions, a content moderation mechanism would be needed.

### 1.3 Kids Category — N/A
App is not targeted at children. Financial services require age verification (KYC).

### 1.4 Physical Harm — PASS
No health, drug, or physical harm content.

### 1.5 Developer Information — REVIEW NEEDED
- Support contact found in-app:
  - Email: `support@tcc.com` (`account_screen.dart:651`)
  - Phone: `+232 123 456 789` (`account_screen.dart:687`)
  - WhatsApp: `+232 123 456 789` (`account_screen.dart:721`)
- **Issue:** These appear to be placeholder values. Must be real, reachable contact information.
- **Issue:** Support URL must be provided in App Store Connect metadata.

### 1.6 Data Security — PASS
- All API calls use HTTPS (`https://dppyssab6rrh5.cloudfront.net/v1`)
- Stripe 3DS authentication enforced
- Token-based authentication with refresh tokens

---

## 2. PERFORMANCE

### 2.1 App Completeness — REVIEW NEEDED

| Requirement | Status | Notes |
|-------------|--------|-------|
| Final version, no placeholders | REVIEW | Support contact appears placeholder |
| All URLs functional | REVIEW | Privacy policy / ToS are in-app only, no URLs |
| Demo account or built-in demo | NEEDED | Must provide reviewer credentials or demo mode |
| Tested on-device | NEEDED | Must test full payment flow on physical device |

**Action:** Provide App Review team with a demo account and instructions in "Notes for Review" in App Store Connect.

### 2.3 Accurate Metadata — REVIEW NEEDED
- **2.3.3** Screenshots must show app in use (not just splash/login).
- **2.3.6** Age rating: Must accurately answer questionnaire. App contains:
  - Financial transactions (real money)
  - No gambling, but has **investments** and **currency trading** — may trigger questions
- **2.3.7** App name "TCC" is 3 characters — acceptable (max 30).

### 2.4 Hardware Compatibility — PASS
- Universal iOS app (iPhone/iPad via Flutter)
- No excessive battery usage
- No cryptocurrency mining

### 2.5 Software Requirements — PASS
- Uses public APIs only
- Self-contained Flutter bundle
- IPv6 compatible (Flutter default networking)
- iOS deployment target: 13.0 (`Podfile:2`)

---

## 3. BUSINESS — CRITICAL ISSUES

### 3.1 Payments

#### 3.1.1 In-App Purchase — FAIL (HIGH RISK)

**Current implementation:** Stripe processes wallet deposits (digital currency "TCC Coin").

**The core question:** Is the TCC wallet a **digital good/service consumed within the app**?

| If wallet is... | Required payment method | Current status |
|-----------------|----------------------|----------------|
| Digital currency/token used in-app | Apple In-App Purchase REQUIRED | FAIL — uses Stripe |
| Funding for real-world services (bill payments, transfers) | External payment OK | Partial pass |
| Person-to-person money transfer | External payment OK (3.1.3(d)) | PASS |

**Analysis of app features:**
- Wallet top-up → used for bill payments (electricity, water, internet) — **real-world services consumed outside app** → Stripe OK per 3.1.3(e)
- Wallet top-up → used for person-to-person transfers — **Stripe OK** per 3.1.3(d)
- Wallet top-up → used for **investments/currency trading** — this is a **financial service**, Stripe OK per 3.1.3(e) and 3.2.1(viii)

**Verdict:** Stripe is likely acceptable because TCC is a **financial services app** where funds are used for real-world transactions, not in-app digital content. However, the "TCC Coin" branding may confuse Apple reviewers into thinking it's a virtual currency.

**Recommendations:**
1. Avoid calling it "coin" or "token" in App Store metadata — use "wallet balance" or "funds"
2. In "Notes for Review," explicitly explain that funds are used for real-world bill payments and transfers
3. Reference Guideline 3.1.3(e) — goods/services consumed outside the app

#### 3.1.5 Cryptocurrencies — REVIEW NEEDED

**Risk:** The app brand is "The Community Coin" and uses "TCC" as currency code (`app_constants.dart:167-168`). If Apple perceives this as cryptocurrency:
- Guideline 3.1.5(i): Wallets allowed only from **organization-enrolled** developers
- Guideline 3.1.5(iii): Exchanges require proper licensing
- Guideline 3.1.5(iv): Securities/investments require established financial institutions

**Recommendation:** Clarify in app metadata and "Notes for Review" that TCC is a fiat-backed digital wallet, not a cryptocurrency.

### 3.2 Other Business Model Issues

#### 3.2.1(viii) Financial Apps — CRITICAL

> "Apps that facilitate trading in securities must be submitted by the financial institution performing such services."

**App features requiring licensing:**
- Wallet/money transfers
- Investment products (fixed returns, variable returns)
- Currency trading (`currency_investment_screen.dart`, `currency_purchase_screen.dart`)
- Bill payments

**Requirements:**
- Must be submitted by a **licensed financial entity**, not an individual developer
- Must have **necessary regulatory licenses** for Sierra Leone / target markets
- Apple account must be enrolled as an **organization**, not individual

#### 3.2.2(viii) Trading Restrictions

> "Apps that facilitate binary options trading are not permitted. Apps that facilitate trading in contracts for difference or forex must be properly licensed."

- Currency trading feature must comply — needs forex/trading license documentation.

---

## 4. DESIGN

### 4.1 Copycats — PASS
App appears original.

### 4.2 Minimum Functionality — PASS
Rich feature set: wallet, transfers, investments, bill payments, KYC, voting. Not a repackaged website.

### 4.3 Spam — PASS
Single app, not duplicated.

### 4.7 Mini Apps — N/A
No mini-apps, games, or chatbots.

### 4.8 Login Services — PASS
App uses its own authentication system (email + phone + password). No third-party social login. Apple Sign-In is **not required** because the app uses an exclusive first-party account system.

### 4.9 Apple Pay — N/A
No Apple Pay integration.

---

## 5. LEGAL / PRIVACY — CRITICAL ISSUES

### 5.1.1 Privacy

#### (i) Privacy Policy — FAIL

| Requirement | Status | Details |
|-------------|--------|---------|
| Link in App Store Connect | MISSING | No external URL found anywhere in codebase |
| Accessible within app | PARTIAL | In-app text only (`account_screen.dart:900-1001`) |
| Identifies all data collected | PARTIAL | Mentions general categories but missing specifics |
| Identifies collection methods | MISSING | Not detailed |
| Identifies all uses of data | PARTIAL | General statements |
| Third-party SDK disclosure | MISSING | Firebase Analytics not mentioned in privacy text |
| Data retention/deletion policy | MISSING | No retention timeline stated |

**Actions required:**
1. Host privacy policy at a public URL (e.g., `https://your-domain.com/privacy`)
2. Add URL to App Store Connect metadata
3. Update policy to explicitly disclose:
   - Firebase Analytics data collection
   - Stripe payment data handling
   - FCM token collection for push notifications
   - KYC document storage and processing

#### (ii) Permission Purpose Strings — PASS

All permission strings found in `Info.plist`:

| Permission | Description | Adequate? |
|------------|-------------|-----------|
| NSCameraUsageDescription | "capture photos for KYC verification and profile pictures" | YES |
| NSContactsUsageDescription | "select a recipient for gift transfers" | YES |
| NSPhotoLibraryUsageDescription | "save payment receipts" | YES |
| NSPhotoLibraryAddUsageDescription | "save payment receipts to your photo library" | YES |

#### (v) Account Sign-In & Deletion — FAIL

> "If your app supports account creation, you must also offer account deletion within the app."

| Requirement | Status |
|-------------|--------|
| Account creation | YES — registration flow exists |
| Account deletion within app | **NO — NOT FOUND** |
| Data deletion request | **NO — NOT FOUND** |

**This is a hard rejection reason.** Apple has enforced this strictly since June 2022.

**Actions required:**
1. Add "Delete Account" option in account/profile settings
2. Implement backend `DELETE /users/account` or `POST /users/delete-account` endpoint
3. Must actually delete/anonymize user data (not just deactivate)
4. Must handle: wallet balance, pending transactions, KYC documents
5. Add confirmation dialog warning about permanent deletion

### 5.1.2 Data Use & Sharing — REVIEW NEEDED

#### App Tracking Transparency (ATT)

- Firebase Analytics is integrated (`firebase_analytics: ^11.3.8`)
- **No ATT prompt found** in codebase (no `app_tracking_transparency` package)
- If Firebase Analytics collects IDFA or tracks users across apps, ATT is required

**Action:** Verify Firebase Analytics configuration. If using default Firebase Analytics without IDFA, ATT may not be needed. Document this in App Store Connect privacy questionnaire.

### 5.1.5 Location Services — PASS
No location permission requested. No location tracking found.

### 5.2 Intellectual Property — PASS
No third-party trademarks or copyrighted material detected.

### 5.3 Gaming, Gambling, Lotteries — REVIEW NEEDED

**Voting/Elections feature:**
- `elections_screen.dart`, `election_details_screen.dart`, `election_results_screen.dart`
- If this is real election infrastructure, additional scrutiny applies
- If community polls only, likely acceptable

**Investment products:**
- Not gambling per se, but Apple may scrutinize claims about returns
- "Fixed returns" and "variable returns" language must not guarantee profits

### 5.4 VPN Apps — N/A

### 5.5 Mobile Device Management — N/A

---

## App Store Connect Privacy Questionnaire

Based on codebase analysis, here's what must be declared:

### Data Types Collected

| Data Type | Collected? | Linked to Identity? | Used for Tracking? |
|-----------|-----------|---------------------|-------------------|
| Name | YES (registration) | YES | NO |
| Email | YES (registration) | YES | NO |
| Phone Number | YES (registration) | YES | NO |
| Physical Address | YES (billing/KYC) | YES | NO |
| Payment Info | YES (Stripe) | YES | NO |
| Photos | YES (KYC documents, profile) | YES | NO |
| Contacts | YES (transfer recipients) | YES | NO |
| Identifiers (device) | YES (FCM token) | YES | NO |
| Usage Data | YES (Firebase Analytics) | MAYBE | MAYBE |
| Financial Info | YES (transactions, balance) | YES | NO |
| Sensitive Info | YES (ID documents for KYC) | YES | NO |

---

## iOS Technical Compliance

| Check | Status | File/Evidence |
|-------|--------|---------------|
| iOS 13.0+ deployment target | PASS | `Podfile:2` |
| HTTPS for all API calls | PASS | `app_constants.dart:26` |
| URL scheme registered | PASS | `Info.plist:76` — `tccapp` |
| Background modes declared | PASS | `Info.plist:61-65` — fetch, remote-notification |
| App icon configured | PASS | `pubspec.yaml:157-163` — flutter_launcher_icons |
| Launch screen configured | PASS | `pubspec.yaml:165-173` — flutter_native_splash |
| Firebase configured | PASS | `firebase_options.dart` — iOS config present |
| Stripe live mode | PASS | `app_constants.dart:65` — `pk_live_*` key |
| Push notification permission | PASS | `notification_service.dart:71-92` |
| No hardcoded secrets in code | FAIL | Stripe publishable key in code (`app_constants.dart:65`), CurrencyBeacon API key (`app_constants.dart:69`) — acceptable for publishable keys, but CurrencyBeacon key should be server-side |
| CFBundleDisplayName set | PASS | `Info.plist:8` — "TCC" |
| Entitlements file | MISSING | No `.entitlements` file found — may need for Push Notifications capability |

---

## Action Items — Priority Order

### BLOCKERS (Must fix before submission)

| # | Issue | Guideline | Effort |
|---|-------|-----------|--------|
| 1 | **Implement account deletion** | 5.1.1(v) | Backend endpoint + UI screen |
| 2 | **Host privacy policy at public URL** | 5.1.1(i) | Web hosting + App Store Connect |
| 3 | **Host terms of service at public URL** | 5.1.1(i) | Web hosting + App Store Connect |
| 4 | **Update privacy policy content** — disclose Firebase Analytics, Stripe, FCM token collection | 5.1.1(i) | Policy rewrite |
| 5 | **Verify developer account is Organization type** (not Individual) | 3.2.1(viii) | Apple Developer account check |
| 6 | **Prepare financial licensing documentation** for investment/currency trading features | 3.2.1(viii), 3.2.2(viii) | Legal/regulatory |
| 7 | **Provide demo account** for App Review in Notes for Review | 2.1(a) | Create test account |

### HIGH PRIORITY (Likely to cause rejection)

| # | Issue | Guideline | Effort |
|---|-------|-----------|--------|
| 8 | Replace placeholder support contacts with real ones | 1.5 | Content update |
| 9 | Clarify "TCC Coin" is not cryptocurrency in metadata and Notes for Review | 3.1.5 | Metadata wording |
| 10 | Ensure investment disclaimers visible (no guaranteed returns) | 3.2.2(viii) | UI text update |
| 11 | Add Push Notification entitlement file if not auto-generated by Xcode | 2.5 | Xcode config |

### MEDIUM PRIORITY (May cause issues)

| # | Issue | Guideline | Effort |
|---|-------|-----------|--------|
| 12 | Verify App Tracking Transparency requirements for Firebase Analytics | 5.1.2 | Configuration check |
| 13 | Complete App Store Connect privacy questionnaire accurately | 5.1.1 | Form completion |
| 14 | Prepare App Store screenshots showing actual app usage (not splash/login) | 2.3.3 | Marketing assets |
| 15 | Answer age rating questionnaire accurately (financial transactions, investments) | 2.3.6 | Form completion |
| 16 | Move CurrencyBeacon API key to backend (currently exposed in client code) | Security best practice | Code change |

---

## Conclusion

The app has **4 critical blockers** that will result in immediate rejection:

1. **No account deletion** — Apple's most enforced policy since 2022
2. **No external privacy policy URL** — Required in App Store Connect
3. **Financial licensing** — Investment/trading features require submission by licensed entity
4. **Cryptocurrency perception** — "Community Coin" / "TCC" naming risks triggering crypto review

The technical implementation (Stripe payments, push notifications, network security, permissions) is solid. The primary gaps are **policy/legal compliance**, not code quality.
