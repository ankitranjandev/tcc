# Apple App Store Guidelines Compliance Analysis
## TCC User Mobile Client - February 2026

---

## Executive Summary

| Category | Status | Critical Issues |
|----------|--------|-----------------|
| **Safety** | ⚠️ Needs Review | Age rating verification needed |
| **Performance** | ⚠️ Needs Work | Demo account required |
| **Business/Payments** | ✅ Compliant | Physical goods exemption applies |
| **Design** | ✅ Compliant | Meets minimum functionality |
| **Legal/Privacy** | ❌ CRITICAL | Account deletion missing, Privacy policy URL missing |
| **Financial Services** | ⚠️ Needs Review | Must be submitted by licensed entity |

**Overall Status: NOT READY FOR SUBMISSION**

---

## 1. SAFETY REQUIREMENTS (Section 1)

### 1.1 Objectionable Content
| Requirement | Status | Notes |
|-------------|--------|-------|
| No offensive/discriminatory content | ✅ Pass | App is financial services only |
| No false information | ✅ Pass | Real financial data displayed |
| No deceptive functionality | ✅ Pass | All features work as described |

### 1.3 Kids Category
| Requirement | Status | Notes |
|-------------|--------|-------|
| Not targeting children | ✅ N/A | Adult financial app (17+) |

### 1.4 Physical Harm
| Requirement | Status | Notes |
|-------------|--------|-------|
| No medical claims | ✅ Pass | Not a health app |
| No substance abuse | ✅ Pass | Financial services only |

### 1.5 Developer Information
| Requirement | Status | Notes |
|-------------|--------|-------|
| Contact method available | ⚠️ Check | Verify support contact in AccountScreen |
| Valid developer info | ⚠️ Check | Verify App Store Connect metadata |

### 1.6 Data Security
| Requirement | Status | Notes |
|-------------|--------|-------|
| HTTPS enforcement | ✅ Pass | CloudFront CDN with HTTPS |
| Token-based auth | ✅ Pass | JWT with refresh tokens |
| 3DS for payments | ✅ Pass | Stripe 3DS integration |

---

## 2. PERFORMANCE REQUIREMENTS (Section 2)

### 2.1 App Completeness
| Requirement | Status | Notes |
|-------------|--------|-------|
| Final version submitted | ⚠️ Pending | Version 1.0.0 Build 3 |
| All URLs functional | ⚠️ Verify | Check all deep links work |
| **Demo account for reviewers** | ❌ MISSING | **CRITICAL: Must provide test credentials** |
| Backend services live | ✅ Pass | Production API on CloudFront |

### 2.2 Beta Testing
| Requirement | Status | Notes |
|-------------|--------|-------|
| TestFlight for betas | ✅ Pass | Using TestFlight |

### 2.3 Accurate Metadata
| Requirement | Status | Notes |
|-------------|--------|-------|
| **Privacy policy link** | ❌ MISSING | **CRITICAL: Required in App Store Connect + in-app** |
| All features documented | ⚠️ Check | Verify app description completeness |
| Accurate screenshots | ⚠️ Pending | Must show actual app usage |
| App name ≤30 chars | ✅ Pass | "TCC" is within limit |
| **Age rating accurate** | ⚠️ UPDATE | Must be 17+ (financial services) |

### 2.4 Hardware Compatibility
| Requirement | Status | Notes |
|-------------|--------|-------|
| iPad compatibility | ✅ Pass | Flutter responsive design |
| Power efficiency | ✅ Pass | No background processes |
| No crypto mining | ✅ Pass | No mining code present |

### 2.5 Software Requirements
| Requirement | Status | Notes |
|-------------|--------|-------|
| Public APIs only | ✅ Pass | Using Flutter + standard plugins |
| IPv6 compatible | ✅ Pass | HTTP client supports IPv6 |
| Self-contained binary | ✅ Pass | No external code loading |
| **Xcode/SDK version** | ⚠️ CHECK | Must use iOS 18 SDK now, iOS 26 SDK by April 28, 2026 |

