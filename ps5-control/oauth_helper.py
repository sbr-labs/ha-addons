"""OAuth helper for HAOS users who can't run get-account-id.sh externally.

Two modes:
  python oauth_helper.py print-login-url
      → prints Sony's OAuth login URL on stdout

  python oauth_helper.py extract-id <redirect_url>
      → prints the base64 PSN Account ID extracted from the post-login
        redirect URL on stdout

Wraps `pyremoteplay.oauth.{get_login_url, get_user_account}`. Handles the
decimal → base64 conversion fallback so the output is always the form
that `pyremoteplay.RPDevice.register()` actually accepts.
"""

from __future__ import annotations

import base64
import sys


def main() -> int:
    if len(sys.argv) < 2:
        print(
            "Usage: oauth_helper.py [print-login-url | extract-id <redirect_url>]",
            file=sys.stderr,
        )
        return 64

    try:
        from pyremoteplay.oauth import get_login_url, get_user_account
    except ImportError as exc:  # noqa: BLE001
        print(f"pyremoteplay missing: {exc}", file=sys.stderr)
        return 70

    cmd = sys.argv[1]

    if cmd == "print-login-url":
        print(get_login_url())
        return 0

    if cmd == "extract-id":
        if len(sys.argv) < 3 or not sys.argv[2].strip():
            print("extract-id requires a redirect URL", file=sys.stderr)
            return 64

        url = sys.argv[2].strip()
        try:
            info = get_user_account(url)
        except Exception as exc:  # noqa: BLE001
            print(f"OAuth fetch failed: {exc}", file=sys.stderr)
            print(
                "Most common cause: the redirect URL was incomplete, expired, "
                "or copied without the trailing query string.",
                file=sys.stderr,
            )
            return 3

        if not isinstance(info, dict):
            print(f"Unexpected response shape: {info!r}", file=sys.stderr)
            return 4

        # Prefer the base64 form pyremoteplay actually uses (`user_rpid`).
        # Fall back to converting decimal `user_id` locally if missing.
        account_id = info.get("user_rpid") or info.get("account_id_base64")
        if not account_id:
            decimal_id = info.get("user_id") or info.get("account_id")
            if decimal_id and str(decimal_id).isdigit():
                account_id = base64.b64encode(
                    int(decimal_id).to_bytes(8, "little")
                ).decode()

        if not account_id:
            print(
                f"Could not extract Account ID from OAuth response: {info}",
                file=sys.stderr,
            )
            return 5

        print(account_id)
        return 0

    print(f"Unknown command: {cmd!r}", file=sys.stderr)
    return 64


if __name__ == "__main__":
    sys.exit(main())
