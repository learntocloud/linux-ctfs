"""Challenge 18: Disk Detective.

Learner goal: find a flag hidden in filesystem metadata by inspecting a disk image.
Skills tested: disk images, filesystem metadata.
Plants: /opt/ctf_disk.img, an ext4 image whose label is flags[18].
"""

from __future__ import annotations

from helpers import run


def setup(flags: dict[int, str]) -> None:
    run(["dd", "if=/dev/zero", "of=/opt/ctf_disk.img", "bs=1M", "count=10"])
    # ext4 labels hold 16 bytes, exactly the length of a flag.
    run(["mkfs.ext4", "-F", "-L", flags[18], "/opt/ctf_disk.img"])
