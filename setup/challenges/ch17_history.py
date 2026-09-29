"""Challenge 17: History Mystery.

Learner goal: find a secret someone typed into their command line.
Skills tested: shell history, text search.
Plants: .bash_history files for three users, each with decoy secrets; one holds flags[17] in a command line.
"""

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


DECOY_SECRETS = [
    "export API_KEY=sk_live_51Hq7xT2eZvKYlo2C",
    "export DB_PASSWORD=hunter2",
    "export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCY",
    "export SLACK_TOKEN=xoxb-0000-0000-placeholder",
    "mysql -u root -pchangeme123 -h db01",
    "curl -H 'Authorization: Bearer expired-token-do-not-use' https://api.example.internal/v1/status",
    "sshpass -p 'Summer2019!' ssh backup@10.0.0.5",
    "git remote add origin https://deploy:notarealtoken@git.example.internal/app.git",
]

USERS = ("old_admin", "deploy", "intern")


def setup(flags: dict[int, str]) -> None:
    rng = random.Random()
    flag_owner = rng.choice(USERS)
    for user in USERS:
        ensure_user(user)
        lines = [rng.choice(COMMANDS) for _ in range(400)]
        for secret in rng.sample(DECOY_SECRETS, 4):
            lines.insert(rng.randrange(0, len(lines)), secret)
        if user == flag_owner:
            lines.insert(
                rng.randrange(100, 300),
                f"curl -H 'X-Deploy-Token: {flags[17]}' https://deploy.example.internal/release",
            )
        write_file(
            f"/home/{user}/.bash_history",
            "\n".join(lines) + "\nexit\n",
            mode=0o644,
            owner=user,
            group=user,
        )
        Path(f"/home/{user}").chmod(0o755)
