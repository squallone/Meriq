# Distribution Notes

This document is for maintainers preparing Meriq for direct distribution outside the Mac App Store.

For product and implementation context, see:

- [README](/Users/admin/Documents/Projects/iOS/Meriq/README.md)
- [Architecture](/Users/admin/Documents/Projects/iOS/Meriq/docs/architecture.md)
- [UI and interaction model](/Users/admin/Documents/Projects/iOS/Meriq/docs/ui.md)

## Apple Distribution Flow

The current Apple direct-distribution flow is:

- sign with a `Developer ID Application` certificate
- enable hardened runtime
- notarize with `notarytool`
- staple the notarization ticket

Useful Apple references:

- [Developer ID overview](https://developer.apple.com/support/developer-id/)
- [Signing Mac software with Developer ID](https://developer.apple.com/developer-id/)
- [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution?changes=_5)
- [Customizing the notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)
- [Preparing your app for distribution](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution/)

## Project Assumptions

The generated Xcode project is configured so `Release` builds are compatible with direct distribution requirements such as hardened runtime.

## 1. Install A Developer ID Certificate

The machine performing the export must have a `Developer ID Application` signing identity installed in Keychain Access.

Check available signing identities with:

```bash
security find-identity -v -p codesigning
```

## 2. Store Notary Credentials

Using an App Store Connect API key:

```bash
Scripts/store_notary_credentials.sh \
  --profile meriq-notary \
  --key /path/to/AuthKey_ABC123XYZ.p8 \
  --key-id ABC123XYZ \
  --issuer 00000000-0000-0000-0000-000000000000
```

Using Apple ID credentials:

```bash
Scripts/store_notary_credentials.sh \
  --profile meriq-notary \
  --apple-id you@example.com \
  --team-id ABCDE12345
```

## 3. Export And Notarize

This script archives the app, exports a Developer ID-signed build, verifies signing, submits for notarization, staples the ticket, and packages the result:

```bash
Scripts/export_notarized_release.sh \
  --team-id ABCDE12345 \
  --notary-profile meriq-notary
```

If you want a Developer ID-signed export without notarization yet:

```bash
Scripts/export_notarized_release.sh \
  --team-id ABCDE12345 \
  --skip-notarization
```

Distribution artifacts are written to:

```text
build/distribution/
```

## Release Archive Only

To create a plain Release archive from the command line:

```bash
xcodebuild -project Meriq.xcodeproj \
  -scheme Meriq \
  -configuration Release \
  -derivedDataPath .derivedData \
  -archivePath build/Release/Meriq.xcarchive \
  archive
```

The archive is written to:

```text
build/Release/Meriq.xcarchive
```

## Current Machine Status

On this machine, `security find-identity -v -p codesigning` previously reported `0 valid identities found`, so a true Developer ID export cannot complete until a Developer ID certificate is installed.

The export script checks that early and fails with a clear message rather than producing a misleading local-only result.
