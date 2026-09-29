from __future__ import annotations

from pathlib import Path

from helpers import restart_service, write_file


def replace_once(content: str, old: str, new: str) -> str:
    old_count = content.count(old)
    new_count = content.count(new)
    if old_count == 1 and new_count == 0:
        return content.replace(old, new, 1)
    if old_count == 0 and new_count == 1:
        return content
    raise RuntimeError(
        f"Expected exactly one original or modified nginx directive, "
        f"found {old_count} original and {new_count} modified: {old!r}"
    )


def setup(flags: dict[int, str]) -> None:
    write_file(
        "/var/www/html/index.html",
        f'<h2 style="text-align:center;">Flag value: {flags[11]}</h2>\n',
    )
    nginx_default = Path("/etc/nginx/sites-available/default")
    content = nginx_default.read_text()
    content = replace_once(content, "listen 80 default_server;", "listen 8083 default_server;")
    content = replace_once(content, "listen [::]:80 default_server;", "listen [::]:8083 default_server;")
    content = replace_once(content, "root /var/www/html;", "root /var/www/htm;")
    nginx_default.write_text(content)
    restart_service("nginx")