---

## 3. BUSINESS & PAYMENTS (Section 3)

### 3.1.1 In-App Purchase Analysis

**TCC is EXEMPT from IAP requirement per Guideline 3.1.3:**

| Exemption Category | Applies? | Justification |
|-------------------|----------|---------------|
| **3.1.3(e) Physical Goods/Services** | ✅ YES | Bill payments (electricity, water, internet) are real-world services |
| **3.1.3(d) Person-to-Person Payments** | ✅ YES | Wallet transfers between users |
| **3.1.3 Reader Apps (content)** | ❌ No | Not a content consumption app |

**Payment Methods Used:**
- Stripe (credit/debit cards) ✅ Allowed for physical goods
- Apple Pay ✅ Allowed and integrated
- Bank transfers ✅ Allowed for real money
- Mobile Money ✅ Allowed for real money

### 3.1.5 Cryptocurrency Compliance

| Requirement | Status | Notes |
|-------------|--------|-------|
| TCC is cryptocurrency | ❌ NO | TCC is fiat-backed (1:1 USD peg) |
| Crypto wallet features | ❌ NO | Standard digital wallet |
| Mining functionality | ❌ NO | No mining present |
| Token rewards for tasks | ❌ NO | No referral token rewards |

**RECOMMENDATION:** Clarify in app description that TCC is NOT cryptocurrency but a regulated digital wallet.

### 3.2 Business Model Issues

| Requirement | Status | Notes |
|-------------|--------|-------|
| No binary options | ✅ Pass | Not offered |
| Loan APR ≤36% | ✅ N/A | No lending features |
| No forced ratings | ✅ Pass | No rating prompts found |
| Proper licensing | ⚠️ VERIFY | Sierra Leone financial license required |

---

## 4. DESIGN REQUIREMENTS (Section 4)

### 4.1 Copycats
| Requirement | Status | Notes |
|-------------|--------|-------|
| Original design | ✅ Pass | Unique TCC branding |
| No impersonation | ✅ Pass | Original concept |

### 4.2 Minimum Functionality
| Requirement | Status | Notes |
|-------------|--------|-------|
| Useful functionality | ✅ Pass | Full financial services |
| Not just a website | ✅ Pass | Native Flutter app with rich features |
| Lasting value | ✅ Pass | Core financial services |

### 4.7 Third-Party Content
| Requirement | Status | Notes |
|-------------|--------|-------|
| No mini apps/games | ✅ N/A | Not applicable |
| Content filtering | ✅ N/A | No user-generated content |

### 4.8 Login Services
| Requirement | Status | Notes |
|-------------|--------|-------|
| Third-party login options | ✅ N/A | Email/phone auth only |
| Sign in with Apple | ⚠️ Optional | Consider adding for better UX |

### 4.9 Apple Pay Compliance
| Requirement | Status | Notes |
|-------------|--------|-------|
| Material info before sale | ✅ Pass | Amount shown before payment |
| Correct branding | ⚠️ VERIFY | Check Apple Pay button styling |
| Recurring payment disclosure | ✅ N/A | No recurring payments |

---

## 5. LEGAL REQUIREMENTS (Section 5)

### 5.1.1 Data Collection & Storage

| Requirement | Status | Action Required |
|-------------|--------|-----------------|
| **Privacy policy URL** | ❌ MISSING | **Create and host privacy policy** |
| **In-app privacy policy** | ❌ MISSING | **Add link in app settings** |
| User consent before collection | ⚠️ PARTIAL | Add consent dialogs for data collection |
| Data minimization | ✅ Pass | Only collecting necessary data |
| **Account deletion** | ❌ MISSING | **CRITICAL: Must implement** |
| Purpose strings (iOS) | ✅ Pass | Camera/Photos strings present |

