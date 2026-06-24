<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# Privacy Policy for FireFlag

**Last Updated:** February 4, 2026
**Effective Date:** February 4, 2026
**Version:** 1.0.0

## Introduction

FireFlag is a Firefox browser extension that helps users safely manage browser flags (about:config settings, experimental features, and developer flags). This privacy policy explains what data FireFlag collects, how it's used, and your rights regarding your data.

**TL;DR:** FireFlag stores all data locally on your device. We do not collect, transmit, or share any personal information. We do not use analytics, tracking, or telemetry.

## Developer Information

- **Extension Name:** FireFlag
- **Developer:** Jonathan D.A. Jewell
- **Contact:** j.d.a.jewell@open.ac.uk
- **Source Code:** https://github.com/hyperpolymath/fireflag
- **License:** MPL-2.0 (Mozilla Public License 2.0)

## Data Collection and Storage

### What Data is Stored Locally

FireFlag stores the following data **locally on your device only** using Firefox's browser.storage API:

1. **Flag States**
   - Which flags you have enabled/disabled
   - Current flag values
   - Last modified timestamps

2. **Change History** (if tracking enabled)
   - Before/after values when you toggle flags
   - Timestamps of changes
   - Performance metrics at time of change

3. **User Preferences**
   - Auto-update settings
   - UI preferences (compact view, safety badges, etc.)
   - Permission grants
   - Export format preferences

4. **Flag Database**
   - Local copy of the flag database (105+ Firefox flags)
   - Flag metadata (descriptions, safety levels, effects)
   - Version information

**Storage Location:** All data is stored using `browser.storage.local` API, which keeps data on your device in Firefox's profile directory.

### What Data is NOT Collected

FireFlag does **NOT** collect, store, or transmit:

- ❌ Personal identifying information (name, email, IP address)
- ❌ Browsing history or website URLs
- ❌ Search queries or form data
- ❌ Cookies or authentication tokens
- ❌ System information (OS, hardware specs)
- ❌ Analytics or telemetry data
- ❌ Crash reports or error logs
- ❌ User behavior patterns
- ❌ Any data that leaves your device

## Network Activity

### Automatic Database Updates

When auto-update is enabled (default), FireFlag checks for database updates:

