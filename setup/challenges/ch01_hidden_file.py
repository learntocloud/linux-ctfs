"""Challenge 1: The Hidden File.

Learner goal: find and read a hidden file in ctf_challenges.
Skills tested: hidden files, directory listing.
Plants: a dotfile in /home/ctf_user/ctf_challenges containing flags[1].
"""

from __future__ import annotations

from helpers import write_file


def setup(flags: dict[int, str]) -> None:
    write_file("/home/ctf_user/ctf_challenges/.hidden_flag", f"{flags[1]}\n")
