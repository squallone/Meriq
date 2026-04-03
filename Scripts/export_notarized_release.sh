#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/Meriq.xcodeproj"
SCHEME_NAME="Meriq"
APP_NAME="Meriq"
CONFIGURATION="Release"
DERIVED_DATA_PATH="$ROOT_DIR/.derivedData"
BUILD_ROOT="$ROOT_DIR/build/distribution"
ARCHIVE_PATH="$BUILD_ROOT/$APP_NAME.xcarchive"
EXPORT_PATH="$BUILD_ROOT/export"
EXPORT_APP_PATH="$EXPORT_PATH/$APP_NAME.app"
SIGNED_ZIP_PATH="$BUILD_ROOT/$APP_NAME-signed.zip"
NOTARIZED_ZIP_PATH="$BUILD_ROOT/$APP_NAME-notarized.zip"

TEAM_ID=""
BUNDLE_ID=""
NOTARY_PROFILE=""
SIGNING_CERTIFICATE="Developer ID Application"
SKIP_NOTARIZATION=0
ALLOW_PROVISIONING_UPDATES=0

usage() {
  cat <<'EOF'
Usage:
  Scripts/export_notarized_release.sh --team-id TEAM_ID [options]

Options:
  --team-id TEAM_ID                Apple Developer Team ID. Required.
  --bundle-id BUNDLE_ID            Override PRODUCT_BUNDLE_IDENTIFIER for the build.
  --notary-profile PROFILE         Keychain profile saved with notarytool store-credentials.
  --signing-certificate NAME       Signing certificate selector. Defaults to "Developer ID Application".
  --skip-notarization              Export a Developer ID-signed app without submitting it to Apple.
  --allow-provisioning-updates     Allow xcodebuild to talk to Apple during archive/export.
  -h, --help                       Show this help text.

Examples:
  Scripts/export_notarized_release.sh --team-id ABCDE12345 --notary-profile mermaid-notary
  Scripts/export_notarized_release.sh --team-id ABCDE12345 --skip-notarization
EOF
}

print_step() {
  printf '\n==> %s\n' "$1"
}

fail() {
  echo "error: $1" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

verify_developer_id_certificate() {
  local identities
  identities="$(security find-identity -v -p codesigning 2>/dev/null || true)"

  if ! grep -q "Developer ID Application" <<<"$identities"; then
    fail "No Developer ID Application signing identity is installed. Install a Developer ID Application certificate in Keychain Access or Xcode before exporting for distribution."
  fi
}

write_export_options_plist() {
  local plist_path="$1"

  cat >"$plist_path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>destination</key>
    <string>export</string>
    <key>method</key>
    <string>developer-id</string>
    <key>signingCertificate</key>
    <string>${SIGNING_CERTIFICATE}</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
</dict>
</plist>
EOF
}

create_zip() {
  local source_app="$1"
  local destination_zip="$2"

  rm -f "$destination_zip"
  ditto -c -k --sequesterRsrc --keepParent "$source_app" "$destination_zip"
}

verify_exported_signature() {
  local app_path="$1"
  local signature_details

  codesign --verify --deep --strict "$app_path"
  signature_details="$(codesign -dv --verbose=4 "$app_path" 2>&1 || true)"

  if ! grep -q "Authority=Developer ID Application" <<<"$signature_details"; then
    fail "The exported app is not signed with a Developer ID Application certificate."
  fi

  if ! grep -q "^Timestamp=" <<<"$signature_details"; then
    fail "The exported app does not include a secure timestamp."
  fi

  if ! grep -q "runtime" <<<"$signature_details"; then
    fail "The exported app is missing the hardened runtime flag."
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --team-id)
      TEAM_ID="${2:?Missing value for --team-id}"
      shift 2
      ;;
    --bundle-id)
      BUNDLE_ID="${2:?Missing value for --bundle-id}"
      shift 2
      ;;
    --notary-profile)
      NOTARY_PROFILE="${2:?Missing value for --notary-profile}"
      shift 2
      ;;
    --signing-certificate)
      SIGNING_CERTIFICATE="${2:?Missing value for --signing-certificate}"
      shift 2
      ;;
    --skip-notarization)
      SKIP_NOTARIZATION=1
      shift
      ;;
    --allow-provisioning-updates)
      ALLOW_PROVISIONING_UPDATES=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

