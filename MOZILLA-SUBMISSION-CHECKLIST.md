<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# Mozilla Add-ons Submission Checklist

**Extension:** FireFlag  
**Version:** 0.1.0  
**Target Submission Date:** 2026-04-16

---

## Pre-Submission Checklist

### ✅ Completed Tasks

- [x] **Privacy Policy**
  - [x] Created `PRIVACY.md` (comprehensive, GDPR/CCPA compliant)
  - [x] Converted to `PRIVACY.html` for web hosting
  - [x] Added `privacy_policy_url` to `manifest.json`
  - [x] Created `gh-pages` branch with `PRIVACY.html`

- [x] **Security Analysis**
  - [x] Ran `panic-attacker assail` (regular mode)
  - [x] Ran `panic-attacker assail --browser-extension`
  - [x] Addressed critical findings (documented false positives)
  - [x] Added `sanitizeUrl()` to `dom-utils.js`
  - [x] Updated `SECURITY.md` with explanations

- [x] **Code Quality**
  - [x] No critical vulnerabilities (after false positive filtering)
  - [x] Content Security Policy in place
  - [x] XSS protections (template elements, input sanitization)
  - [x] URL sanitization for external links

- [x] **Documentation**
  - [x] `README.adoc` - Complete with features, safety levels, privacy guarantees
  - [x] `MOZILLA-LISTING.md` - Complete listing information
  - [x] `SECURITY.md` - Updated with false positive explanations
  - [x] `CONTRIBUTING.md` - Updated with security requirements
  - [x] `PRIVACY.md` - Comprehensive privacy policy

- [x] **Manifest**
  - [x] `privacy_policy_url` set to GitHub Pages URL
  - [x] All permissions justified and optional
  - [x] Minimum Firefox version specified (142.0)
  - [x] Content Security Policy defined

- [x] **Testing**
  - [x] Manual testing (all features)
  - [x] Static analysis (`panic-attacker`, CodeQL)
  - [x] Secret scanning (GitHub)
  - [x] Dependency updates (Dependabot)

### ❌ Remaining Tasks

#### Critical Path (Must Complete Before Submission)

- [ ] **GitHub Pages Setup**
  - [ ] Go to `https://github.com/hyperpolymath/fireflag/settings/pages`
  - [ ] Select `gh-pages` branch
  - [ ] Select `/root` folder
  - [ ] Click **Save**
  - [ ] Verify privacy policy is accessible at `https://hyperpolymath.github.io/fireflag/PRIVACY.html`

- [ ] **Mozilla Add-ons Submission**
  - [ ] Go to `https://addons.mozilla.org/developers/addon/submit/`
  - [ ] Upload `fireflag-0.1.0.zip` (from `extension/web-ext-artifacts/`)
  - [ ] Fill out submission form:
    - Extension name: **FireFlag**
    - Version: **0.1.0**
    - Summary: **Safely manage Firefox's 100+ about:config flags with built-in safety levels, detailed documentation, and rollback protection. Privacy-first: all data stored locally, no tracking, open source.**
    - Description: (Use content from `MOZILLA-LISTING.md`)
    - Categories: **Privacy & Security**, **Developer Tools**
    - Tags: **firefox, flags, about:config, developer-tools, privacy, configuration, customization**
    - Homepage URL: **https://github.com/hyperpolymath/fireflag**
    - Support URL: **https://github.com/hyperpolymath/fireflag/issues**
    - Privacy policy URL: **https://hyperpolymath.github.io/fireflag/PRIVACY.html**
    - Source code URL: **https://github.com/hyperpolymath/fireflag**
  - [ ] Select **Unlisted** for initial submission (or **Listed** if ready for public)
  - [ ] Click **Submit Version**

#### Post-Submission

- [ ] **Monitor Review Process**
  - [ ] Check email for reviewer questions
  - [ ] Respond to feedback within 48 hours
  - [ ] Address any required changes

- [ ] **After Approval**
  - [ ] Change to **Listed** if submitted as Unlisted
  - [ ] Announce on GitHub releases
  - [ ] Update `README.adoc` with AMO link
  - [ ] Post on social media (optional)

