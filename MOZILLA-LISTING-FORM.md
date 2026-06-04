<!--
SPDX-License-Identifier: MPL-2.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# Mozilla Add-ons Listing Form - FireFlag

Use these values when filling out the Mozilla Add-ons submission form:

## Basic Information

**Name:**
```
FireFlag
```

**Summary (250 characters max):**
```
Feature flag management for developers. Track, validate, and analyze feature flags with safety classification, visual DevTools, and export capabilities.
```

**Description (Markdown supported):**
```markdown
## What is FireFlag?

FireFlag is a developer tool for managing feature flags safely and efficiently. Built with formal verification and modern web standards.

### Features

**🎯 Flag Management**
- Visual popup interface for quick flag overview
- Sidebar analytics with timeline and statistics
- Safety classification (Safe, Caution, Dangerous, Critical)

**🔧 Developer Tools**
- Integrated DevTools panel
- Flag validation and safety checking
- Export to JSON/CSV formats
- Real-time flag tracking

**🛡️ Safety First**
- Built with Idris2 formally verified components
- ReScript type-safety
- Validated against unsafe patterns
- Comprehensive flag database

**📊 Analytics**
- Flag usage tracking
- Timeline visualization
- Impact analysis
- Trend detection

### Why FireFlag?

Feature flags can introduce bugs and technical debt. FireFlag helps developers:
- **Avoid dangerous flag combinations**
- **Track flag lifecycle**
- **Identify unused flags**
- **Export for documentation**

### Technical Details

- Manifest V3 compliant
- Works on Firefox 142+ (including Android)
- Zero external dependencies
- Privacy-focused (all data stays local)

### Support

- GitHub: https://github.com/hyperpolymath/fireflag
- Issues: https://github.com/hyperpolymath/fireflag/issues
- License: MPL-2.0
```

## Categories

Select these categories:
- ✅ **Developer Tools**
- ✅ **Web Development**

## Tags (Keywords)

```
feature-flags
developer-tools
devtools
flag-management
safety-analysis
analytics
development
```

## Support Information

**Support Email:**
```
j.d.a.jewell@open.ac.uk
```

**Support URL:**
```
https://github.com/hyperpolymath/fireflag/issues
```

**Homepage:**
```
https://github.com/hyperpolymath/fireflag
```

## Privacy Policy

**Does this extension collect user data?**
```
No
```

**Privacy Policy URL (optional):**
```
Not required (no data collection)
```

## License

**License:**
```
Custom License
```

**License Name:**
```
Palimpsest Meta-Project License 1.0 or later (MPL-2.0)
```

**License URL:**
```
https://github.com/hyperpolymath/palimpsest-license
```

**Note:** If Mozilla requires an OSI-approved license, use MPL-2.0 as fallback:
```
Mozilla Public License 2.0 (MPL-2.0)
```

## Screenshots

Upload these screenshots (if you have them):
1. Popup interface showing flag list
2. Sidebar analytics view
3. DevTools panel
4. Options page

**Screenshot locations:** `/var$REPOS_DIR/fireflag/screenshots/` (if they exist)

## Version Notes (for reviewers)

**Version 0.1.0 - Initial Release:**
```
First public release of FireFlag.

Features:
- Flag database with 50+ common feature flags
- Safety classification system
- Visual popup and sidebar interfaces
- Integrated DevTools panel
- Export capabilities (JSON/CSV)
- Formally verified core components

Technical:
- Manifest V3 compliant
- Firefox 142+ (desktop and Android)
- Built with ReScript and Idris2
- All data stored locally
- No external API calls
- No tracking or analytics

Security:
- XSS-safe HTML rendering
- Content Security Policy compliant
- No eval() or dynamic code execution
- All dependencies bundled locally
```

## Additional Notes for Reviewers

```
This extension uses formally verified Idris2 libraries for safety guarantees.
The Idris2 code is compiled to JavaScript and included in lib/idris/*.

The extension does not make any external network requests.
All flag data is stored locally using browser.storage.local API.

Source code repository: https://github.com/hyperpolymath/fireflag
```

## After Submission

Mozilla will:
1. Automatically validate the extension (you already passed this with 1 error, 1 warning)
2. Queue for manual review (typically 1-2 weeks)
3. Email you with approval or requested changes

**Expected result:** Approval with note about the one remaining warning (safe innerHTML in dom-utils.js)
