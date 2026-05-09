# PS5 Control add-on

Runs the [`ps5-control-uc`](https://github.com/sbr-labs/ps5-control-uc) daemon inside your Home Assistant Supervisor / HAOS box. Drives a PlayStation 5 over Sony Remote Play, exposes an HTTP API on port `8456` for the Unfolded Circle Remote 3 (or HA scripts, voice intents, custom dashboards).

This add-on doesn't use MQTT and doesn't need any internet-facing port-forward — its HTTP API is LAN-only on `8456`.

## Migrating from the older `ps5-mqtt` add-on

If you previously ran the community **`ps5-mqtt`** add-on (`funkeyflo/ps5-mqtt`) and have now switched to this one, tidy up the leftover state from the old setup:

1. **Uninstall the `ps5-mqtt` add-on** in HA → Settings → Add-ons. Stopping it isn't enough — uninstall it.
2. **Delete any router port-forwards** you added for the old add-on (typically `1883/tcp` and/or `8883/tcp`). This add-on is LAN-only and doesn't need any WAN forward.
3. If you don't use MQTT for anything else (e.g. Zigbee2MQTT), you can also uninstall the **Mosquitto broker** add-on. If you do use it for Zigbee2MQTT etc., just leave it installed — it's fine on the LAN.

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

## Use your own picture on the media-player widget (optional)

By default, the Remote 3 shows a PS5 wordmark on the media-player widget when the PS5 is on the home screen (no game running). You can swap it for any picture you like — a screenshot, a piece of art, anything.

### Step 1 — Find a picture and get its link

1. Find any picture on the internet you'd like to use.
2. **Right-click the picture** in your browser → click **"Copy image address"** (Chrome / Edge) or **"Copy image link"** (Safari / Firefox).
3. **Check the link ends in `.png`, `.jpg`, or `.jpeg`** — paste it into a new browser tab; you should see the picture by itself, with no website around it.
   - If the link ends in `.html` or `.com` or anything else, you copied the webpage instead. Try right-clicking the picture itself, not the page.
   - If the link ends in `.svg` it won't work — the Remote 3 only displays `.png` or `.jpg`.

### Step 2 — Paste it into the add-on

1. In Home Assistant, go to **Settings** → **Add-ons** → **PS5 Control**.
2. Click the **Configuration** tab at the top.
3. Find the field labelled **"Custom media-player image (optional)"** (the `home_image_url` field).
4. Paste the link you copied in Step 1.
5. Click **Save** at the bottom of the page.

### Step 3 — Restart the add-on

Click the **Restart** button at the top of the add-on page. About 10 seconds later, your picture appears on the Remote 3's media-player widget when the PS5 is on the home screen.

### Want to go back to the default?

Same place — **Configuration** tab, clear the **Custom media-player image** field (leave it blank), Save, Restart. The PS5 wordmark comes back.

### Want the official PS5 wordmark instead of the default gamepad?

The default is a generic gamepad illustration so the project doesn't redistribute Sony trademarks. If you'd rather see the official PS5 wordmark on the widget, paste this URL into the **Custom media-player image** field, Save, Restart:

```
https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/PlayStation_5_logo_and_wordmark.svg/500px-PlayStation_5_logo_and_wordmark.svg.png
```

This is the Wikimedia-hosted PNG render of the wordmark — works straight out of the box, no copyright issues since you're personally pointing your own widget at Wikimedia's copy.

### "But my picture still doesn't show up!"

- **Did the link end in `.png` or `.jpg`?** If it ends in `.svg`, `.html`, `.webp`, or anything else, the Remote 3 won't render it.
- **Does the link work in a private/incognito browser tab?** If you only see the picture when logged in to that website, the Remote 3 can't see it either.
- **Did you copy the *page* URL instead of the *image* URL?** Right-click the picture itself, not the page.
- **Wikipedia / Pinterest / Imgur problems?** Those sites sometimes block "hot-linking" — using their pictures from outside their website. Easiest fix: upload your picture to a free image host like [imgbb.com](https://imgbb.com) or [postimages.org](https://postimages.org) and use the direct link they give you. Make sure the link ends in `.png` or `.jpg`.
- **Picture looks letterboxed or stretched?** The Remote 3's media-player widget is **16:9 (widescreen)**, ~1024×576. Square images get black bars on the sides; very tall images get cropped. For best fit use a 16:9 PNG/JPG.

## Connect the Unfolded Circle Remote 3

In the Remote 3 web configurator → Settings → Integrations → Upload custom integration → upload [`ps5-uc-integration.tar.gz`](https://github.com/sbr-labs/ps5-control-uc/releases/latest/download/ps5-uc-integration.tar.gz) from the main repo's latest release.

Run setup for the new "PS5 Control (SBR)" integration. When it asks for the daemon URL, type your **HA box's LAN IP** followed by `:8456`. For example, if HA is at `192.168.1.50`, type `192.168.1.50:8456`.

(Find your HA box's IP under **Settings → System → Network**.) The Remote 3 then talks to the add-on directly.

## Control the PS5 from Home Assistant itself

You don't need a Remote 3 to use this add-on — Home Assistant can drive the PS5 directly via dashboards, automations, voice, scripts, NFC tags, anything that can call a service. The add-on's daemon exposes a tiny HTTP API on port `8456`; HA's built-in `rest_command` integration calls it.

**One-time setup** (~2 minutes):

1. **Edit your HA `configuration.yaml`** (Settings → Add-ons → File editor / Studio Code Server, or SSH in). Paste this block at the top level:

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
     ps5_launch:
       url: "http://localhost:8456/launch"
       method: post
       content_type: "application/json"
       payload: '{"title_id": "{{ title_id }}"}'
   ```

2. **Add a REST sensor** so HA always knows whether the PS5 is on, what game is running, and the box art (also under `configuration.yaml`):

   ```yaml
   rest:
     - resource: "http://localhost:8456/state"
       scan_interval: 10
       sensor:
         - name: "PS5 power"
           value_template: "{{ value_json.power }}"
         - name: "PS5 app"
           value_template: "{{ value_json.app }}"
         - name: "PS5 box art"
           value_template: "{{ value_json.image_url }}"
   ```

3. **Restart Home Assistant** (Settings → System → Restart). After restart you'll have new services (`rest_command.ps5_wakeup`, `ps5_standby`, `ps5_button`, `ps5_launch`) and three sensors (`sensor.ps5_power`, `sensor.ps5_app`, `sensor.ps5_box_art`).

**Use them anywhere:**

- **Dashboard button** that wakes the PS5:
  ```yaml
  type: button
  name: Wake PS5
  tap_action:
    action: call-service
    service: rest_command.ps5_wakeup
  ```

- **Dashboard button** that presses the PS button:
  ```yaml
  type: button
  name: PS Button
  tap_action:
    action: call-service
    service: rest_command.ps5_button
    data: { button: PS }
  ```

- **Automation** — wake PS5 when you walk into the living room after 7 pm:
  ```yaml
  trigger:
    - platform: state
      entity_id: binary_sensor.living_room_motion
      to: "on"
  condition:
    - condition: time
      after: "19:00:00"
  action:
    - service: rest_command.ps5_wakeup
  ```

- **Voice / Assist** — say "Hey Google, turn on the PS5" routed through HA Assist that calls `rest_command.ps5_wakeup`.

- **Mushroom media-player card** — drop in `sensor.ps5_box_art` as the picture, `sensor.ps5_app` as the title, controls calling the rest_commands. Looks like a real media player card.

**Available button names** for `rest_command.ps5_button`:
`UP`, `DOWN`, `LEFT`, `RIGHT`, `CROSS`, `CIRCLE`, `TRIANGLE`, `SQUARE`, `L1`, `R1`, `L2`, `R2`, `L3`, `R3`, `OPTIONS`, `SHARE`, `PS`, `TOUCHPAD`.

**Note:** if you're running this add-on on a different host than HA itself, change `localhost` to that host's LAN IP in all the URLs above. Most users run both on the same HA box, so `localhost` is correct.

## Troubleshooting

**Add-on log shows `Could not reach PS5 at <ip>`.** PS5 is off or unreachable on the LAN, or its IP changed (DHCP). Set a static IP / DHCP reservation for the PS5.

**Add-on log shows `Registration failed`.** PIN expired (regen and retry) or Account ID is wrong (re-check on flipscreen.games).

**Add-on log shows `IsADirectoryError: ... credentials.json`.** Old leftover state from a failed install. SSH into HA, `rm -rf /addon_configs/<addon_slug>/credentials.json` then restart the add-on. The standalone repo handles this automatically; the add-on's `/data` folder shouldn't normally hit this.

**Stuck on "Building wheel for cffi" for several minutes on Pi 3.** Normal — armv7l has no prebuilt wheels, pip compiles. 5–10 min the first time, instant on rebuilds (Docker layer cache).

## How this relates to the standalone repo

The daemon code (`daemon.py`) is the same as in [`sbr-labs/ps5-control-uc`](https://github.com/sbr-labs/ps5-control-uc). This add-on is a packaging wrapper that handles HA's options, persistent storage, and pairing flow. Functional behavior — buttons forwarded, state polled, sessions managed — is identical.

## License

MIT — same as the main repo.
