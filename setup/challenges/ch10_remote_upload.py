from __future__ import annotations

from helpers import enable_service, write_executable, write_file, write_service


def setup(flags: dict[int, str]) -> None:
    write_file("/etc/ctf/flag_10", f"{flags[10]}\n", mode=0o600)
    write_executable(
        "/usr/local/bin/monitor_directory.sh",
        """#!/bin/bash
DIRECTORY="/home/ctf_user/ctf_challenges"
FLAG=$(cat /etc/ctf/flag_10)
while [ ! -f /var/lib/cloud/instance/ctf-setup.done ]; do
    sleep 5
done
sleep 10
touch /tmp/.ctf_upload_triggered 2>/dev/null || true
chmod 666 /tmp/.ctf_upload_triggered 2>/dev/null || true
inotifywait -m -e create --format '%f' "$DIRECTORY" | while read FILE
do
    {
        printf '\\n========== CHALLENGE 10: REMOTE UPLOAD =========='
        printf '\\nA new file was uploaded to %s.' "$DIRECTORY"
        printf '\\nHere is your flag: %s' "$FLAG"
        printf '\\n==================================================\\n'
    } | wall
    echo "$FLAG" > /tmp/.ctf_upload_triggered
    sync
done
""",
    )
    write_service(
        "ctf-monitor-directory.service",
        """[Unit]
Description=CTF Directory Monitor Challenge
After=local-fs.target

[Service]
Type=simple
ExecStart=/usr/local/bin/monitor_directory.sh
Restart=always
RestartSec=1
StandardOutput=append:/var/log/monitor_directory.log
StandardError=append:/var/log/monitor_directory.log

[Install]
WantedBy=multi-user.target
""",
    )
    enable_service("ctf-monitor-directory.service")
