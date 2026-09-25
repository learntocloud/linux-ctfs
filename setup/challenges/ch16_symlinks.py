from __future__ import annotations

from pathlib import Path

from helpers import write_file


SECRETS = Path("/var/lib/ctf/secrets")


def setup(flags: dict[int, str]) -> None:
    # The flag is part of the final target's path, not its contents, so
    # `cat follow_me` isn't enough - the learner has to resolve the chain.
    final_target = SECRETS / "deep" / flags[16] / "end_of_the_trail.txt"
    write_file(
        final_target,
        "You reached the end of the trail. The flag isn't written in this file - look at where it lives.\n",
        mode=0o644,
    )
    links = [
        (final_target, SECRETS / "deep" / "link3"),
        (SECRETS / "deep" / "link3", SECRETS / "link2"),
        (SECRETS / "link2", Path("/home/ctf_user/ctf_challenges/follow_me")),
    ]
    for target, link in links:
        link.unlink(missing_ok=True)
        link.symlink_to(target)
    for directory in (Path("/var/lib/ctf"), SECRETS, SECRETS / "deep", final_target.parent):
        directory.chmod(0o755)
