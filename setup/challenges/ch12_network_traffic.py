from __future__ import annotations

from helpers import enable_service, write_executable, write_service


def setup(flags: dict[int, str]) -> None:
    flag_hex = flags[12].encode().hex()
    write_executable(
        "/usr/local/bin/ping_message.sh",
        f"""#!/bin/bash
while true; do
    ping -p {flag_hex} -c 1 127.0.0.1
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
StandardOutput=append:/var/log/ping_message.log
StandardError=append:/var/log/ping_message.log

[Install]
WantedBy=multi-user.target
""",
    )
    enable_service("ctf-ping-message.service")
