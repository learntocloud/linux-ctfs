from __future__ import annotations

from pathlib import Path

from helpers import write_file


def write_ctf_state(flag_hashes: list[str], instance_id: str, verification_secret: str) -> None:
    etc_ctf = Path("/etc/ctf")
    var_ctf = Path("/var/ctf")

    etc_ctf.mkdir(parents=True, exist_ok=True)
    etc_ctf.chmod(0o711)

    write_file(etc_ctf / "flag_hashes", "\n".join(flag_hashes) + "\n", mode=0o644)
    write_file(etc_ctf / "instance_id", f"{instance_id}\n", mode=0o644)
    write_file(
        etc_ctf / "verification_secret",
        f"{verification_secret}\n",
        mode=0o640,
        owner="root",
        group="ctf_user",
    )

    var_ctf.mkdir(parents=True, exist_ok=True)
    var_ctf.chmod(0o777)
