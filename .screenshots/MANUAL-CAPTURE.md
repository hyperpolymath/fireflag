<!--
SPDX-License-Identifier: MPL-2.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# Manual Screenshot Capture Guide

Quick guide for capturing FireFlag screenshots manually.

## Prerequisites

1. Build extension: `just build-ext`
2. Load in Firefox: `about:debugging` → "This Firefox" → "Load Temporary Add-on"
3. Select `extension/manifest.json`

## Screenshot List (Priority Order)

### 1. Popup (REQUIRED)
**File:** `01-popup-overview.png`
**Size:** 400x600px
**How:**
1. Click FireFlag toolbar icon
2. Use Firefox Screenshot (Shift+Ctrl+S)
3. Select and save popup area

**Show:**
- Flag list with 5+ flags visible
- Search bar at top
- Safety badges (Safe/Experimental/Dangerous colors)
- Toggle switches
- Category filters

---

### 2. Sidebar - Flags Tab (REQUIRED)
**File:** `02-sidebar-flags-tab.png`
**Size:** 350x700px
**How:**
1. Open sidebar: `Ctrl+Shift+F` or View → Sidebar → FireFlag
2. Ensure "Flags" tab is active
3. Select a flag to show detail view
4. Capture sidebar area

**Show:**
- Tab navigation (Flags/Tracking/Analytics/Export)
- Detailed flag information
- Positive/Negative/Interesting effects
- Metadata (type, category, version, permissions)
- Enable/Disable button

---

### 3. DevTools Panel (REQUIRED)
**File:** `06-devtools-active-flags.png`
**Size:** 1280x400px
**How:**
1. Open DevTools (F12)
2. Click "FireFlag" tab
3. Ensure "Active Flags" tab is selected
4. Navigate to a page with active flags
5. Capture DevTools panel area only

**Show:**
- List of active flags affecting current page
- Safety levels
- "Start Recording" button
- Dark theme (DevTools default)

---

### 4. Options Page
**File:** `05-options-general.png`
**Size:** 1280x800px
**How:**
1. Right-click FireFlag icon → "Manage Extension"
2. Or: `about:addons` → FireFlag → "Preferences"
3. Capture full page or scroll to show General section

**Show:**
- Auto-update settings
- UI preferences (safety badges, compact view)
- Search & filtering options

---

### 5. Sidebar - Tracking Tab
**File:** `03-sidebar-tracking-tab.png`
**Size:** 350x700px
**How:**
1. Open sidebar
2. Click "Tracking" tab
3. Toggle a flag to create tracking data
4. Capture sidebar

**Show:**
- Change history list
- Before/After values
- Timestamps
- Clear history button

---

### 6. Sidebar - Analytics Tab
**File:** `04-sidebar-analytics-tab.png`
**Size:** 350x700px
**How:**
1. Open sidebar
2. Click "Analytics" tab
3. Capture sidebar

**Show:**
- Performance metrics
- Impact analysis data
- Charts/graphs if available

---

### 7. Permission Request Dialog
**File:** `08-permission-request.png`
**Size:** 480x300px
**How:**
1. Find a flag requiring permissions (e.g., `privacy.resistFingerprinting`)
2. Toggle the flag
3. When permission dialog appears, capture it

**Show:**
- Permission request dialog
- List of permissions being requested
- Allow/Deny buttons
- Explanation text

## Quick Capture (Minimum Viable)

For immediate submission, capture AT LEAST these 3:

1. **Popup** - Main UI
2. **Sidebar Flags Tab** - Detailed view
3. **DevTools Panel** - Developer features

## Tools

### Firefox Built-in Screenshot
- Press `Shift+Ctrl+S`
- Click "Save visible" or select area
- Auto-saves to Downloads

### Third-party (Optional)
- Flameshot (Linux): `flameshot gui`
- ShareX (Windows)
- Spectacle (KDE)

## After Capture

1. **Rename files** according to naming scheme above
2. **Move** to `.screenshots/` directory
3. **Optimize:** `just optimize-screenshots`
4. **Verify** image dimensions and file size (<5MB each)

## Tips

- Use **default Firefox theme** (light or dark - pick one)
- Ensure **high DPI** display if available (looks better)
- **Populate UI** with realistic data (real flags, not empty)
- **Clean screenshots** - no debug console, errors, or personal data
- Keep **consistent window size** across shots (1280x800 recommended)

## Checklist Before Submission

- [ ] At least 3 screenshots captured
- [ ] All images 320x200 minimum, 3840x2160 maximum
- [ ] File sizes under 5MB each
- [ ] PNG format (preferred over JPEG)
- [ ] No personal information visible
- [ ] Clean UI (no debug artifacts)
- [ ] Images show actual extension (not mockups)
- [ ] Optimized with imagemagick or similar

## Questions?

See `.screenshots/README.adoc` for comprehensive guide.
