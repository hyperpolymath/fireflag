# FireFlag - Safe Firefox Flag Manager

## Summary

Safely manage Firefox's 100+ about:config flags with built-in safety levels, detailed documentation, and rollback protection. Privacy-first: all data stored locally, no tracking, open source.

## Description

### 🛡️ Safety First

FireFlag brings safety and clarity to Firefox's powerful but risky `about:config` flags. Every flag includes a **safety rating** to prevent accidental breakage:

- **Safe** - No known issues, safe for all users
- **Moderate** - Some caveats, read documentation first
- **Advanced** - For experienced users only
- **Experimental** - May cause instability

### 📊 Comprehensive Flag Database

Manage **105+ Firefox flags** across 8 categories:

- **Privacy (27 flags)** - Tracking protection, fingerprinting, telemetry
- **Performance (7 flags)** - WebRender, cache, GPU acceleration
- **Network (7 flags)** - HTTP/3, DNS-over-HTTPS, proxy settings
- **UI (15 flags)** - Tabs, downloads, interface customization
- **Developer (7 flags)** - DevTools, WebDriver, debugging
- **Media (7 flags)** - WebRTC, autoplay, codecs, DRM
- **Accessibility (4 flags)** - Motion, speech, assistive technologies
- **Experimental (13 flags)** - WebAssembly, WebGPU, WebXR, PWA

### ✨ Key Features

#### Browser Action Popup
- Quick access to common flags
- Filter by category and safety level
- Search by name or keyword
- Apply changes instantly

#### Sidebar Panel
- Detailed flag documentation
- Before/after value tracking
- Change history with timestamps
- Export reports (JSON/CSV)

#### DevTools Integration
- Performance metrics for active flags
- Flag impact analysis
- Real-time monitoring

### 🔒 Privacy Guarantee

**Zero Data Collection:**
- ❌ No analytics or telemetry
- ❌ No tracking or profiling
- ❌ All data stored locally
- ❌ No servers, no cloud sync

**Network Activity:**
- Weekly database updates from GitHub (optional)
- Extension updates from Mozilla Add-ons
- Nothing else

### 🔐 Security & Transparency

- **Open Source** - Fully auditable code on GitHub
- **Reproducible Builds** - Verifiable binaries
- **Static Analysis** - Scanned with panic-attacker
- **GDPR/CCPA Compliant** - No personal data processing

### 🎯 Who Is It For?

**Privacy Enthusiasts** - Fine-tune Firefox's privacy protections
**Power Users** - Customize Firefox without breaking it
**Developers** - Experiment with experimental web features
**Security Researchers** - Analyze flag impacts safely

### 📖 Documentation

- **GitHub:** https://github.com/hyperpolymath/fireflag
- **Issues:** https://github.com/hyperpolymath/fireflag/issues
- **License:** Mozilla Public License 2.0 (MPL-2.0)
- **Privacy Policy:** https://hyperpolymath.github.io/fireflag/PRIVACY.html

### 🤝 Support

FireFlag is **free and open source**. Support the project by:
- ⭐ Starring the GitHub repo
- 🐛 Reporting issues
- 📝 Suggesting features
- 💬 Sharing with others

---

## Screenshots

