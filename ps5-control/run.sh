#!/usr/bin/env bash
# Add-on entrypoint. Reads HA add-on options, does first-time pairing if
# needed, then starts the daemon. Logs go to HA add-on logs.
set -eu

CONFIG_FILE=/data/options.json
CREDS_FILE=/data/credentials.json

# --- read options from HA -----------------------------------------------------
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "FATAL: $CONFIG_FILE not found — HA didn't pass add-on options."
  exit 1
fi

PS5_HOST=$(jq -r '.ps5_host // ""' "$CONFIG_FILE")
ACCOUNT_ID=$(jq -r '.account_id // ""' "$CONFIG_FILE")
PIN=$(jq -r '.pin // ""' "$CONFIG_FILE")
LOG_LEVEL=$(jq -r '.log_level // "INFO"' "$CONFIG_FILE")

if [[ -z "$PS5_HOST" ]]; then
  echo "FATAL: ps5_host is required in add-on options."
  echo "       Open the add-on Configuration tab and set ps5_host to your PS5's LAN IP."
  exit 1
fi

# --- first-time pairing if no credentials yet --------------------------------
if [[ ! -f "$CREDS_FILE" ]]; then
  echo "==> No credentials.json yet — attempting first-time pairing."

  if [[ -z "$ACCOUNT_ID" ]]; then
    echo "FATAL: account_id is empty. Set it in the add-on Configuration tab."
    echo "       Public PSN profile: https://psn.flipscreen.games"
    echo "       Private profile:    use the OAuth helper from the main repo,"
    echo "                           https://github.com/sbr-labs/ps5-control-uc"
    exit 1
  fi
  if [[ -z "$PIN" ]]; then
    echo "FATAL: pin is empty. Generate a fresh 8-digit PIN on the PS5"
    echo "       (Settings → System → Remote Play → Link Device), set the 'pin'"
    echo "       field in the add-on Configuration tab, save, and start again."
    echo "       PINs are valid only ~5 minutes — type quickly."
    exit 1
  fi

  if python /app/pair.py "$PS5_HOST" "$ACCOUNT_ID" "$PIN" "$CREDS_FILE"; then
    echo "==> Pairing succeeded. credentials.json saved to $CREDS_FILE."
    echo "==> Now CLEAR the 'pin' field in the add-on Configuration tab so it"
    echo "    doesn't sit in your config (and isn't re-tried on next start)."
  else
    echo "==> Pairing FAILED. See errors above. The 'pin' is wasted —"
    echo "    generate a fresh one on the PS5 before retrying."
    exit 1
  fi
fi

# --- start daemon ------------------------------------------------------------
echo "==> Starting PS5 control daemon."
export PS5_HOST
export PS5_CREDS="$CREDS_FILE"
export LISTEN_HOST="0.0.0.0"
export LISTEN_PORT="8456"
export PS5_CTRL_LOG_LEVEL="$LOG_LEVEL"

exec python /app/daemon.py
