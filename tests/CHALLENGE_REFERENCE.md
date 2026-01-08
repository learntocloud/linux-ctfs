# CTF Challenge Testing Reference

> **⚠️ SPOILER WARNING**: This file contains solution commands. For maintainers and automated testing only.

This document provides context for testing the Linux CTF challenges across AWS, GCP, and Azure.

## Overview

The CTF contains 18 challenges (plus 1 example) that test Linux command line skills. Each challenge has:
- A **dynamically generated flag** in format `CTF{descriptive_text_XXXXXXXX}` (unique per VM instance)
- A setup mechanism in `ctf_setup.sh`
- A solution command to retrieve the flag
- SHA256 hash validation via the `verify` command

## Dynamic Flag System

**Flags are generated at VM setup time** with a unique 8-character hex suffix. This means:
- Each VM instance has different flags
- Students cannot share answers between instances
- Looking at the GitHub repo reveals no flag values
- The `verify` command validates against hashes stored in `/etc/ctf/flag_hashes`

### Flag Format
- Example flag (static): `CTF{example}`
- Challenge flags (dynamic): `CTF{descriptive_text_XXXXXXXX}` where `XXXXXXXX` is random hex

## Challenge Reference

### Challenge 0: Example
- **Flag**: `CTF{example}` (static - for documentation purposes)
- **Test**: `verify 0 CTF{example}`

### Challenge 1: Hidden File Discovery
- **Flag Pattern**: `CTF{finding_hidden_treasures_XXXXXXXX}`
- **Location**: `/home/ctf_user/ctf_challenges/.hidden_flag`
- **Solution**: `cat /home/ctf_user/ctf_challenges/.hidden_flag`
- **Verify Setup**: `test -f /home/ctf_user/ctf_challenges/.hidden_flag`

### Challenge 2: Basic File Search
- **Flag Pattern**: `CTF{search_and_discover_XXXXXXXX}`
- **Location**: `/home/ctf_user/documents/projects/backup/secret_notes.txt`
- **Solution**: `cat /home/ctf_user/documents/projects/backup/secret_notes.txt`
- **Verify Setup**: `test -f /home/ctf_user/documents/projects/backup/secret_notes.txt`

### Challenge 3: Log Analysis
- **Flag Pattern**: `CTF{size_matters_in_linux_XXXXXXXX}`
- **Location**: `/var/log/large_log_file.log` (500MB file, flag at end)
- **Solution**: `tail -1 /var/log/large_log_file.log`
- **Verify Setup**: `test -f /var/log/large_log_file.log && test $(stat -c%s /var/log/large_log_file.log) -gt 100000000`

### Challenge 4: User Investigation
- **Flag Pattern**: `CTF{user_enumeration_expert_XXXXXXXX}`
- **Location**: `/home/flag_user/.profile`
- **User**: `flag_user` (UID 1002)
- **Solution**: `cat /home/flag_user/.profile`
- **Verify Setup**: `id flag_user && test -f /home/flag_user/.profile`

### Challenge 5: Permission Analysis
- **Flag Pattern**: `CTF{permission_sleuth_XXXXXXXX}`
- **Location**: `/opt/systems/config/system.conf` (chmod 777)
- **Solution**: `cat /opt/systems/config/system.conf`
- **Verify Setup**: `test -f /opt/systems/config/system.conf && test $(stat -c%a /opt/systems/config/system.conf) = "777"`

### Challenge 6: Service Discovery
- **Flag Pattern**: `CTF{network_detective_XXXXXXXX}`
- **Service**: `ctf-secret-service.service` on port 8080
- **Solution**: `curl -s localhost:8080`
- **Verify Setup**: `systemctl is-active ctf-secret-service.service && ss -tulpn | grep -q :8080`

### Challenge 7: Encoding Challenge
- **Flag Pattern**: `CTF{decoding_master_XXXXXXXX}`
- **Location**: `/home/ctf_user/ctf_challenges/encoded_flag.txt` (double base64)
- **Solution**: `cat /home/ctf_user/ctf_challenges/encoded_flag.txt | base64 -d | base64 -d`
- **Verify Setup**: `test -f /home/ctf_user/ctf_challenges/encoded_flag.txt`

