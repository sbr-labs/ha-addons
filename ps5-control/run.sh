#!/usr/bin/env bash
# Add-on entrypoint. Reads HA add-on options, does OAuth lookup or
# first-time pairing if needed, then starts the daemon. All status goes
# to the HA add-on Log tab.
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
OAUTH_REDIRECT=$(jq -r '.oauth_redirect_url // ""' "$CONFIG_FILE")
PIN=$(jq -r '.pin // ""' "$CONFIG_FILE")
HOME_IMAGE_URL=$(jq -r '.home_image_url // ""' "$CONFIG_FILE")
LOG_LEVEL=$(jq -r '.log_level // "INFO"' "$CONFIG_FILE")

if [[ -z "$PS5_HOST" ]]; then
  echo "FATAL: ps5_host is required in add-on options."
  echo "       Open the Configuration tab and set ps5_host to your PS5's LAN IP."
  echo "       Find PS5 IP under: PS5 → Settings → Network → View Connection Status."
  exit 1
fi

# --- OAuth helper modes (only when account_id is empty) ----------------------
# Two sub-modes:
#   1. oauth_redirect_url filled in → user has done sign-in, extract Account ID
#   2. neither filled in → print Sony's login URL so user can do sign-in
# Both modes exit cleanly so the user can paste the result back into options.
if [[ -z "$ACCOUNT_ID" ]]; then
  if [[ -n "$OAUTH_REDIRECT" ]]; then
    echo "==> oauth_redirect_url set — extracting Account ID from Sony's response..."
    if ID=$(python /app/oauth_helper.py extract-id "$OAUTH_REDIRECT" 2>&1); then
      echo ""
      echo "    +-----------------------------------------------------------------+"
      echo "    | Your PSN Account ID (Base64):                                   |"
      echo "    |                                                                 |"
      echo "    |     $ID"
      echo "    |                                                                 |"
      echo "    | Next steps in this add-on's Configuration tab:                  |"
      echo "    |  1. Paste the Account ID above into the 'account_id' field.    |"
      echo "    |  2. CLEAR the 'oauth_redirect_url' field (leave it blank).     |"
      echo "    |  3. Generate a fresh 8-digit PIN on the PS5 right before       |"
      echo "    |     step 4 (PS5 → Settings → System → Remote Play → Link       |"
      echo "    |     Device). PINs expire in ~5 min.                            |"
      echo "    |  4. Paste the PIN into the 'pin' field, Save, Start the add-on.|"
      echo "    +-----------------------------------------------------------------+"
      echo ""
      echo "==> OAuth lookup complete. Add-on will now exit so you can update options."
      exit 0
    else
      echo "$ID"  # contains the error from oauth_helper.py
      echo ""
      echo "==> OAuth lookup FAILED. Most common causes:"
      echo "    - Redirect URL was incomplete (you must copy the FULL URL"
      echo "      including everything after the '?'). It should look like"
      echo "      https://remoteplay.dl.playstation.net/...?code=...&cid=..."
      echo "    - Sony token expired (the redirect is only valid for ~10 min"
      echo "      after sign-in — sign in again, copy the URL quickly)."
      echo "    Fix the URL or do the OAuth sign-in again, then restart."
      exit 1
    fi
  fi

  # Neither account_id nor oauth_redirect_url set → show user the options.
  echo "==> Need a PSN Account ID before we can pair. Two paths:"
  echo ""
  echo "    Path A — Public PSN profile (easiest):"
  echo "      1. Open https://psn.flipscreen.games in any browser"
  echo "      2. Type your PSN online ID, copy the *Base64 Account ID*"
  echo "      3. Paste into the add-on's 'account_id' field, Save."
  echo ""
  echo "    Path B — Sony OAuth (works for private profiles):"
  if URL=$(python /app/oauth_helper.py print-login-url 2>&1); then
    echo "      1. Open this URL in any browser (PC, phone, anywhere):"
    echo ""
    echo "         $URL"
    echo ""
    echo "      2. Sign in to your PSN account."
    echo "      3. Browser will redirect to a page that LOOKS like an error"
    echo "         (blank page, white error, etc.) — that's expected."
    echo "      4. Copy the FULL URL from the browser's address bar. It"
    echo "         starts with https://remoteplay.dl.playstation.net/..."
    echo "      5. Paste that URL into this add-on's 'oauth_redirect_url'"
    echo "         field in the Configuration tab, Save, then Start the"
    echo "         add-on again. The add-on will print your Account ID."
  else
    echo "      (could not generate Sony OAuth URL — pyremoteplay missing? See above)"
  fi
  echo ""
  echo "==> Whichever path you pick, paste the Account ID into 'account_id',"
  echo "    then generate a fresh PIN on the PS5 and put it in 'pin', then start."
  exit 0
fi

# --- first-time pairing if no credentials yet --------------------------------
if [[ ! -f "$CREDS_FILE" ]]; then
  echo "==> No credentials.json yet — attempting first-time pairing."

  if [[ -z "$PIN" ]]; then
    echo "FATAL: pin is empty. Generate a fresh 8-digit PIN on the PS5"
    echo "       (PS5 → Settings → System → Remote Play → Link Device), set"
    echo "       the 'pin' field in the Configuration tab, Save, Start again."
    echo "       PINs are valid only ~5 minutes — type quickly after generating."
    exit 1
  fi

  if python /app/pair.py "$PS5_HOST" "$ACCOUNT_ID" "$PIN" "$CREDS_FILE"; then
    echo "==> Pairing succeeded. credentials.json saved to $CREDS_FILE."
    echo "==> Now CLEAR the 'pin' field in the Configuration tab so it"
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

# Home-screen / fallback image priority:
#  1. user-supplied home_image_url in add-on options (any external URL)
#  2. bundled PNG inside the container, served from the daemon's
#     own /home_image endpoint (default — works without internet,
#     reliably renders on the UC Remote 3 which expects raster art)
if [[ -n "$HOME_IMAGE_URL" ]]; then
  export HOME_IMAGE_URL
  echo "==> Using home_image_url from add-on options: $HOME_IMAGE_URL"
else
  export HOME_IMAGE_URL=""
  echo "==> Using bundled PNG home image (served from /home_image)."
fi
# Bundled PNG file path the daemon serves at /home_image when
# HOME_IMAGE_URL is empty.
export HOME_IMAGE_FILE=/app/default-home-image.png

exec python /app/daemon.py
