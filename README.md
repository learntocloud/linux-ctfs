# Phase 1: Linux Command Line CTF Challenge

Test your Linux command line skills with 18 progressive Capture The Flag challenges. All flags follow the format `CTF{some_text_here}`.

> [!IMPORTANT]  
> Please complete [Phase 1 Guide](https://learntocloud.guide/phase1/) before attempting these challenges. Do not share solutions publicly - focus on sharing your learning journey instead.

## Challenges

> **⏱️ Expected time:** 3-4 hours to complete all challenges

| # | Challenge | Description | Difficulty | Skills |
|---|-----------|-------------|------------|--------|
| 1 | The Hidden File | Find and read a hidden file in `ctf_challenges` | ⭐ | Hidden files, `ls` |
| 2 | The Secret File | Locate a file containing "secret" in its name under your home directory | ⭐ | File searching, `find` |
| 3 | The Largest Log | Find and read an unusually large file in `/var/log` | ⭐⭐ | File sizes, log navigation |
| 4 | The User Detective | A user with UID 1002 has a flag in their login configuration | ⭐⭐ | User management, UIDs |
| 5 | The Permissive File | Find a suspicious file with wide-open permissions under `/opt` | ⭐⭐ | Permissions |
| 6 | The Hidden Service | Something is listening on port 8080. Connect to it | ⭐⭐ | Networking, ports |
| 7 | The Encoded Secret | Find and decode an encoded flag in `ctf_challenges` | ⭐⭐ | Base64, encoding |
| 8 | SSH Key Authentication | Configure SSH key authentication and find a hidden flag | ⭐⭐ | SSH configuration |
| 9 | DNS Troubleshooting | Someone modified a critical DNS config file. Fix it | ⭐⭐ | DNS, `/etc/resolv.conf` |
| 10 | Remote Upload | Transfer any file to `ctf_challenges` to trigger the flag | ⭐⭐ | File transfer, SCP |
| 11 | Web Configuration | The web server is running on a non-standard port. Find and fix it | ⭐⭐ | Nginx, services |
| 12 | Network Traffic Analysis | Someone is sending secret messages via ping packets | ⭐⭐⭐ | Packet inspection, tcpdump |
| 13 | Cron Job Hunter | A scheduled task contains a hidden flag. Find and read it | ⭐⭐ | Cron, scheduling |
| 14 | Process Environment | A running process has a secret in its environment. Extract it | ⭐⭐⭐ | `/proc`, environment vars |
| 15 | Archive Archaeologist | A flag is buried inside nested archives. Dig it out | ⭐⭐ | tar, gzip, archives |
| 16 | Symbolic Sleuth | Follow the trail of symbolic links to find the flag | ⭐⭐ | Symlinks, `readlink` |
| 17 | History Mystery | Someone typed a flag in their command history. Find it | ⭐⭐ | Bash history |
| 18 | Disk Detective | A flag is hidden in filesystem metadata. Investigate mounted filesystems | ⭐⭐⭐ | Disk images, mounting |

**Difficulty:** ⭐ Beginner | ⭐⭐ Intermediate | ⭐⭐⭐ Advanced

## Get Started

Deploy your CTF lab using your preferred cloud provider:

| Provider | Cost for ~4 hours | Setup Guide |
|----------|-------------------|-------------|
| AWS | ~$0.01 (Free Tier eligible) | [AWS Setup](./aws/README.md) |
| Azure | ~$0.05 | [Azure Setup](./azure/README.md) |
| GCP | ~$0.03 | [GCP Setup](./gcp/README.md) |

## Completing the CTF

Once you've solved all 18 challenges, export your completion certificate:

```bash
verify export <your-github-username>
```

> [!IMPORTANT]  
> Enter your GitHub username **exactly** as it appears on GitHub—no `@` symbol, no extra spaces, no special characters. For example: `verify export octocat` not `verify export @octocat`.

This generates a cryptographically signed completion token. **Save this token!** A verification system is coming soon where you'll be able to verify your completion. For now, keep your token safe—you'll need it later.

## Tips

- Use `man` pages to learn commands (e.g., `man find`)
- Combine commands with pipes (`|`) to process output
- Use `verify hint [num]` when stuck on a challenge
- Experiment freely—you can't break anything permanently

## License

[MIT License](LICENSE)

## Contributing

Want to help improve the CTF? See our [Contributing Guide](CONTRIBUTING.md).

Please only submit issues with the lab infrastructure, not for help completing challenges—struggling is part of learning!
