<!--
SPDX-License-Identifier: CC-BY-SA-4.0
SPDX-FileCopyrightText: 2025-2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->

[![License: MPL-2.0](https://img.shields.io/badge/License-MPL_2.0--2.0-blue.svg)](https://mozilla.org/MPL/2.0/)
[![RSR Certified](https://img.shields.io/badge/RSR-Certified-gold)](https://github.com/hyperpolymath/rhodium-standard-repositories)
![Status](https://img.shields.io/badge/Status-Ready%20for%20Submission-brightgreen)
![Version](https://img.shields.io/badge/Version-0.1.0-blue)

**Safe Firefox/Gecko flag management for users and developers**

Jonathan D.A. Jewell \<[j.d.a.jewell@open.ac](j.d.a.jewell@open.ac).uk\>
:toc: macro :toclevels: 3 :icons: font :source-highlighter: rouge
:experimental: :url-github: <https://github.com/hyperpolymath/fireflag>
:url-gitlab: <https://gitlab.com/hyperpolymath/fireflag> :url-bitbucket:
<https://bitbucket.org/hyperpolymath/fireflag>

<div id="toc">

</div>

# Overview

FireFlag is a Firefox extension that makes about:config flags accessible
and safe for everyone. Manage 105+ Firefox flags with built-in safety
ratings, detailed documentation, and rollback protection.

**Key Features:**

- 🛡️ **Safety First** - Every flag rated: Safe, Moderate, Advanced, or
  Experimental

- 📊 **Comprehensive Database** - 105 flags across 8 categories

- 🔒 **Privacy-First** - Zero data collection, all data stored locally

- ✅ **Change Tracking** - Before/after values with timestamps

- 📤 **Export Capability** - JSON/CSV export for backup

- 🔧 **DevTools Integration** - Performance impact analysis

- 🔐 **Granular Permissions** - Only request what you need

# Current Status

**Version:** 0.1.0\
**Phase:** Ready for Mozilla Add-ons Submission\
**Completion:** 99%

| Component | Status | Details |
|----|----|----|
| **Extension Package** | ✅ Complete | fireflag-0.1.0.xpi (120 KB, 46 files) |
| **Flag Database** | ✅ Complete | 105 flags with safety levels, documentation |
| **UI Components** | ✅ Complete | Popup, sidebar, options, DevTools panel |
| **Documentation** | ✅ Complete | Privacy policy, submission docs, test reports |
| **Validation** | ✅ Complete | 0 errors, 8/8 automated tests passing |
| **Screenshots** | ✅ Complete | 7 mockups ready for submission |
| **Signing** | ⏳ Pending | Awaiting Mozilla API credentials |
| **Submission** | ⏳ Pending | Ready to submit once signed |

# Installation

## From Source (Development)

```bash
# Clone repository
git clone https://github.com/hyperpolymath/fireflag
cd fireflag

# Install dependencies (Deno required)
# No npm install needed - Deno handles dependencies

# Build extension
just build-ext

# Run in Firefox for testing
just run-ext

# Or load manually
# Firefox → about:debugging → Load Temporary Add-on
# Select: extension/web-ext-artifacts/fireflag-0.1.0.xpi
```

## From Mozilla Add-ons (Coming Soon)

Once approved by Mozilla:

```bash
# Install from addons.mozilla.org
# Visit: https://addons.mozilla.org/firefox/addon/fireflag/
```

# Usage

## Browser Action Popup

Click the FireFlag icon in the toolbar:

- **Search flags** - Type to filter by name or keyword

- **Filter by category** - Privacy, Performance, Network, UI, Developer,
  Media, Accessibility, Experimental

- **Filter by safety** - Safe, Moderate, Advanced, Experimental

- **View details** - Click a flag to see full documentation

- **Apply changes** - Toggle or modify flag values (requires
  permissions)

## Sidebar Panel

Open via View → Sidebars → FireFlag (or
<span class="kbd">**Ctrl**</span>+<span class="kbd">**Shift**</span>+<span class="kbd">**Y**</span>):

- **Flags tab** - View all modified flags with before/after values

- **History tab** - Chronological change history with timestamps

- **Export** - Download as JSON or CSV

## Options Page

Right-click FireFlag icon → Manage Extension → Options:

- **Auto-update** - Enable/disable weekly database updates

- **Notifications** - Toggle update notifications

- **Permissions** - Manage granted permissions

- **Clear data** - Reset all changes

## DevTools Panel

Press <span class="kbd">**F12**</span> → FireFlag tab:

- **Active flags** - Flags affecting current page

- **Performance impact** - Resource usage indicators

- **Recommendations** - Suggested flag changes

# Flag Database

**Total Flags:** 105 across 8 categories

| Category | Count | Examples |
|----|----|----|
| **Privacy** | 27 | resistFingerprinting, trackingprotection, telemetry |
| **UI** | 15 | Tabs, downloads, appearance customization |
| **Experimental** | 13 | WebAssembly, WebGPU, WebXR, PWA features |
| **Performance** | 7 | WebRender, cache, GPU acceleration |
| **Network** | 7 | HTTP/3, DNS-over-HTTPS, proxy settings |
| **Developer** | 7 | DevTools, WebDriver, debugging |
| **Media** | 7 | WebRTC, autoplay, codecs, DRM |
| **Accessibility** | 4 | Motion, speech, assistive technologies |

**Safety Levels:**

- **Safe** - No known issues, recommended for all users

- **Moderate** - Some caveats, read documentation first

- **Advanced** - For experienced users only, may affect stability

- **Experimental** - Unstable, may cause crashes or data loss

# Privacy & Security

**Zero Data Collection:**

- ❌ No analytics or telemetry

- ❌ No tracking or profiling

- ❌ No personal information collected

- ❌ No remote servers (except optional database updates)

**Local Storage Only:**

- ✅ All data in `browser.storage.local`

- ✅ Stays on your device

- ✅ Fully exportable

- ✅ Completely deletable

**Network Activity:**

- Weekly database update checks (optional, can be disabled)

- Extension updates from Mozilla Add-ons (standard Firefox behavior)

- **Nothing else**

**Security:**

- ✅ CodeQL static analysis

- ✅ TruffleHog secret detection

- ✅ Neurosymbolic security scanning (svalin)

- ✅ SLSA Level 3 provenance (reproducible builds)

See <a href="PRIVACY.md" class="md">PRIVACY</a> for full privacy policy.

# Development

## Prerequisites

- **Deno** 1.40+ (package management and runtime)

- **Firefox** 112+ (minimum version for extension)

- **ImageMagick** (for screenshot generation)

- **Guix** or **Nix** (optional, for containerized builds)

## Quick Start

```bash
# Install Justfile runner
# Fedora: dnf install just
# Arch: pacman -S just
# macOS: brew install just

# Build extension
just build-ext

# Run in Firefox
just run-ext

# Lint extension
just lint-ext

# Run all tests
just test
```

## Project Structure

    fireflag/
    ├── extension/              # Extension source
    │   ├── manifest.json       # Manifest V3 config
    │   ├── background/         # Service worker
    │   ├── popup/              # Browser action UI
    │   ├── sidebar/            # Sidebar panel
    │   ├── options/            # Settings page
    │   ├── devtools/           # DevTools integration
    │   ├── data/               # Flag database (105 flags)
    │   ├── icons/              # Extension icons
    │   └── lib/
    │       ├── idris/          # Safety proofs (Idris2)
    │       └── rescript/       # Type definitions (ReScript)
    ├── .containerization/      # Docker + Guix builds
    ├── .screenshots/           # Screenshot generation
    ├── scripts/                # Build and signing scripts
    ├── .machine_readable/6a2/STATE.a2ml               # Project state tracking
    ├── .machine_readable/6a2/ECOSYSTEM.a2ml           # Ecosystem relationships
    └── .machine_readable/6a2/META.a2ml                # Architecture decisions

## Build System

**Simple Build:**

```bash
just build-ext  # Uses web-ext
```

**Full Build Pipeline:**

```bash
just full-build
# 1. Check Idris2 proofs
# 2. Build ReScript (if applicable)
# 3. Generate icons
# 4. Lint extension
# 5. Run security scans
# 6. Build .xpi package
```

**Containerized Build:**

```bash
just container-build-full
# Reproducible build with Guix + Chainguard
# Generates SLSA provenance
# SBOM (CycloneDX)
```

## Signing & Submission

```bash
# Get Mozilla API credentials
# https://addons.mozilla.org/developers/addon/api/key/

# Sign extension
./scripts/sign-extension.sh \
  --api-key YOUR_KEY \
  --api-secret YOUR_SECRET \
  --channel listed

# Signed .xpi will be created in extension/web-ext-artifacts/
```

See
<a href="SUBMISSION-CHECKLIST.md" class="md">SUBMISSION-CHECKLIST</a>
for complete submission guide.

# Contributing

See <a href="CONTRIBUTING.md" class="md">CONTRIBUTING</a> for general
contribution guidelines.

See <a href="CONTRIBUTING-FLAGS.md" class="md">CONTRIBUTING-FLAGS</a>
for flag database contributions.

**Areas for Contribution:**

- **Flag Database** - Add missing flags, improve documentation

- **Translations** - i18n support (planned for v0.2.0)

- **Testing** - Browser compatibility testing (Librewolf, Waterfox, Pale
  Moon)

- **UI/UX** - Design improvements

- **Documentation** - User guides, tutorials, videos

# Roadmap

See <a href="ROADMAP.adoc" class="adoc">ROADMAP</a> for detailed
roadmap.

**v0.1.0 (Current):**

- ✅ 105-flag database with safety levels

- ✅ Browser action popup

- ✅ Sidebar panel with tracking

- ✅ Options page

- ✅ DevTools integration

- ✅ Privacy policy & submission docs

- ⏳ Mozilla Add-ons submission

**v0.2.0 (Planned):**

- Android support (Firefox for Android)

- Flag recommendations based on usage

- Import/export profiles

- Multi-profile support

- Advanced filtering (by version, impact, dependencies)

- i18n support

**v1.0.0 (Future):**

- WASM optimizations for flag evaluation

- ReScript compilation for type safety

- Advanced permission management

- Flag impact analysis

- Automated testing suite

# License

**Mozilla Public License 2.0 (MPL-2.0)**

FireFlag is open source software licensed under MPL-2.0. This was chosen
for compatibility with Mozilla Add-ons ecosystem requirements.

**Preferred License:** MPL-2.0 (MPL-2.0)\
**Fallback License:** MPL-2.0 (for Chrome/Firefox extension stores)

See [LICENSE](LICENSE) for full text.

# Links

- **GitHub:** {url-github}

- **Issues:** {url-github}/issues

- **Discussions:** {url-github}/discussions

- **GitLab Mirror:** {url-gitlab}

- **Bitbucket Mirror:** {url-bitbucket}

# Acknowledgments

Built with:

- **ReScript** - Type-safe JavaScript compilation

- **Idris2** - Formal verification and safety proofs

- **Guix** - Reproducible build environment

- **Chainguard** - Minimal security-focused containers

- **web-ext** - Mozilla’s official extension build tool

Inspired by the need for safer about:config management in Firefox and
Gecko-based browsers.

------------------------------------------------------------------------

**FireFlag** - Safe Firefox flag management for everyone.

# Architecture

See <a href="TOPOLOGY.md" class="md">TOPOLOGY</a> for a visual
architecture map and completion dashboard.
