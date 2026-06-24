<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# FireFlag - Mozilla Add-ons Store Listing

## Extension Name
**FireFlag**

## Tagline (64 characters max)
Safe Firefox/Gecko flag management for users and developers

## Summary (250 characters max)
Safely manage Firefox's 100+ about:config flags with built-in safety levels, detailed documentation, and rollback protection. Privacy-first: all data stored locally, no tracking, open source.

## Description (Full)

### Safe Firefox Flag Management

FireFlag makes Firefox's powerful about:config flags accessible and safe for everyone. Whether you're a privacy enthusiast, power user, or developer, FireFlag helps you customize Firefox without breaking your browser.

### 🛡️ Safety First

Every flag includes a safety rating:
- **Safe** - No known issues, safe for all users
- **Moderate** - Some caveats, read documentation first
- **Advanced** - For experienced users only
- **Experimental** - May cause instability

### 📊 Comprehensive Database

**105+ Firefox flags** across 8 categories:
- Privacy (27 flags) - Tracking protection, fingerprinting, telemetry
- Performance (7 flags) - WebRender, cache, GPU acceleration
- Network (7 flags) - HTTP/3, DNS-over-HTTPS, proxy settings
- UI (15 flags) - Tabs, downloads, interface customization
- Developer (7 flags) - DevTools, WebDriver, debugging
- Media (7 flags) - WebRTC, autoplay, codecs, DRM
- Accessibility (4 flags) - Motion, speech, assistive technologies
- Experimental (13 flags) - WebAssembly, WebGPU, WebXR, PWA

### ✨ Key Features

**Browser Action Popup**
- Quick access to common flags
- Filter by category and safety level
- Search by name or keyword
- Apply changes instantly

**Sidebar Panel**
- Detailed flag documentation
- Before/after value tracking
- Change history with timestamps
- Export reports (JSON/CSV)

**Options Page**
- Granular permission control
- Auto-update preferences
- Advanced settings
- Clear all data option

**DevTools Integration**
- Performance metrics for active flags
- Flag impact analysis
- Real-time monitoring

### 🔒 Privacy Guarantee

**Zero Data Collection**
- No analytics or telemetry
- No tracking or profiling
- All data stored locally in browser.storage.local
- No servers, no cloud sync
- No personal information collected

**Network Activity**
- Weekly database updates from GitHub (optional, can be disabled)
- Extension updates from Mozilla Add-ons (standard Firefox behavior)
- **Nothing else**

### 🔐 Security & Transparency

- **Open Source** - Fully auditable code on GitHub
- **Reproducible Builds** - Verifiable binaries with SLSA provenance
- **Formal Verification** - Idris2 safety proofs for critical code paths
- **Weekly Security Scans** - Automated vulnerability detection
- **GDPR/CCPA Compliant** - No personal data processing

### 🎯 Who Is This For?

**Privacy Enthusiasts**
- Disable telemetry and tracking
- Control fingerprinting defenses
- Manage privacy-critical flags safely

**Power Users**
- Customize Firefox beyond Settings UI
- Optimize performance for your workflow
- Enable experimental features

**Developers**
- Test WebAssembly, WebGPU, and other experimental APIs
- Configure DevTools behavior
- Debug browser issues

### 📦 What's Included

- 105-flag comprehensive database with documentation
- Safety levels for every flag
- Change tracking and rollback
- Export functionality (JSON/CSV)
- Weekly automatic database updates (optional)
- DevTools panel for performance monitoring
- Granular permission system

### ⚙️ Permissions Explained

**Required**
- `storage` - Store flag states and preferences locally

**Optional (requested only when needed)**
- `browserSettings` - Modify browser flags (required for core functionality)
- `privacy` - Modify privacy-related flags
- `tabs` - Show active flags in DevTools panel
- `notifications` - Database update notifications
- `downloads` - Export reports to disk

All optional permissions can be granted/revoked anytime through Firefox's permission manager.

### 🚀 Getting Started