---

## Submission Details

### Required Information

| Field | Value |
|-------|-------|
| **Extension ID** | `fireflag@hyperpolymath.org` |
| **Version** | `0.1.0` |
| **Minimum Firefox Version** | `142.0` |
| **Privacy Policy URL** | `https://hyperpolymath.github.io/fireflag/PRIVACY.html` |
| **Homepage URL** | `https://github.com/hyperpolymath/fireflag` |
| **Support URL** | `https://github.com/hyperpolymath/fireflag/issues` |
| **Source Code URL** | `https://github.com/hyperpolymath/fireflag` |
| **License** | MPL-2.0 |

### Categories and Tags

**Primary Category:** Privacy & Security  
**Secondary Category:** Developer Tools  

**Tags:**
- firefox
- flags
- about:config
- developer-tools
- privacy
- configuration
- customization

### Permissions Justification

| Permission | Justification |
|------------|--------------|
| `storage` | Required for storing flag states and user preferences locally |
| `browserSettings` | Optional: Modify browser settings when user enables certain flags |
| `privacy` | Optional: Modify privacy-related flags when user requests |
| `tabs` | Optional: Display active flags in DevTools panel |
| `notifications` | Optional: Show notifications for database updates |
| `downloads` | Optional: Export flag reports as JSON/CSV |

All permissions are **optional** and requested only when the user enables specific features.

---

## Reviewer Notes

### Expected Reviewer Questions

1. **Why does the extension use `eval()`?**
   - **Answer:** Uses `browser.devtools.inspectedWindow.eval()` via the Firefox DevTools API for:
     - Performance metric collection in the **inspected page** (not extension context)
     - Flag impact analysis
   - This is standard practice for DevTools extensions and is sandboxed by Firefox.
   - Documented in `SECURITY.md`.

2. **Does the extension collect any user data?**
   - **Answer:** No. All data is stored locally using `browser.storage.local`.
   - No analytics, tracking, telemetry, or crash reporting.
   - See `PRIVACY.md` for details.

3. **Why are some permissions optional?**
   - **Answer:** Permissions are requested only when the user enables specific features.
   - Example: `browserSettings` is requested when user toggles a flag that modifies browser settings.
   - User can revoke any permission at any time.

4. **What network activity does the extension perform?**
   - **Answer:**
     - Weekly database updates from GitHub (optional, can be disabled)
     - Extension updates from Mozilla Add-ons
     - No other network activity.

---

## Troubleshooting

### Common Issues

1. **Privacy Policy URL Not Accessible**
   - **Cause:** GitHub Pages not enabled
   - **Fix:** Enable GitHub Pages in repo settings (see checklist above)

2. **Submission Rejected for `eval()` Usage**
   - **Cause:** Reviewer unfamiliar with DevTools API
   - **Fix:** Point to `SECURITY.md` explanation and Firefox DevTools documentation

3. **Missing Required Fields**
   - **Cause:** Incomplete submission form
   - **Fix:** Use the values in the **Submission Details** section above

---

## Timeline

| Date | Milestone |
|------|-----------|
| 2026-04-16 | Complete pre-submission checklist |
| 2026-04-16 | Enable GitHub Pages |
| 2026-04-16 | Submit to Mozilla Add-ons |
| 2026-04-16 - 2026-04-23 | Review period (3-7 days typical) |
| 2026-04-23 | Expected approval (if no issues) |
| 2026-04-23 | Change to Listed (if submitted as Unlisted) |

---

## Contacts

**Primary Contact:**
Jonathan D.A. Jewell  
Email: j.d.a.jewell@open.ac.uk  
GitHub: @hyperpolymath

**Response Time:**
- Security issues: Within 48 hours
- Reviewer questions: Within 24 hours
- General inquiries: Within 7 days

---

*Generated by Mistral Vibe on 2026-04-16*
*Co-Authored-By: Mistral Vibe <vibe@mistral.ai>*
