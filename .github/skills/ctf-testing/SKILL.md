---
name: ctf-testing
description: Deploy and test Linux CTF challenges across cloud providers (AWS, Azure, GCP). Use when testing CTF setup, validating challenges work correctly, running the full test suite, verifying services survive VM reboots, or after creating new challenges with ctf-challenge-creator skill.
---

# CTF Challenge Testing

This skill deploys CTF infrastructure to cloud providers and validates all challenges work correctly.

**Often used after:** `ctf-challenge-creator` skill to verify new challenges work.

## Decision Tree: Which Provider?

```
What to test? → Testing new challenge locally first?
├─ Yes → Use Azure (fastest deploy, ~3 min)
│
└─ No → Full validation before release?
    ├─ Quick check → Pick one: aws | azure | gcp
    └─ Full release validation → Use "all" + --with-reboot
```

## When to Use

- Testing changes to `ctf_setup.sh`
- Validating challenge setup across AWS, Azure, or GCP
- Running the full test suite before releases
- Verifying services survive VM reboots

## Prerequisites

1. **terraform** (>= 1.0)
2. **sshpass** - Install on macOS: `brew install hudochenkov/sshpass/sshpass`
3. **Cloud CLI authenticated** for target provider:
   - AWS: `aws sts get-caller-identity`
   - Azure: `az account show`
   - GCP: `gcloud auth list --filter=status:ACTIVE`

## Running Tests

The scripts are black boxes - run with `--help` or use these commands:

```bash
./.github/skills/ctf-testing/deploy_and_test.sh <provider> [--with-reboot]
```

| Command | Description |
|---------|-------------|
| `deploy_and_test.sh aws` | Test AWS only (~15 min) |
| `deploy_and_test.sh azure` | Test Azure only (~15 min) |
| `deploy_and_test.sh gcp` | Test GCP only (~15 min) |
| `deploy_and_test.sh all` | Test all providers (~45 min) |
| `deploy_and_test.sh aws --with-reboot` | Test with reboot verification (~20 min) |

## Common Pitfalls

❌ **Don't** run tests without checking cloud CLI authentication first
✅ **Do** verify with `aws sts get-caller-identity` / `az account show` / `gcloud auth list`

❌ **Don't** forget to check for leftover resources after a failed run
✅ **Do** run the cleanup verification commands in "Post-Test Cleanup" section

❌ **Don't** run `all` for quick iteration - it takes 45+ minutes
✅ **Do** pick one provider (AWS is fastest) for development, `all` for releases

## What Gets Tested

1. **Verify command subcommands** - progress, list, hint, time, export
2. **Challenge setup** - Files exist, services running, permissions correct
3. **Solution commands** - Each challenge returns valid flag
4. **Flag submission** - All 19 flags accepted by `verify`
5. **Verification token system** - Instance secrets, token generation, token format validation
6. **Reboot resilience** (with `--with-reboot`) - Services restart, progress persists

## Expected Results

A successful run shows **~84 tests passing**, followed by a short summary:
- 7 verify subcommand tests
- 24 challenge setup verifications
- 19 solution command tests
- 20 flag verification tests
- 15 verification token tests

Summary line: `RESULT: PASS (<providers>)` or `RESULT: FAIL (<providers>)`

## Troubleshooting

### Setup not completing
- Check `/var/log/setup_complete` exists on VM
- Review cloud-init logs: `/var/log/cloud-init-output.log`

### Service not running
- Check status: `systemctl status <service-name>`
- Check logs: `journalctl -u <service-name>`

### Port not accessible externally
- Verify firewall rules in Terraform allow the port
- Check security group/NSG in cloud console

### SSH connection fails
- Wait longer for VM setup (~3-5 minutes after IP available)
- Verify security group allows port 22

## Post-Test Cleanup

Always verify resources were destroyed to avoid unexpected charges:

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

If resources remain, manually destroy:
```bash
cd <provider> && terraform destroy -auto-approve
```

## Scripts

Reference files - treat as black boxes, run directly:

- 📄 [deploy_and_test.sh](deploy_and_test.sh) - Orchestration script (runs locally)
- 📄 [test_ctf_challenges.sh](test_ctf_challenges.sh) - VM test script (copied to and runs on deployed VM)

## Related Skills

- **ctf-challenge-creator** - Create new challenges, then use this skill to validate
