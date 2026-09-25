from __future__ import annotations

from pathlib import Path

from helpers import ensure_user, recursive_chown, write_file


def setup(flags: dict[int, str]) -> None:
    ensure_user("old_admin")
    write_file(
        "/home/old_admin/.bash_history",
        f"""ls -la
cd /var/www/html
sudo systemctl status nginx
sudo tail -n 50 /var/log/nginx/error.log
df -h
free -m
cd ~
git clone https://github.com/example/inventory-app.git
cd inventory-app
cp .env.example .env
nano .env
mysql -u inventory -p'{flags[17]}' -h 127.0.0.1 inventory -e 'SHOW TABLES;'
sudo systemctl restart nginx
crontab -l
history -c
exit
""",
        mode=0o600,
    )
    recursive_chown("/home/old_admin", "old_admin", "old_admin")
    Path("/home/old_admin").chmod(0o755)