1. Install FireFlag
2. Click the extension icon in your toolbar
3. Browse flags by category or use search
4. Read the documentation and safety level
5. Grant permissions only for flags you want to modify
6. Apply changes and track results

### 📚 Documentation

- Full documentation: https://github.com/hyperpolymath/fireflag
- Privacy policy: https://github.com/hyperpolymath/fireflag/blob/main/PRIVACY.md
- Report issues: https://github.com/hyperpolymath/fireflag/issues
- Contribute flags: https://github.com/hyperpolymath/fireflag/blob/main/CONTRIBUTING-FLAGS.md

### 🆘 Support

- Email: j.d.a.jewell@open.ac.uk
- GitHub Issues: https://github.com/hyperpolymath/fireflag/issues
- Response time: Within 7 days

### 📜 License

Mozilla Public License 2.0 (MPL-2.0)

---

**FireFlag respects your privacy and puts you in control of your browser.**

## Version Notes (v0.1.0)

### Initial Release Features

**Database**
- 105 Firefox flags with comprehensive documentation
- Safety levels: Safe, Moderate, Advanced, Experimental
- 8 categories: Privacy, Performance, Network, UI, Developer, Media, Accessibility, Experimental
- Version range support (Firefox 109+)
- Effect tracking and permission requirements

**User Interface**
- Browser action popup for quick access
- Sidebar panel with detailed tracking
- Options page for settings
- DevTools panel for performance monitoring

**Core Features**
- Flag search and filtering
- Before/after value tracking
- Change history with timestamps
- Export functionality (JSON/CSV)
- Automated database updates (weekly, optional)
- Granular permission system

**Privacy & Security**
- Zero data collection
- Local-only storage (browser.storage.local)
- No analytics or telemetry
- Open source and auditable
- Formal verification for safety-critical code

### Known Limitations

- Pale Moon compatibility not yet tested (different Gecko version)
- Some experimental flags may require Firefox Nightly
- Database updates require internet connection (can be disabled)

### Planned Features

- Flag recommendations based on usage patterns
- Import/export profiles
- Multi-profile support
- Advanced filtering (by version, impact, dependencies)

## Technical Details

**Minimum Firefox Version:** 109.0

**Manifest Version:** 3

**Extension ID:** fireflag@hyperpolymath.org

**Package Size:** 119 KB

**Languages:** JavaScript (UI), Idris2 (proofs), ReScript (types)

**Build System:** web-ext 9.2.0, containerized with Guix/Chainguard

**License:** MPL-2.0

**Homepage:** https://github.com/hyperpolymath/fireflag

**Source Code:** https://github.com/hyperpolymath/fireflag

## Categories

**Primary:** Privacy & Security

**Secondary:**
- Developer Tools
- Other
- Appearance

## Tags

firefox, flags, about:config, privacy, security, performance, customization, power-user, developer-tools, webassembly, webgpu, experimental-features, tracking-protection, fingerprinting, telemetry, open-source, reproducible-builds

## Screenshots

### Required Screenshots (7 total)

1. **Popup Overview (400x600)**
   - File: `.screenshots/mockups/01-popup-overview.png`
   - Caption: "Browser action popup with category filters and safety levels"

2. **Flag Details (400x600)**
   - File: `.screenshots/mockups/02-popup-flag-detail.png`
   - Caption: "Detailed flag information with documentation and safety warnings"

3. **Sidebar Flags Tab (350x700)**
   - File: `.screenshots/mockups/03-sidebar-flags.png`
   - Caption: "Sidebar panel showing active flags with before/after tracking"

4. **Sidebar History Tab (350x700)**
   - File: `.screenshots/mockups/04-sidebar-history.png`
   - Caption: "Change history with timestamps and rollback capability"

5. **Options Page (1280x800)**
   - File: `.screenshots/mockups/05-options.png`
   - Caption: "Settings page with granular permission control and preferences"