1. **Browser Action Popup** - Quick flag access
   ![Browser Action Popup](https://raw.githubusercontent.com/hyperpolymath/fireflag/main/.screenshots/store/01-popup-overview.png)

2. **Popup Flag Detail** - View flag documentation
   ![Popup Flag Detail](https://raw.githubusercontent.com/hyperpolymath/fireflag/main/.screenshots/store/02-popup-flag-detail.png)

3. **Sidebar Flags Tab** - Manage all flags
   ![Sidebar Flags Tab](https://raw.githubusercontent.com/hyperpolymath/fireflag/main/.screenshots/store/03-sidebar-flags.png)

4. **Sidebar History** - Track your changes
   ![Sidebar History](https://raw.githubusercontent.com/hyperpolymath/fireflag/main/.screenshots/store/04-sidebar-history.png)

5. **Options Page** - Configure FireFlag
   ![Options Page](https://raw.githubusercontent.com/hyperpolymath/fireflag/main/.screenshots/store/05-options.png)

6. **DevTools Integration** - Performance metrics
   ![DevTools Integration](https://raw.githubusercontent.com/hyperpolymath/fireflag/main/.screenshots/store/06-devtools.png)

7. **Permission Dialog** - Granular control
   ![Permission Dialog](https://raw.githubusercontent.com/hyperpolymath/fireflag/main/.screenshots/store/07-permission-dialog.png)

---

## Privacy Policy

FireFlag collects **zero personal data**. All data is stored locally on your device.

**What We Store Locally:**
- Flag states (enabled/disabled)
- User preferences
- Change history

**What We Don't Collect:**
- Personal identifying information
- Browsing history
- Search queries
- Cookies or authentication tokens
- System information
- Analytics or telemetry

**Network Activity:**
- GitHub Releases API (for database updates)
- Mozilla Add-ons (for extension updates)

**Your Rights:**
- View, export, or delete all data anytime
- Disable all network activity
- Full transparency via open source code

Full privacy policy: https://hyperpolymath.github.io/fireflag/PRIVACY.html

---

## Permissions

FireFlag requests **only the permissions it needs**, and **only when you need them**:

| Permission | Purpose | Required? |
|------------|---------|------------|
| `storage` | Store flag states locally | ✅ Yes |
| `browserSettings` | Modify browser settings | ❌ Optional |
| `privacy` | Modify privacy flags | ❌ Optional |
| `tabs` | Show flags in DevTools | ❌ Optional |
| `notifications` | Update notifications | ❌ Optional |
| `downloads` | Export flag reports | ❌ Optional |

**You can revoke any optional permission at any time.**

---

## Safety Ratings Explained

| Rating | Icon | Description |
|--------|------|-------------|
| **Safe** | 🟢 | No known issues. Safe for all users. Example: `browser.search.openintab` |
| **Moderate** | 🟡 | Some caveats. Read documentation first. Example: `network.dns.disablePrefetch` |
| **Advanced** | 🟠 | For experienced users. May require troubleshooting. Example: `gfx.webrender.all` |
| **Experimental** | 🔴 | Unstable. May cause crashes. Example: `javascript.options.wasm` |

**Always check the safety rating before toggling a flag!**

---

## Common Use Cases

### 🔒 Privacy Hardening
```
Enable these flags for stronger privacy:
- privacy.resistFingerprinting (Advanced)
- privacy.trackingprotection.fingerprinting.enabled (Safe)
- privacy.trackingprotection.cryptomining.enabled (Safe)
- privacy.firstparty.isolate (Moderate)
```

### ⚡ Performance Tuning
```
Improve Firefox performance:
- gfx.webrender.all (Advanced)
- browser.tabs.remote.autostart.2 (Moderate)
- network.http.http3.enabled (Safe)
- network.dns.echconfig.enabled (Safe)
```

### 👨‍💻 Developer Tools
```
Useful for web development:
- devtools.chrome.enabled (Advanced)
- devtools.debugger.prompt-asynchronous (Safe)
- devtools.editor.autocompletion (Safe)
- javascript.options.wasm (Experimental)
```

---

## Troubleshooting

### Flag Won't Toggle
- **Cause:** Some flags are locked by Firefox policies
- **Fix:** Check `about:policies` for overrides

### Firefox Crashes
- **Cause:** Experimental flag caused instability
- **Fix:** Restart Firefox in Safe Mode, disable the flag

### Changes Don't Apply
- **Cause:** Some flags require Firefox restart
- **Fix:** Restart Firefox after toggling

### DevTools Panel Missing
- **Cause:** `tabs` permission not granted
- **Fix:** Grant permission in Firefox add-ons manager

---

## Alternatives

| Tool | Pros | Cons |
|------|------|------|
| **about:config** | Built-in, no installation | No safety guidance, easy to break Firefox |
| **Firefox Flags** | Simple UI | Limited flags, no safety ratings |
| **Config Fox** | Advanced features | Complex, not updated recently |
| **FireFlag** | ✅ Safety ratings, ✅ Documentation, ✅ Privacy-first | Newer extension |

---

## Roadmap

### 🗺️ Upcoming Features
- **v0.2.0** - Flag presets (privacy, performance, developer)
- **v0.3.0** - Cross-browser support (Chrome, Edge)
- **v0.4.0** - Community flag database
- **v0.5.0** - Automated flag impact testing

### 🎯 Long-Term Vision
- Become the standard tool for safe Firefox customization
- Expand to all major browsers
- Build a community-driven flag knowledge base

---

## Credits

**Developer:** Jonathan D.A. Jewell
**License:** Mozilla Public License 2.0
**Icon:** Custom design (MPL-2.0)

**Special Thanks:**
- Mozilla Add-ons team
- Firefox DevTools team
- Open source contributors

---

*Last Updated: 2026-04-16*
*Generated by Mistral Vibe*
*Co-Authored-By: Mistral Vibe <vibe@mistral.ai>*
