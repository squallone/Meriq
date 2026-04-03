#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  Scripts/store_notary_credentials.sh --profile PROFILE --key PATH --key-id KEY_ID [--issuer ISSUER]
  Scripts/store_notary_credentials.sh --profile PROFILE --apple-id APPLE_ID --team-id TEAM_ID [--app-password PASSWORD]

Options:
  --profile PROFILE       Keychain profile name for notarytool.
  --key PATH              App Store Connect API private key (.p8).
  --key-id KEY_ID         App Store Connect API key ID.
  --issuer ISSUER         App Store Connect issuer ID. Omit for Individual API Keys.
  --apple-id APPLE_ID     Apple ID email for notarytool authentication.
  --team-id TEAM_ID       Apple Developer Team ID.
  --app-password VALUE    App-specific password for Apple ID authentication.
  --keychain PATH         Optional custom keychain path.
  --sync                  Store credentials in the iCloud-synced keychain.
  --no-validate           Skip immediate credential validation.
  -h, --help              Show this help text.
EOF
}

PROFILE=""
KEY_PATH=""
KEY_ID=""
ISSUER=""
APPLE_ID=""
TEAM_ID=""
APP_PASSWORD=""
KEYCHAIN_PATH=""
SYNC_CREDENTIALS=0
VALIDATE_CREDENTIALS=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="${2:?Missing value for --profile}"
      shift 2
      ;;
    --key)
      KEY_PATH="${2:?Missing value for --key}"
      shift 2
      ;;
    --key-id)
      KEY_ID="${2:?Missing value for --key-id}"
      shift 2
      ;;
    --issuer)
      ISSUER="${2:?Missing value for --issuer}"
      shift 2
      ;;
    --apple-id)
      APPLE_ID="${2:?Missing value for --apple-id}"
      shift 2
      ;;
    --team-id)
      TEAM_ID="${2:?Missing value for --team-id}"
      shift 2
      ;;
    --app-password)
      APP_PASSWORD="${2:?Missing value for --app-password}"
      shift 2
      ;;
    --keychain)
      KEYCHAIN_PATH="${2:?Missing value for --keychain}"
      shift 2
      ;;
    --sync)
      SYNC_CREDENTIALS=1
      shift
      ;;
    --no-validate)
      VALIDATE_CREDENTIALS=0
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

if [[ -z "$PROFILE" ]]; then
  echo "Missing required --profile option." >&2
  usage >&2
  exit 1
fi

if [[ -n "$KEY_PATH" || -n "$KEY_ID" || -n "$ISSUER" ]]; then
  if [[ -z "$KEY_PATH" || -z "$KEY_ID" ]]; then
    echo "API key authentication requires both --key and --key-id." >&2
    exit 1
  fi
  if [[ -n "$APPLE_ID" || -n "$TEAM_ID" || -n "$APP_PASSWORD" ]]; then
    echo "Choose either API key authentication or Apple ID authentication, not both." >&2
    exit 1
  fi
elif [[ -n "$APPLE_ID" || -n "$TEAM_ID" || -n "$APP_PASSWORD" ]]; then
  if [[ -z "$APPLE_ID" || -z "$TEAM_ID" ]]; then
    echo "Apple ID authentication requires both --apple-id and --team-id." >&2
    exit 1
  fi
else
  echo "Provide either API key credentials or Apple ID credentials." >&2
  usage >&2
  exit 1
fi

if (( SYNC_CREDENTIALS )) && [[ -n "$KEYCHAIN_PATH" ]]; then
  echo "--sync and --keychain cannot be used together." >&2
  exit 1
fi

cmd=(xcrun notarytool store-credentials "$PROFILE")

if [[ -n "$KEY_PATH" ]]; then
  cmd+=(--key "$KEY_PATH" --key-id "$KEY_ID")
  if [[ -n "$ISSUER" ]]; then
    cmd+=(--issuer "$ISSUER")
  fi
else
  cmd+=(--apple-id "$APPLE_ID" --team-id "$TEAM_ID")
  if [[ -n "$APP_PASSWORD" ]]; then
    cmd+=(--password "$APP_PASSWORD")
  fi
fi

if [[ -n "$KEYCHAIN_PATH" ]]; then
  cmd+=(--keychain "$KEYCHAIN_PATH")
fi

if (( SYNC_CREDENTIALS )); then
  cmd+=(--sync)
fi

if (( VALIDATE_CREDENTIALS )); then
  cmd+=(--validate)
else
  cmd+=(--no-validate)
fi

"${cmd[@]}"
