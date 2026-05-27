from __future__ import annotations

from helpers import write_file


def setup(flags: dict[int, str]) -> None:
    write_file(
        "/etc/systemd/resolved.conf.d/ctf-dns.conf",
        f"""# CTF Challenge 9: DNS inspection
# The live resolver file is intentionally left untouched.
# FLAG: {flags[9]}

[Resolve]
# This drop-in is harmless. It exists so learners can inspect systemd-resolved config safely.
""",
        mode=0o644,
    )
