<!--
SPDX-License-Identifier: MPL-2.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# FireFlag - Build Instructions for Mozilla Reviewers

This document explains how to build FireFlag from source code.

## Prerequisites

- **Deno** 2.1.4 or later (JavaScript/TypeScript runtime)
- **ReScript** compiler (for .res → .js compilation)
- **Idris2** 0.7.0 or later (optional - for rebuilding formally verified libraries)

## Quick Build (Reviewers)

The extension is **already built** - all `.res.js` files are included in the source.

To verify the build:

```bash
# 1. Navigate to extension directory
cd extension/

# 2. Package the extension
zip -r ../fireflag-0.1.0.zip * -x "*.DS_Store" -x "__MACOSX/*" -x "web-ext-artifacts/*"

# 3. Verify the package
ls -lh ../fireflag-0.1.0.zip
```

**Expected output:** `fireflag-0.1.0.zip` (approximately 122KB)

## Full Build from Source (Optional)

If you want to rebuild the ReScript files:

### 1. Install Dependencies

```bash
# Install Deno (if not already installed)
curl -fsSL https://deno.land/install.sh | sh

# Install ReScript globally
deno install -g @rescript/core
```

### 2. Rebuild ReScript Files

```bash
# Navigate to lib/rescript directory
cd extension/lib/rescript/

# Compile .res files to .res.js
rescript build

# OR use Deno to compile
deno task build
```

**Files compiled:**
- `Types.res` → `Types.res.js`
- `BrowserAPI.res` → (inline, no separate output)
- `DevTools.res` → (inline, no separate output)
- `DatabaseUpdater.res` → (inline, no separate output)

### 3. Verify Compilation

```bash
# Check that .res.js files exist
ls -l extension/lib/rescript/*.res.js

# Should show: Types.res.js
```

### 4. Package Extension

```bash
cd extension/
zip -r ../fireflag-0.1.0.zip * -x "*.DS_Store" -x "__MACOSX/*" -x "web-ext-artifacts/*"
```

## Idris2 Files (Formally Verified Library)

The Idris2 files in `extension/lib/idris/*.idr` are **not compiled** as part of the extension build.

These files are:
- Formally verified safety proofs
- Type definitions with dependent types
- Included for **transparency** and **auditing**
- NOT executed at runtime (JavaScript implementation is separate)

**Purpose:** Demonstrate formal verification of core safety logic.

**To rebuild Idris2 proofs (optional, not required for extension):**

```bash
cd extension/lib/idris/
idris2 --build fireflag.ipkg
```

This generates proof artifacts but does NOT affect the extension package.

## Directory Structure

```
fireflag/
├── extension/                   # Extension source
│   ├── manifest.json            # Extension manifest
│   ├── background/              # Background scripts
│   ├── popup/                   # Popup UI
│   ├── sidebar/                 # Sidebar UI
│   ├── options/                 # Options page
│   ├── devtools/                # DevTools panel
│   ├── lib/                     # Libraries
│   │   ├── rescript/            # ReScript source (.res)
│   │   │   └── *.res.js         # Compiled JavaScript
│   │   ├── idris/               # Idris2 proofs (.idr)
│   │   └── dom-utils.js         # Safe DOM utilities
│   ├── data/                    # Flag database
│   └── icons/                   # Extension icons
├── README.md                    # Project documentation
├── LICENSE                      # MPL-2.0
└── BUILD_INSTRUCTIONS.md        # This file
```

## Build Verification

To verify the build matches the submitted package:

```bash
# 1. Build extension
cd extension/
zip -r ../fireflag-built.zip * -x "*.DS_Store" -x "__MACOSX/*" -x "web-ext-artifacts/*"

# 2. Compare with submitted package
cd ..
unzip -l fireflag-0.1.0.zip > submitted.txt
unzip -l fireflag-built.zip > built.txt
diff submitted.txt built.txt
```

**Expected result:** No differences (or only timestamp differences)

## Third-Party Code

**None.** All code is original, except:
- Browser APIs (provided by Firefox)
- Standard JavaScript built-ins

## Code Generators Used

1. **ReScript Compiler**
   - Version: Latest stable
   - Input: `.res` files (ReScript source)
   - Output: `.res.js` files (JavaScript)
   - Purpose: Type-safe JavaScript generation
   - Repository: https://github.com/rescript-lang/rescript-compiler

2. **Idris2** (Optional, for proofs only)
   - Version: 0.7.0+
   - Input: `.idr` files (Idris2 source)
   - Output: Proof artifacts (not included in extension)
   - Purpose: Formal verification of safety properties
   - Repository: https://github.com/idris-lang/Idris2

## License

- **Extension Code:** MPL-2.0 (Palimpsest Meta-Project License)
- **License File:** `LICENSE` in repository root
- **License URL:** https://github.com/hyperpolymath/palimpsest-license

## Support

- **Author:** Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
- **Repository:** https://github.com/hyperpolymath/fireflag
- **Issues:** https://github.com/hyperpolymath/fireflag/issues

## Notes for Reviewers

### Why ReScript?

ReScript provides:
- **Type safety:** Compile-time guarantees against common JavaScript errors
- **Memory safety:** No null/undefined errors at runtime
- **Performance:** Generates optimized JavaScript
- **Readability:** `.res.js` output is human-readable, not minified

### Why Include Idris2 Files?

The Idris2 `.idr` files demonstrate:
- **Formal verification:** Mathematical proofs of safety properties
- **Transparency:** Auditable safety claims
- **Documentation:** Self-documenting type guarantees

These files are **NOT executed** - they're included for transparency and verification.

### Source Code Availability

All source code is available at:
- **GitHub:** https://github.com/hyperpolymath/fireflag
- **License:** Open source (MPL-2.0)

---

**Build Time:** < 5 seconds (ReScript compilation only)
**Build Reproducibility:** Deterministic (same source → same output)
**Build Dependencies:** Deno + ReScript (optional: Idris2 for proofs)
