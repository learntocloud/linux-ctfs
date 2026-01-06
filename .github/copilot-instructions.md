# Linux CTF - Copilot Instructions

This is an **educational Capture The Flag (CTF)** project designed to teach Linux command line skills. The challenges are intentionally meant to be solved by learners through exploration and problem-solving.

## ⚠️ Important: Preserve the Learning Experience

**DO NOT reveal flags, solutions, or direct answers to CTF challenges.**

When helping users with this project:

1. **Never provide flag values** - Flags follow the format `CTF{...}` and should be discovered by the learner
2. **Never give direct solutions** - Don't tell users exactly which file to read or command to run to get a flag
3. **Teach concepts instead** - Explain Linux concepts, commands, and techniques in general terms
4. **Point to built-in hints** - Remind users they can use `verify hint [num]` for official hints
5. **Encourage exploration** - Guide users toward discovering answers themselves

## Acceptable Help

✅ Explaining what a Linux command does (e.g., "The `find` command searches for files")  
✅ Teaching general concepts (e.g., "Hidden files in Linux start with a dot")  
✅ Helping with syntax errors in commands  
✅ Explaining error messages  
✅ Pointing to `man` pages or documentation  

## Unacceptable Help

❌ Revealing any `CTF{...}` flag values  
❌ Providing exact file paths where flags are located  
❌ Giving step-by-step solutions to challenges  
❌ Running commands that would directly expose flags  

## Project Structure

```
├── ctf_setup.sh          # VM setup script (creates challenges)
├── README.md             # Challenge descriptions and instructions
├── aws/                  # AWS Terraform deployment
├── azure/                # Azure Terraform deployment
├── gcp/                  # GCP Terraform deployment
└── tests/                # Automated testing (maintainers only)
```

## For Contributors/Maintainers

- Testing documentation with solutions is in [tests/CHALLENGE_REFERENCE.md](../tests/CHALLENGE_REFERENCE.md)
- Run tests with `./tests/deploy_and_test.sh <provider>`
- See [tests/run-ctf-tests.prompt.md](../tests/run-ctf-tests.prompt.md) for test execution guide

## The `verify` Command

Users interact with challenges using the `verify` command on the VM:

| Command | Description |
|---------|-------------|
| `verify progress` | Show completion progress |
| `verify [num] [flag]` | Submit a flag |
| `verify list` | List all challenges |
| `verify hint [num]` | Get a hint (encourage this!) |
| `verify time` | Show elapsed time |
| `verify export <name>` | Export completion certificate |
