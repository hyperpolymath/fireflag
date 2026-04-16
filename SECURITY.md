<!-- SPDX-License-Identifier: MPL-2.0 -->
# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |
| < main  | :x:                |

## Reporting a Vulnerability

Please report security vulnerabilities through GitHub private vulnerability reporting:
1. Go to the **Security** tab
2. Click **Report a vulnerability**
3. Fill out the form

We respond within 48 hours.

## Security Measures

- Dependabot for dependency updates
- CodeQL for code scanning
- Secret scanning and push protection
- `panic-attacker` static analysis for all submissions

## False Positives in Static Analysis

### `eval()` Usage in DevTools

FireFlag uses `browser.devtools.inspectedWindow.eval()` in:
- `extension/lib/rescript/DevTools.res.js`
- `extension/devtools/panel.js`

**This is not a security vulnerability.** The `eval()` is called via the Firefox DevTools API, which:
- Operates in the inspected page's context (not the extension's context)
- Requires explicit user action (opening DevTools)
- Is sandboxed by Firefox's security model

This is standard practice for DevTools extensions and is required for functionality like performance metric collection.

### Hardcoded Secrets in `sign-extension.sh`

The `scripts/sign-extension.sh` script does **not** contain hardcoded secrets. It:
- Reads credentials from environment variables (`MOZILLA_API_KEY`, `MOZILLA_API_SECRET`)
- Accepts credentials via command-line arguments
- Never stores or commits secrets

This is a false positive from static analysis tools detecting variable names like `API_KEY` and `API_SECRET`.

## Known Limitations

### DOM Manipulation

`extension/lib/dom-utils.js` uses `innerHTML` and `document.write` for:
- Rendering extension UI components
- Injecting flag documentation into panels

**Mitigations:**
- All content is controlled by the extension (no user input)
- No dynamic evaluation of untrusted data
- Content Security Policy (CSP) restricts script sources

### Supply Chain (Nix Flake)

`flake.nix` inputs are not pinned with `narHash` or `rev`. This is a low-risk issue because:
- Flakes are only used for development/reproducible builds
- Production builds use locked dependencies (`package-lock.json`, `Cargo.lock`)
- The extension itself has no runtime dependencies

## Security Checklist for Submissions

1. **Static Analysis**: Run `panic-attacker assail` and address all critical findings.
2. **False Positives**: Document legitimate uses of `eval()` and secret handling.
3. **Privacy Policy**: Ensure `privacy_policy_url` is set in `manifest.json`.
4. **CSP**: Verify Content Security Policy in `manifest.json`.
5. **Permissions**: Review and justify all requested permissions.

