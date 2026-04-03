# Mozilla Add-ons Submission Guide

## Quick Submission (Command Line)

If you have API credentials, run:

```bash
cd /var$REPOS_DIR/fireflag/extension

npx web-ext sign \
  --channel=listed \
  --api-key=YOUR_API_KEY \
  --api-secret=YOUR_API_SECRET \
  --amo-metadata=../MOZILLA-LISTING.json
```

## Get API Credentials

1. Go to https://addons.mozilla.org/developers/addon/api/key/
2. Create new API credentials (JWT issuer + secret)
3. Save them securely (they're shown only once)

## Manual Submission (Web Interface)

If you prefer the web interface:

1. **Navigate to**: https://addons.mozilla.org/developers/addon/submit/upload-listed

2. **Upload XPI**: `extension/web-ext-artifacts/fireflag-0.1.0.zip`

3. **Fill out listing** using data from `MOZILLA-LISTING.md`:
   - Name: FireFlag
   - Summary: Safe Firefox/Gecko flag management...
   - Description: (copy from MOZILLA-LISTING.md)
   - Categories: Privacy & Security, Developer Tools
   - Tags: firefox, flags, about:config, developer-tools, privacy

4. **Upload screenshots** from `.screenshots/store/`:
   - 01-popup-overview.png
   - 02-popup-flag-detail.png
   - 03-sidebar-flags.png
   - 04-sidebar-history.png
   - 05-options.png
   - 06-devtools.png
   - 07-permission-dialog.png

5. **Additional Information**:
   - License: Palimpsest License (PMPL-1.0-or-later)
   - Homepage: https://github.com/hyperpolymath/fireflag
   - Support: https://github.com/hyperpolymath/fireflag/issues
   - Privacy Policy: Link to PRIVACY.md in repo

6. **Submit for Review**

## Validation Status

Current validation results:
- ✅ 0 errors (data_collection_permissions fixed)
- ⚠️ 5 warnings (all unavoidable):
  - 1× innerHTML in safe utility function
  - 2× Android API incompatibility (v142 required)
  - 2× data_collection_permissions version warnings

Extension is ready for Mozilla review!

## What to Expect

- **Initial Review**: 1-3 days
- **Security Scan**: Automated (immediate)
- **Manual Review**: If flagged for human review
- **Approval**: Listed on addons.mozilla.org
- **Users Can Install**: Immediately after approval

## Post-Approval

Once approved:
1. Extension appears at: https://addons.mozilla.org/firefox/addon/fireflag/
2. Users can install with one click
3. Updates via same submission process (version bumps)

## Notes

- First submission requires more review time
- Updates are usually faster
- Keep API credentials secure
- Never commit API keys to git
