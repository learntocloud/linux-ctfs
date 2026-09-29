from __future__ import annotations

import base64
import hashlib
import hmac
import json
import time
from datetime import datetime
from pathlib import Path

from pyfiglet import Figlet
from rich.console import Console

from .state import (
    END_TIME_FILE,
    PROGRESS_FILE,
    START_TIME_FILE,
    CtfState,
    read_completed,
    write_completed,
)


console = Console()

CHALLENGE_NAMES = [
    "Example Challenge",
    "Hidden File Discovery",
    "Basic File Search",
    "Log Analysis",
    "User Investigation",
    "Permission Analysis",
    "Service Discovery",
    "Encoding Challenge",
    "SSH Secrets",
    "DNS Inspection",
    "Remote Upload Detection",
    "Web Configuration",
    "Network Traffic Analysis",
    "Cron Job Hunter",
    "Process Environment",
    "Archive Archaeologist",
    "Symbolic Sleuth",
    "History Mystery",
    "Disk Detective",
]

CHALLENGE_HINTS = [
    "Run: verify 0 CTF{example}",
    "Hidden files in Linux start with a dot. Try 'ls -la' in the ctf_challenges directory.",
    "Use 'find' to search by name. Try: find ~ -type f -iname '*secret*' 2>/dev/null",
    "Every log line looks alike except one. Find the biggest file in /var/log (ls -lS), then filter out the noise with grep (try grep -v).",
    "Every account has a comment (GECOS) field in /etc/passwd. Compare the users with 'getent passwd' and look at the fifth field.",
    "Look under /opt for regular files anyone can write to. Try: find /opt -type f -perm -o+w 2>/dev/null. If a file says 'Permission denied', check 'ls -l': who owns it, and what can you change?",
    "What services are running? Use 'netstat -tulpn' or 'ss -tulpn' to find listening ports.",
    "The flag is encoded. Look for encoded files and use 'base64 -d' to decode.",
    "The 'vault' user has no password and only accepts an SSH key. Create a key pair with 'ssh-keygen', authorize the public key in your own ~/.ssh/authorized_keys, then run 'ssh vault@localhost'.",
    "Find the custom search domain with 'resolvectl status' or /etc/systemd/resolved.conf.d/. The lab's 'intranet' host lives in that domain: resolve its full name with 'getent hosts'.",
    "Run scp from your own computer, not the VM. The destination must be the ctf_challenges directory (e.g. user@ip:~/ctf_challenges/), and the file must be new - overwriting doesn't count. The flag is broadcast to your open terminals when the upload lands.",
    "nginx should serve the site on port 80 but doesn't. Check 'ss -tlnp', 'curl -i localhost:<port>', and /var/log/nginx/error.log. Fix the config, then 'sudo nginx -t && sudo systemctl reload nginx'.",
    "Network traffic can carry hidden messages. The pings run on the loopback interface. Capture ICMP payloads with: sudo tcpdump -i lo -X icmp",
    "Cron jobs run on schedules. Check /etc/cron.d/ and /etc/crontab, see what the job runs and where it writes, then wait for the next run.",
    "Process info lives in /proc. Each process has a directory with its environment in /proc/PID/environ.",
    "Archives can be nested, and each layer may use a different compression. Check every layer with 'file'; 'tar -xf' detects the format for you.",
    "Follow the chain with 'ls -l' one hop at a time, or jump to the end with 'readlink -f'. The flag is where the trail ends, not what is inside it.",
    "Bash stores command history in ~/.bash_history. Other users have history files too. Search them for keywords like 'export' or 'key'.",
    "Filesystems carry metadata besides files. Inspect the disk image in /opt with 'blkid', 'e2label', or 'sudo dumpe2fs -h'.",
]


EXAMPLE_CHALLENGE_NUMBER = 0
MAX_CHALLENGE_NUMBER = len(CHALLENGE_NAMES) - 1
REAL_CHALLENGE_COUNT = MAX_CHALLENGE_NUMBER
TOTAL_PROGRESS_CHECKS = len(CHALLENGE_NAMES)


def completed_progress_count() -> int:
    return len(read_completed())


