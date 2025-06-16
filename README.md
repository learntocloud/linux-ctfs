# Phase 1: Linux Command Line CTF Challenge

This set of progressive Capture The Flag (CTF) challenges will test your Linux command line skills. Each challenge builds upon previous concepts while introducing new ones. All flags follow the format `CTF{some_text_here}`.

> [!IMPORTANT]  
> Please complete [Phase 1 Guide](https://learntocloud.guide/phase1/) before attempting these challenges. Do not share solutions publicly - focus on sharing your learning journey instead.

## Flag Submission

Submit flags using the `verify` command:

- Check progress: `verify progress`
- Submit a flag: `verify [challenge_number] [flag]`

Try the command and capture first flag: `verify 0 CTF{example}`

``` sh
ctf_user@ctf-vm:~$ verify 0 CTF{example}
✓ Test flag verified! Now try finding real flags.
```

## Environment Setup

Follow the setup guide for your preferred cloud provider:

- [AWS](./aws/README.md)
- [Azure](./azure/README.md)

## Challenges

NOTE: You should be able to complete all challenges in about 2 to 3 hours. The lab is intentionally made to be done in one go. If you power off the VM and power it back on, certain challenges (specifically challenges 6, 10, 11, and 12) will not work properly as they depend on running services.

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

## Tips

1. Use `man` pages to understand command options.
2. Experiment with different approaches, combining commands and piping output.

## [License](LICENSE)

## Contributing

Please only submit issues with the lab and not if you are having difficulties completing any challenge. That is the point, to learn.
