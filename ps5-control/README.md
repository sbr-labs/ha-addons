# PS5 Control add-on

Runs the [`ps5-control-uc`](https://github.com/sbr-labs/ps5-control-uc) daemon inside your Home Assistant Supervisor / HAOS box. Drives a PlayStation 5 over Sony Remote Play, exposes an HTTP API on port `8456` for the Unfolded Circle Remote 3 (or HA scripts, voice intents, custom dashboards).

This add-on does **not** use MQTT, does **not** require any internet-facing port-forward, and only exposes its HTTP API on your **LAN**.

## ⚠️ Migrating from the legacy `ps5-mqtt` add-on (read this)

If you previously ran the community **`ps5-mqtt`** add-on (`funkeyflo/ps5-mqtt`) and you've now moved to this add-on, do all three:

1. **Uninstall the `ps5-mqtt` add-on** in HA → Settings → Add-ons. Stopping isn't enough — uninstall it. Otherwise it keeps a Mosquitto broker active on `1883/8883` for no reason.
2. **Remove any router port-forward** you set up for the legacy add-on. Common ones to delete: `1883/tcp`, `8883/tcp`. The new add-on doesn't need any WAN forward — communication is LAN-only on `8456`.
3. **Make sure your Mosquitto broker is LAN-only.** If you don't otherwise use MQTT, you can also uninstall the **Mosquitto broker** add-on. If you do use MQTT (e.g. Zigbee2MQTT), leave Mosquitto installed but verify there's no public forward to it. From a phone on 4G, run `nc -zv <your-public-ip> 8883` — it should time out.

A leaked `1883`/`8883` listener — even with TLS — is the #1 reason ISPs (Vodafone, BT, EE, Sky) send "insecure MQTT service detected" warnings to home users. It's not specific to this project; it's a symptom of leftover state from the legacy add-on. Cleaning up the three items above resolves the warning.

## Prerequisites on the PS5 (one-time)

- **Settings → System → Remote Play → Enable Remote Play** → ON
- **Settings → Users and Accounts → Other → Console Sharing and Offline Play** → Enable
- **Settings → System → Power Saving → Features Available in Rest Mode**
  - **Stay Connected to the Internet** → ON
  - **Enable Turning On PS5 from Network** → ON

## Install

1. In HA: **Settings → Add-ons → Add-on Store → ⋮ → Repositories**, paste `https://github.com/sbr-labs/ha-addons`, click **Add**.
2. Refresh, find **PS5 Control**, click **Install**. Build takes ~1–3 minutes (longer on Pi 3 / armv7 — pip compiles a few packages from source, that's normal).

## First-time setup

You'll need three things:
1. **Your PS5's LAN IP** (PS5 → Settings → Network → View Connection Status → IP Address). Example: `192.168.1.50`.
2. **Your PSN Account ID** — short Base64 string ending in `=`, e.g. `aBc1dEfg23h=`.
3. **An 8-digit pairing PIN** generated on the PS5 RIGHT BEFORE the pair step. PS5 → Settings → System → Remote Play → Link Device. PINs expire after ~5 minutes.

The add-on includes a **built-in OAuth helper** so you don't need any other machine to get your PSN Account ID — even for private profiles.

### Step 1: Set ps5_host and start the add-on

In the add-on **Configuration** tab:
- Set `ps5_host` to your PS5's LAN IP (only required field)
- Leave everything else blank
- Save → **Start** the add-on
- Open the **Log** tab

The log will offer two paths to get your Account ID:

**Path A — Public PSN profile (easiest):**
Open [psn.flipscreen.games](https://psn.flipscreen.games), type your PSN online ID, copy the *Base64 Account ID*. Skip to Step 3.

**Path B — Built-in OAuth (works for private profiles too):**
The log will show a Sony PSN sign-in URL. Open it on any device, sign in, the browser will redirect to a page that looks like an error/blank page — that's normal. Copy the FULL URL from your browser's address bar (starts with `https://remoteplay.dl.playstation.net/...`). Continue to Step 2.

### Step 2: Run the OAuth helper (only if you used Path B)

Back in the add-on **Configuration** tab:
- Paste the redirect URL into the `oauth_redirect_url` field
- Save → **Start** the add-on
- The Log will print your Account ID in a box

### Step 3: Set account_id, generate PIN, pair

In the **Configuration** tab:
- Paste your Account ID into the `account_id` field
- **Clear the `oauth_redirect_url` field** (leave blank)
- Generate a fresh PIN on the PS5 (PS5 → Settings → System → Remote Play → Link Device) — *do this RIGHT before the next save, PINs expire in ~5 min*
- Set the `pin` field to those 8 digits
- Save → **Start** the add-on
- Log should show `==> Pairing succeeded. credentials.json saved`

### Step 4: Clean up

In the **Configuration** tab:
- Clear the `pin` field (no longer needed)
- Restart the add-on. From now on it just starts the daemon — no pairing.

The add-on saves `credentials.json` to `/data/credentials.json` (HA's persistent add-on storage). Pairing is one-time — survives add-on updates and HA reboots.

> **Decimal Account ID**: if you find your Account ID as a 19-digit decimal number (e.g. `7067298559098XXXXXX`), you can paste it directly — the add-on auto-converts to base64.

## Connect the Unfolded Circle Remote 3

In the Remote 3 web configurator → Settings → Integrations → Upload custom integration → upload [`ps5-uc-integration.tar.gz`](https://github.com/sbr-labs/ps5-control-uc/releases/latest/download/ps5-uc-integration.tar.gz) from the main repo's latest release.

Run setup for the new "PS5 Control (SBR)" integration. When it asks for the daemon URL, type your **HA box's LAN IP** followed by `:8456`. For example, if HA is at `192.168.1.50`, type `192.168.1.50:8456`.

(Find your HA box's IP under **Settings → System → Network**.) The Remote 3 then talks to the add-on directly.

## API for HA scripts / voice intents

The daemon's HTTP API:

```
POST /button     {"button": "<name>", "action": "tap|press|release"}
POST /wakeup
POST /standby
POST /launch     {"title_id": "<PPSAxxxxx>"}
GET  /state      → {"power": "on|off", "session": bool, "app": "<name>"}
GET  /health     → small JSON, useful for HA's REST sensor
```

Example HA REST command (in `configuration.yaml`):

```yaml
rest_command:
  ps5_wakeup:
    url: "http://localhost:8456/wakeup"
    method: post
  ps5_standby:
    url: "http://localhost:8456/standby"
    method: post
  ps5_button:
    url: "http://localhost:8456/button"
    method: post
    content_type: "application/json"
    payload: '{"button": "{{ button }}", "action": "tap"}'
```

Then call from automations: `service: rest_command.ps5_button` with `data: { button: PS }`.

## Troubleshooting

**Add-on log shows `Could not reach PS5 at <ip>`.** PS5 is off or unreachable on the LAN, or its IP changed (DHCP). Set a static IP / DHCP reservation for the PS5.

**Add-on log shows `Registration failed`.** PIN expired (regen and retry) or Account ID is wrong (re-check on flipscreen.games).

**Add-on log shows `IsADirectoryError: ... credentials.json`.** Old leftover state from a failed install. SSH into HA, `rm -rf /addon_configs/<addon_slug>/credentials.json` then restart the add-on. The standalone repo handles this automatically; the add-on's `/data` folder shouldn't normally hit this.

**Stuck on "Building wheel for cffi" for several minutes on Pi 3.** Normal — armv7l has no prebuilt wheels, pip compiles. 5–10 min the first time, instant on rebuilds (Docker layer cache).

## How this relates to the standalone repo

The daemon code (`daemon.py`) is the same as in [`sbr-labs/ps5-control-uc`](https://github.com/sbr-labs/ps5-control-uc). This add-on is a packaging wrapper that handles HA's options, persistent storage, and pairing flow. Functional behavior — buttons forwarded, state polled, sessions managed — is identical.

## License

MIT — same as the main repo.
