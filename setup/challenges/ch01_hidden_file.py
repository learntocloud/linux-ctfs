from __future__ import annotations

from helpers import write_file


def setup(flags: dict[int, str]) -> None:
    write_file("/home/ctf_user/ctf_challenges/.hidden_flag", f"{flags[1]}\n")