**Data Collected (Must Disclose):**
- Personal info (name, email, phone)
- Financial data (transactions, balance)
- KYC documents (ID photos, selfie)
- Device identifiers (FCM token)
- Location (for agent search)
- Contacts (for transfers)

### 5.1.2 Data Use & Sharing

| Requirement | Status | Notes |
|-------------|--------|-------|
| Third-party disclosure | ⚠️ NEEDED | Must disclose Stripe, Firebase, CurrencyBeacon |
| No secret profiling | ✅ Pass | No hidden analytics |
| App Tracking Transparency | ⚠️ CHECK | May need ATT if using IDFA |

**Third-Party Services Requiring Disclosure:**
1. **Stripe** - Payment processing, customer data
2. **Firebase** - Analytics, push notifications
3. **CurrencyBeacon** - Currency rate data
4. **CloudFront** - Content delivery

### 5.1.5 Location Services

| Requirement | Status | Notes |
|-------------|--------|-------|
| Relevant to features | ✅ Pass | Used for agent search only |
| User consent | ✅ Pass | Permission handler used |
| Purpose explained | ⚠️ CHECK | Verify location purpose string |

### 5.2 Intellectual Property

| Requirement | Status | Notes |
|-------------|--------|-------|
| Original content | ✅ Pass | All assets appear original |
| Licensed content | ⚠️ VERIFY | Check image/icon licenses |
| No unauthorized data | ✅ Pass | Using legitimate APIs |

### 5.3 Gambling/Gaming

| Requirement | Status | Notes |
|-------------|--------|-------|
| No gambling features | ✅ Pass | Not a gambling app |
| Investment disclosures | ⚠️ CHECK | May need risk disclaimers |

---

## FINANCIAL SERVICES COMPLIANCE (Guideline 3.2.1(viii))

### Critical Requirements for Fintech Apps

| Requirement | Status | Action Required |
|-------------|--------|-----------------|
| **Submitted by licensed entity** | ❌ CRITICAL | Must be submitted by TCC's licensed financial entity, not individual developer |
| All jurisdictions licensed | ⚠️ VERIFY | Sierra Leone financial services license |
| Fee transparency | ✅ Pass | Fees shown in transaction flows |
| Investment risk disclosure | ⚠️ ADD | Add investment risk warnings |
| Terms of service | ⚠️ VERIFY | Check ToS link in app |

---

## UPCOMING REQUIREMENTS (2026)

### April 28, 2026 Deadline
| Requirement | Current Status | Action Required |
|-------------|----------------|-----------------|
| iOS 26 SDK | ❌ Not yet | Update to Xcode 26 before deadline |
| iPadOS 26 SDK | ❌ Not yet | Update to Xcode 26 before deadline |

### Already Active
| Requirement | Status | Notes |
|-------------|--------|-------|
| iOS 18 SDK (Xcode 16) | ⚠️ VERIFY | Check current build settings |
| Privacy manifest | ⚠️ CHECK | Required for listed APIs |
| Age rating update | ⚠️ RESPOND | Update in App Store Connect |

---

## CRITICAL BLOCKERS (Must Fix Before Submission)

### 1. ❌ Account Deletion Feature
**Guideline:** 5.1.1(v)
**Issue:** No account deletion mechanism in app
**Solution:**
```dart
// Add to AccountScreen or ProfileScreen
- "Delete Account" button
- Confirmation dialog with warning
- API call to /users/delete-account
- Clear local data and logout
```

### 2. ❌ Privacy Policy URL
**Guideline:** 5.1.1(i), 2.3
**Issue:** No privacy policy linked
**Solution:**
- Create comprehensive privacy policy
- Host at accessible URL (e.g., tcc.com/privacy)
- Add link in App Store Connect
- Add link in app Settings/Account screen

