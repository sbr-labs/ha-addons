# Changelog

All notable changes to the SBR Labs HA add-ons repo are recorded here.
Versions track the `ps5-control` add-on (the only add-on in the repo right
now). Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning is [SemVer](https://semver.org/spec/v2.0.0.html).

## [0.5.2] - 2026-05-10

### Changed
- **Cover art appears faster.** Default presence-poll interval lowered
  from 30 s to 15 s, plus a new activity-aware mode: when a button has
  been pressed within the last 60 s, the daemon polls every 5 s
  instead of every 15 s. So when you're actively switching games,
  the widget catches up much quicker. Knobs:
  `PSN_PRESENCE_POLL_S` (idle), `PSN_PRESENCE_FAST_POLL_S`,
  `PSN_PRESENCE_ACTIVITY_WINDOW_S`.
- **Cover art preference reordered.** `SIXTEEN_BY_NINE_BANNER` is now
  the top choice over `GAMEHUB_COVER_ART` — Sony's banner art is
  explicitly composed for widescreen widget tiles, so it tends to
  fill the Remote 3 media-player widget without letterboxing.
  GAMEHUB_COVER_ART remains the fallback. The cached cover for
  already-fetched titles will refresh the next time the title changes.

## [0.5.1] - 2026-05-10

### Changed
- README now has a dedicated step-by-step **"Get live game cover art
  on the media-player widget"** section walking users through getting
  their npsso from Sony's ssocookie URL, pasting it into the
  Configuration tab, confirming the log lines, and (optionally)
  clearing the field once saved tokens take over. Existing v0.5.0
  users will see this in the addon page docs the next time they look
  at the add-on. Docs only — no code change.

## [0.5.0] - 2026-05-10

### Added
- **Live game cover art on the media-player widget (PSN presence).**
  PS5 firmware 13.x stripped the running-app metadata from the local
  DDP broadcast, so the daemon's `app_name` / `app_id` had been empty
  regardless of what was playing. This release adds an optional PSN
  REST client that fills that gap directly from Sony's "currently
  playing" endpoint — same data source the PlayStation mobile app
  uses. The Remote 3 widget now shows live game cover art (Call of
  Duty, Spider-Man, GT7, etc.) when a PSN-catalogued title is
  running, instead of always showing the fallback home image.
- **One-time setup** via a new `psn_npsso_token` field in the addon
  Configuration tab (password input). Paste your npsso cookie from
  https://ca.account.sony.com/api/v1/ssocookie once; the daemon
  exchanges it for OAuth tokens persisted at `/data/psn_tokens.json`
  and never asks again (refresh tokens auto-roll). Leaving the field
  blank disables presence and the daemon behaves as before.
- **Catalog cover-art fallback.** When Sony's presence response omits
  the cover URL for a title (happens for some games), the daemon
  queries the public PSN catalog endpoint to fetch the
  `GAMEHUB_COVER_ART` (16:9, fills the Remote 3 widget). Per-title
  cache so it's one extra HTTP call per title change, never per poll.
- Three knobs for power users: `PSN_PRESENCE_POLL_S` (default 30s)
  and `PSN_TOKENS_PATH` env vars in addition to the addon UI field.

### Changed
- `/state` now returns real `app` / `app_id` / `image_url` whenever
  presence is enabled and Sony reports a title (works around the
  empty-DDP issue). Falls back to DDP when presence is disabled or
  no PSN token is available.

### Removed
- DRM auto-disconnect watcher (added in v0.4.25). After real-world
  testing, only Sky Go and HBO Max actually require tearing down
  Remote Play to play; auto-disconnecting on a long list of apps
  was solving a non-problem and silently disabling the Remote 3
  during streaming was surprising. The `/disconnect?pause=N` and
  `/reconnect` HTTP endpoints remain — use them in a Remote 3
  activity or HA script for the apps that genuinely need it.

## [0.4.29] - 2026-05-09

### Changed
- **Default home image is now 16:9 (1024×576)** to match the Remote 3
  media-player widget aspect ratio — same dimensions Sky Q programme
  artwork uses. Previous PNG was 800×800 square so it letterboxed or
  cropped on the widget. The bundled gamepad illustration now fills
  the widget edge-to-edge.

### Added
- README pointer for users who'd prefer the official PS5 wordmark on
  the widget — paste a Wikimedia-hosted PNG render URL into the
  Configuration tab, no redistribution involved.

## [0.4.28] - 2026-05-09

### Changed
- README rewritten in plain-English step-by-step form for setting
  a custom media-player picture: "right-click the picture → Copy
  image address → check the link ends in .png/.jpg → paste it into
  the Configuration tab → Save → Restart". Adds a troubleshooting
  block for the most common confusions (link ends in .svg / copied
  the page URL instead of the image / hot-link blocking on Wikipedia
  / Pinterest / Imgur). Docs only.

## [0.4.27] - 2026-05-09

### Changed
- **Clearer instructions for setting your own media-player picture.**
  Added a dedicated step-by-step section to the README ("Use your own
  picture on the media-player widget"), and an in-UI description for
  the `home_image_url` Configuration field that explains exactly what
  format the URL needs to be in (direct PNG/JPG link), how to get one
  ("right-click → Copy image address"), and the common gotchas (SVG
  doesn't render, page URLs aren't image URLs, hot-link blocking).
- **Expanded "Control the PS5 from Home Assistant itself" section**
  with copy-paste `configuration.yaml` for `rest_command` services
  (wakeup / standby / button / launch) AND a REST sensor block for
  power / app / box-art. Plus dashboard-button, automation,
  voice-assist, and Mushroom media-player examples. Makes it obvious
  the add-on works even without a Remote 3. Docs only — no code change.

## [0.4.26] - 2026-05-09

### Changed
- **Default home image is now a PNG**, served from the daemon's own
  `/home_image` endpoint. The UC Remote 3 firmware only renders
  raster art (PNG/JPG); the previous default — an SVG hosted on
  Wikimedia Commons — wasn't displayed on the media-player widget
  even though the URL was set. The bundled PNG looks the same as
  before but actually appears on the Remote.
- `HOME_IMAGE_URL` add-on option still works for users who want a
  custom external URL (PNG/JPG only).

## [0.4.25] - 2026-05-09

### Added
- **Streaming-app compatibility.** When a DRM-protected streaming
  app (Netflix, Disney+, HBO Max / Max, Prime Video, NOW, BBC iPlayer,
  ITVX, Apple TV+, Sky Go / Sky Stream, YouTube, Paramount+, Discovery+,
  Twitch, Spotify, Plex / Jellyfin / Emby, etc.) is opened on the PS5,
  the add-on now automatically tears down the Remote Play session and
  pauses auto-reconnect. Those apps refuse to play while an RP session
  is connected; this restores playback without needing to manually call
  `/disconnect`. When the user closes the app or switches back to a
  game, the pause clears and the next button press re-establishes the
  session as usual.
- New env knobs (defaults work for most users):
  - `DRM_APPS` — comma-separated list to override / extend the DRM
    app match list (case-insensitive substring match).
  - `DRM_PAUSE_S` — how long the pause lasts after a DRM app is seen
    (default `300` s; refreshed every check cycle while the app stays
    in foreground).
  - `DRM_CHECK_S` — how often the watcher polls the foreground app
    (default `5` s).

## [0.4.24] - 2026-05-08

### Changed
- **Wakeup is now instant.** `POST /wakeup` returns as soon as the
  Wake-on-LAN packet is sent, instead of blocking up to 60 seconds
  waiting for the PS5 to finish booting. Cold-boot from rest mode
  takes 25–45 seconds — well past most HTTP timeouts — so callers
  (UC Remote 3 activities, HA scripts, voice intents) sometimes saw
  spurious timeout errors even though the PS5 was actually waking
  up correctly. Now the call completes in ~1 s; the daemon
  pre-warms the Remote Play session in the background so the first
  button press after wake is still instant. Power-state polling on
  the integration side picks up the "on" state within 10 seconds
  of the PS5 finishing boot.

## [0.4.23] - 2026-05-08

### Added
- **Migration cleanup notes** in the README for users coming from the
  older community `ps5-mqtt` add-on: uninstall the old add-on, delete any
  router port-forwards (`1883/tcp` / `8883/tcp`) added for the old setup,
  and optionally uninstall the Mosquitto broker if it isn't being used
  for anything else (e.g. Zigbee2MQTT).
- Top-level README links to the migration notes so they're visible
  before install.

### Changed
- Bumped `ps5-control` add-on to `0.4.23`. Docs-only release — no code
  changes.

## [0.4.22] - 2026-05-08

### Added
- `icon.png` and `logo.png` for the HA add-on store listing so the
  Supervisor renders the tile correctly.

## [0.4.21] - 2026-05-08

### Changed
- Default home / fallback image is the official PS5 wordmark hosted on
  Wikimedia Commons (URL, not bundled). User can override with
  `home_image_url`.

## [0.4.20] - 2026-05-08

### Added
- Bundled default home image at `/app/default-home-image.svg` and
  `home_image_url` add-on option.

## [0.4.17] - 2026-05-07

### Added
- "Open Web UI" button + index route synced with the standalone daemon.

## [0.4.16] - 2026-05-07

### Added
- Built-in PSN OAuth helper so users don't need a separate machine to
  fetch their PSN Account ID — works for private profiles too.
