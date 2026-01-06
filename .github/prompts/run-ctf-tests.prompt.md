---
agent: agent
---
# Run CTF Challenge Tests

Execute the CTF challenge test suite to validate all 18 challenges work correctly across cloud providers.

## Instructions

1. First, check prerequisites are installed by running:
   ```
   command -v terraform && command -v sshpass && echo "Prerequisites OK"
   ```

2. Verify cloud CLI authentication for the target provider:
   - **AWS**: `aws sts get-caller-identity`
   - **Azure**: `az account show`
   - **GCP**: `gcloud auth list --filter=status:ACTIVE`

3. Run the deploy and test script from the repository root:
   ```
   ./tests/deploy_and_test.sh <provider> [--with-reboot]
   ```

   Where `<provider>` is one of: `aws`, `azure`, `gcp`, or `all`

4. The script will:
   - Deploy infrastructure with Terraform
   - Wait for VM setup to complete
   - SSH into the VM and run all challenge tests
   - If `--with-reboot`: reboot VM and verify services/progress persist
   - Destroy infrastructure on completion

## Test Options

| Command | Description |
|---------|-------------|
| `./tests/deploy_and_test.sh aws` | Test AWS only (~20 min) |
| `./tests/deploy_and_test.sh azure` | Test Azure only (~20 min) |
| `./tests/deploy_and_test.sh gcp` | Test GCP only (~20 min) |
| `./tests/deploy_and_test.sh all` | Test all providers sequentially (~60 min) |
| `./tests/deploy_and_test.sh aws --with-reboot` | Test AWS with reboot verification (~30 min) |
| `./tests/deploy_and_test.sh all --with-reboot` | Full test suite (~90 min) |

## What Gets Tested

1. **Verify command subcommands**: progress, list, hint, time, export
2. **Challenge setup verification**: Files exist, services running, permissions correct
3. **Solution commands**: Each challenge's solution returns the correct flag
4. **Flag submission**: All 18 flags accepted by `verify` command
5. **Reboot resilience** (with `--with-reboot`): Services restart, progress persists

## Expected Output

A successful run shows:
- All verify subcommand tests passing
- All 18 challenge setups verified
- All 18 solution commands returning correct flags
- All 18 flags accepted by verify
- Final "All tests passed!" message

## Troubleshooting

If tests fail:
- Check the specific challenge that failed in the output
- SSH into the VM manually: `ssh ctf_user@<ip>` (password: `CTFpassword123!`)
- Review service status: `systemctl status <service-name>`
- Check setup logs: `cat /var/log/cloud-init-output.log`
