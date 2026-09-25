from __future__ import annotations

from helpers import enable_service, restart_service, write_file, write_service


DNS_ADDRESS = "127.0.0.2"
ZONE = "ctf.internal"


def setup(flags: dict[int, str]) -> None:
    # A private resolver answers for the lab zone. Its config (and the flag) is
    # root-only; learners find the zone through systemd-resolved and query it.
    write_file(
        "/etc/ctf/dns.conf",
        f"""port=53
listen-address={DNS_ADDRESS}
bind-interfaces
no-resolv
no-hosts
user=nobody
group=nogroup
local=/{ZONE}/
txt-record={ZONE},"{flags[9]}"
""",
        mode=0o600,
    )
    write_service(
        "ctf-dns.service",
        """[Unit]
Description=CTF Internal DNS Challenge
After=network.target
Before=systemd-resolved.service

[Service]
Type=simple
ExecStart=/usr/sbin/dnsmasq --keep-in-foreground --conf-file=/etc/ctf/dns.conf --pid-file
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
""",
    )
    enable_service("ctf-dns.service")

    # A route-only domain keeps every other lookup on the normal upstream resolver.
    write_file(
        "/etc/systemd/resolved.conf.d/ctf-dns.conf",
        f"""# Lab internal DNS: only names under {ZONE} are sent to this server.
[Resolve]
DNS={DNS_ADDRESS}
Domains=~{ZONE}
""",
        mode=0o644,
    )
    restart_service("systemd-resolved")
