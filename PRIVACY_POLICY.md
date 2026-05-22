# Privacy Policy for FireFlag

**Last Updated:** February 4, 2026

## Overview

FireFlag is committed to protecting your privacy. This privacy policy explains our data practices for the FireFlag browser extension.

## Data Collection

**FireFlag collects ZERO personal data.**

Specifically, FireFlag does NOT collect, store, transmit, or process:
- Personal information
- Browsing history
- Website content
- Authentication credentials
- Location data
- Search terms
- Bookmarks
- Cookies
- Usage analytics
- Telemetry data
- Error reports
- Any other personal or identifiable information

## Data Storage

All FireFlag data is stored **locally on your device** using the browser's built-in storage API (`browser.storage.local`).

**What is stored locally:**
- Flag definitions you create or import
- Flag safety classifications
- Flag usage history (timestamps only)
- Extension preferences and settings

**This data:**
- Never leaves your device
- Is not transmitted to any server
- Is not shared with any third party
- Is not accessible to the extension developer
- Is deleted when you uninstall the extension

## Permissions Explained

FireFlag requests the following permissions:

### Required Permissions

**`storage`**
- **Purpose:** Store flag data and settings locally on your device
- **Data stored:** Flag definitions, classifications, preferences
- **Location:** Browser local storage (never transmitted)

### Optional Permissions

These permissions are **optional** and only requested when you explicitly use certain features:

**`browserSettings`**
- **Purpose:** Allow you to view and modify browser experimental features
- **Usage:** Only when you explicitly request to view browser flags
- **Data:** No data is collected; this permission only allows reading/writing browser settings

**`privacy`**
- **Purpose:** Access privacy-related browser settings
- **Usage:** Only when viewing privacy-related feature flags
- **Data:** No data is collected

**`tabs`**
- **Purpose:** Track which tab is active (for DevTools integration)
- **Usage:** Only to display flag information in the correct DevTools panel
- **Data:** No tab content or URLs are accessed or stored

**`notifications`**
- **Purpose:** Show alerts when potentially dangerous flags are detected
- **Usage:** Optional feature you can disable in settings
- **Data:** No notification content is transmitted or stored externally

**`downloads`**
- **Purpose:** Export flag data to JSON/CSV files
- **Usage:** Only when you explicitly click "Export"
- **Data:** Exported files are saved to your device; no data is transmitted

## Network Activity

FireFlag makes **ZERO network requests**.

- No connections to external servers
- No API calls
- No telemetry or analytics endpoints
- No update checks (updates via Mozilla Add-ons only)
- Works completely offline

## Third-Party Services

FireFlag does **NOT** use any third-party services, including:
- Analytics services (e.g., Google Analytics)
- Error tracking (e.g., Sentry)
- Content Delivery Networks (CDNs)
- Ad networks
- Social media integrations
- Any other external services

All code runs locally in your browser. All dependencies are bundled with the extension.

## Children's Privacy

FireFlag does not knowingly collect data from anyone, including children under 13. Since we collect zero data, there is no age restriction or concern.

## Data Retention

Since FireFlag does not collect any data:
- There is no data retention policy
- There is no data to delete from servers
- Uninstalling the extension removes all local data

To manually clear FireFlag data while keeping the extension installed:
1. Open the extension options page
2. Click "Reset to Defaults"
3. Or use Firefox's built-in "Clear Site Data" feature

## Your Rights

Since FireFlag collects no personal data:
- There is no data to access, rectify, or delete from our systems
- There is no data to export or transfer
- There is no data to object to processing of

All data is stored locally on your device and is under your control.

## Changes to This Policy

We may update this privacy policy to reflect changes in the extension or legal requirements. Changes will be posted at:
- https://github.com/hyperpolymath/fireflag/blob/main/PRIVACY_POLICY.md

Material changes will be announced in the extension's release notes.

## Compliance

FireFlag complies with:
- **GDPR** (EU General Data Protection Regulation)
- **CCPA** (California Consumer Privacy Act)
- **Mozilla Add-on Policies**
- **Firefox Data Collection Requirements**

Since we collect zero data, compliance is straightforward: no data collection means no privacy concerns.

## Open Source

FireFlag is open source software. You can audit our privacy claims by reviewing the source code:
- **Repository:** https://github.com/hyperpolymath/fireflag
- **License:** MPL-2.0 (Palimpsest Meta-Project License)

## Contact

For privacy-related questions or concerns:
- **Email:** j.d.a.jewell@open.ac.uk
- **GitHub Issues:** https://github.com/hyperpolymath/fireflag/issues

## Transparency

FireFlag's privacy commitment is backed by:
- **No server infrastructure:** We don't run servers, so there's nowhere for your data to go
- **Open source code:** Anyone can verify our privacy claims
- **Formal verification:** Core safety components are mathematically proven
- **Mozilla review:** Extension is reviewed by Mozilla before publication

---

**Summary:** FireFlag collects ZERO data. Everything stays on your device. Your privacy is guaranteed by design, not just by policy.
