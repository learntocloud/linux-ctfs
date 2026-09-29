# Playing the Lab

This guide covers everything you do once your lab VM is running, and it's the same on AWS, Azure, and GCP. Deploy the lab first with your provider's guide: [AWS](./aws/README.md), [Azure](./azure/README.md), or [GCP](./gcp/README.md).

## Contents

- [Connect to the Lab](#connect-to-the-lab)
- [Capture Flags](#capture-flags)
- [Verify Commands](#verify-commands)
- [Finish the CTF](#finish-the-ctf)

## Connect to the Lab

1. Connect via SSH using the `public_ip_address` output from Terraform:

    ```sh
    ssh ctf_user@<public_ip_address>
    ```

2. On first login you'll be asked whether to add the host fingerprint to your known hosts file. Type `yes` and press Enter.

3. Enter the password when prompted: `CTFpassword123!`

    > [!NOTE]
    > This password is intentionally public. The lab uses password authentication for simplicity. In production, use key-based authentication.

You'll see a welcome message when you're in. If SSH works but the lab doesn't seem ready yet, see [Lab not ready after SSH login](./TROUBLESHOOTING.md#lab-not-ready-after-ssh-login).

## Capture Flags

Each challenge hides a flag somewhere on the VM. Find it using the command line, then submit it with `verify`.

- **What a flag looks like:** Flags are wrapped in `CTF{...}`. Every lab instance generates its own flags, so a flag from someone else's lab won't work in yours.
- **Start with the example:** Run `verify 0 CTF{example}` to confirm the `verify` command works. `verify progress` should then show `1/19`.
- **Pick a challenge:** Read the [challenge list](./README.md#challenges). They're roughly ordered from easiest to hardest, but you can solve them in any order.
- **Submit what you find:** Run `verify <challenge_number> <flag>`. For example, a flag for challenge 3 is submitted with `verify 3 CTF{...}`.
- **Challenge 10 starts on your computer:** Run it from a terminal on your own machine, not from inside the SSH session.

Tips:

- Use `man` pages to learn commands (e.g., `man find`).
- Combine commands with pipes (`|`) to process output.
- Use `verify hint <challenge_number>` when you're stuck.
- Experiment freely. You can't break anything permanently, and you can always redeploy.

## Verify Commands

Run these on the lab VM. Running `verify` with no arguments prints the usage summary.

| Command | What it does |
|---------|--------------|
| `verify <challenge_number> <flag>` | Submits a flag for challenge `0`-`18`. Tells you whether it's correct and shows your updated progress. Your first submission starts the timer. |
| `verify progress` | Shows how many flags you've found out of 19: the example flag (challenge 0) plus the 18 real challenges. |
| `verify list` | Lists every challenge by name, with `[✓]` next to the ones you've solved. |
| `verify hint <challenge_number>` | Shows a hint for challenge `0`-`18`. Hints nudge you toward the right tool or location; they don't give you the answer. |
| `verify time` | Shows wall clock time elapsed since your first submission, not active keyboard time. |
| `verify export <github_username>` | Available after you solve all 18 real challenges. Prints your completion certificate and completion token, and saves the certificate to `~/ctf_certificate_<timestamp>.txt`. |

How the timer works:

- It starts the first time you run `verify <challenge_number> <flag>`.
- It keeps running while the VM is stopped, so paused time still counts.
- It freezes on your first successful `verify export` after you've solved all 18 real challenges.

## Finish the CTF

Once you've solved all 18 challenges, export your completion certificate:

```sh
verify export <your-github-username>
```

> [!IMPORTANT]
> Enter your GitHub username **exactly** as it appears on GitHub: no `@` symbol, no extra spaces, no special characters. For example: `verify export octocat`, not `verify export @octocat`.

Use the same GitHub account that owns your fork of this repository. Verification checks for the fork.

Save the token it prints. You'll need it to record your progress at [learntocloud.guide/phase1](https://learntocloud.guide/phase1). The full token is around **300+ characters**. If it isn't accepted, see [Completion token not accepted](./TROUBLESHOOTING.md#completion-token-not-accepted).

**Save your token before cleaning up.** Destroying the lab deletes the VM and everything on it.
