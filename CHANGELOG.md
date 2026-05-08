# Changelog

All notable changes to the SBR Labs HA add-ons repo are recorded here.
Versions track the `ps5-control` add-on (the only add-on in the repo right
now). Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning is [SemVer](https://semver.org/spec/v2.0.0.html).

## [0.4.23] - 2026-05-08

### Added
- **README migration & security section** for users coming from the legacy
  `ps5-mqtt` add-on. Tells users to uninstall the old add-on, remove any
  router port-forwards for `1883/tcp` and `8883/tcp`, and verify Mosquitto
  is LAN-only. This resolves the "insecure MQTT service detected"
  warnings UK ISPs (Vodafone, BT, EE, Sky) send to home users when a
  Mosquitto broker is left exposed on the WAN — it isn't caused by this
  add-on (no MQTT here), but the warning is a common consequence of
  upgrading from the old MQTT-based PS5 add-on without cleaning up.
- Top-level README links to the migration warning so it's visible
  before install.

### Changed
- Bumped `ps5-control` add-on to `0.4.23`. No code changes — docs only.

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
