from __future__ import annotations

from helpers import write_file


def setup(flags: dict[int, str]) -> None:
    write_file("/opt/systems/config/system.conf", f"{flags[5]}\n", mode=0o777)
