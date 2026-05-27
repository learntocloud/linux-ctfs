from __future__ import annotations

from helpers import write_file


def setup(flags: dict[int, str]) -> None:
    write_file("/home/ctf_user/documents/projects/backup/secret_notes.txt", f"{flags[2]}\n")