### Challenge 8: SSH Secrets
- **Flag Pattern**: `CTF{ssh_security_master_XXXXXXXX}`
- **Location**: `/home/ctf_user/.ssh/secrets/backup/.authorized_keys`
- **Solution**: `cat /home/ctf_user/.ssh/secrets/backup/.authorized_keys`
- **Verify Setup**: `test -f /home/ctf_user/.ssh/secrets/backup/.authorized_keys`

### Challenge 9: DNS Troubleshooting
- **Flag Pattern**: `CTF{dns_name_XXXXXXXX}`
- **Location**: `/etc/resolv.conf` (appended to nameserver line)
- **Solution**: `grep -o 'CTF{[^}]*}' /etc/resolv.conf`
- **Verify Setup**: `grep -q 'CTF{' /etc/resolv.conf`

### Challenge 10: Remote Upload Detection
- **Flag Pattern**: `CTF{network_copy_XXXXXXXX}`
- **Service**: `ctf-monitor-directory.service` using inotifywait
- **Trigger**: Create any file in `/home/ctf_user/ctf_challenges`
- **Solution**: `touch /home/ctf_user/ctf_challenges/testfile && cat /tmp/.ctf_upload_triggered`
- **Verify Setup**: `systemctl is-active ctf-monitor-directory.service`

### Challenge 11: Web Configuration
- **Flag Pattern**: `CTF{web_config_XXXXXXXX}`
- **Location**: `/var/www/html/index.html`
- **Service**: nginx on port 8083
- **Solution**: `curl -s localhost:8083`
- **Verify Setup**: `systemctl is-active nginx && ss -tulpn | grep -q :8083`

### Challenge 12: Network Traffic Analysis
- **Flag Pattern**: `CTF{net_chat_XXXXXXXX}`
- **Service**: `ctf-ping-message.service` sending hex-encoded ping pattern
- **Solution**: Extract hex from `/usr/local/bin/ping_message.sh` and decode with `xxd -r -p`
- **Verify Setup**: `systemctl is-active ctf-ping-message.service`

### Challenge 13: Cron Job Hunter
- **Flag Pattern**: `CTF{cron_task_master_XXXXXXXX}`
- **Location**: `/etc/cron.d/ctf_secret_task`
- **Solution**: `grep -o 'CTF{[^}]*}' /etc/cron.d/ctf_secret_task`
- **Verify Setup**: `test -f /etc/cron.d/ctf_secret_task`

### Challenge 14: Process Environment
- **Flag Pattern**: `CTF{env_variable_hunter_XXXXXXXX}`
- **Service**: `ctf-secret-process.service`
- **Environment Variable**: `CTF_SECRET_FLAG`
- **Solution**: `cat /proc/$(pgrep -f ctf_secret_process)/environ | tr '\0' '\n' | grep -o 'CTF{[^}]*}'`
- **Verify Setup**: `systemctl is-active ctf-secret-process.service && pgrep -f ctf_secret_process`

### Challenge 15: Archive Archaeologist
- **Flag Pattern**: `CTF{archive_explorer_XXXXXXXX}`
- **Location**: `/home/ctf_user/ctf_challenges/mystery_archive.tar.gz` (triple nested)
- **Structure**: `mystery_archive.tar.gz` → `middle.tar.gz` → `inner.tar.gz` → `flag.txt`
- **Solution**: Extract all layers and read `flag.txt`
- **Verify Setup**: `test -f /home/ctf_user/ctf_challenges/mystery_archive.tar.gz`

### Challenge 16: Symbolic Sleuth
- **Flag Pattern**: `CTF{link_follower_XXXXXXXX}`
- **Location**: Chain starting at `/home/ctf_user/ctf_challenges/follow_me`
- **Solution**: `cat $(readlink -f /home/ctf_user/ctf_challenges/follow_me)`
- **Verify Setup**: `test -L /home/ctf_user/ctf_challenges/follow_me`

### Challenge 17: History Mystery
- **Flag Pattern**: `CTF{history_detective_XXXXXXXX}`
- **Location**: `/home/old_admin/.bash_history`
- **Solution**: `grep -o 'CTF{[^}]*}' /home/old_admin/.bash_history`
- **Verify Setup**: `test -f /home/old_admin/.bash_history`

