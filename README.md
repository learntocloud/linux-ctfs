# Phase 1: Linux Command Line CTF Challenge

Test your Linux command line skills with 18 progressive Capture The Flag challenges. All flags follow the format `CTF{some_text_here}`.

> [!IMPORTANT]  
> Please complete [Phase 1 Guide](https://learntocloud.guide/phase1/) before attempting these challenges. Do not share solutions publicly - focus on sharing your learning journey instead.

## Challenges

> **⏱️ Expected time:** 3-4 hours to complete all challenges

| # | Challenge | Difficulty | Skills |
|---|-----------|------------|--------|
| 1 | The Hidden File | ⭐ | Hidden files, `ls` |
| 2 | The Secret File | ⭐ | File searching, `find` |
| 3 | The Largest Log | ⭐⭐ | File sizes, log navigation |
| 4 | The User Detective | ⭐⭐ | User management, UIDs |
| 5 | The Permissive File | ⭐⭐ | Permissions |
| 6 | The Hidden Service | ⭐⭐ | Networking, ports |
| 7 | The Encoded Secret | ⭐⭐ | Base64, encoding |
| 8 | SSH Key Authentication | ⭐⭐ | SSH configuration |
| 9 | DNS Troubleshooting | ⭐⭐ | DNS, `/etc/resolv.conf` |
| 10 | Remote Upload | ⭐⭐ | File transfer, SCP |
| 11 | Web Configuration | ⭐⭐ | Nginx, services |
| 12 | Network Traffic Analysis | ⭐⭐⭐ | Packet inspection, tcpdump |
| 13 | Cron Job Hunter | ⭐⭐ | Cron, scheduling |
| 14 | Process Environment | ⭐⭐⭐ | `/proc`, environment vars |
| 15 | Archive Archaeologist | ⭐⭐ | tar, gzip, archives |
| 16 | Symbolic Sleuth | ⭐⭐ | Symlinks, `readlink` |
| 17 | History Mystery | ⭐⭐ | Bash history |
| 18 | Disk Detective | ⭐⭐⭐ | Disk images, mounting |

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
