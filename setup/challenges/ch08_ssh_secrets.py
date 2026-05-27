from __future__ import annotations

from pathlib import Path

from helpers import recursive_chown, write_file


def setup(flags: dict[int, str]) -> None:
    flag_path = "/home/ctf_user/.ssh/secrets/backup/.authorized_keys"
    write_file(flag_path, f"{flags[8]}\n", mode=0o600)
    recursive_chown("/home/ctf_user/.ssh", "ctf_user", "ctf_user")
    Path("/home/ctf_user/.ssh").chmod(0o700)