### Challenge 18: Disk Detective
- **Flag Pattern**: `CTF{disk_detective_XXXXXXXX}`
- **Location**: Hidden file `.flag` inside `/opt/ctf_disk.img` (ext4 filesystem image)
- **Solution**: `sudo mount -o loop /opt/ctf_disk.img /mnt/ctf_disk && cat /mnt/ctf_disk/.flag`
- **Verify Setup**: `test -f /opt/ctf_disk.img`

## Services (Must Survive Reboot)

| Service Name | Challenge | Port | Purpose |
|-------------|-----------|------|---------|
| `ctf-secret-service.service` | 6 | 8080 | HTTP server returning flag |
| `ctf-monitor-directory.service` | 10 | N/A | inotifywait file monitor |
| `ctf-ping-message.service` | 12 | N/A | Ping with hex-encoded pattern |
| `ctf-secret-process.service` | 14 | N/A | Process with env variable |
| `nginx` | 11 | 8083 | Web server with flag |

## Verify Command Subcommands

| Command | Expected Behavior |
|---------|------------------|
| `verify 0 CTF{example}` | Returns "✓ Example flag verified!" |
| `verify progress` | Shows "Flags Found: X/18" |
| `verify list` | Shows all 19 challenges with checkmarks |
| `verify hint 1` | Shows hint for challenge 1 |
| `verify time` | Shows elapsed time or "Timer not started" |
| `verify export <name>` | Shows certificate if 18/18, else error message |

## Cloud Provider Firewall Ports

All providers must allow inbound traffic on:
- Port 22 (SSH)
- Port 80 (HTTP - for user testing)
- Port 8080 (Challenge 6 - hidden service)
- Port 8083 (Challenge 11 - nginx)

## Testing Scripts

### `tests/test_ctf_challenges.sh`
Runs on the VM to validate all challenges. Usage:
```bash
./test_ctf_challenges.sh [--with-reboot]
```

**Flags:**
- `--with-reboot`: After initial tests, creates a marker file and exits with code 100 to signal the orchestration script to reboot the VM. After reboot, re-run the script to verify services restarted and progress persisted.

### `tests/deploy_and_test.sh`
Orchestration script to deploy and test. Usage:
```bash
./deploy_and_test.sh <aws|azure|gcp|all> [--with-reboot]
```

**Prerequisites:**
- `terraform` (>= 1.0)
- `sshpass` (macOS: `brew install hudochenkov/sshpass/sshpass`)
- Provider CLI authenticated:
  - AWS: `aws` CLI configured
  - Azure: `az` CLI logged in
  - GCP: `gcloud` CLI authenticated

**What it does:**
1. Checks prerequisites
2. Runs `terraform apply` in provider directory
3. Waits for VM setup to complete
4. SCPs test script to VM
5. Runs tests via SSH with password auth
6. If `--with-reboot`: stops/starts VM via provider CLI, reconnects, re-runs verification
7. Runs `terraform destroy` on completion

## Expected Test Results

A successful test run should show:
- All 19 verify subcommand tests passing
- All 18 challenge setup verifications passing
- All 18 challenge solution commands returning correct flags
- All 18 flag submissions accepted by verify
- (If --with-reboot) All 5 services active after reboot
- (If --with-reboot) Progress file persisted

## Troubleshooting

### Setup not completing
- Check `/var/log/setup_complete` exists
- Review cloud-init logs: `/var/log/cloud-init-output.log`

### Service not running
- Check status: `systemctl status <service-name>`
- Check logs: `journalctl -u <service-name>`

### Port not accessible externally
- Verify firewall rules in Terraform allow the port
- Check security group/NSG in cloud console

### Verifying Resources Are Destroyed

After tests complete, verify all cloud resources were properly destroyed:

**AWS:**
```bash
aws ec2 describe-instances --filters "Name=tag:Name,Values=CTF*" "Name=instance-state-name,Values=running,pending,stopping,stopped" --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=CTF*" --query 'Vpcs[*].VpcId' --output table
```

**Azure:**
```bash
az group list --query "[?starts_with(name, 'ctf')].name" --output table
```

**GCP:**
```bash
gcloud compute instances list --filter="name~'ctf'" --format="table(name,zone,status)"
```

If any resources remain, run `terraform destroy -auto-approve` in the appropriate provider directory.
