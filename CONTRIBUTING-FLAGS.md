<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# Contributing to the FireFlag Database

Thank you for helping keep FireFlag's flag database current and comprehensive!

## How the Database Stays Updated

### Automated Detection (Weekly)

FireFlag uses a GitHub Action that runs every Sunday to:

1. **Fetch Firefox source code** from mozilla-central
2. **Compare** Firefox prefs with our database
3. **Detect changes:**
   - New flags added by Mozilla
   - Flags removed or deprecated
   - Changed default values
4. **Create GitHub issues** for review with new/removed flags listed

### Manual Verification Required

While detection is automated, **human review is essential** because:
- Safety classification requires judgment
- Effects documentation needs research
- Compatibility testing is needed
- False positives occur (internal flags, etc.)

## Contributing New Flags

### Step 1: Research the Flag

Before adding a flag, gather this information:

1. **Flag key** (e.g., `privacy.resistFingerprinting`)
2. **Type** (boolean, integer, string, float)
3. **Default value**
4. **Minimum Gecko version** where it was introduced
5. **Maximum Gecko version** (if deprecated/removed)
6. **Official documentation** (MDN, Bugzilla, Mozilla wiki)
7. **Safety level** classification:
   - **Safe**: No breaking changes, no major downsides
   - **Experimental**: May have bugs, compatibility issues
   - **Dangerous**: Can break browsing, security risks if misused
8. **Effects** in three categories:
   - **Positive**: Benefits of enabling/changing the flag
   - **Negative**: Drawbacks, breaking changes, risks
   - **Interesting**: Technical details, trivia, implementation notes

### Step 2: Add to Database

Edit `extension/data/flags-database.json`:

```json
{
  "key": "example.new.flag",
  "type": "boolean",
  "category": "privacy",
  "safetyLevel": "safe",
  "defaultValue": false,
  "description": "Clear, concise one-line description",
  "effects": {
    "positive": [
      "Benefit 1",
      "Benefit 2"
    ],
    "negative": [
      "Downside 1",
      "Downside 2"
    ],
    "interesting": [
      "Technical detail 1",
      "Implementation note 2"
    ]
  },
  "permissions": ["privacy"],
  "geckoMinVersion": "109.0",
  "documentation": "https://link-to-official-docs"
}
```

### Step 3: Safety Level Guidelines

**Safe:**
- No significant breaking changes
- Well-tested by Mozilla
- Minimal negative effects
- Reversible without data loss
- Examples: `privacy.resistFingerprinting`, `browser.tabs.drawInTitlebar`

**Experimental:**
- May have bugs or compatibility issues
- Not enabled by default for a reason
- Some websites may break
- Generally safe to test
- Examples: `network.http.http3.enable`, `gfx.webrender.all`

**Dangerous:**
- Can break most/all web browsing
- Security implications if misconfigured
- Should only be changed by advanced users
- Examples: `browser.cache.disk.enable=false`, `devtools.debugger.remote-enabled=true`

### Step 4: Testing

Before submitting:

1. **Test the flag** in Firefox (about:config)
2. **Verify effects** match your documentation
3. **Check compatibility** across Firefox versions if possible
4. **Validate JSON** schema:
   ```bash
   npx ajv-cli validate -s extension/data/flags-schema.json -d extension/data/flags-database.json
   ```

### Step 5: Submit Pull Request

1. Fork the repository
2. Create a branch: `git checkout -b add-flag-example-new-flag`
3. Add your flag to the database
4. Commit with clear message:
   ```
   feat(db): add example.new.flag

   - Type: boolean
   - Category: privacy
   - Safety: safe
   - Gecko: 115.0+
   - Effects: [brief summary]
   ```
5. Push and create PR with template:
   ```markdown
   ## Flag Addition

   **Flag key:** `example.new.flag`
   **Category:** Privacy
   **Safety level:** Safe
   **Gecko version:** 115.0+

   ### Research
   - [ ] Tested in Firefox
   - [ ] Consulted official documentation
   - [ ] Verified effects
   - [ ] Classified safety level

   ### Documentation
   - Bugzilla: [link]
   - MDN: [link]
   - Testing notes: [brief notes]
   ```

## Reporting Deprecated Flags

If you discover a flag has been removed from Firefox:

1. **Verify** it's actually gone (check latest Nightly)
2. **Find** the Gecko version where it was removed
3. **Update** the database entry:
   ```json
   {
     "key": "deprecated.old.flag",
     "geckoMaxVersion": "115.0",
     ...
   }
   ```
4. **Submit PR** with title: `fix(db): deprecate old.flag (removed in Gecko 115)`

## Flag Categories

- **privacy**: Privacy, security, tracking protection
- **performance**: Speed, resource usage, caching
- **experimental**: New features, beta functionality
- **developer**: DevTools, debugging, development
- **ui**: User interface, visual changes
- **network**: Connectivity, protocols, DNS
- **media**: Audio, video, WebRTC, graphics
- **accessibility**: Screen readers, assistive tech

## Questions?

- Open an issue: https://github.com/hyperpolymath/fireflag/issues
- Check existing flags for examples
- Read the schema: `extension/data/flags-schema.json`

## Recognition

Contributors are listed in:
- Git commit history
- `CONTRIBUTORS.md` (alphabetically)
- Release notes for database updates

Thank you for helping make Firefox safer and more accessible! 🦎🚩
