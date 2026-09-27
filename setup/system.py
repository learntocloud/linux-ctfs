from __future__ import annotations

import socket
from pathlib import Path

from external_rewards import configure_external_rewards
from helpers import (
    CHALLENGE_DIR,
    DONE_MARKER,
    append_line_once,
    ensure_user,
    restart_service,
    run,
    set_password,
    write_file,
)


CTF_PASSWORD = "CTFpassword123!"
APT_OPTIONS = [
    "-o",
    "DPkg::Lock::Timeout=120",
    "-o",
    "Acquire::Retries=3",
]


def apt_get(*arguments: str) -> None:
    run(["apt-get", *APT_OPTIONS, *arguments])


# Tools learners are expected to use. Packages a challenge needs to run its
# own setup belong in that challenge module's PACKAGES list.
LEARNER_PACKAGES = [
    "net-tools",
    "nmap",
    "tree",
    "tcpdump",
    "dnsutils",
]


def install_packages(challenge_packages: list[str]) -> None:
    packages = sorted({*LEARNER_PACKAGES, *challenge_packages})
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

Welcome to the lab.

Start here:
  verify 0 CTF{example}

Useful commands:
  verify [challenge number] [flag]
  verify progress
  verify time

Finished all 18 challenges?
  verify export <your-github-username>

Save your export token for learntocloud.guide.

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
    CHALLENGE_DIR.mkdir(parents=True, exist_ok=True)


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


def configure_system(challenge_packages: list[str]) -> None:
    install_packages(challenge_packages)
    configure_users()
    configure_shell_profile()
    # Before configure_ssh(), whose sshd restart applies the rewards drop-in.
    configure_external_rewards()
    configure_ssh()
    configure_motd_support()
    configure_hostname()
