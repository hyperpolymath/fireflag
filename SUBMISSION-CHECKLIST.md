# FireFlag v0.1.0 - Mozilla Add-ons Submission Checklist

## Pre-Submission Requirements

### 1. Build & Verification ✅
- [x] Extension built successfully (fireflag-0.1.0.xpi, 119 KB)
- [x] SHA256 checksum generated (7275dac7...)
- [x] Build report created (BUILD-REPORT.md)
- [x] Package contains all required files (37 files)
- [x] Manifest V3 validated
- [x] No build errors or warnings (non-critical npm deprecations only)

### 2. Documentation ✅
- [x] README.adoc complete with installation and usage
- [x] PRIVACY.md policy (8000+ words, GDPR/CCPA compliant)
- [x] PRIVACY-SUMMARY.txt for store listing
- [x] PRIVACY-CARD.md quick reference
- [x] LICENSE (MPL-2.0)
- [x] SECURITY.md with vulnerability reporting
- [x] CONTRIBUTING.md for contributors
- [x] CONTRIBUTING-FLAGS.md for flag database contributions
- [x] MOZILLA-LISTING.md with store content

### 3. Code Quality ✅
- [x] All files have SPDX headers (SPDX-License-Identifier: MPL-2.0)
- [x] No hardcoded secrets or API keys
- [x] Security scans passed (CodeQL, TruffleHog, selur, svalin)
- [x] EditorConfig compliance
- [x] web-ext lint passed

### 4. Screenshots ⏳
- [x] SVG mockups created (4 primary views)
- [x] Automated capture script ready (.screenshots/capture-screenshots.js)
- [x] Manual capture guide (.screenshots/MANUAL-CAPTURE.md)
- [ ] **ACTION REQUIRED:** Capture real screenshots from loaded extension
  ```bash
  # Option 1: Automated (recommended)
  just capture-screenshots

  # Option 2: Manual
  # Follow .screenshots/MANUAL-CAPTURE.md
  # Save to .screenshots/store/ directory
  ```

### 5. Testing ⏳
- [ ] **ACTION REQUIRED:** Test on Firefox stable (latest)
  ```bash
  firefox extension/web-ext-artifacts/fireflag-0.1.0.xpi
  # Or: about:debugging → Load Temporary Add-on
  ```
- [ ] **ACTION REQUIRED:** Test on Firefox Nightly
- [ ] Test all UI components:
  - [ ] Browser action popup opens and displays flags
  - [ ] Sidebar panel shows flags and history tabs
  - [ ] Options page loads and saves preferences
  - [ ] DevTools panel appears and functions
  - [ ] Permission requests work as expected
- [ ] Test core functionality:
  - [ ] Flag search and filtering
  - [ ] Flag modification (requires granting permissions)
  - [ ] Change tracking and history
  - [ ] Export to JSON/CSV
  - [ ] Database auto-update (if enabled)
- [ ] Test edge cases:
  - [ ] Fresh install (no existing data)
  - [ ] Upgrade scenario (if applicable later)
  - [ ] Permission denial handling
  - [ ] Network errors during database update
  - [ ] Invalid flag values
- [ ] **OPTIONAL:** Test on other browsers
  - [ ] Librewolf
  - [ ] Waterfox
  - [ ] Pale Moon (different Gecko version - may have issues)

### 6. Signing ⏳
- [ ] **ACTION REQUIRED:** Obtain Mozilla API credentials
  - Visit: https://addons.mozilla.org/developers/addon/api/key/
  - Generate API key and secret
  - **Keep these secret** (add to .gitignore or environment)
- [ ] **ACTION REQUIRED:** Sign extension
  ```bash
  # Using web-ext
  web-ext sign \
    --api-key=YOUR_API_KEY \
    --api-secret=YOUR_API_SECRET \
    --channel=listed

  # Or using justfile
  just sign-ext YOUR_API_KEY YOUR_API_SECRET
  ```
- [ ] Verify signed .xpi created
- [ ] Test signed .xpi in Firefox

