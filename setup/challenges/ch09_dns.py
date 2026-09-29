"""Challenge 9: DNS Inspection.

Learner goal: find the lab's custom search domain and resolve a host inside it.
Skills tested: DNS, name resolution.
Plants: a resolved.conf.d search domain and an /etc/hosts entry carrying flags[9].
"""

from __future__ import annotations

from helpers import append_line_once, restart_service, write_file


def setup(flags: dict[int, str]) -> None:
    write_file(
        "/etc/systemd/resolved.conf.d/ctf-dns.conf",
        """# Internal search domain for the lab intranet.
[Resolve]
Domains=ctf-lab.internal
""",
        mode=0o644,
    )
    append_line_once("/etc/hosts", f"10.10.10.10 intranet.ctf-lab.internal {flags[9]}")
    restart_service("systemd-resolved")
