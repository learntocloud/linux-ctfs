"""Challenge 4: The User Detective.

Learner goal: find the flag in another user's account record.
Skills tested: users, account records.
Plants: flag_user with flags[4] in its GECOS (comment) field.
"""

from __future__ import annotations

from helpers import ensure_user, run


def setup(flags: dict[int, str]) -> None:
    ensure_user("flag_user")
    run(["usermod", "-c", f"Service account {flags[4]}", "flag_user"])