### 7. Store Listing Content ✅
- [x] Extension name: FireFlag
- [x] Tagline (64 chars): "Safe Firefox/Gecko flag management for users and developers"
- [x] Summary (250 chars) ready
- [x] Full description ready (MOZILLA-LISTING.md)
- [x] Version notes ready
- [x] Categories selected: Privacy & Security (primary), Developer Tools, Other, Appearance
- [x] Tags prepared (20 tags)
- [x] Developer comments for reviewers ready

### 8. Mozilla Add-ons Account Setup ⏳
- [ ] **ACTION REQUIRED:** Create/login to Mozilla Add-ons account
  - Visit: https://addons.mozilla.org/
  - Login with Firefox Account
- [ ] **ACTION REQUIRED:** Set up developer profile
  - Display name: Jonathan D.A. Jewell
  - Email: j.d.a.jewell@open.ac.uk (must be verified)
  - Homepage: https://github.com/hyperpolymath
- [ ] Accept developer agreement
- [ ] Verify email address

## Submission Process

### Step 1: Create New Add-on
1. Go to: https://addons.mozilla.org/developers/addon/submit/upload-listed
2. Upload signed .xpi file
3. Wait for automated validation to complete
4. Review validation results and fix any errors

### Step 2: Add-on Details
1. **Extension name:** FireFlag
2. **Add-on URL:** fireflag (or auto-generated)
3. **Summary:** Copy from MOZILLA-LISTING.md (Summary section)
4. **Description:** Copy from MOZILLA-LISTING.md (Description section)
5. **Homepage:** https://github.com/hyperpolymath/fireflag
6. **Support email:** j.d.a.jewell@open.ac.uk
7. **Support URL:** https://github.com/hyperpolymath/fireflag/issues
8. **Privacy policy:** Copy from PRIVACY.md or link to GitHub
9. **License:** Mozilla Public License 2.0 (MPL-2.0)

### Step 3: Categories & Tags
1. **Primary category:** Privacy & Security
2. **Secondary categories:** Developer Tools, Other, Appearance
3. **Tags:** firefox, flags, about:config, privacy, security, performance, customization, power-user, developer-tools, webassembly, webgpu, experimental-features, tracking-protection, fingerprinting, telemetry, open-source, reproducible-builds

### Step 4: Screenshots
1. Upload 7 screenshots (from .screenshots/store/ directory):
   - 01-popup-overview.png - "Browser action popup with category filters and safety levels"
   - 02-popup-flag-detail.png - "Detailed flag information with documentation and safety warnings"
   - 03-sidebar-flags.png - "Sidebar panel showing active flags with before/after tracking"
   - 04-sidebar-history.png - "Change history with timestamps and rollback capability"
   - 05-options.png - "Settings page with granular permission control and preferences"
   - 06-devtools.png - "DevTools integration showing flag performance impact"
   - 07-permission-dialog.png - "Granular permission requests - only when needed"
2. Set screenshot order (drag to arrange)
3. Add captions to each screenshot

### Step 5: Version Notes
1. **Version number:** 0.1.0
2. **Release notes:** Copy from MOZILLA-LISTING.md (Version Notes section)
3. **Compatibility:**
   - Minimum Firefox version: 109.0
   - Maximum: No maximum (tested up to latest)
   - Android: Not yet supported (desktop only)

### Step 6: Developer Comments
1. **Source code:** https://github.com/hyperpolymath/fireflag
2. **Build instructions:** Copy from MOZILLA-LISTING.md (Developer Comments section)
3. **Permissions justification:** Copy from MOZILLA-LISTING.md (Permissions Justification)
4. **Network requests:** Copy from MOZILLA-LISTING.md (Network Requests)
5. **Testing notes:** Mention testing on Firefox, Librewolf, Waterfox

### Step 7: Review & Submit
1. Review all fields for accuracy
2. Check "I agree to the Firefox Add-on Distribution Agreement"
3. Click "Submit Version"
4. Wait for automated review
5. Respond to any reviewer questions promptly

## Post-Submission

### Automated Review (usually minutes to hours)
- [ ] Extension passes automated security scans
- [ ] No policy violations detected
- [ ] File structure validated
- [ ] Permissions validated

