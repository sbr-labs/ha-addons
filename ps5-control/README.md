# PS5 Control add-on

Runs the [`ps5-control-uc`](https://github.com/sbr-labs/ps5-control-uc) daemon inside your Home Assistant Supervisor / HAOS box. Drives a PlayStation 5 over Sony Remote Play, exposes an HTTP API on port `8456` for the Unfolded Circle Remote 3 (or HA scripts, voice intents, custom dashboards).

## Prerequisites on the PS5 (one-time)

- **Settings → System → Remote Play → Enable Remote Play** → ON
- **Settings → Users and Accounts → Other → Console Sharing and Offline Play** → Enable
- **Settings → System → Power Saving → Features Available in Rest Mode**
  - **Stay Connected to the Internet** → ON
  - **Enable Turning On PS5 from Network** → ON

## Install

1. In HA: **Settings → Add-ons → Add-on Store → ⋮ → Repositories**, paste `https://github.com/sbr-labs/ha-addons`, click **Add**.
2. Refresh, find **PS5 Control**, click **Install**. Build takes ~1–3 minutes (longer on Pi 3 / armv7 — pip compiles a few packages from source, that's normal).

## First-time pairing

You'll need three things:
1. **PS5's LAN IP** (Settings → Network → View Connection Status → IP Address). Looks like `192.168.1.107`.
2. **Your PSN Account ID** — short Base64 string ending in `=`, e.g. `aBc1dEfg23h=`.
   - Public PSN profile: paste your PSN online ID into [psn.flipscreen.games](https://psn.flipscreen.games) and copy the *Base64 Account ID*.
   - Private PSN profile: use the OAuth helper from the [main repo](https://github.com/sbr-labs/ps5-control-uc) (`./get-account-id.sh`) on any machine with Docker.
   - If you only have the long decimal form (`7067298559098XXXXXX`), paste it in — the add-on auto-converts.
3. **An 8-digit pairing PIN** generated on the PS5 RIGHT BEFORE starting the add-on. PS5 → Settings → System → Remote Play → Link Device. PINs expire after ~5 minutes.

Then in the add-on **Configuration** tab:
- Set `ps5_host` to your PS5's LAN IP
- Set `account_id` to your Base64 Account ID
- Set `pin` to the fresh 8-digit PIN
- Save, then **Start** the add-on
- Watch the log — you should see `==> Pairing succeeded. credentials.json saved`
- **Clear the `pin` field** in Configuration (so it doesn't sit there and isn't retried)

The add-on will save `credentials.json` to `/data/credentials.json` (HA add-on persistent storage). Pairing is one-time — subsequent starts skip it.

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
