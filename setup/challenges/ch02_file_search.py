"""Challenge 2: The Secret File.

Learner goal: locate a regular file with "secret" in its name under the home directory.
Skills tested: file searching.
Plants: a nested file under /home/ctf_user/documents containing flags[2].
"""

from __future__ import annotations

from helpers import write_file


def setup(flags: dict[int, str]) -> None:
    write_file("/home/ctf_user/documents/projects/backup/secret_notes.txt", f"{flags[2]}\n")
