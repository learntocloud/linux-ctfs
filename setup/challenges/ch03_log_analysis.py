from __future__ import annotations

from pathlib import Path

from helpers import run


LOG_SIZE_BYTES = 120 * 1024 * 1024


def setup(flags: dict[int, str]) -> None:
    log_file = Path("/var/log/large_log_file.log")
    line = "INFO backup-worker completed routine health check without findings\n"
    chunk = line * (1024 * 1024 // len(line))

    bytes_written = 0
    with log_file.open("w") as file:
        while bytes_written < LOG_SIZE_BYTES:
            file.write(chunk)
            bytes_written += len(chunk)
        file.write(f"{flags[3]}\n")

    run(["chown", "ctf_user:ctf_user", str(log_file)])
