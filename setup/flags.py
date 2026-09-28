from __future__ import annotations

import hashlib
import secrets


# Intentionally public: learners control the VM, so no on-VM key can stay secret.
# Completion tokens are honor-system certificates, not proof (see README.md).
# Changing this breaks token verification on learntocloud.guide.
MASTER_SECRET = "L2C_CTF_MASTER_2024"

CHALLENGE_COUNT = 18
EXAMPLE_FLAG = "CTF{example}"

# Base58: letters and digits without look-alikes 0, O, I, l.
FLAG_ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
# 11 chars keeps CTF{...} at 16 bytes, the max pattern size for ping -p (challenge 12).
FLAG_LENGTH = 11


def generate_flag() -> str:
    body = "".join(secrets.choice(FLAG_ALPHABET) for _ in range(FLAG_LENGTH))
    return f"CTF{{{body}}}"


def generate_flags() -> dict[int, str]:
    flags = {0: EXAMPLE_FLAG}
    for challenge_num in range(1, CHALLENGE_COUNT + 1):
        flags[challenge_num] = generate_flag()
    return flags


def hash_flags(flags: dict[int, str]) -> list[str]:
    return [
        hashlib.sha256(flags[challenge_num].encode()).hexdigest()
        for challenge_num in range(CHALLENGE_COUNT + 1)
    ]


def generate_instance_id() -> str:
    return secrets.token_hex(16)


def derive_verification_secret(instance_id: str) -> str:
    return hashlib.sha256(f"{MASTER_SECRET}:{instance_id}".encode()).hexdigest()
