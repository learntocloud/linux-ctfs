from __future__ import annotations

from pathlib import Path

from helpers import ensure_user, recursive_chown, restart_service, write_executable, write_file


def setup(flags: dict[int, str]) -> None:
    # The vault user has no password. Its only way in is a public key listed in ctf_user's authorized_keys.
    ensure_user("vault")
    write_file("/etc/ctf/flag_8", f"{flags[8]}\n", mode=0o400, owner="vault", group="vault")
    write_executable("/usr/local/bin/ctf_vault_keys", "#!/bin/sh\ncat /home/ctf_user/.ssh/authorized_keys\n")
    write_executable(
        "/usr/local/bin/ctf_vault_login",
        "#!/bin/sh\necho \"Welcome to the vault. Your key was accepted. Flag: $(cat /etc/ctf/flag_8)\"\n",
    )
    write_file(
        "/etc/ssh/sshd_config.d/98-ctf-vault.conf",
        """Match User vault
    PasswordAuthentication no
    KbdInteractiveAuthentication no
    AuthorizedKeysCommand /usr/local/bin/ctf_vault_keys
    AuthorizedKeysCommandUser root
    ForceCommand /usr/local/bin/ctf_vault_login
""",
        mode=0o644,
    )

    ssh_dir = Path("/home/ctf_user/.ssh")
    ssh_dir.mkdir(exist_ok=True)
    (ssh_dir / "authorized_keys").touch()
    recursive_chown(ssh_dir, "ctf_user", "ctf_user")
    ssh_dir.chmod(0o700)
    (ssh_dir / "authorized_keys").chmod(0o600)
    restart_service("ssh")
