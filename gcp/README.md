# Linux Command Line CTF Lab - GCP

> [!IMPORTANT]  
> Please complete [Phase 1 Guide](https://learntocloud.guide/phase/1) before attempting these challenges. Do not share solutions publicly - focus on sharing your learning journey instead.

## Contents

- [Prerequisites](#prerequisites)
- [Deploy the Lab](#deploy-the-lab)
- [Connect to the Lab](#connect-to-the-lab)
- [Capture Flags](#capture-flags)
- [Verify Commands](#verify-commands)
- [Finish the CTF](#finish-the-ctf)
- [Pause the Lab](#pause-the-lab)
- [Clean Up](#clean-up)
- [Troubleshooting](#troubleshooting)
- [Security Note](#security-note)

## Prerequisites

1. [Terraform](https://developer.hashicorp.com/terraform/install) (v1.9.0 or later)
2. [gcloud CLI](https://cloud.google.com/sdk/docs/install)
3. A Google Cloud account with a project and billing enabled

## Deploy the Lab

1. Fork this repository.

2. Clone your fork:

    ```sh
    git clone https://github.com/<your-github-username>/linux-ctfs
    cd linux-ctfs/gcp
    ```

3. Log in to Google Cloud:

    ```sh
    gcloud auth login
    gcloud auth application-default login
    ```

4. Initialize and apply Terraform:

    ```sh
    terraform init
    terraform apply \
      -var gcp_project="YOUR_GCP_PROJECT_ID" \
      -var gcp_region="YOUR_GCP_REGION" \
      -var gcp_zone="YOUR_GCP_ZONE"
    ```

    Replace the values with your project ID and preferred region/zone (defaults to us-central1/us-central1-a).

    Type `yes` when prompted.

    If you run into errors when deploying, see [TROUBLESHOOTING.md](../TROUBLESHOOTING.md#gcp) for common issues and fixes.

5. Note the `public_ip_address` output—you'll use this to connect.

## Connect to the Lab

1. Connect via SSH:

    ```sh
    ssh ctf_user@<public_ip_address>
    ```

1. On first login you will be asked if you want to add fingerprints to the known hosts file; type `yes` and press Enter.

1. When prompted, enter the password: `CTFpassword123!`

You'll see a welcome message when you're in. If SSH works but the lab doesn't seem ready yet, see [Lab not ready after SSH login](../TROUBLESHOOTING.md#lab-not-ready-after-ssh-login).

## Capture Flags

Each challenge hides a flag somewhere on the VM. Your job is to find it using the command line, then submit it with `verify`.

- **What a flag looks like:** Flags are wrapped in `CTF{...}`. Every lab instance generates its own flags, so a flag from someone else's lab won't work in yours.
- **Start with the example:** Run `verify 0 CTF{example}` to confirm the `verify` command works. `verify progress` should then show `1/19`.
- **Pick a challenge:** Read the challenge descriptions in the [challenge list](../README.md#challenges). They're roughly ordered from easiest to hardest, but you can solve them in any order.
- **Submit what you find:** When you find a flag, run `verify <challenge_number> <flag>`. For example, a flag for challenge 3 is submitted with `verify 3 CTF{...}`.
- **Challenge 10 starts on your computer:** Run it from a terminal on your own machine, not from inside the SSH session.

Tips:

- Use `man` pages to learn commands (e.g., `man find`).
- Combine commands with pipes (`|`) to process output.
- Use `verify hint <challenge_number>` when you're stuck.
- Experiment freely—you can't break anything permanently, and you can always redeploy.

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

- The timer starts the first time you run `verify <challenge_number> <flag>`.
- It keeps running while the VM is stopped, so paused time still counts.
- It freezes on your first successful `verify export` after you've solved all 18 real challenges.

## Finish the CTF

Once you've solved all 18 challenges, export your completion certificate:

```sh
verify export <your-github-username>
```

> [!IMPORTANT]  
> Enter your GitHub username **exactly** as it appears on GitHub—no `@` symbol, no extra spaces, no special characters. For example: `verify export octocat` not `verify export @octocat`.

Use the same GitHub account that owns your fork of this repository—verification checks for the fork.

Save the token it prints—you'll need it to record your progress at [learntocloud.guide/phase1](https://learntocloud.guide/phase1). The full token is around **300+ characters**. If it isn't accepted, see [Completion token not accepted](../TROUBLESHOOTING.md#completion-token-not-accepted).

Save your token before cleaning up—destroying the lab deletes the VM and everything on it.

## Pause the Lab

If you want to pause the lab and reduce cost, stop the VM with the gcloud CLI. Use the same zone you deployed to (default `us-central1-a`).

Power off the VM:

```sh
gcloud compute instances stop ctf-instance --zone=YOUR_GCP_ZONE
```

Power on the VM:

```sh
gcloud compute instances start ctf-instance --zone=YOUR_GCP_ZONE
```

This lab uses an ephemeral public IP, so the IP may change after a restart. Look up the current IP:

```sh
gcloud compute instances describe ctf-instance \
  --zone=YOUR_GCP_ZONE \
  --format="value(networkInterfaces[0].accessConfigs[0].natIP)"
```

If you see a "Remote host identification has changed" warning after a restart, remove the old key, then reconnect:

```sh
# 1) Remove the old host key for that IP
ssh-keygen -R <public_ip_address>

# 2) Reconnect and accept the new key
ssh ctf_user@<public_ip_address>
```

> [!NOTE]
> `verify time` uses wall clock elapsed time. If the lab is stopped before you complete and export, stopped time still counts in elapsed time.

## Clean Up

Destroy the resources when you're done to avoid charges:

```sh
terraform destroy
```

Type `yes` when prompted.

## Troubleshooting

1. Ensure your gcloud CLI is authenticated
2. Check that you're using Terraform v1.9.0 or later
3. Verify you have permissions to create Compute Engine instances and firewall rules

See [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) for common issues. If problems persist, [open an issue](../TROUBLESHOOTING.md#getting-help--reporting-issues).

## Security Note

This lab uses password authentication for simplicity. In production, use key-based authentication.
