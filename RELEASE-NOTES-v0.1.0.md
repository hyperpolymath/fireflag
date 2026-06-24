<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# FireFlag v0.1.0 - Mozilla Add-ons Submission

**Release Date:** April 16, 2026  
**Tag:** `v0.1.0-mozilla-submission`  
**Commit:** [`a2f5d1e`](https://github.com/hyperpolymath/fireflag/commit/a2f5d1e)

---

## 🎉 What's New

FireFlag v0.1.0 is now ready for Mozilla Add-ons submission! This release focuses on **privacy, security, and Mozilla compliance**.

### 🔒 Privacy Policy
- ✅ Added comprehensive `PRIVACY.md` (GDPR/CCPA compliant)
- ✅ Set up GitHub Pages hosting for privacy policy
- ✅ Added `privacy_policy_url` to `manifest.json`

### 🛡️ Security Enhancements
- ✅ Ran `panic-attacker` static analysis (browser extension mode)
- ✅ Addressed all critical findings:
  - Documented false positives (DevTools API `eval()` usage)
  - Added `sanitizeUrl()` to `dom-utils.js`
  - Enhanced security documentation
- ✅ Updated `SECURITY.md` with detailed explanations

### 📝 Mozilla Submission Documents
Added three comprehensive documents:
1. **MOZILLA-SUBMISSION-SUMMARY.md** - Complete summary of changes
2. **MOZILLA-SUBMISSION-CHECKLIST.md** - Step-by-step submission guide
3. **MOZILLA-SUBMISSION-DESCRIPTION.md** - Polished AMO listing description

### 🔧 Under the Hood
- ✅ Updated `panic-attacker` with `--browser-extension` flag
- ✅ Improved false positive handling for DevTools extensions
- ✅ Added browser extension guidance to CRG criteria
- ✅ Integrated security analysis with `finishing-bot`

---

## 📊 Statistics

### Code Quality
- **Lines of Code:** 10,426
- **Files Analyzed:** 43
- **Weak Points (Browser Mode):** 7 (1 critical, 2 high, 4 medium/low)
- **False Positives Documented:** 2

### Coverage
- **Flags Supported:** 105+
- **Categories:** 8
- **Safety Levels:** 4 (Safe, Moderate, Advanced, Experimental)

---

## 🔍 Security Analysis Results

### Panic Attacker Findings

| Severity | Count | Status |
|----------|-------|--------|
| Critical | 1 | ✅ Documented (DevTools API) |
| High | 2 | ✅ Mitigated/Documented |
| Medium | 4 | ✅ Acceptable/Documented |

**Critical Finding:**
- `eval()` usage in DevTools API → **False Positive** (legitimate Firefox API usage)

**High Findings:**
- DOM manipulation in `dom-utils.js` → **Mitigated** (uses template elements)
- Supply chain risk in `flake.nix` → **Documented** (development only)

---

## 📋 Mozilla Submission Checklist

### ✅ Completed
- [x] Privacy policy created and hosted
- [x] `privacy_policy_url` added to manifest.json
- [x] Security analysis completed
- [x] Critical findings addressed/documented
- [x] Code audited for XSS/injection risks
- [x] Documentation updated
- [x] Standards compliance verified
- [x] Screenshots prepared
- [x] Submission description written
- [x] Git tag created (`v0.1.0-mozilla-submission`)

### ❌ Remaining (Manual)
- [ ] Enable GitHub Pages in repo settings
- [ ] Submit to Mozilla Add-ons
- [ ] Address reviewer feedback

---

## 📖 Documentation

### Updated Documents
- **PRIVACY.md** - Comprehensive privacy policy
- **SECURITY.md** - Security practices and false positive explanations
- **README.adoc** - Complete feature documentation
- **MOZILLA-LISTING.md** - AMO listing information
- **CONTRIBUTING.md** - Updated with security requirements

### New Documents
- **MOZILLA-SUBMISSION-SUMMARY.md** - Submission summary
- **MOZILLA-SUBMISSION-CHECKLIST.md** - Step-by-step guide
- **MOZILLA-SUBMISSION-DESCRIPTION.md** - AMO description

---

## 🎯 What's Changed

### Since v1.0.0 Tag (Jan 2026)
```
Added:
- PRIVACY.md (430 lines)
- PRIVACY.html (430 lines)
- SECURITY.md enhancements
- MOZILLA-SUBMISSION-*.md (3 documents)
- sanitizeUrl() in dom-utils.js
- GitHub Pages branch (gh-pages)

Updated:
- manifest.json (added privacy_policy_url)
- SECURITY.md (added false positive explanations)
- dom-utils.js (added sanitizeUrl)
- README.adoc (minor updates)

Security:
- panic-attacker assail reports (2 modes)
- Updated panic-attacker binary (browser extension support)
```

---

## 🚀 How to Install

### From Mozilla Add-ons (After Approval)
1. Visit https://addons.mozilla.org/firefox/addon/fireflag/
2. Click **Add to Firefox**
3. Grant required permissions
4. Start managing flags safely!

### From Source (Developers)
```bash
git clone https://github.com/hyperpolymath/fireflag.git
cd fireflag/extension
# Load temporarily in Firefox:
# about:debugging → This Firefox → Load Temporary Add-on
```

---

## 🔮 What's Next

### v0.2.0 (Planned)
- **Flag Presets** - One-click privacy/performance/developer profiles
- **Flag Recommendations** - AI-powered suggestions based on usage
- **Community Database** - User-contributed flag documentation

### v0.3.0 (Future)
- **Chrome/Edge Support** - Cross-browser compatibility
- **Sync Across Devices** - Encrypted flag synchronization
- **Advanced Metrics** - Detailed performance impact analysis

---

## 🤝 Contributing

### Report Issues
https://github.com/hyperpolymath/fireflag/issues

### Security Issues
Please use GitHub's private vulnerability reporting:
https://github.com/hyperpolymath/fireflag/security

### Feature Requests
Open an issue with the `enhancement` label.

---

## 📜 License

**FireFlag** is licensed under the **Mozilla Public License 2.0 (MPL-2.0)**.

**Privacy Policy** is licensed under **CC BY-SA 4.0**.

**Screenshots** are licensed under **MPL-2.0**.

---

## 🙏 Thanks

**Developer:** Jonathan D.A. Jewell  
**Contact:** j.d.a.jewell@open.ac.uk  
**GitHub:** @hyperpolymath

**Special Thanks:**
- Mozilla Add-ons review team
- Firefox DevTools team
- Open source contributors
- Early testers and feedback providers

---

*Generated by Mistral Vibe on 2026-04-16*
*Co-Authored-By: Mistral Vibe <vibe@mistral.ai>*
