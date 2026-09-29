from __future__ import annotations

from helpers import write_executable, write_file


def setup(flags: dict[int, str]) -> None:
    write_file("/etc/ctf/flag_13", f"{flags[13]}\n", mode=0o600)
    write_executable(
        "/opt/scripts/nightly_backup.sh",
        """#!/bin/bash
umask 022
echo "$(date -Is) backup ok, audit token: $(cat /etc/ctf/flag_13)" > /var/tmp/backup_status.log
""",
    )
    write_file(
        "/etc/cron.d/nightly_backup",
        """# Nightly backup (runs every minute in the lab)
* * * * * root /opt/scripts/nightly_backup.sh
""",
        mode=0o644,
    )