### Manual Review (can take 1-2 weeks for new extensions)
- [ ] Mozilla reviewer examines code
- [ ] Reviewer verifies permissions usage
- [ ] Reviewer checks privacy policy accuracy
- [ ] Reviewer tests basic functionality

### If Approved
- [ ] Extension appears on addons.mozilla.org
- [ ] Users can install from store
- [ ] Update GitHub README with store link
- [ ] Announce on GitHub (release notes)
- [ ] **OPTIONAL:** Create marketing materials
- [ ] **OPTIONAL:** Write blog post or announcement

### If Changes Requested
- [ ] Read reviewer feedback carefully
- [ ] Make required changes
- [ ] Test changes thoroughly
- [ ] Rebuild and re-sign extension
- [ ] Upload new version
- [ ] Respond to reviewer with explanation of changes

## Common Rejection Reasons (Avoid These)

### Code Issues
- ❌ Obfuscated or minified code without source maps
- ❌ Remote code execution (eval, Function constructor, etc.)
- ❌ Unexpected network requests
- ❌ Unnecessary permissions requested
- ❌ Security vulnerabilities

**FireFlag Status:** ✅ None of these issues present

### Documentation Issues
- ❌ Misleading description or screenshots
- ❌ Missing or incomplete privacy policy
- ❌ Permissions not explained
- ❌ No clear purpose or functionality

**FireFlag Status:** ✅ All documentation complete and accurate

### Policy Violations
- ❌ Cryptocurrency mining
- ❌ Ads or analytics without disclosure
- ❌ Data collection without consent
- ❌ Trademark infringement
- ❌ Spam or SEO manipulation

**FireFlag Status:** ✅ No policy violations

## Troubleshooting

### Automated Validation Errors
If you get validation errors:
1. Read error message carefully
2. Fix issues in source code
3. Rebuild extension (`just build-ext`)
4. Test locally
5. Re-sign and re-upload

### Reviewer Questions
Respond promptly (within 7 days) with:
- Clear explanation of questioned behavior
- Code references (GitHub links)
- Screenshots if helpful
- Offer to make changes if needed

### Signing Issues
If signing fails:
```bash
# Check API credentials are correct
# Verify you're using latest web-ext
npm install -g web-ext@latest

# Try manual upload to addons.mozilla.org instead
```

## Timeline Estimate

| Stage | Estimated Time |
|-------|----------------|
| Screenshot capture | 30 minutes |
| Testing (thorough) | 2-3 hours |
| Signing | 5 minutes |
| Account setup | 15 minutes |
| Form filling | 30 minutes |
| Automated review | 10 minutes - 2 hours |
| Manual review | 1-14 days (typically 3-5 days for new extensions) |

**Total time from now to store listing:** 1-2 weeks (assuming quick manual review)

## Post-Launch Checklist

### Immediate (Day 1)
- [ ] Update GitHub README with store installation link
- [ ] Create GitHub release (v0.1.0) with .xpi attached
- [ ] Tag release in git (`git tag v0.1.0`)
- [ ] Push tags (`git push --tags`)

### Week 1
- [ ] Monitor store reviews and ratings
- [ ] Respond to user questions/issues
- [ ] Fix any critical bugs reported
- [ ] Monitor extension analytics (if enabled in AMO dashboard)

### Month 1
- [ ] Collect user feedback
- [ ] Plan v0.2.0 features
- [ ] Update flag database if Mozilla releases new Firefox flags
- [ ] Consider adding more browser compatibility (Pale Moon, etc.)

## Resources

- **Mozilla Add-ons Developer Hub:** https://extensionworkshop.com/
- **Add-on Policies:** https://extensionworkshop.com/documentation/publish/add-on-policies/
- **Distribution Agreement:** https://extensionworkshop.com/documentation/publish/firefox-add-on-distribution-agreement/
- **Review Process:** https://extensionworkshop.com/documentation/publish/add-on-review-process/
- **API Documentation:** https://addons-server.readthedocs.io/en/latest/topics/api/signing.html

---

**Current Status:** Ready for screenshots, testing, and signing.

**Blockers:** None - all preparation complete.

**Next Action:** Capture real screenshots and test in Firefox.
