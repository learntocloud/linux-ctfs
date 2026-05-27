from __future__ import annotations

from pathlib import Path

from helpers import ensure_user, recursive_chown, write_file


def setup(flags: dict[int, str]) -> None:
    ensure_user("flag_user")
    write_file("/home/flag_user/.profile", f"{flags[4]}\n", mode=0o644)
    recursive_chown("/home/flag_user", "flag_user", "flag_user")
    Path("/home/flag_user").chmod(0o755)
