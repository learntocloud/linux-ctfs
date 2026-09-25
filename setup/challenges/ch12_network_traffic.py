from __future__ import annotations

from helpers import enable_service, write_executable, write_file, write_service


def setup(flags: dict[int, str]) -> None:
    write_file("/etc/ctf/flag_12", flags[12], mode=0o600)
    # The pattern is built at runtime from a root-only file and ping's output is
    # discarded, so the flag only exists on the wire.
    write_executable(
        "/usr/local/bin/ping_message.sh",
        """#!/bin/bash
PATTERN=$(od -An -tx1 /etc/ctf/flag_12 | tr -d ' \\n')
while true; do
    ping -q -p "$PATTERN" -c 1 127.0.0.1 >/dev/null 2>&1
    sleep 1
done
""",
    )
    write_service(
        "ctf-ping-message.service",
        """[Unit]
Description=CTF Ping Message Challenge
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ping_message.sh
Restart=always
RestartSec=1
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
""",
    )
    enable_service("ctf-ping-message.service")
