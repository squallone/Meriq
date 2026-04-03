# Distribution Notes

This document is for maintainers preparing builds for distribution outside the Mac App Store.

For general product and architecture context, see:

- [README](../README.md)
- [Architecture](architecture.md)
- [UI and interaction model](ui.md)

Apple’s current direct-distribution flow is:
- sign with a `Developer ID Application` certificate
- enable hardened runtime
- submit with `notarytool`
- staple the notary ticket to the exported app

Helpful Apple references:
- [Developer ID overview](https://developer.apple.com/support/developer-id/)
- [Signing Mac software with Developer ID](https://developer.apple.com/developer-id/)
- [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution?changes=_5)
- [Customizing the notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)
- [Preparing your app for distribution](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution/)

## Project Setup

The generated Xcode project enables hardened runtime for `Release` builds, which is required for notarized direct distribution.

## 1. Install a Developer ID Certificate

The Mac that runs the export must have a `Developer ID Application` signing identity available in Keychain Access.

Check that with:

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

## 3. Export and Notarize

This command archives the app, exports a Developer ID-signed build, verifies the signature, submits it to Apple with `notarytool`, staples the ticket, and packages the final notarized zip:

```bash
Scripts/export_notarized_release.sh \
  --team-id ABCDE12345 \
  --notary-profile meriq-notary
```

If you only want the Developer ID-signed export without notarization yet:

```bash
Scripts/export_notarized_release.sh \
  --team-id ABCDE12345 \
  --skip-notarization
```

The distribution outputs end up under:

```text
build/distribution/
```

## Release Archive Only

To create a plain Release archive from Terminal:

```bash
xcodebuild -project Meriq.xcodeproj \
  -scheme Meriq \
  -configuration Release \
  -derivedDataPath .derivedData \
  -archivePath build/Release/Meriq.xcarchive \
  archive
```

The archive ends up at:

```text
build/Release/Meriq.xcarchive
```

## Current Machine Status

On this machine, `security find-identity -v -p codesigning` reports `0 valid identities found`, so a true Developer ID export cannot complete until a Developer ID certificate is installed. The export script checks for that up front and fails with a clear message instead of producing a misleading local-only archive.
