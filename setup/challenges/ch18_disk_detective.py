from __future__ import annotations

from helpers import recursive_chown, run, write_file


def setup(flags: dict[int, str]) -> None:
    run(["dd", "if=/dev/zero", "of=/opt/ctf_disk.img", "bs=1M", "count=10"])
    run(["mkfs.ext4", "-F", "-L", "ctf_disk", "/opt/ctf_disk.img"])
    run(["mkdir", "-p", "/mnt/ctf_disk"])
    run(["mount", "-o", "loop", "/opt/ctf_disk.img", "/mnt/ctf_disk"])
    try:
        write_file("/mnt/ctf_disk/.flag", f"{flags[18]}\n")
    finally:
        run(["umount", "/mnt/ctf_disk"])
    recursive_chown("/home/ctf_user/ctf_challenges", "ctf_user", "ctf_user")
