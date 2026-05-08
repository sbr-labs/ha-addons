# Changelog

All notable changes to the SBR Labs HA add-ons repo are recorded here.
Versions track the `ps5-control` add-on (the only add-on in the repo right
now). Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning is [SemVer](https://semver.org/spec/v2.0.0.html).

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
