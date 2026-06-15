# Contributing to Linux CTF

Thanks for helping improve Linux CTF. This guide covers what contributors need today to make, test, and submit changes.

## Before You Start

Open an issue before submitting a PR. This gives maintainers a chance to discuss the change before you spend time on it.

Open an issue for:

- New challenges
- Bug fixes in existing challenges
- Infrastructure changes
- Documentation updates

## What We Accept

Good contributions include:

- Challenge setup fixes
- Setup reliability improvements
- Cloud provider fixes or optimizations
- Clear documentation improvements

Do not contribute:

- Challenge solutions in learner-facing docs
- Extra hints beyond what `verify hint` provides
- Files that copy flags, answers, or solution commands
- Changes that make a challenge much easier unless the issue asks for that

Keep solution commands only in `.github/skills/ctf-testing/test_ctf_challenges.sh`.

## Pull Request Checklist

Before opening a PR:

1. Create a feature branch.
2. Make focused changes tied to an issue.
3. Run the relevant local checks.
4. Run a basic CTF test on at least one cloud provider.
5. Include the issue number, what you tested, and the result in the PR description.

## Local Checks

Run the checks that match the files you changed.

For setup or verify changes:

```bash
python3 -m compileall -q setup verify
bash -n ctf_setup.sh
shellcheck -S warning -e SC1091 -e SC2086 ctf_setup.sh .github/skills/ctf-testing/test_ctf_challenges.sh .github/skills/ctf-testing/deploy_and_test.sh
```

For Terraform changes:

```bash
terraform -chdir=aws fmt -check && terraform -chdir=aws validate
terraform -chdir=azure fmt -check && terraform -chdir=azure validate
terraform -chdir=gcp fmt -check && terraform -chdir=gcp validate
```

If you only changed one provider, you only need to run that provider's Terraform checks.

## Cloud Testing

All PRs that change setup, challenges, verify behavior, or Terraform should be tested on at least one cloud provider.

### Prerequisites

Install:

1. `terraform` 1.0 or newer; Azure requires Terraform 1.14.0 or newer
2. `jq`
3. `sshpass`
4. The cloud CLI for the provider you want to test

Check cloud authentication before running a test:

| Provider | Authentication check |
| --- | --- |
| AWS | `aws sts get-caller-identity` |
| Azure | `az account show` |
| GCP | `gcloud auth list --filter=status:ACTIVE` |

### Basic and Full Tests

The testing script uses contributor mode automatically. It uploads your local `ctf_setup.sh`, `setup/`, and `verify/` files to the VM, so it tests your working tree. It does not test GitHub Release assets.

| Test type | Command | Use when |
| --- | --- | --- |
| Basic AWS | `./.github/skills/ctf-testing/deploy_and_test.sh aws` | Testing normal challenge behavior on AWS |
| Basic Azure | `./.github/skills/ctf-testing/deploy_and_test.sh azure` | Testing normal challenge behavior on Azure |
| Basic GCP | `./.github/skills/ctf-testing/deploy_and_test.sh gcp` | Testing normal challenge behavior on GCP |
| Basic all providers | `./.github/skills/ctf-testing/deploy_and_test.sh all` | Checking all providers without reboot |
| Full AWS | `./.github/skills/ctf-testing/deploy_and_test.sh aws --with-reboot` | Testing AWS plus reboot behavior |
| Full Azure | `./.github/skills/ctf-testing/deploy_and_test.sh azure --with-reboot` | Testing Azure plus reboot behavior |
| Full GCP | `./.github/skills/ctf-testing/deploy_and_test.sh gcp --with-reboot` | Testing GCP plus reboot behavior |
| Full all providers | `./.github/skills/ctf-testing/deploy_and_test.sh all --with-reboot` | Release confidence across all providers |

Basic tests validate the `verify` command, all 18 challenges, export certificates, and verification tokens.

Full tests do everything in a basic test, then reboot the VM and check required services plus progress persistence.

If you use an AI coding assistant with skills, use prompts like:

- `Run a basic test on Azure`
- `Run a basic test on GCP`
- `Run a full test on AWS`
- `Run a full test on all providers`

See `.github/skills/ctf-testing/SKILL.md` for the agent workflow.

## Deployment Modes

Most contributors only need to know this:

- Normal learner deployments use release mode.
- Contributor testing uses local files.
- `deploy_and_test.sh` handles contributor mode for you.

Setup readiness differs by provider:

- Azure release mode uses VM Custom Script Extension (Terraform 1.14.0 or newer), so Terraform waits for extension success or failure.
- AWS release mode uses Systems Manager Run Command to run the shared marker readiness check.
- GCP release mode still uses the shared SSH marker wait.
- Contributor mode stays on `use_local_setup=true`, uploading local files over SSH for test runs.

If you manually run Terraform to test local setup changes, pass:

```bash
terraform apply -var use_local_setup=true
```

Release mode downloads a setup package from GitHub Releases. Testing release mode requires published release assets, so it is usually maintainer work.

## Troubleshooting

If setup fails on a VM, check:

```text
/var/lib/linux-ctfs/setup.failed
/var/log/ctf_setup.log
/var/log/cloud-init-output.log
```

If cloud cleanup fails, run `terraform destroy` from the provider directory and report any resources that remain.

## Questions

If you are unsure what to test or how to scope a change, open an issue and ask.
