from __future__ import annotations

import os
import pwd
import grp
import shutil
import subprocess
from pathlib import Path
from typing import Iterable


def run(command: Iterable[str], *, input_text: str | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        list(command),
        input=input_text,
        text=True,
        check=True,
    )


def write_file(
    path: str | Path,
    content: str | bytes,
    *,
    mode: int | None = None,
    owner: str | None = None,
    group: str | None = None,
) -> None:
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    if isinstance(content, bytes):
        target.write_bytes(content)
    else:
        target.write_text(content)
    if mode is not None:
        target.chmod(mode)
    if owner is not None or group is not None:
        shutil.chown(target, user=owner, group=group)


def append_line_once(path: str | Path, line: str) -> None:
    target = Path(path)
    current = target.read_text() if target.exists() else ""
    if line not in current.splitlines():
        with target.open("a") as file:
            file.write(f"{line}\n")


def ensure_user(username: str, *, shell: str = "/bin/bash", sudo: bool = False) -> None:
    try:
        pwd.getpwnam(username)
    except KeyError:
        run(["useradd", "-m", "-s", shell, username])

    if sudo:
        run(["usermod", "-aG", "sudo", username])


def set_password(username: str, password: str) -> None:
    run(["chpasswd"], input_text=f"{username}:{password}\n")


def recursive_chown(path: str | Path, user: str, group: str, *, follow_symlinks: bool = False) -> None:
    root = Path(path)
    uid = pwd.getpwnam(user).pw_uid
    gid = grp.getgrnam(group).gr_gid

    os.chown(root, uid, gid, follow_symlinks=follow_symlinks)
    for current_root, directories, files in os.walk(root, followlinks=follow_symlinks):
        for name in directories + files:
            os.chown(Path(current_root) / name, uid, gid, follow_symlinks=follow_symlinks)


def write_executable(path: str | Path, content: str) -> None:
    write_file(path, content, mode=0o755)


def write_service(unit_name: str, content: str) -> None:
    write_file(Path("/etc/systemd/system") / unit_name, content, mode=0o644)
    run(["systemctl", "daemon-reload"])


def enable_service(unit_name: str) -> None:
    run(["systemctl", "enable", "--now", unit_name])


def restart_service(unit_name: str) -> None:
    run(["systemctl", "restart", unit_name])
