"""Challenge 16: Symbolic Sleuth.

Learner goal: follow a trail of symbolic links; the flag is where the trail ends.
Skills tested: symbolic links.
Plants: a five-link chain from ctf_challenges/follow_me to a final file named flags[16], plus decoy links to a fake flag.
"""

from __future__ import annotations

from pathlib import Path

from helpers import write_file


def setup(flags: dict[int, str]) -> None:
    hidden = Path("/var/lib/ctf/secrets/deep/hidden")
    final_target = hidden / flags[16]
    write_file(final_target, "You reached the end of the trail. The flag is the name of this file.\n", mode=0o644)

    decoy_target = Path("/var/lib/ctf/decoy/CTF{decoy_trail}")
    write_file(decoy_target, "Nice try. This trail was a decoy.\n", mode=0o644)

    links = [
        (final_target, Path("/var/lib/ctf/secrets/vault/link5")),
        (Path("link5"), Path("/var/lib/ctf/secrets/vault/link4")),
        (Path("../vault/link4"), Path("/var/lib/ctf/secrets/deep/link3")),
        (Path("deep/link3"), Path("/var/lib/ctf/secrets/link2")),
        (Path("/var/lib/ctf/secrets/link2"), Path("/home/ctf_user/ctf_challenges/follow_me")),
        (decoy_target, Path("/var/lib/ctf/secrets/deep/link3_old")),
        (Path("deep/link3_old"), Path("/var/lib/ctf/secrets/link2_old")),
    ]
    for target, link in links:
        link.parent.mkdir(parents=True, exist_ok=True)
        link.unlink(missing_ok=True)
        link.symlink_to(target)
    for directory in (
        Path("/var/lib/ctf"),
        Path("/var/lib/ctf/secrets"),
        Path("/var/lib/ctf/secrets/deep"),
        Path("/var/lib/ctf/secrets/vault"),
    ):
        directory.chmod(0o755)
    hidden.chmod(0o711)
    decoy_target.parent.chmod(0o711)
