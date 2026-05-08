"""One-shot Remote Play pairing helper for the HA add-on.

Reads PS5 host, PSN Account ID, and 8-digit PIN from the command line,
runs `pyremoteplay.RPDevice.register()` against the PS5, and writes the
resulting credentials.json to the path given. Exits 0 on success, non-0
on failure with a short error to stderr.

Mirrors the inline Python from the main repo's `pair.sh` so the add-on
produces credentials.json in the exact same native pyremoteplay format
that the daemon's loader accepts.

Usage:
    python pair.py <ps5_host> <account_id_base64> <pin> <out_path>
"""

from __future__ import annotations

import base64
import json
import sys
from pathlib import Path


def to_base64_account_id(value: str) -> str:
    """Forgiving Account ID input.

    pyremoteplay's `register()` only accepts the base64 form. Sony's OAuth
    response carries the same value as decimal `user_id` — if the user
    pasted that by mistake, convert here so we don't fail later with an
    inscrutable error.
    """
    value = value.strip()
    if value.isdigit():
        return base64.b64encode(int(value).to_bytes(8, "little")).decode()
    return value


def main() -> int:
    if len(sys.argv) != 5:
        print("Usage: pair.py <ps5_host> <account_id> <pin> <out_path>", file=sys.stderr)
        return 64

    ps5_host, account_id, pin, out_path = sys.argv[1:]
    account_id = to_base64_account_id(account_id)

    try:
        from pyremoteplay import RPDevice
        from pyremoteplay.profile import Profiles, UserProfile
    except ImportError as exc:
        print(f"pyremoteplay not installed inside the add-on container: {exc}", file=sys.stderr)
        return 70

    device = RPDevice(ps5_host)
    if not device.get_status():
        print(f"ERROR: Could not reach PS5 at {ps5_host}", file=sys.stderr)
        return 1

    profiles = Profiles()
    profiles.update_user(UserProfile("shared-user", {"id": account_id, "hosts": {}}))

    result = device.register("shared-user", pin, profiles=profiles, save=False)
    if not result:
        print(
            "ERROR: Registration failed. Check the PIN is current "
            "(generate a fresh one on the PS5 right before this), and that "
            "the Account ID is correct.",
            file=sys.stderr,
        )
        return 2

    # Same on-disk format as the standalone repo's pair.sh writes — daemon's
    # build_profiles_from_creds() loads either this format or the legacy
    # ps5-mqtt format.
    out = dict(profiles)
    out_p = Path(out_path)
    out_p.parent.mkdir(parents=True, exist_ok=True)
    out_p.write_text(json.dumps(out, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
