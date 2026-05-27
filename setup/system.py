from __future__ import annotations

import socket
from pathlib import Path

from helpers import append_line_once, ensure_user, restart_service, run, set_password, write_file


CTF_PASSWORD = "CTFpassword123!"
DONE_MARKER = "/var/lib/cloud/instance/ctf-setup.done"
APT_OPTIONS = [
    "-o",
    "DPkg::Lock::Timeout=120",
    "-o",
    "Acquire::Retries=3",
]


def apt_get(*arguments: str) -> None:
    run(["apt-get", *APT_OPTIONS, *arguments])


def install_packages() -> None:
    packages = [
        "net-tools",
        "nmap",
        "tree",
        "nginx",
        "inotify-tools",
        "netcat-openbsd",
        "tcpdump",
    ]
    apt_get("update")
    apt_get("install", "-y", *packages)


def configure_motd_support() -> None:
    for file_path in Path("/etc/update-motd.d").glob("*"):
        try:
            file_path.chmod(file_path.stat().st_mode & ~0o111)
        except FileNotFoundError:
            continue

    write_file(
        "/etc/motd",
        """+==============================================+
|  Learn To Cloud - Linux Command Line CTF    |
+==============================================+

Welcome! Here are 18 Progressive Linux Challenges.
Refer to the readme for information on each challenge.

Once you find a flag, use our verify tool to check your answer
and review your progress.

Usage:
  verify [challenge number] [flag] - Submit flag for verification
  verify 0 CTF{example} - Example flag (required)
  verify progress     - Shows your progress
  verify time         - Shows elapsed wall clock time

  Run this first to initialize progress: verify 0 CTF{example}
  Note: Timer starts on your first challenge submission.
  It freezes on your first successful verify export after 18/18.

When you complete all challenges, run: verify export <your-github-username>
Save the token it generates. You'll need it to verify your
progress at https://learntocloud.guide

Good luck!
Team L2C

+==============================================+
""",
        mode=0o644,
    )

    for pam_file in (Path("/etc/pam.d/login"), Path("/etc/pam.d/sshd")):
        if not pam_file.exists():
            continue
        content = pam_file.read_text()
        content = content.replace(
            "#session    optional     pam_motd.so",
            "session    optional     pam_motd.so",
        )
        pam_file.write_text(content)


def configure_users() -> None:
    ensure_user("ctf_user", sudo=True)
    set_password("ctf_user", CTF_PASSWORD)
    Path("/home/ctf_user/ctf_challenges").mkdir(parents=True, exist_ok=True)


def configure_shell_profile() -> None:
    write_file(
        "/etc/profile.d/fix-term.sh",
        'case "$TERM" in *-ghostty) export TERM=xterm-256color;; esac\n',
        mode=0o644,
    )

    write_file(
        "/usr/local/bin/check_setup",
        f"""#!/bin/bash
if [ ! -f {DONE_MARKER} ]; then
    echo "System is still being configured. Please wait..."
    exit 1
fi
""",
        mode=0o755,
    )
    append_line_once("/home/ctf_user/.profile", "/usr/local/bin/check_setup")


def configure_ssh() -> None:
    write_file(
        "/etc/ssh/sshd_config.d/99-ctf-password-auth.conf",
        """PasswordAuthentication yes
KbdInteractiveAuthentication yes
ChallengeResponseAuthentication yes
""",
        mode=0o644,
    )

    sshd_config = Path("/etc/ssh/sshd_config")
    content = sshd_config.read_text()
    replacements = {
        "PasswordAuthentication no": "PasswordAuthentication yes",
        "ChallengeResponseAuthentication no": "ChallengeResponseAuthentication yes",
        "KbdInteractiveAuthentication no": "KbdInteractiveAuthentication yes",
    }
    for old, new in replacements.items():
        content = content.replace(old, new)
    sshd_config.write_text(content)
    restart_service("ssh")


def configure_hostname() -> None:
    hostname = socket.gethostname()
    hosts = Path("/etc/hosts")
    content = hosts.read_text()
    if hostname not in content:
        with hosts.open("a") as file:
            file.write(f"127.0.0.1 {hostname}\n")


def configure_system() -> None:
    install_packages()
    configure_users()
    configure_shell_profile()
    configure_ssh()
    configure_motd_support()
    configure_hostname()
