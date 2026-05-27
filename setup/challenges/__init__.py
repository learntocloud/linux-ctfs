from __future__ import annotations

from . import (
    ch01_hidden_file,
    ch02_file_search,
    ch03_log_analysis,
    ch04_user_investigation,
    ch05_permissions,
    ch06_service_discovery,
    ch07_encoding,
    ch08_ssh_secrets,
    ch09_dns,
    ch10_remote_upload,
    ch11_web_config,
    ch12_network_traffic,
    ch13_cron,
    ch14_process_env,
    ch15_archive,
    ch16_symlinks,
    ch17_history,
    ch18_disk_detective,
)


def setup_all_challenges(flags: dict[int, str]) -> None:
    for module in (
        ch01_hidden_file,
        ch02_file_search,
        ch03_log_analysis,
        ch04_user_investigation,
        ch05_permissions,
        ch06_service_discovery,
        ch07_encoding,
        ch08_ssh_secrets,
        ch09_dns,
        ch10_remote_upload,
        ch11_web_config,
        ch12_network_traffic,
        ch13_cron,
        ch14_process_env,
        ch15_archive,
        ch16_symlinks,
        ch17_history,
        ch18_disk_detective,
    ):
        module.setup(flags)
