from __future__ import annotations

from pathlib import Path

from helpers import recursive_chown, restart_service, write_file


def setup(flags: dict[int, str]) -> None:
    # Port 8083 serves a decoy; the flag page is only served once nginx is
    # moved back to port 80. The flag page is readable only by www-data.
    write_file(
        "/var/www/html/index.html",
        '<h2 style="text-align:center;">This site is running on the wrong port.</h2>\n',
    )
    write_file(
        "/var/www/ctf/index.html",
        f'<h2 style="text-align:center;">Flag value: {flags[11]}</h2>\n',
        mode=0o600,
    )
    recursive_chown("/var/www/ctf", "www-data", "www-data")
    Path("/var/www/ctf").chmod(0o700)

    write_file(
        "/etc/nginx/conf.d/ctf-web.conf",
        """map $server_port $ctf_site_root {
    80      /var/www/ctf;
    default /var/www/html;
}
""",
        mode=0o644,
    )
    nginx_default = Path("/etc/nginx/sites-available/default")
    content = nginx_default.read_text()
    content = content.replace("listen 80 default_server;", "listen 8083 default_server;")
    content = content.replace("listen [::]:80 default_server;", "listen [::]:8083 default_server;")
    content = content.replace("root /var/www/html;", "root $ctf_site_root;", 1)
    nginx_default.write_text(content)
    restart_service("nginx")
