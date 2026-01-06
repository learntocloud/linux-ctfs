# Phase 1: Linux Command Line CTF Challenge

This set of progressive Capture The Flag (CTF) challenges will test your Linux command line skills. Each challenge builds upon previous concepts while introducing new ones. All flags follow the format `CTF{some_text_here}`. This is meant to mimic an exam situation and test your skills. Once you launch the lab, you cannot shut it down without losing your progress.

> [!IMPORTANT]  
> Please complete [Phase 1 Guide](https://learntocloud.guide/phase1/) before attempting these challenges. Do not share solutions publicly - focus on sharing your learning journey instead.

## Flag Submission

Submit flags using the `verify` command:

| Command | Description |
|---------|-------------|
| `verify progress` | Show your current progress (completed/total challenges) |
| `verify [num] [flag]` | Submit a flag for challenge number `num` |
| `verify list` | List all challenges with completion status |
| `verify hint [num]` | Show a hint for challenge number `num` |
| `verify time` | Show elapsed time since you started |
| `verify export <name>` | Export a completion certificate (when all challenges are done) |

Try the command and capture first flag: `verify 0 CTF{example}`

``` sh
ctf_user@ctf-vm:~$ verify 0 CTF{example}
✓ Test flag verified! Now try finding real flags.
```

### Example Commands

``` sh
# Check your overall progress
ctf_user@ctf-vm:~$ verify progress
Progress: 5/18 challenges completed

# List all challenges with status
ctf_user@ctf-vm:~$ verify list
[✓] 0. Test Challenge
[✓] 1. The Hidden File
[ ] 2. The Secret File
...

# Get a hint for challenge 3
ctf_user@ctf-vm:~$ verify hint 3
Hint for Challenge 3 (The Largest Log):
Identify a very large file by inspecting file details...

# Check elapsed time
ctf_user@ctf-vm:~$ verify time
Elapsed time: 1h 23m 45s
```

## Environment Setup

Follow the setup guide for your preferred cloud provider:

- [AWS](./aws/README.md)
- [Azure](./azure/README.md)
- [GCP](./gcp/README.md)

## Challenges

> **Note:** You should be able to complete all challenges in about 3 to 4 hours.

### Reboot Resilience

This lab is designed to survive VM reboots:
- **Progress is saved** - Your completed challenges are persisted to disk
- **Services auto-restart** - Background services (challenges 6, 10, 12) use systemd and will automatically restart after a reboot
- **Timer uses wall-clock time** - The elapsed time tracks real-world time from when you first logged in, so it continues correctly even after a reboot

You can safely reboot the VM if needed without losing your progress or breaking any challenges.

> **Note:** The timer tracks real-world elapsed time, not VM uptime. If you shut down the VM overnight and start it again the next day, that time will be counted. Plan to complete the challenges in one session if you want an accurate completion time.

### Challenge 1: The Hidden File

Find and read a hidden file in the `ctf_challenges` directory.

- **Skills**: Basic file listing, hidden files concept
- **Hint**: Hidden files in Linux begin with a special character.

### Challenge 2: The Secret File

Locate a file containing "secret" in its name somewhere under your home directory.

- **Skills**: File searching, directory navigation
- **Hint**: Use tools that allow you to search through directory structures.

### Challenge 3: The Largest Log

Find and read the contents of an unusually large file in `/var/log`.

- **Skills**: File size analysis, sorting, log navigation
- **Hint**: Identify a very large file by inspecting file details, and find a way to view it partially so as not to overwhelm your terminal.

### Challenge 4: The User Detective

A user with UID 1002 has a flag in their login configuration.

- **Skills**: User management, system files, permissions
- **Hint**: Determine which user this UID corresponds to and check their configuration files.

### Challenge 5: The Permissive File

Find a suspicious file with wide-open permissions under `/opt`.

- **Skills**: Permission understanding, file searching
- **Hint**: Look for files where the permission settings and ownership seem unusually permissive.

### Challenge 6: The Hidden Service

Something is listening on port `8080`. Connect to it to retrieve the flag.

- **Skills**: Process management, networking tools, service inspection
- **Hint**: Consider what kind of service might be running on that port and how you’d interact with it.

### Challenge 7: The Encoded Secret

Find and decode an encoded flag in the `ctf_challenges` directory.

- **Skills**: Base64 encoding/decoding, command piping
- **Hint**: Notice that the flag has been processed twice by an encoding algorithm; think about how to reverse this in sequence.

### Challenge 8: SSH Key Authentication

Configure SSH key authentication and find a hidden flag.

- **Skills**: SSH configuration, key management, security practices
- **Hint**: Inspect the SSH directory structure and verify the file permissions to uncover hidden files.

### Challenge 9: DNS troubleshooting

Someone modified a critical DNS configuration file. Fix it to reveal the flag.

- **Skills**: DNS troubleshooting, file editing
- **Hint**: Compare the current configuration with its backup to understand what has changed.

### Challenge 10: Remote upload

Transfer any file to the `ctf_challenges` directory to trigger the flag.

- **Skills**: Upload files to remote servers
- **Hint**: Make use of standard file transfer methods available to you.

### Challenge 11: Web Configuration

The web server is running on a non-standard port. Find and fix it.

- **Skills**: Nginx configuration, service management
- **Hint**: Review the web server's configuration files for unusual port assignments and remember to restart the service after making any changes.

### Challenge 12: Network Traffic Analysis

Someone is sending secret messages via ping packets.

- **Skills**: Network dumps, packet inspection, decoding
- **Hint**: Utilize general network analysis techniques to inspect traffic and search for concealed information. Check all interfaces and protocols.

### Challenge 13: Cron Job Hunter

A scheduled task contains a hidden flag. Find and read it.

- **Skills**: Cron job management, system scheduling, task automation
- **Hint**: Cron jobs can be scheduled by different users and stored in various locations. Check system-wide cron directories and user-specific crontabs.

### Challenge 14: Process Environment

A running process has a secret stored in its environment. Extract it.

- **Skills**: Process inspection, environment variables, /proc filesystem
- **Hint**: Every running process has environment variables. Explore how Linux exposes process information through a special filesystem.

### Challenge 15: Archive Archaeologist

A flag is buried inside nested archives. Dig it out.

- **Skills**: Archive extraction, tar/gzip handling, file compression
- **Hint**: Archives can contain other archives. You may need to extract multiple layers to find what you're looking for.

### Challenge 16: Symbolic Sleuth

Follow the trail of symbolic links to find the flag.

- **Skills**: Symbolic links, file system navigation, link resolution
- **Hint**: Symbolic links can point to other links. Use commands that help you trace where links ultimately lead.

### Challenge 17: History Mystery

Someone typed a flag in their command history. Find it.

- **Skills**: Bash history, command-line forensics, user activity tracking
- **Hint**: Command history is often stored in hidden files in user home directories. Multiple users may have history files.

### Challenge 18: Disk Detective

A flag is hidden in filesystem metadata. Investigate mounted filesystems.

- **Skills**: Disk management, mount points, filesystem labels
- **Hint**: Filesystems have labels and metadata beyond just file contents. Check how disks are mounted and what information they expose.

## Tips

1. Use `man` pages to understand command options.
2. Experiment with different approaches, combining commands and piping output.
3. Use `verify list` to see all challenges and track which ones you've completed.
4. Stuck on a challenge? Use `verify hint [num]` to get a helpful hint.
5. Use `verify time` to track how long you've been working.

## [License](LICENSE)

## Contributing

Please only submit issues with the lab and not if you are having difficulties completing any challenge. That is the point, to learn. Please also open issues before PRs so we can discuss potential work beforehand.