[[ -n "$TEAM_ID" ]] || fail "Missing required --team-id option."

if (( SKIP_NOTARIZATION == 0 )) && [[ -z "$NOTARY_PROFILE" ]]; then
  fail "Provide --notary-profile for a full notarized distribution, or use --skip-notarization to stop after Developer ID export."
fi

require_command xcodebuild
require_command xcrun
require_command codesign
require_command ditto
require_command plutil
require_command security

verify_developer_id_certificate

mkdir -p "$BUILD_ROOT"
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
rm -f "$SIGNED_ZIP_PATH" "$NOTARIZED_ZIP_PATH"

EXPORT_OPTIONS_PLIST="$(mktemp "$BUILD_ROOT/export-options.XXXXXX.plist")"
NOTARY_RESULT_PLIST="$(mktemp "$BUILD_ROOT/notary-submit.XXXXXX.plist")"
NOTARY_LOG_PATH="$BUILD_ROOT/notary-log.json"

cleanup() {
  rm -f "$EXPORT_OPTIONS_PLIST" "$NOTARY_RESULT_PLIST"
}
trap cleanup EXIT

write_export_options_plist "$EXPORT_OPTIONS_PLIST"

ARCHIVE_CMD=(
  xcodebuild
  -project "$PROJECT_PATH"
  -scheme "$SCHEME_NAME"
  -configuration "$CONFIGURATION"
  -derivedDataPath "$DERIVED_DATA_PATH"
  -archivePath "$ARCHIVE_PATH"
  archive
)

if [[ -n "$BUNDLE_ID" ]]; then
  ARCHIVE_CMD+=(PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID")
fi

if (( ALLOW_PROVISIONING_UPDATES )); then
  ARCHIVE_CMD+=(-allowProvisioningUpdates)
fi

print_step "Archiving $APP_NAME"
"${ARCHIVE_CMD[@]}"

EXPORT_CMD=(
  xcodebuild
  -exportArchive
  -archivePath "$ARCHIVE_PATH"
  -exportPath "$EXPORT_PATH"
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"
)

if (( ALLOW_PROVISIONING_UPDATES )); then
  EXPORT_CMD+=(-allowProvisioningUpdates)
fi

print_step "Exporting Developer ID-signed app"
"${EXPORT_CMD[@]}"

[[ -d "$EXPORT_APP_PATH" ]] || fail "Expected exported app at $EXPORT_APP_PATH"

print_step "Verifying exported signature"
verify_exported_signature "$EXPORT_APP_PATH"

print_step "Packaging signed app"
create_zip "$EXPORT_APP_PATH" "$SIGNED_ZIP_PATH"

if (( SKIP_NOTARIZATION )); then
  printf '\nCreated signed export:\n%s\n' "$EXPORT_APP_PATH"
  printf 'Created signed zip:\n%s\n' "$SIGNED_ZIP_PATH"
  exit 0
fi

print_step "Submitting zip to Apple notary service"
xcrun notarytool submit "$SIGNED_ZIP_PATH" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait \
  --output-format plist >"$NOTARY_RESULT_PLIST"

NOTARY_STATUS="$(plutil -extract status raw -o - "$NOTARY_RESULT_PLIST")"
NOTARY_SUBMISSION_ID="$(plutil -extract id raw -o - "$NOTARY_RESULT_PLIST")"

if [[ "$NOTARY_STATUS" != "Accepted" ]]; then
  xcrun notarytool log "$NOTARY_SUBMISSION_ID" "$NOTARY_LOG_PATH" --keychain-profile "$NOTARY_PROFILE"
  fail "Notarization failed with status '$NOTARY_STATUS'. See $NOTARY_LOG_PATH for Apple's log."
fi

print_step "Stapling notary ticket"
xcrun stapler staple "$EXPORT_APP_PATH"
xcrun stapler validate "$EXPORT_APP_PATH"

print_step "Packaging notarized app"
create_zip "$EXPORT_APP_PATH" "$NOTARIZED_ZIP_PATH"

printf '\nCreated notarized app:\n%s\n' "$EXPORT_APP_PATH"
printf 'Created notarized zip:\n%s\n' "$NOTARIZED_ZIP_PATH"
