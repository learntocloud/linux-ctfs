from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


HASH_FILE = Path("/etc/ctf/flag_hashes")
INSTANCE_ID_FILE = Path("/etc/ctf/instance_id")
VERIFICATION_SECRET_FILE = Path("/etc/ctf/verification_secret")
PROGRESS_FILE = Path("/var/ctf/completed_challenges")
START_TIME_FILE = Path("/var/ctf/ctf_start_time")
END_TIME_FILE = Path("/var/ctf/ctf_end_time")


@dataclass(frozen=True)
class CtfState:
    answer_hashes: list[str]
    instance_id: str
    verification_secret: str


def load_state() -> CtfState:
    if not HASH_FILE.exists():
        raise SystemExit("Error: CTF not properly initialized. Hash file missing.")

    answer_hashes = HASH_FILE.read_text().splitlines()
    instance_id = INSTANCE_ID_FILE.read_text().strip() if INSTANCE_ID_FILE.exists() else ""
    verification_secret = (
        VERIFICATION_SECRET_FILE.read_text().strip()
        if VERIFICATION_SECRET_FILE.exists()
        else ""
    )
    return CtfState(answer_hashes, instance_id, verification_secret)


def read_completed() -> set[int]:
    if not PROGRESS_FILE.exists():
        return set()
    completed: set[int] = set()
    for line in PROGRESS_FILE.read_text().splitlines():
        if line.isdigit():
            completed.add(int(line))
    return completed


def write_completed(completed: set[int]) -> None:
    PROGRESS_FILE.parent.mkdir(parents=True, exist_ok=True)
    PROGRESS_FILE.write_text("".join(f"{num}\n" for num in sorted(completed)))
    PROGRESS_FILE.chmod(0o666)
