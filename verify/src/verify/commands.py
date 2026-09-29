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
    "The Hidden File",
    "The Secret File",
    "The Odd Log Entry",
    "The User Detective",
    "The Permissive File",
    "The Hidden Service",
    "The Encoded Secret",
    "SSH Key Authentication",
    "DNS Inspection",
    "Remote Upload",
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
    "Some files aren't shown by default. 'man ls' explains how to list everything in the ctf_challenges directory.",
    "Search your home directory by name. 'man find' covers matching names and file types. You want a regular file, not a directory.",
    "Every log line looks alike except one. Sorting files by size helps you spot the big log in /var/log. Then filter out the noise: a search tool can exclude lines as well as match them.",
    "Accounts store more than a name and ID. Find the other users on this system and read everything their records contain. 'man 5 passwd' explains the fields.",
    "Look under /opt for regular files anyone can write to; 'man find' covers matching by permission. If a file says 'Permission denied', check 'ls -l': who owns it, and what can you change?",
    "Something on this machine is listening on a port. 'man ss' shows how to list listening sockets. Once you know the port, connect to it: the service speaks HTTP.",
    "Look for a file in ctf_challenges that isn't readable as-is. Its look (letters, digits, maybe '=' padding) hints at the encoding, and 'man' pages for that encoding cover reversing it. Check whether the result is readable yet.",
    "The 'vault' user has no password and only accepts a key. 'man ssh-keygen' covers making one. The sshd settings in /etc/ssh/sshd_config.d/ show where the vault login looks for authorized keys. You can connect from the VM itself.",
    "The resolver's settings ('man resolvectl') reveal a custom search domain, and the lab's 'intranet' host lives in it. Build its full name, then look it up with a tool that uses the system's own name resolution, not just DNS servers.",
    "Do this from your own computer, not the VM, with a tool that copies files over SSH. The destination is the ctf_challenges directory on the VM, and the file must be new - overwriting doesn't count. The flag is broadcast to your open terminals when the upload lands.",
    "nginx should serve the site on port 80 but doesn't. Compare where it is listening with where it should be, and read its error log under /var/log/nginx/. nginx can test a config before you reload it ('man nginx'); then reload the service.",
    "Capture on the loopback interface with a tool that can print packet contents as hex and ASCII, and filter down to ping traffic so you can see the payload clearly. It needs sudo.",
    "Find where scheduled jobs are defined on this system ('man 5 crontab' is a start), read what the job runs and where its output goes, then wait for the next run.",
    "Every running process exposes information about itself in the /proc filesystem ('man proc'). Find the right process, then look at what it was started with.",
    "Archives can be nested, and each layer may use a different compression. Identify each layer before extracting it; 'man file' and 'man tar' help.",
    "A long directory listing shows where each link points. Follow the chain hop by hop, or look for a tool that resolves it all at once. Some links may lead nowhere useful, so make sure you start from the right one. The flag is where the trail ends, not what is inside it.",
    "Shells keep a record of the commands typed, and users other than you have one. Secrets show up in more than variables. Not every secret you find is the flag, so look at what the real one is shaped like.",
    "A filesystem is more than the files inside it. The image is a file on this machine, but not a normal document. Something that describes a filesystem may not need it mounted. Check the man pages of ext4 tools.",
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
    console.print("   * The Hidden File            * The Hidden Service")
    console.print("   * The Secret File            * The Encoded Secret")
    console.print("   * The Odd Log Entry          * SSH Key Authentication")
    console.print("   * The User Detective         * DNS Inspection")
    console.print("   * The Permissive File        * Remote Upload")
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
   * The Hidden File            * The Hidden Service
   * The Secret File            * The Encoded Secret
   * The Odd Log Entry          * SSH Key Authentication
   * The User Detective         * DNS Inspection
   * The Permissive File        * Remote Upload
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
