from __future__ import annotations

from helpers import ensure_user, run


def setup(flags: dict[int, str]) -> None:
    ensure_user("flag_user")
    run(["usermod", "-c", f"Service account {flags[4]}", "flag_user"])
