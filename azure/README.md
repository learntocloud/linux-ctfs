# Linux Command Line CTF Lab - Azure

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

1. [Terraform](https://developer.hashicorp.com/terraform/install) (v1.14.0 or later)
2. [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
3. An Azure account with an active subscription

> [!NOTE]  
> If you have an Azure Student account, you may encounter errors. See [this workaround](https://github.com/g-now-zero/l2c-guides/blob/main/posts/ctf-azure-spot-instances-guide.md).

## Deploy the Lab

1. Fork this repository.

2. Clone your fork:

    ```sh
    git clone https://github.com/<your-github-username>/linux-ctfs
    cd linux-ctfs/azure
    ```

3. Log in to Azure:

    ```sh
    az login
    ```

4. Initialize and apply Terraform:

    ```sh
    terraform init
    terraform apply \
      -var subscription_id="YOUR_AZURE_SUBSCRIPTION_ID" \
      -var az_region="YOUR_AZURE_REGION"
    ```

    Replace the values with your subscription ID and preferred region (defaults to East US).

    Type `yes` when prompted.

    If you run into errors when deploying, see [TROUBLESHOOTING.md](../TROUBLESHOOTING.md#azure) for common issues and fixes.

5. Note the `public_ip_address` output—you'll use this to connect.

### VM Size / Capacity Errors

If `terraform apply` fails with `SkuNotAvailable` or quota/capacity errors, the fastest fix is usually switching region and/or VM size.

Defaults for this lab:
- Region: `East US` (`az_region`)
- VM size: `Standard_B1s` (`azure_vm_size`)

Use the full Azure troubleshooting steps here:
- [Azure: SkuNotAvailable / Capacity errors](../TROUBLESHOOTING.md#azure-skunotavailable--capacity-errors)
- [Azure: Quota limit errors](../TROUBLESHOOTING.md#azure-quota-limit-errors)

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

Save the token it prints—you'll need it to verify your progress at [learntocloud.guide/phase1](https://learntocloud.guide/phase1). The full token is around **300+ characters**. If it isn't accepted, see [Completion token not accepted](../TROUBLESHOOTING.md#completion-token-not-accepted).

Save your token before cleaning up—destroying the lab deletes the VM and everything on it.

## Pause the Lab

If you want to pause the lab and reduce cost, use these commands.

Power off the VM:

```sh
terraform apply -invoke=action.azurerm_virtual_machine_power.ctf_power_off
```

Type `yes` when prompted.

Power on the VM:

```sh
terraform apply -invoke=action.azurerm_virtual_machine_power.ctf_power_on
```

Type `yes` when prompted.

Connect again:

```sh
ssh ctf_user@<public_ip_address>
```

> [!NOTE]
> `verify time` uses wall clock elapsed time. If the lab is powered off before you complete and export, powered-off time still counts in elapsed time.

## Clean Up

Destroy the resources when you're done to avoid charges:

```sh
terraform destroy
```

Type `yes` when prompted.

## Troubleshooting

1. Ensure your Azure CLI is logged in with valid credentials
2. Check that you're using Terraform v1.14.0 or later
3. Verify you have permissions to create VMs, VNets, and Network Security Groups

If release setup fails during `terraform apply`, Azure reports the failure through the VM Custom Script Extension. Useful VM-side logs are:

```text
/var/log/ctf_setup.log
/var/log/waagent.log
/var/log/azure/custom-script/handler.log
```

For SKU, capacity, and quota errors, see the [Azure section of TROUBLESHOOTING.md](../TROUBLESHOOTING.md#azure). If problems persist, [open an issue](../TROUBLESHOOTING.md#getting-help--reporting-issues).

## Security Note

This lab uses password authentication for simplicity. In production, use key-based authentication.
