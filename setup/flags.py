from __future__ import annotations

import hashlib
import secrets


MASTER_SECRET = "L2C_CTF_MASTER_2024"

FLAG_BASES: dict[int, str] = {
    0: "example",
    1: "hidden_files",
    2: "file_search",
    3: "log_analysis",
    4: "user_enum",
    5: "perm_sleuth",
    6: "net_detective",
    7: "decode_master",
    8: "ssh_secrets",
    9: "dns_name",
    10: "net_copy",
    11: "web_config",
    12: "icmp",
    13: "cron_master",
    14: "proc_env",
    15: "archive_dig",
    16: "link_follow",
    17: "history_sleuth",
    18: "disk_sleuth",
}


def generate_flags() -> dict[int, str]:
    instance_suffix = secrets.token_hex(4)
    short_suffix = instance_suffix[:4]

    flags: dict[int, str] = {}
    for challenge_num, flag_base in FLAG_BASES.items():
        if challenge_num == 0:
            flags[challenge_num] = "CTF{example}"
        elif challenge_num == 12:
            flags[challenge_num] = f"CTF{{{flag_base}_{short_suffix}}}"
        else:
            flags[challenge_num] = f"CTF{{{flag_base}_{instance_suffix}}}"
    return flags


def hash_flags(flags: dict[int, str]) -> list[str]:
    return [
        hashlib.sha256(flags[challenge_num].encode()).hexdigest()
        for challenge_num in range(19)
    ]


def generate_instance_id() -> str:
    return secrets.token_hex(16)


def derive_verification_secret(instance_id: str) -> str:
    return hashlib.sha256(f"{MASTER_SECRET}:{instance_id}".encode()).hexdigest()
