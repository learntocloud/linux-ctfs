# Phase 1: Linux Command Line CTF Challenge

Test your Linux command line skills with 18 progressive Capture The Flag challenges.

> [!IMPORTANT]  
> Please complete [Phase 1 Guide](https://learntocloud.guide/phase/1) before attempting these challenges. Do not share solutions publicly - focus on sharing your learning journey instead.

## Get Started

Start by [forking this repository](https://github.com/learntocloud/linux-ctfs/fork) to your GitHub account—completion verification checks that you have a fork. Then pick a cloud provider and follow its guide. Each guide covers deploying the lab, connecting, capturing flags, using the `verify` command, exporting your completion token, and cleaning up.

| Provider | Cost for ~4 hours | Guide |
|----------|-------------------|-------|
| AWS | ~$0.01 (Free Tier eligible) | [AWS Guide](./aws/README.md) |
| Azure | ~$0.05 | [Azure Guide](./azure/README.md) |
| GCP | ~$0.03 | [GCP Guide](./gcp/README.md) |

Running into problems? See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md).

## Challenges

> **⏱️ Expected time:** 3-4 hours to complete all challenges

| # | Challenge | Description | Difficulty | Skills |
|---|-----------|-------------|------------|--------|
| 1 | The Hidden File | Find and read a hidden file in `ctf_challenges` | ⭐ | Hidden files, `ls` |
| 2 | The Secret File | Locate a regular file (not a directory) with "secret" in its name under your home directory | ⭐ | File searching, `find` |
| 3 | The Largest Log | Find and read an unusually large file in `/var/log` | ⭐⭐ | File sizes, log navigation |
| 4 | The User Detective | Another user has a flag in their login configuration | ⭐⭐ | User management, UIDs |
| 5 | The Permissive File | Find a suspicious file with wide-open permissions under `/opt` | ⭐⭐ | Permissions |
| 6 | The Hidden Service | Something is listening on port 8080. Connect to it | ⭐⭐ | Networking, ports |
| 7 | The Encoded Secret | Find and decode an encoded flag in `ctf_challenges` | ⭐⭐ | Base64, encoding |
| 8 | SSH Key Authentication | Configure SSH key authentication and find a hidden flag | ⭐⭐ | SSH configuration |
| 9 | DNS Inspection | Inspect the system DNS configuration without changing live resolver files | ⭐⭐ | DNS, `systemd-resolved` |
| 10 | Remote Upload | From your own computer, upload a new file into `~/ctf_challenges` on the VM to trigger the flag. It is broadcast to your open terminals | ⭐⭐ | File transfer, SCP |
| 11 | Web Configuration | The web server is running on a non-standard port. Find and fix it | ⭐⭐ | Nginx, services |
| 12 | Network Traffic Analysis | Someone is sending secret messages via ping packets on the loopback interface (needs `sudo`) | ⭐⭐⭐ | Packet inspection, tcpdump |
| 13 | Cron Job Hunter | A scheduled task contains a hidden flag. Find and read it | ⭐⭐ | Cron, scheduling |
| 14 | Process Environment | A running process has a secret in its environment. Extract it | ⭐⭐⭐ | `/proc`, environment vars |
| 15 | Archive Archaeologist | A flag is buried inside nested archives. Dig it out | ⭐⭐ | tar, gzip, archives |
| 16 | Symbolic Sleuth | Follow the trail of symbolic links to find the flag | ⭐⭐ | Symlinks, `readlink` |
| 17 | History Mystery | Someone typed a flag in their command history. Find it | ⭐⭐ | Bash history |
| 18 | Disk Detective | A flag is hidden in filesystem metadata. Investigate mounted filesystems | ⭐⭐⭐ | Disk images, mounting |

**Difficulty:** ⭐ Beginner | ⭐⭐ Intermediate | ⭐⭐⭐ Advanced

## About Your Completion Certificate

The certificate and token from `verify export` work on the honor system. They record that you finished the lab, but they can't prove it. You control the VM and have root on it, and the token's signing key is in this public repository, so anyone determined to fake a token can.

That's a deliberate choice. The lab exists to build your skills, and a token you didn't earn gets you nothing. Anyone reviewing your work should treat the certificate as your own statement, not as proof.

## Contributing

Want to help improve the CTF? See our [Contributing Guide](CONTRIBUTING.md).

Please only submit issues with the lab infrastructure, not for help completing challenges—struggling is part of learning!

## License

[MIT License](LICENSE)
