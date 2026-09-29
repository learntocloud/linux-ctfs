"""Challenge 15: Archive Archaeologist.

Learner goal: dig a flag out of nested archives.
Skills tested: archives, compression.
Plants: /home/ctf_user/ctf_challenges/mystery_archive.tar.gz with flags[15] buried inside.
"""

from __future__ import annotations

import tarfile
import tempfile
from pathlib import Path


def setup(flags: dict[int, str]) -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        (temp_path / "flag.txt").write_text(f"{flags[15]}\n")
        with tarfile.open(temp_path / "inner.tar.xz", "w:xz") as archive:
            archive.add(temp_path / "flag.txt", arcname="flag.txt")
        with tarfile.open(temp_path / "middle.tar.bz2", "w:bz2") as archive:
            archive.add(temp_path / "inner.tar.xz", arcname="inner.tar.xz")
        with tarfile.open("/home/ctf_user/ctf_challenges/mystery_archive.tar.gz", "w:gz") as archive:
            archive.add(temp_path / "middle.tar.bz2", arcname="middle.tar.bz2")
