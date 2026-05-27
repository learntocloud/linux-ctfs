from __future__ import annotations

import sys

from .commands import check_flag, export_certificate, show_hint, show_list, show_progress, show_time
from .state import load_state


USAGE = """Usage:
  verify [challenge_number] [flag] - Check a flag
  verify progress - Show progress
  verify list     - List all challenges with status
  verify hint [n] - Show hint for challenge n
  verify time     - Show elapsed time
  verify export <github_username> - Export certificate with your GitHub username

Example: verify 0 CTF{example}
         verify export octocat
"""


def main() -> int:
    args = sys.argv[1:]
    if not args:
        print(USAGE)
        return 0

    command = args[0]
    state = load_state()

    if command == "progress":
        show_progress()
        return 0
    if command == "list":
        return show_list()
    if command == "hint":
        return show_hint(args[1] if len(args) > 1 else None)
    if command == "time":
        return show_time()
    if command == "export":
        return export_certificate(state, args[1] if len(args) > 1 else None)
    if command.isdigit() and len(args) > 1:
        return check_flag(state, command, args[1])

    print(USAGE)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
