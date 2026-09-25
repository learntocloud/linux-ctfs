from __future__ import annotations

from helpers import write_executable, write_file


def setup(flags: dict[int, str]) -> None:
    # The flag is only published for a short window each minute, so learners
    # have to read the job, follow it to its script, and work out the timing.
    write_file("/etc/ctf/flag_13", f"{flags[13]}\n", mode=0o600)
    write_executable(
        "/usr/local/bin/ctf_status_report.sh",
        """#!/bin/bash
# Publishes a short-lived status report, then cleans up after itself.
REPORT=/var/tmp/ctf_status_report.txt
{
    echo "Status report generated $(date)"
    echo "Access code: $(cat /etc/ctf/flag_13)"
} > "$REPORT"
chmod 644 "$REPORT"
sleep 20
rm -f "$REPORT"
""",
    )
    write_file(
        "/etc/cron.d/ctf_status_report",
        """# Generates the lab status report
* * * * * root /usr/local/bin/ctf_status_report.sh
""",
        mode=0o644,
    )
