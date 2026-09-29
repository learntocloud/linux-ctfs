"""Challenge 3: The Odd Log Entry.

Learner goal: find the single successful login among thousands of failed ones in a log under /var/log.
Skills tested: log analysis, text filtering.
Plants: /var/log/auth_audit.log with flags[3] on the one "Accepted" line.
"""

from __future__ import annotations

import random
from pathlib import Path

from helpers import run


FAILED_ATTEMPTS = 50_000
USERS = ["root", "admin", "test", "oracle", "postgres", "ubuntu", "deploy", "git", "guest", "backup"]


def setup(flags: dict[int, str]) -> None:
    rng = random.Random()
    success_at = rng.randrange(FAILED_ATTEMPTS // 4, FAILED_ATTEMPTS * 3 // 4)
    log_file = Path("/var/log/auth_audit.log")

    with log_file.open("w") as file:
        for index in range(FAILED_ATTEMPTS):
            minute, second = divmod(index % 3600, 60)
            stamp = f"Sep 29 {(index // 3600) % 24:02d}:{minute:02d}:{second:02d}"
            ip = f"{rng.randint(11, 223)}.{rng.randint(0, 255)}.{rng.randint(0, 255)}.{rng.randint(1, 254)}"
            file.write(
                f"{stamp} ctf-vm sshd[{rng.randint(1000, 32000)}]: "
                f"Failed password for {rng.choice(USERS)} from {ip} port {rng.randint(1024, 65535)} ssh2\n"
            )
            if index == success_at:
                file.write(
                    f"{stamp} ctf-vm sshd[{rng.randint(1000, 32000)}]: "
                    f"Accepted password for {flags[3]} from 203.0.113.7 port 51022 ssh2\n"
                )

    run(["chown", "ctf_user:ctf_user", str(log_file)])
