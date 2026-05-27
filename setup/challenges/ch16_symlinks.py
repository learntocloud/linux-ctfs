from __future__ import annotations

from pathlib import Path

from helpers import write_file


def setup(flags: dict[int, str]) -> None:
    write_file("/var/lib/ctf/secrets/deep/hidden/final_flag.txt", f"{flags[16]}\n", mode=0o644)
    links = [
        (Path("/var/lib/ctf/secrets/deep/hidden/final_flag.txt"), Path("/var/lib/ctf/secrets/deep/link3")),
        (Path("/var/lib/ctf/secrets/deep/link3"), Path("/var/lib/ctf/secrets/link2")),
        (Path("/var/lib/ctf/secrets/link2"), Path("/home/ctf_user/ctf_challenges/follow_me")),
    ]
    for target, link in links:
        link.unlink(missing_ok=True)
        link.symlink_to(target)
    for directory in (
        Path("/var/lib/ctf"),
        Path("/var/lib/ctf/secrets"),
        Path("/var/lib/ctf/secrets/deep"),
        Path("/var/lib/ctf/secrets/deep/hidden"),
    ):
        directory.chmod(0o755)
