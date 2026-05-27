from __future__ import annotations

from helpers import write_file


def setup(flags: dict[int, str]) -> None:
    write_file(
        "/etc/cron.d/ctf_secret_task",
        f"""# CTF Challenge - Secret scheduled task
# This task runs every minute but the flag is hidden here
# FLAG: {flags[13]}
* * * * * root /bin/true
""",
        mode=0o644,
    )