def completed_challenge_count() -> int:
    completed = read_completed()
    return max(len(completed - {EXAMPLE_CHALLENGE_NUMBER}), 0)


def show_progress() -> None:
    count = completed_progress_count()
    console.print(f"Flags Found: {count}/{TOTAL_PROGRESS_CHECKS}")
    if count == TOTAL_PROGRESS_CHECKS:
        console.print("Congratulations! You've completed all challenges!")


def init_timer() -> None:
    if not START_TIME_FILE.exists():
        START_TIME_FILE.parent.mkdir(parents=True, exist_ok=True)
        START_TIME_FILE.write_text(f"{int(time.time())}\n")
        START_TIME_FILE.chmod(0o666)


def elapsed_seconds() -> int | None:
    if not START_TIME_FILE.exists():
        return None
    start_time = int(START_TIME_FILE.read_text().strip())
    end_time = int(END_TIME_FILE.read_text().strip()) if END_TIME_FILE.exists() else int(time.time())
    return end_time - start_time


def freeze_end_time_on_export() -> None:
    if END_TIME_FILE.exists():
        return
    if completed_challenge_count() >= REAL_CHALLENGE_COUNT:
        END_TIME_FILE.write_text(f"{int(time.time())}\n")
        END_TIME_FILE.chmod(0o666)


def format_elapsed(seconds: int, *, include_seconds: bool) -> str:
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    if include_seconds:
        remaining_seconds = seconds % 60
        return f"{hours:02d}:{minutes:02d}:{remaining_seconds:02d}"
    return f"{hours:02d}:{minutes:02d}"


def check_flag(state: CtfState, challenge_num: str, submitted_flag: str) -> int:
    init_timer()
    if not challenge_num.isdigit() or not 0 <= int(challenge_num) <= MAX_CHALLENGE_NUMBER:
        console.print(f"✗ Invalid challenge number. Use 0-{MAX_CHALLENGE_NUMBER}.")
        return 1

    num = int(challenge_num)
    submitted_hash = hashlib.sha256(submitted_flag.encode()).hexdigest()
    if submitted_hash == state.answer_hashes[num]:
        if num == 0:
            console.print("✓ Example flag verified! Now try finding real flags.")
        else:
            console.print(f"✓ Correct flag for Challenge {num}!")
        completed = read_completed()
        completed.add(num)
        write_completed(completed)
    else:
        console.print("✗ Incorrect flag. Try again!")
    show_progress()
    return 0


def show_time() -> int:
    elapsed = elapsed_seconds()
    if elapsed is None:
        console.print("Timer not started. Complete your first challenge to start the timer.")
        return 0
    console.print(f"Elapsed Time: {format_elapsed(elapsed, include_seconds=True)}")
    return 0


def show_list() -> int:
    completed = read_completed()
    console.print("======================================")
    console.print("       CTF Challenge Status")
    console.print("======================================")
    for index, name in enumerate(CHALLENGE_NAMES):
        status = "[✓]" if index in completed else "[ ]"
        suffix = " (Example)" if index == 0 else ""
        console.print(f"{status} {index:2d}. {name}{suffix}")
    console.print("======================================")
    show_progress()
    return 0


def show_hint(num_text: str | None) -> int:
    if num_text is None or not num_text.isdigit() or int(num_text) > MAX_CHALLENGE_NUMBER:
        console.print(f"Usage: verify hint [0-{MAX_CHALLENGE_NUMBER}]")
        return 1
    num = int(num_text)
    console.print("======================================")
    console.print(f"Hint for Challenge {num}: {CHALLENGE_NAMES[num]}")
    console.print("======================================")
    console.print(CHALLENGE_HINTS[num])
    console.print("======================================")
    return 0


