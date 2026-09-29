from __future__ import annotations

from pathlib import Path

from helpers import restart_service, write_file


def setup(flags: dict[int, str]) -> None:
    write_file(
        "/var/www/html/index.html",
        f'<h2 style="text-align:center;">Flag value: {flags[11]}</h2>\n',
    )
    nginx_default = Path("/etc/nginx/sites-available/default")
    content = nginx_default.read_text()
    content = content.replace("listen 80 default_server;", "listen 8083 default_server;")
    content = content.replace("listen [::]:80 default_server;", "listen [::]:8083 default_server;")
    # Wrong port and a typo in the document root: both must be fixed to serve the flag on port 80.
    content = content.replace("root /var/www/html;", "root /var/www/htm;")
    nginx_default.write_text(content)
    restart_service("nginx")
