from __future__ import annotations

from helpers import enable_service, write_executable, write_file, write_service


def setup(flags: dict[int, str]) -> None:
    write_file("/etc/ctf/flag_14", f"{flags[14]}\n", mode=0o600)
    write_executable(
        "/usr/local/bin/ctf_secret_process.sh",
        """#!/bin/bash
if [ -r /etc/ctf/flag_14 ]; then
    export CTF_SECRET_FLAG=$(cat /etc/ctf/flag_14)
fi
while true; do
    sleep 3600
done
""",
    )
    write_service(
        "ctf-secret-process.service",
        f"""[Unit]
Description=CTF Secret Process Challenge
After=network.target

[Service]
Type=simple
User=ctf_user
Group=ctf_user
Environment="CTF_SECRET_FLAG={flags[14]}"
ExecStart=/usr/local/bin/ctf_secret_process.sh
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
""",
    )
    enable_service("ctf-secret-process.service")
