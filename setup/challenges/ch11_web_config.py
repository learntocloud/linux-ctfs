"""Challenge 11: Web Configuration.

Learner goal: nginx should serve the site on port 80 but is misconfigured; find and fix it.
Skills tested: web servers, services, config debugging.
Plants: a deliberately broken nginx default site and a web root that reveals flags[11] once fixed.
"""

from __future__ import annotations

from helpers import restart_service, write_file


def setup(flags: dict[int, str]) -> None:
    write_file(
        "/var/www/html/index.html",
        f'<h2 style="text-align:center;">Flag value: {flags[11]}</h2>\n',
    )
    write_file(
        "/etc/nginx/sites-available/default",
        """server {
    listen 8083 default_server;
    listen [::]:8083 default_server;

    root /var/www/htm;
    index index.html;
    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }
}
""",
        mode=0o644,
    )
    restart_service("nginx")
