from __future__ import annotations

from pathlib import Path

from helpers import write_file


def setup(flags: dict[int, str]) -> None:
    hidden = Path("/var/lib/ctf/secrets/deep/hidden")
    final_target = hidden / flags[16]
    write_file(final_target, "You reached the end of the trail. The flag is the name of this file.\n", mode=0o644)
    links = [
        (final_target, Path("/var/lib/ctf/secrets/deep/link3")),
        (Path("deep/link3"), Path("/var/lib/ctf/secrets/link2")),
        (Path("/var/lib/ctf/secrets/link2"), Path("/home/ctf_user/ctf_challenges/follow_me")),
    ]
    for target, link in links:
        link.unlink(missing_ok=True)
        link.symlink_to(target)
    for directory in (
        Path("/var/lib/ctf"),
        Path("/var/lib/ctf/secrets"),
        Path("/var/lib/ctf/secrets/deep"),
    ):
        directory.chmod(0o755)
    hidden.chmod(0o711)  # traversable but not listable, so the name only shows via readlink
