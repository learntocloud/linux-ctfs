from __future__ import annotations

import base64

from helpers import CHALLENGE_DIR, write_file


def setup(flags: dict[int, str]) -> None:
    first = base64.b64encode(flags[7].encode())
    second = base64.b64encode(first).decode()
    write_file(CHALLENGE_DIR / "encoded_flag.txt", f"{second}\n")