- **Frequency:** Weekly (Sundays at midnight UTC)
- **Source:** GitHub Releases API (https://api.github.com/repos/hyperpolymath/fireflag/releases/latest)
- **Data Sent:** Standard HTTP request headers (User-Agent, Accept)
- **Data Received:** Version number and download URL only
- **IP Logging:** GitHub may log IP addresses per their privacy policy

**You can disable auto-updates** in Settings → General → Auto-Update.

### Manual Database Updates

When you manually check for updates:

- Same process as automatic updates
- Triggered by user action only
- Can be disabled entirely

### No Analytics or Tracking

FireFlag does **NOT**:
- Use Google Analytics or similar services
- Track user behavior
- Send telemetry data
- Phone home for any reason except database updates
- Include third-party scripts or trackers

## Permissions and Data Access

### Required Permissions

FireFlag requests these Firefox permissions:

1. **`storage`** (Required)
   - **Purpose:** Store flag states and user preferences locally
   - **Data Access:** Your flag configurations and settings
   - **Scope:** Local device only

### Optional Permissions

These permissions are requested **only when you enable specific flags**:

1. **`browserSettings`** (Optional)
   - **Purpose:** Modify browser settings when you enable certain flags
   - **Requested When:** You toggle a flag affecting browser settings
   - **Can Be Revoked:** Yes, anytime in Firefox permissions

2. **`privacy`** (Optional)
   - **Purpose:** Modify privacy-related flags
   - **Requested When:** You toggle a privacy flag
   - **Can Be Revoked:** Yes, anytime

3. **`tabs`** (Optional)
   - **Purpose:** Display active flags in DevTools panel
   - **Requested When:** You open DevTools panel
   - **Data Access:** Current tab URL (not stored or transmitted)
   - **Can Be Revoked:** Yes, anytime

4. **`notifications`** (Optional)
   - **Purpose:** Show notifications for database updates
   - **Requested When:** You enable update notifications
   - **Can Be Revoked:** Yes, anytime

5. **`downloads`** (Optional)
   - **Purpose:** Export flag reports as JSON/CSV
   - **Requested When:** You export data
   - **Can Be Revoked:** Yes, anytime

### Permission Transparency

FireFlag implements **granular permission requests**:
- Permissions are requested **only when needed**
- Each permission shows **what it enables**
- You can **review and revoke** permissions anytime
- The extension explains **why each permission is requested**

## Data Sharing and Third Parties

### No Data Sharing

FireFlag does **NOT** share your data with:
- ❌ Third-party services
- ❌ Analytics providers
- ❌ Advertising networks
- ❌ Data brokers
- ❌ The developer (us)
- ❌ Mozilla (except standard extension metadata)

### Third-Party Services Used

FireFlag interacts with these external services:

1. **GitHub** (for database updates)
   - **URL:** https://api.github.com
   - **Data Sent:** Standard HTTP headers
   - **Privacy Policy:** https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement
   - **Purpose:** Check for database updates
   - **Opt-out:** Disable auto-updates in settings

2. **Mozilla Add-ons** (for extension updates)
   - **URL:** https://addons.mozilla.org
   - **Data Sent:** Extension ID, version number
   - **Privacy Policy:** https://www.mozilla.org/privacy/firefox/
   - **Purpose:** Update the extension itself
   - **Opt-out:** Disable auto-updates in Firefox settings

**Note:** FireFlag does not control these third-party services. Please review their privacy policies.

## Data Retention

### Local Data

- **Stored:** Until you uninstall the extension or clear Firefox data
- **Deletion:** Automatically deleted when extension is removed
- **Manual Deletion:** Settings → Clear All Data button

### Exported Data

When you export flag reports:
- **Stored:** On your device in Downloads folder
- **Retention:** Your responsibility to delete
- **Content:** Flag states, change history, performance metrics (no personal data)

## Your Privacy Rights

### Access and Control

You have complete control over your data:

1. **View Data**
   - Open DevTools → Application → Storage → Extension Storage
   - View all stored flag states and preferences

2. **Export Data**
   - Sidebar → Export tab → Download as JSON/CSV
   - Portable format you can review

3. **Delete Data**
   - Per-flag: Click "Reset to Default"
   - All data: Settings → Advanced → Clear All Data
   - Complete removal: Uninstall extension

4. **Manage Permissions**
   - Firefox → Add-ons → FireFlag → Permissions
   - Revoke any optional permission

### No Account Required

FireFlag does **NOT** require:
- Account creation
- Registration
- Login credentials
- Email address
- Personal information

## GDPR Compliance (EU Users)

FireFlag complies with GDPR because:

1. **No Personal Data Processing**
   - All data stored locally
   - No profiling or automated decision-making
   - No data transfer outside EU (all local)

2. **Data Minimization**
   - Only essential data stored
   - No excessive data collection

3. **User Control**
   - Full access to your data
   - Easy export and deletion
   - Transparent processing

4. **No Consent Required**
   - GDPR requires consent for personal data processing
   - FireFlag doesn't process personal data
   - All storage is local and user-initiated

### Your GDPR Rights

Even though FireFlag doesn't collect personal data, you have these rights:

- ✅ **Right to Access:** View all data in browser storage
- ✅ **Right to Rectification:** Edit flag states anytime
- ✅ **Right to Erasure:** Delete all data or uninstall
- ✅ **Right to Data Portability:** Export as JSON/CSV
- ✅ **Right to Object:** Disable features or uninstall

## CCPA Compliance (California Users)

FireFlag complies with CCPA:

1. **No Sale of Personal Information**
   - FireFlag does **NOT** sell personal information
   - We don't collect personal information to sell

2. **No Sharing with Third Parties**
   - All data stays on your device
   - No third-party data sharing

3. **Opt-Out Rights**
   - Not applicable (no data collection to opt out of)
   - Can disable all network activity (auto-updates)

## Children's Privacy

FireFlag does not:
- Target children under 13
- Knowingly collect data from children
- Require age verification (no accounts)

FireFlag is safe for all ages because it collects no personal data.

## Data Security

### Local Storage Security

- **Encryption:** Firefox encrypts browser.storage data
- **Access Control:** Only FireFlag can access its storage
- **Isolation:** Separate from other extensions and websites

### Code Security

- **Open Source:** All code publicly auditable on GitHub
- **Security Scanning:** Automated security analysis (Svalin, Vordr, Selur)
- **No Minification:** Source code is readable
- **Reproducible Builds:** Verifiable build process

### No Server-Side Risk

- **No Backend:** No servers to hack
- **No Database:** No central storage to breach
- **No Cloud:** Nothing stored in the cloud
- **Local Only:** All data on your device

## Changes to Privacy Policy

### Notification of Changes

We will notify you of privacy policy changes by:
1. Updating the "Last Updated" date at the top
2. Publishing changes on GitHub
3. Including in extension update notes (for major changes)

### Material Changes

If we make material changes (e.g., start collecting data):
- We will request new permissions
- Firefox will prompt you to approve
- You can decline and continue using the old version

### Version History

Privacy policy versions are tracked on GitHub:
https://github.com/hyperpolymath/fireflag/commits/main/PRIVACY.md

## Open Source Transparency

FireFlag is fully open source:

- **Source Code:** https://github.com/hyperpolymath/fireflag
- **License:** MPL-2.0 (Mozilla Public License 2.0)
- **Auditing:** Anyone can review the code
- **Issues:** Report privacy concerns on GitHub

### Build Reproducibility

FireFlag uses reproducible builds:
- Anyone can verify the published extension matches the source code
- Build instructions in repository
- No hidden code or telemetry

## Contact and Questions

### Privacy Questions

For privacy-related questions:
- **Email:** j.d.a.jewell@open.ac.uk
- **GitHub Issues:** https://github.com/hyperpolymath/fireflag/issues
- **Response Time:** Within 7 days

### Data Requests

To exercise your privacy rights (though not needed for local data):
- **Access:** Use DevTools or export feature
- **Deletion:** Use "Clear All Data" or uninstall
- **Questions:** Email above address

### Security Vulnerabilities

To report security issues:
- **Email:** j.d.a.jewell@open.ac.uk (GPG key available on request)
- **GitHub:** Security tab (private disclosure)
- **Bug Bounty:** None currently

## Mozilla Add-ons Privacy

FireFlag is distributed through Mozilla Add-ons:

- **Mozilla Privacy Policy:** https://www.mozilla.org/privacy/firefox/
- **Add-ons Policy:** https://extensionworkshop.com/documentation/publish/add-on-policies/
- **Data Collected by Mozilla:** Extension ID, download count, ratings (not linked to users)

Mozilla may collect:
- Extension installation/update events
- Crash reports (if Firefox crash reporting enabled)
- General usage statistics (opt-in)

**This is separate from FireFlag** - we don't receive this data.

## Commitment to Privacy

**Our Promise:**

1. We will **never** collect personal data
2. We will **never** sell or share your data
3. We will **never** add analytics or tracking
4. We will **always** store data locally
5. We will **always** be transparent about changes

**If we ever violate these promises:**
- We will immediately notify all users
- We will request new permissions
- You can decline and keep using the old version
- You can report violations to Mozilla

## Legal Basis (GDPR)

FireFlag's data processing is based on:
- **Legitimate Interest:** Provide extension functionality
- **User Consent:** Explicit permission grants for optional features
- **Contract Performance:** Not applicable (no terms of service)

Since all processing is local and user-initiated, no additional legal basis is required.

## International Data Transfers

**Not applicable** - all data stored locally on your device.

## Automated Decision-Making

FireFlag does **NOT** use:
- Profiling
- Automated decision-making
- Machine learning on user data
- Behavioral analysis

## License

This privacy policy is licensed under CC BY-SA 4.0:
https://creativecommons.org/licenses/by-sa/4.0/

You may share and adapt this policy with attribution.

---

**Last Updated:** February 4, 2026
**Effective Date:** February 4, 2026
**Version:** 1.0.0

**FireFlag Privacy Policy**
Copyright (C) 2026 Jonathan D.A. Jewell
Licensed under CC BY-SA 4.0
