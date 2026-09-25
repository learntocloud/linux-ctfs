from __future__ import annotations

from helpers import enable_service, write_executable, write_file, write_service


def setup(flags: dict[int, str]) -> None:
    write_file("/etc/ctf/flag_8", f"{flags[8]}\n", mode=0o600)
    # Watch sshd's own journal entries (matched on the trusted _COMM field, so
    # `logger` can't fake them) and award the flag on the first key-based login.
    write_executable(
        "/usr/local/bin/ctf_ssh_key_watch.sh",
        """#!/bin/bash
journalctl -f -n 0 -o cat _COMM=sshd _COMM=sshd-session | while read -r LINE; do
    case "$LINE" in
        "Accepted publickey for ctf_user "*)
            install -o ctf_user -g ctf_user -m 600 /etc/ctf/flag_8 /var/lib/ctf-rewards/flag_8
            ;;
    esac
done
""",
    )
    write_service(
        "ctf-ssh-key-watch.service",
        """[Unit]
Description=CTF SSH Key Authentication Challenge
After=systemd-journald.service

[Service]
Type=simple
ExecStart=/usr/local/bin/ctf_ssh_key_watch.sh
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
""",
    )
    enable_service("ctf-ssh-key-watch.service")
