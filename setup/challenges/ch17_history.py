from __future__ import annotations

from pathlib import Path

from helpers import ensure_user, recursive_chown, write_file


def setup(flags: dict[int, str]) -> None:
    ensure_user("old_admin")
    write_file(
        "/home/old_admin/.bash_history",
        f"""# Old admin command history
ls -la
cd /var/log
# Note to self: the secret flag is {flags[17]}
sudo systemctl restart nginx
exit
""",
        mode=0o644,
    )
    recursive_chown("/home/old_admin", "old_admin", "old_admin")
    Path("/home/old_admin").chmod(0o755)
