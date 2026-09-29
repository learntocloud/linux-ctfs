# Phase 1: Linux Command Line CTF Challenge

Test your Linux command line skills with 18 progressive Capture The Flag challenges.

> [!IMPORTANT]  
> Please complete [Phase 1 Guide](https://learntocloud.guide/phase/1) before attempting these challenges. Do not share solutions publicly - focus on sharing your learning journey instead.

## Get Started

**You'll need:** a cloud account (AWS, Azure, or GCP), [Terraform](https://developer.hashicorp.com/terraform/install), your provider's CLI, and about 3-4 hours.

1. **Fork** this repository to your GitHub account. Completion verification checks that you have a fork.
2. **Deploy** the lab with your provider's guide:

    | Provider | Cost for ~4 hours | Guide |
    |----------|-------------------|-------|
    | AWS | ~$0.01 (Free Tier eligible) | [AWS Guide](./aws/README.md) |
    | Azure | ~$0.05 | [Azure Guide](./azure/README.md) |
    | GCP | ~$0.03 | [GCP Guide](./gcp/README.md) |

3. **Play** by connecting over SSH and solving challenges with the [Playing the Lab guide](./GUIDE.md). It covers the `verify` command and exporting your completion token.
4. **Clean up** with `terraform destroy` when you're done, after saving your token, so you aren't billed for a VM you've finished with.

Running into problems? See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md).

## Challenges

> **⏱️ Expected time:** 3-4 hours to complete all challenges

| # | Challenge | Description | Difficulty | Skills |
|---|-----------|-------------|------------|--------|
| 1 | The Hidden File | Find and read a hidden file in `ctf_challenges` | ⭐ | Hidden files, `ls` |
| 2 | The Secret File | Locate a regular file (not a directory) with "secret" in its name under your home directory | ⭐ | File searching, `find` |
| 3 | The Odd Log Entry | Thousands of failed logins hide a single successful one in a log under `/var/log` | ⭐⭐ | `grep`, log analysis |
| 4 | The User Detective | Another user's account record carries a flag | ⭐⭐ | Users, `getent passwd` |
| 5 | The Permissive File | Find a suspicious file with wide-open permissions under `/opt`, then follow where it leads | ⭐⭐ | Permissions, `chmod` |
| 6 | The Hidden Service | Something is listening on port 8080. Connect to it | ⭐⭐ | Networking, ports |
| 7 | The Encoded Secret | Find and decode an encoded flag in `ctf_challenges` | ⭐⭐ | Base64, encoding |
| 8 | SSH Key Authentication | Set up SSH key authentication to log in as the key-only `vault` user | ⭐⭐⭐ | `ssh-keygen`, `authorized_keys` |
| 9 | DNS Inspection | Find the lab's custom search domain and resolve a host inside it | ⭐⭐ | DNS, `resolvectl`, `getent hosts` |
| 10 | Remote Upload | From your own computer, upload a new file into `~/ctf_challenges` on the VM to trigger the flag. It is broadcast to your open terminals | ⭐⭐ | File transfer, SCP |
| 11 | Web Configuration | nginx should serve the site on port 80 but is misconfigured. Find and fix it | ⭐⭐ | Nginx, `nginx -t`, services |
| 12 | Network Traffic Analysis | Someone is sending secret messages via ping packets on the loopback interface (needs `sudo`) | ⭐⭐⭐ | Packet inspection, tcpdump |
| 13 | Cron Job Hunter | A scheduled job handles a secret. Find out what it runs and inspect the result | ⭐⭐ | Cron, scheduling |
| 14 | Process Environment | A running process has a secret in its environment. Extract it | ⭐⭐⭐ | `/proc`, environment vars |
| 15 | Archive Archaeologist | A flag is buried inside nested archives. Dig it out | ⭐⭐ | tar, gzip, archives |
| 16 | Symbolic Sleuth | Follow the trail of symbolic links. The flag is where the trail ends | ⭐⭐ | Symlinks, `readlink` |
| 17 | History Mystery | Someone typed a secret into their command line. Search their history | ⭐⭐ | Bash history, `grep` |
| 18 | Disk Detective | A flag is hidden in filesystem metadata. Inspect the disk image | ⭐⭐⭐ | Disk images, `blkid` |

**Difficulty:** ⭐ Beginner | ⭐⭐ Intermediate | ⭐⭐⭐ Advanced

There are 18 challenges. `verify progress` reports `/19` because it also counts the practice flag (challenge 0) that checks `verify` works.

## About Your Completion Certificate

The certificate and token from `verify export` work on the honor system. They record that you finished the lab, but they can't prove it. You control the VM and have root on it, and the token's signing key is in this public repository, so anyone determined to fake a token can.

That's a deliberate choice. The lab exists to build your skills, and a token you didn't earn gets you nothing. Anyone reviewing your work should treat the certificate as your own statement, not as proof.

## Contributing

Want to help improve the CTF? See our [Contributing Guide](CONTRIBUTING.md).

Please only submit issues with the lab infrastructure, not for help completing challenges—struggling is part of learning!

## License

[MIT License](LICENSE)
