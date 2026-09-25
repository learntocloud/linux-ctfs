from __future__ import annotations

from helpers import enable_service, write_executable, write_file, write_service


def setup(flags: dict[int, str]) -> None:
    # systemd reads EnvironmentFile= as root, so the flag never appears in the
    # unit file or `systemctl show`; it only lives in the process environment.
    write_file("/etc/ctf/flag_14.env", f"CTF_SECRET_FLAG={flags[14]}\n", mode=0o600)
    write_executable(
        "/usr/local/bin/ctf_secret_process.sh",
        """#!/bin/bash
while true; do
    sleep 3600
done
""",
    )
    write_service(
        "ctf-secret-process.service",
        """[Unit]
Description=CTF Secret Process Challenge
After=network.target

[Service]
Type=simple
User=ctf_user
Group=ctf_user
EnvironmentFile=/etc/ctf/flag_14.env
ExecStart=/usr/local/bin/ctf_secret_process.sh
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
""",
    )
    enable_service("ctf-secret-process.service")