### 3. ❌ Demo Account for Reviewers
**Guideline:** 2.1
**Issue:** Apple reviewers cannot test without credentials
**Solution:**
- Create test account with pre-loaded wallet
- Provide credentials in App Store Connect review notes
- Ensure test account has KYC pre-approved

### 4. ❌ Licensed Entity Submission
**Guideline:** 3.2.1(viii)
**Issue:** Financial apps must be submitted by the licensed entity
**Solution:**
- Ensure Apple Developer account is under TCC's licensed financial entity
- Not individual developer account

---

## HIGH PRIORITY ITEMS

### 5. ⚠️ Investment Risk Disclaimers
**Guideline:** 3.2
**Recommendation:** Add risk warnings on investment screens
```
"Investments carry risk. Past performance does not guarantee future results."
```

### 6. ⚠️ Third-Party Data Sharing Disclosure
**Guideline:** 5.1.2
**Recommendation:** Add data sharing disclosure in privacy policy and app:
- Stripe (payment processing)
- Firebase (analytics, notifications)
- CurrencyBeacon (exchange rates)

### 7. ⚠️ App Tracking Transparency
**Guideline:** 5.1.2
**Check:** If using IDFA or cross-app tracking, implement ATT prompt

### 8. ⚠️ "Coin" Branding Clarification
**Guideline:** 3.1.5
**Risk:** "Coin" may confuse reviewers into thinking it's cryptocurrency
**Solution:** Clarify in app description:
```
"TCC (The Community Coin) is a regulated digital wallet backed by real currency,
not a cryptocurrency. It enables secure payments, transfers, and bill payments."
```

---

## RECOMMENDED IMPROVEMENTS

### Privacy & Compliance
1. Add privacy policy link in AccountScreen
2. Add terms of service link
3. Implement account deletion with data purge
4. Add consent checkboxes during registration
5. Create privacy manifest file for iOS

### User Experience
1. Add "Sign in with Apple" option
2. Add biometric authentication (Face ID/Touch ID)
3. Improve error messages for failed transactions

### Documentation
1. Prepare App Store description highlighting non-crypto nature
2. Create reviewer notes with test account
3. Document all third-party integrations

---

## APP STORE CONNECT CHECKLIST

Before submission, ensure:

- [ ] Privacy Policy URL added
- [ ] Support URL added
- [ ] Marketing URL added (optional)
- [ ] Age Rating set to 17+ (Financial Services)
- [ ] App Review notes with demo account credentials
- [ ] All screenshots showing actual app usage
- [ ] App description clarifies TCC is NOT cryptocurrency
- [ ] Contact information for expedited review
- [ ] Export compliance documentation (if applicable)

---

## SUBMISSION READINESS SCORE

| Category | Score | Notes |
|----------|-------|-------|
| Technical Implementation | 85% | App works well |
| Privacy Compliance | 40% | Missing critical items |
| Legal Compliance | 60% | Need licensed entity |
| Metadata Readiness | 50% | Missing privacy policy |
| **Overall** | **~55%** | **Not ready for submission** |

---

## NEXT STEPS

1. **Immediate (Before Submission):**
   - Implement account deletion
   - Create and host privacy policy
   - Create demo account for reviewers
   - Verify submission under licensed entity

2. **Before April 2026:**
   - Update to Xcode 26 / iOS 26 SDK
   - Update age rating in App Store Connect
   - Add privacy manifest file

3. **Recommended:**
   - Add Sign in with Apple
   - Add biometric authentication
   - Improve investment risk disclosures

---

## Sources

- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple Upcoming Requirements](https://developer.apple.com/news/upcoming-requirements/)
- [App Store Review Guidelines 2026 Checklist](https://adapty.io/blog/how-to-pass-app-store-review/)
- [iOS App Store Review Guidelines Best Practices](https://crustlab.com/blog/ios-app-store-review-guidelines/)

---

*Analysis generated: February 6, 2026*
*App Version Analyzed: 1.0.0 (Build 3)*
