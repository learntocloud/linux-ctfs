from __future__ import annotations

from pathlib import Path

from helpers import recursive_chown, run, write_file


def setup(flags: dict[int, str]) -> None:
    image = Path("/opt/ctf_disk.img")
    run(["dd", "if=/dev/zero", f"of={image}", "bs=1M", "count=10"])
    run(["mkfs.ext4", "-F", "-L", "ctf_disk", str(image)])
    run(["mkdir", "-p", "/mnt/ctf_disk"])
    run(["mount", "-o", "loop", str(image), "/mnt/ctf_disk"])
    try:
        write_file("/mnt/ctf_disk/.flag", f"{flags[18]}\n")
    finally:
        run(["umount", "/mnt/ctf_disk"])
    # Root-only so the image has to be mounted (with sudo) instead of grepped.
    image.chmod(0o600)
    recursive_chown("/home/ctf_user/ctf_challenges", "ctf_user", "ctf_user")
