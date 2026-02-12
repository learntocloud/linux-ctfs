# Linux CTF - Copilot Instructions

This is an **educational Capture The Flag (CTF)** project designed to teach Linux command line skills. Learners SSH into a cloud VM to complete challenges - they don't interact with this repository directly.

**These instructions are for contributors and maintainers working on the codebase.**

## Project Structure

```
├── ctf_setup.sh              # VM setup script (creates all challenges)
├── README.md                 # Challenge descriptions for learners
├── aws/                      # AWS Terraform deployment
├── azure/                    # Azure Terraform deployment
├── gcp/                      # GCP Terraform deployment
└── .github/skills/           # Copilot agent skills for testing
```

## Working on Challenges

### Adding a New Challenge

1. Edit `ctf_setup.sh` to add the challenge setup logic
2. Update `README.md` with the challenge description
3. Add test commands to `.github/skills/ctf-testing/test_ctf_challenges.sh`

### Testing Challenges

- Run full test suite: `./.github/skills/ctf-testing/deploy_and_test.sh <provider>`
- Use the `ctf-testing` skill for deployment and validation
- Test scripts contain solution commands - keep them in `.github/skills/` only

### Flag Format

All flags follow the format `CTF{...}` and are defined in `ctf_setup.sh`.

## The `verify` Command

Learners use this command on the VM:

| Command | Description |
|---------|-------------|
| `verify progress` | Show completion progress |
| `verify [num] [flag]` | Submit a flag |
| `verify list` | List all challenges |
| `verify hint [num]` | Get a hint |
| `verify time` | Show elapsed time |
| `verify export <name>` | Export completion certificate |

## Terraform Deployments

Each cloud provider has its own directory with:
- `main.tf` - Infrastructure definition
- `README.md` - Provider-specific setup instructions

All providers use `ctf_setup.sh` as the VM startup script.
