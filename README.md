# PS5 Control — Home Assistant add-on

Home Assistant add-on that runs the [`ps5-control-uc`](https://github.com/sbr-labs/ps5-control-uc) daemon directly on your HAOS / HA Supervised box. Drives a PlayStation 5 over Sony Remote Play, exposes an HTTP API on port `8456` for the Unfolded Circle Remote 3 (or anything else: HA scripts, voice intents, custom dashboards).

## Add this repo to HA

Home Assistant → **Settings → Add-ons → Add-on Store → ⋮ → Repositories**, paste:

```
https://github.com/sbr-labs/ha-addons
```

Click **Add**, refresh. A new "PS5 Control" entry appears under "PS5 Control add-ons" — click it, then **Install**.

## Add-on docs

See [`ps5-control/README.md`](ps5-control/README.md) for setup, pairing, and troubleshooting.

> **Coming from `ps5-mqtt`?** See the [migration cleanup notes](ps5-control/README.md#migrating-from-the-older-ps5-mqtt-add-on) — uninstall the old add-on and delete any 1883/8883 port-forwards you added for it. This add-on is LAN-only on `8456`.

## License

MIT — see [LICENSE](LICENSE).
