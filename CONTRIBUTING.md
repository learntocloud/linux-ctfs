# Contributing to Linux CTF

Thank you for your interest in contributing! This guide will help you get started.

## Before You Start

**Please open an issue before submitting a PR.** This lets us discuss the proposed changes and ensure they align with the project goals. This applies to:

- New challenges
- Bug fixes in existing challenges
- Infrastructure changes
- Documentation improvements

## What We Accept

✅ Bug fixes for challenge infrastructure  
✅ Improvements to setup reliability  
✅ Cloud provider optimizations  
✅ Documentation clarifications  

❌ Challenge solutions or hints beyond what `verify hint` provides  
❌ Changes that make challenges significantly easier  

## Testing Requirements

**All tests must pass before submitting a PR.** You must verify your changes work on at least one cloud provider.

### Prerequisites

1. **Terraform** (>= 1.0)
2. **sshpass**
   - macOS: `brew install hudochenkov/sshpass/sshpass`
   - Linux: `apt install sshpass` or `yum install sshpass`
   - Windows: Use WSL (Windows Subsystem for Linux)
3. **Cloud CLI** authenticated for your chosen provider:

| Provider | Verify Authentication |
|----------|----------------------|
| AWS | `aws sts get-caller-identity` |
| Azure | `az account show` |
| GCP | `gcloud auth list --filter=status:ACTIVE` |

### Running Tests

#### Option 1: Using an AI Coding Assistant (Recommended)

If you use an AI coding assistant with agent/tool capabilities:

| Tool | How to Test |
|------|-------------|
| GitHub Copilot (VS Code) | Open Chat in agent mode, prompt: `Test the AWS lab` |
| Claude Code | Prompt: `Test the AWS lab` |
| Cursor, Windsurf, etc. | Use agent mode and prompt: `Test the AWS lab` |

Replace `AWS` with `Azure` or `GCP` as needed. The AI will use the CTF testing skill to deploy, test, and clean up.

#### Option 2: Manual

Run from the repository root:

```bash
./.github/skills/ctf-testing/deploy_and_test.sh <provider>
```

Examples:
```bash
./.github/skills/ctf-testing/deploy_and_test.sh aws
./.github/skills/ctf-testing/deploy_and_test.sh azure
./.github/skills/ctf-testing/deploy_and_test.sh gcp
```

For thorough testing (includes reboot verification):
```bash
./.github/skills/ctf-testing/deploy_and_test.sh aws --with-reboot
```

### What Gets Tested

- All 18 challenges are properly set up
- Services are running and accessible
- Flags can be discovered and submitted
- Progress tracking works
- (With `--with-reboot`) Services survive VM restart

See [.github/skills/ctf-testing/SKILL.md](.github/skills/ctf-testing/SKILL.md) for detailed documentation.

## Pull Request Process

1. **Open an issue first** to discuss your proposed changes
2. **Fork the repository** and create a feature branch
3. **Make your changes** with clear, descriptive commits
4. **Run tests** on at least one cloud provider
5. **Submit your PR** referencing the issue number
6. **Respond to feedback** from maintainers

## Code Style

- Shell scripts should pass `shellcheck`
- Terraform should be formatted with `terraform fmt`
- Use descriptive variable and function names
- Add comments for non-obvious logic

## Questions?

If you're unsure about anything, open an issue and ask. We're happy to help!
