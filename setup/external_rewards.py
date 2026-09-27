"""Login-banner delivery for flags earned by actions taken outside the VM.

Only challenges 8 (SSH key login) and 10 (remote upload) use this: the learner
solves them from their own computer, so the flag is shown on their next login.
"""

from __future__ import annotations

import shutil
from pathlib import Path

from helpers import write_file


REWARDS_DIR = Path("/var/lib/ctf-rewards")


def grant_command(challenge: int) -> str:
    """Shell command that publishes /etc/ctf/flag_<n> to the login banner."""
    return f"install -o ctf_user -g ctf_user -m 600 /etc/ctf/flag_{challenge} {REWARDS_DIR}/flag_{challenge}"


def configure_external_rewards() -> None:
    REWARDS_DIR.mkdir(parents=True, exist_ok=True)
    shutil.chown(REWARDS_DIR, user="ctf_user", group="ctf_user")
    REWARDS_DIR.chmod(0o700)

    # Exposes $SSH_USER_AUTH so the banner can tell a key-based login apart.
    # Takes effect when configure_ssh() restarts sshd.
    write_file(
        "/etc/ssh/sshd_config.d/99-ctf-expose-auth-info.conf",
        "ExposeAuthInfo yes\n",
        mode=0o644,
    )

    write_file(
        "/etc/profile.d/ctf-rewards.sh",
        f"""if [ "$(id -un)" = "ctf_user" ]; then
    _ctf_rewards={REWARDS_DIR}
    # A key-based login is rewarded asynchronously, so give it a moment to land.
    if [ -n "${{SSH_USER_AUTH:-}}" ] && grep -q '^publickey ' "$SSH_USER_AUTH" 2>/dev/null; then
        _ctf_i=0
        while [ ! -f "$_ctf_rewards/flag_8" ] && [ "$_ctf_i" -lt 10 ]; do
            sleep 0.3
            _ctf_i=$((_ctf_i + 1))
        done
    fi
    if [ -f "$_ctf_rewards/flag_8" ]; then
        echo "Challenge 8: SSH key login detected. Your flag: $(cat "$_ctf_rewards/flag_8")"
    fi
    if [ -f "$_ctf_rewards/flag_10" ]; then
        echo "Challenge 10: remote upload detected. Your flag: $(cat "$_ctf_rewards/flag_10")"
    fi
    unset _ctf_rewards _ctf_i
fi
""",
        mode=0o644,
    )
