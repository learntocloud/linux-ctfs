from __future__ import annotations

from helpers import enable_service, write_executable, write_file, write_service


def setup(flags: dict[int, str]) -> None:
    write_file("/etc/ctf/flag_6", f"{flags[6]}\n", mode=0o600)
    write_executable(
        "/usr/local/bin/secret_service.sh",
        """#!/bin/bash
FLAG=$(cat /etc/ctf/flag_6)
FLAG_LEN=${#FLAG}
while true; do
    echo -e "HTTP/1.1 200 OK\\r\\nContent-Length: ${FLAG_LEN}\\r\\nConnection: close\\r\\n\\r\\n${FLAG}" | nc -l -q 1 8080
done
""",
    )
    write_service(
        "ctf-secret-service.service",
        """[Unit]
Description=CTF Secret Service Challenge
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/secret_service.sh
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
""",
    )
    enable_service("ctf-secret-service.service")