6. **DevTools Panel (1280x400)**
   - File: `.screenshots/mockups/06-devtools.png`
   - Caption: "DevTools integration showing flag performance impact"

7. **Permission Request (400x300)**
   - File: `.screenshots/mockups/07-permission-dialog.png`
   - Caption: "Granular permission requests - only when needed"

### Screenshot Upload Notes

- All mockups are SVG placeholders - replace with real screenshots before submission
- Use `.screenshots/capture-screenshots.js` for automated capture
- Or follow `.screenshots/MANUAL-CAPTURE.md` for manual capture
- Optimize with: `just optimize-screenshots`

## Developer Comments (Private - Mozilla Reviewers Only)

### Build & Verification

This extension is built using a reproducible containerized build system with:
- **Guix** for dependency management
- **Chainguard** base images for security
- **SLSA Level 3** provenance attestations

To verify the build:
```bash
# Check SHA256 checksum
echo "7275dac7cee9ab8ed5a02dd63b5ba82ac6566e96c60acca16871ccb16cfe8cce  fireflag-0.1.0.xpi" | sha256sum -c

# Rebuild from source (requires Guix/Docker)
git clone https://github.com/hyperpolymath/fireflag
cd fireflag
just container-build-full
```

### Security Scanning

This extension undergoes weekly automated security scans:
- **CodeQL** (code analysis)
- **TruffleHog** (secret detection)
- **Svalin** (neurosymbolic security analysis)
- **Selur** (secrets detection)
- **OpenSSF Scorecard** (supply chain security)

Latest security report: https://github.com/hyperpolymath/fireflag/security

### Permissions Justification

**storage (required)**
- Store flag states, preferences, and change history locally
- No remote servers, all data stays on user's device

**browserSettings (optional)**
- Modify browser flags (core functionality)
- Requested only when user attempts to change a flag

**privacy (optional)**
- Modify privacy-related flags (subset of browserSettings)
- Requested only for privacy category flags

**tabs (optional)**
- Show active flags in current tab (DevTools panel)
- Requested only if user opens DevTools panel

**notifications (optional)**
- Notify about database updates
- Requested only if auto-updates enabled

**downloads (optional)**
- Export change history and reports
- Requested only when user clicks "Export" button

### Data Storage

All data stored in `browser.storage.local`:
```javascript
{
  "flags": {
    "flag.name": {
      "before": "value",
      "after": "new_value",
      "timestamp": "ISO8601",
      "reason": "user note"
    }
  },
  "preferences": {
    "autoUpdate": true,
    "updateFrequency": "weekly",
    "showNotifications": false
  },
  "database": {
    "version": "1.0.0",
    "lastUpdate": "ISO8601",
    "flags": [ /* 105 flag definitions */ ]
  }
}
```

### Network Requests

**Weekly database updates (optional, user-controlled):**
```javascript
fetch('https://api.github.com/repos/hyperpolymath/fireflag/contents/extension/data/flags-database.json')
```

**Extension updates:**
- Handled by Firefox's built-in update mechanism
- No custom update code in extension

**No other network activity**

### Testing

Tested on:
- Firefox 109+ (minimum version)
- Firefox Nightly
- Librewolf
- Waterfox

Platform support:
- Linux (primary development)
- Windows (tested)
- macOS (tested)

### Source Code Structure

```
extension/
├── manifest.json           # Manifest V3 configuration
├── background/             # Service worker
├── popup/                  # Browser action UI
├── sidebar/                # Sidebar panel
├── options/                # Settings page
├── devtools/               # DevTools integration
├── data/
│   ├── flags-database-expanded.json  # 105 flags
│   └── flags-schema.json             # JSON schema
├── lib/
│   ├── idris/              # Safety proofs
│   └── rescript/           # Type definitions
└── icons/                  # Extension icons
```

### Contact

Developer: Jonathan D.A. Jewell
Email: j.d.a.jewell@open.ac.uk
GitHub: https://github.com/hyperpolymath

---

**Ready for review. All Mozilla Add-ons policies followed.**