def export_certificate(state: CtfState, github_username: str | None) -> int:
    count = completed_challenge_count()
    if count < REAL_CHALLENGE_COUNT:
        console.print(f"Complete all {REAL_CHALLENGE_COUNT} challenges to earn your certificate!")
        console.print(f"Current progress: {count}/{REAL_CHALLENGE_COUNT}")
        return 1

    if not github_username:
        console.print("Usage: verify export <github_username>")
        console.print("Example: verify export octocat")
        console.print("")
        console.print("⚠️  Use your GitHub username! This will be verified when you")
        console.print("   submit your token at https://learntocloud.guide")
        return 1

    freeze_end_time_on_export()
    elapsed = elapsed_seconds()
    completion_time = format_elapsed(elapsed, include_seconds=False) if elapsed is not None else "Unknown"
    date_str = datetime.now().strftime("%Y-%m-%d")
    cert_file = Path.home() / f"ctf_certificate_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"

    figlet_text = Figlet(justify="center").renderText(github_username).rstrip()

    console.print("")
    console.print("============================================================", style="bold cyan")
    console.print("         LEARN TO CLOUD - CTF COMPLETION CERTIFICATE        ", style="bold cyan")
    console.print("============================================================", style="bold cyan")
    console.print("")
    console.print("  This certifies that GitHub user")
    console.print("")
    console.print(figlet_text, style="bold green")
    console.print("")
    console.print("  has successfully completed all 18 Linux CTF challenges")
    console.print("")
    console.print(f"  Completion Time: {completion_time}")
    console.print(f"  Date: {date_str}")
    console.print("")
    console.print("  Challenges Completed:")
    console.print("   * Hidden File Discovery      * Service Discovery")
    console.print("   * Basic File Search          * Encoding Challenge")
    console.print("   * Log Analysis               * SSH Secrets")
    console.print("   * User Investigation         * DNS Inspection")
    console.print("   * Permission Analysis        * Remote Upload Detection")
    console.print("   * Web Configuration          * Network Traffic Analysis")
    console.print("   * Cron Job Hunter            * Process Environment")
    console.print("   * Archive Archaeologist      * Symbolic Sleuth")
    console.print("   * History Mystery            * Disk Detective")
    console.print("")
    console.print("============================================================", style="bold cyan")
    console.print("                 🎉 Congratulations! 🎉                      ", style="bold magenta")
    console.print("============================================================", style="bold cyan")

    cert_file.write_text(
        f"""============================================================
         LEARN TO CLOUD - CTF COMPLETION CERTIFICATE
============================================================

  This certifies that GitHub user

              {github_username}

  has successfully completed all 18 Linux CTF challenges

  Completion Time: {completion_time}
  Date: {date_str}

  Challenges Completed:
   * Hidden File Discovery      * Service Discovery
   * Basic File Search          * Encoding Challenge
   * Log Analysis               * SSH Secrets
   * User Investigation         * DNS Inspection
   * Permission Analysis        * Remote Upload Detection
   * Web Configuration          * Network Traffic Analysis
   * Cron Job Hunter            * Process Environment
   * Archive Archaeologist      * Symbolic Sleuth
   * History Mystery            * Disk Detective

============================================================
                    Congratulations!
============================================================
"""
    )
    console.print("")
    console.print(f"Certificate saved to: {cert_file}")

    timestamp = int(time.time())
    payload = {
        "github_username": github_username,
        "date": date_str,
        "time": completion_time,
        "challenges": 18,
        "timestamp": timestamp,
        "instance_id": state.instance_id,
    }
    payload_json = json.dumps(payload, separators=(",", ":"))
    signature = hmac.new(
        state.verification_secret.encode(),
        payload_json.encode(),
        hashlib.sha256,
    ).hexdigest()
    token_json = json.dumps(
        {"payload": payload, "signature": signature},
        separators=(",", ":"),
    )
    token = base64.b64encode(token_json.encode()).decode()

    console.print("")
    console.print("============================================================", style="bold cyan")
    console.print("              🎫 COMPLETION TOKEN                             ", style="bold cyan")
    console.print("============================================================", style="bold cyan")
    console.print("")
    console.print("⚠️  Save this token! You'll need it to record your progress")
    console.print("   at https://learntocloud.guide")
    console.print("")
    console.print(f"  1. Go to https://learntocloud.guide")
    console.print(f"  2. Sign in with GitHub (as: {github_username})")
    console.print("  3. Paste the token below")
    console.print("")
    console.print("--- BEGIN L2C CTF TOKEN ---")
    console.print(token, soft_wrap=True)
    console.print("--- END L2C CTF TOKEN ---")
    console.print("")
    return 0
