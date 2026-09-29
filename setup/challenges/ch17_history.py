from __future__ import annotations

from pathlib import Path
import random

from helpers import ensure_user, write_file


COMMANDS = [
    "ls -la", "cd /var/log", "tail -f syslog", "df -h", "free -m", "top", "sudo apt update",
    "sudo apt upgrade -y", "systemctl status nginx", "cd /etc/nginx", "vim nginx.conf",
    "sudo systemctl restart nginx", "git pull", "docker ps", "cat /etc/hosts", "ps aux",
    "netstat -tulpn", "journalctl -u ssh", "crontab -l", "whoami", "uptime", "history",
]


def setup(flags: dict[int, str]) -> None:
    ensure_user("old_admin")
    rng = random.Random()
    lines = [rng.choice(COMMANDS) for _ in range(400)]
    lines.insert(rng.randrange(100, 300), f"export DEPLOY_KEY={flags[17]}")
    write_file(
        "/home/old_admin/.bash_history",
        "\n".join(lines) + "\nexit\n",
        mode=0o644,
        owner="old_admin",
        group="old_admin",
    )
    Path("/home/old_admin").chmod(0o755)
