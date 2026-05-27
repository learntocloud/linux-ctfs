---
name: ctf-testing
description: Deploy and test Linux CTF challenges across cloud providers (AWS, Azure, GCP). Use when running basic tests without reboot or full tests with reboot for CTF setup, challenge validation, and release confidence.
---

# CTF Challenge Testing

This skill deploys CTF infrastructure to cloud providers and validates that learners can complete the lab.

## When to Use

- Testing changes to `ctf_setup.sh`, `setup/`, or `verify/`
- Validating challenge setup across AWS, Azure, or GCP
- Running the full contributor-mode test suite before releases
- Verifying services survive VM reboots

## Trigger Examples

Use this skill when the user asks things like:

- "Run a basic test on Azure"
- "Run a basic test on GCP"
- "Run a basic test on AWS"
- "Run a full test on Azure"
- "Run a full test on GCP"
- "Run a full test on AWS"
- "Run a basic test on all providers"
- "Run a full test on all providers"

## Prerequisites

1. **terraform** (>= 1.0)
2. **jq** - Install: `sudo apt install jq` (Ubuntu) or `brew install jq` (macOS)
3. **sshpass** - Install on macOS: `brew install hudochenkov/sshpass/sshpass`
4. **Cloud CLI authenticated** for target provider:
   - AWS: `aws sts get-caller-identity`
   - Azure: `az account show`
   - GCP: `gcloud auth list --filter=status:ACTIVE`

## Agent Workflow

1. **Determine the mode and provider.**
   - Basic test means no reboot. Use this when the user asks for a basic test or does not mention reboot.
   - Full test means reboot. Use this when the user asks for a full test or asks to verify reboot behavior.
   - Provider must be `aws`, `azure`, `gcp`, or `all`. Azure is usually the fastest single-provider test.
2. **Check provider authentication before deploying.**
   - AWS: `aws sts get-caller-identity`
   - Azure: `az account show`
   - GCP: `gcloud auth list --filter=status:ACTIVE`
3. **Run the requested test from the repository root.**

   | User request | Command | What gets tested |
   | --- | --- | --- |
   | Basic test on AWS | `./.github/skills/ctf-testing/deploy_and_test.sh aws` | Verify command sanity checks, all 18 challenges, export certificate, token format, username, challenge count, and frozen completion time |
   | Basic test on Azure | `./.github/skills/ctf-testing/deploy_and_test.sh azure` | Verify command sanity checks, all 18 challenges, export certificate, token format, username, challenge count, and frozen completion time |
   | Basic test on GCP | `./.github/skills/ctf-testing/deploy_and_test.sh gcp` | Verify command sanity checks, all 18 challenges, export certificate, token format, username, challenge count, and frozen completion time |
   | Basic test on all providers | `./.github/skills/ctf-testing/deploy_and_test.sh all` | Same basic checks across AWS, Azure, and GCP |
   | Full test on AWS | `./.github/skills/ctf-testing/deploy_and_test.sh aws --with-reboot` | Basic checks plus reboot, required service checks, and progress persistence |
   | Full test on Azure | `./.github/skills/ctf-testing/deploy_and_test.sh azure --with-reboot` | Basic checks plus reboot, required service checks, and progress persistence |
   | Full test on GCP | `./.github/skills/ctf-testing/deploy_and_test.sh gcp --with-reboot` | Basic checks plus reboot, required service checks, and progress persistence |
   | Full test on all providers | `./.github/skills/ctf-testing/deploy_and_test.sh all --with-reboot` | Same full checks across AWS, Azure, and GCP |

   The deployment script uses contributor mode, so Terraform uploads the local setup package and runs the code from your working tree. It does not test GitHub Release assets.
4. **Treat cleanup as part of the test, not an optional follow-up.**
   - Verify no test resources remain after the script exits.
   - If resources remain, run provider-specific cleanup or `terraform destroy` from the provider directory.
   - If cleanup still fails, report the remaining resources clearly.
5. **Report the result plainly.**
   - Include provider, mode, pass/fail result, cleanup status, and blocker if any.
   - A successful basic run shows about 27 tests passing.
   - A successful full run includes a second pass after reboot with 5 service checks and 1 progress persistence check.
   - Summary line: `RESULT: PASS (<providers>)` or `RESULT: FAIL (<providers>)`.

## Failure Handling

When a run fails, identify the first failing layer:

| Failure point | What to collect |
| --- | --- |
| Terraform failed | Provider name and Terraform error |
| SSH failed | VM IP and SSH wait output |
| Setup failed | `/var/lib/linux-ctfs/setup.failed`, `/var/log/ctf_setup.log`, and `/var/log/cloud-init-output.log` |
| Challenge failed | Challenge number and failing test output |
| Reboot failed | Failed service name and `journalctl -u <service-name>` output |
| Cleanup failed | Remaining cloud resources |

## CTF Safety Rules

- Do not create committed solution files.
- Keep solution commands only in `.github/skills/ctf-testing/test_ctf_challenges.sh`.
- Do not add flags or challenge solutions to learner-facing docs.
- Do not make challenges easier while fixing tests.

## Scripts

Reference files - treat as black boxes, run directly:

- 📄 [deploy_and_test.sh](deploy_and_test.sh) - Orchestration script (runs locally)
- 📄 [test_ctf_challenges.sh](test_ctf_challenges.sh) - VM test script (copied to and runs on deployed VM)
