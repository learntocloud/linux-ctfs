"""Challenge 5: The Permissive File.

Learner goal: find a suspicious wide-open file under /opt, then follow where it leads.
Skills tested: permissions, file ownership.
Plants: /opt/systems config that points to /opt/systems/keys/master.key (mode 000) holding flags[5].
"""

from __future__ import annotations

from pathlib import Path

from helpers import recursive_chown, write_file


def setup(flags: dict[int, str]) -> None:
    write_file(
        "/opt/systems/config/system.conf",
        "# Access keys were moved to /opt/systems/keys/master.key after the last audit.\n",
        mode=0o777,
    )
    write_file("/opt/systems/keys/master.key", f"{flags[5]}\n", mode=0o000)
    recursive_chown("/opt/systems/keys", "ctf_user", "ctf_user")
    Path("/opt/systems/keys").chmod(0o755)
