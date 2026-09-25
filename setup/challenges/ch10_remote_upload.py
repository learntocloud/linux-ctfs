from __future__ import annotations

from helpers import enable_service, run, write_executable, write_file, write_service


DIRECTORY = "/home/ctf_user/ctf_challenges"


def setup(flags: dict[int, str]) -> None:
    write_file("/etc/ctf/flag_10", f"{flags[10]}\n", mode=0o600)

    # auditd records which program created each file, so a file made on the VM
    # itself (touch, editors, cp) doesn't count - only scp/sftp from outside.
    write_file(
        "/etc/audit/rules.d/ctf-upload.rules",
        f"""-a always,exit -F dir={DIRECTORY} -F perm=wa -F exe=/usr/lib/openssh/sftp-server -k ctf_upload
-a always,exit -F dir={DIRECTORY} -F perm=wa -F exe=/usr/bin/scp -k ctf_upload
""",
        mode=0o640,
    )
    run(["augenrules", "--load"])

    write_executable(
        "/usr/local/bin/monitor_directory.sh",
        f"""#!/bin/bash
DIRECTORY="{DIRECTORY}"
while [ ! -f /var/lib/cloud/instance/ctf-setup.done ]; do
    sleep 5
done

uploaded_remotely() {{
    for _ in $(seq 1 10); do
        # --input-logs: ausearch otherwise reads stdin, which is the inotify stream here
        if ausearch --input-logs -k ctf_upload -ts recent -i </dev/null 2>/dev/null | grep -qF "$1"; then
            return 0
        fi
        sleep 0.5
    done
    return 1
}}

LAST_TRIGGER=0
inotifywait -m -e create --format '%f' "$DIRECTORY" | while read -r FILE
do
    # Ignore editor temp files (vim swap/backup/write-test files)
    case "$FILE" in
        .*.sw? | *~ | 4913) continue ;;
    esac
    if ! uploaded_remotely "$FILE"; then
        echo "$(date -Is) ignored $FILE: not created by scp/sftp"
        continue
    fi
    # Show one banner per upload burst (e.g. scp of several files)
    NOW=$(date +%s)
    if [ $((NOW - LAST_TRIGGER)) -lt 5 ]; then
        continue
    fi
    LAST_TRIGGER=$NOW
    install -o ctf_user -g ctf_user -m 600 /etc/ctf/flag_10 /var/lib/ctf-rewards/flag_10
    {{
        printf '\\n========== CHALLENGE 10: REMOTE UPLOAD =========='
        printf '\\nA new file was uploaded to %s.' "$DIRECTORY"
        printf '\\nHere is your flag: %s' "$(cat /etc/ctf/flag_10)"
        printf '\\n==================================================\\n'
    }} | wall
done
""",
    )
    write_service(
        "ctf-monitor-directory.service",
        """[Unit]
Description=CTF Directory Monitor Challenge
After=local-fs.target auditd.service

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
