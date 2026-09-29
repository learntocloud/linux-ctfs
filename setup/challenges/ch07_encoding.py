"""Challenge 7: The Encoded Secret.

Learner goal: find and decode an encoded flag in ctf_challenges.
Skills tested: encoding, decoding.
Plants: /home/ctf_user/ctf_challenges/encoded_flag.txt with an encoded flags[7].
"""

from __future__ import annotations

import base64

from helpers import write_file


def setup(flags: dict[int, str]) -> None:
    first = base64.b64encode(flags[7].encode())
    second = base64.b64encode(first).decode()
    write_file("/home/ctf_user/ctf_challenges/encoded_flag.txt", f"{second}\n")
