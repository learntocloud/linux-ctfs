from __future__ import annotations

from helpers import CHALLENGE_DIR, write_file


def setup(flags: dict[int, str]) -> None:
    write_file(CHALLENGE_DIR / ".hidden_flag", f"{flags[1]}\n")
