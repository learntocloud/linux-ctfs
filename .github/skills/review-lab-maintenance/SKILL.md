---
name: review-lab-maintenance
description: Check the Linux CTF for version and deprecation drift across AWS, Azure, and GCP. Use when asked whether Terraform, providers, cloud CLI commands, base VM images, or Python/uv pins need upgrading. Produce a short evidence-backed drift report without modifying files or cloud resources.
---

# Review Lab Maintenance

Answer one question: **does anything pinned in this repository need to be
upgraded or changed?** Cover Terraform and providers, cloud CLI commands, base
VM images, and Python/uv. Default to all three clouds unless the user narrows
scope.

This is a drift check, not an audit. Challenge correctness, verification logic,
release packaging, and documentation accuracy are out of scope — use
`ctf-testing` for live validation of those.

## Guardrails

- Report only. Do not edit files, upgrade dependencies, run Terraform
  (`init`/`plan`/`apply`/`destroy`), authenticate to any cloud, or run setup,
  bootstrap, or test scripts. Read them as source.
- Do not recommend an upgrade merely because a newer version exists. Every
  recommendation needs a concrete reason: a breaking change in the allowed
  range, a removed or deprecated CLI command, an end-of-support date, or a
  fixed bug that affects this lab.
- Do not reproduce flags or solution commands from `setup/` or
  `.github/skills/ctf-testing/test_ctf_challenges.sh`.

## Step 1 — Read the current pins

Read every surface below from the repository and record the literal pin you
find. This table is a map of where pins live, not a record of their values;
read the current value each time. Line numbers drift, so search for the field
rather than jumping to a line.

A surface that turns out to be unpinned, or a provider used but never declared
in `required_providers`, is itself worth reporting.

| Surface | What to read |
|---------|--------------|
| Terraform core | `required_version` in the `terraform` block of each provider's `main.tf` |
| Providers | every entry in `required_providers` across `aws/`, `azure/`, and `gcp/main.tf`, plus any provider referenced by a resource but not declared |
| Azure VM extension | `type_handler_version` on the `azurerm_virtual_machine_extension` resource |
| Base image (AWS) | the `name` filter on the `aws_ami` data source |
| Base image (Azure) | `source_image_reference` publisher, offer, sku, and version |
| Base image (GCP) | the boot disk `image` in `gcp/main.tf` |
| Python | `requires-python` in `setup/pyproject.toml` and `verify/pyproject.toml` |
| Python runtime install | the version passed to `uv python install` and `--python` in `ctf_setup.sh` |
| uv | how `ctf_setup.sh` installs uv, and whether that installer is pinned |
| Python deps | the `dependencies` list in `verify/pyproject.toml` |
| CI actions | `uses:` refs in `.github/workflows/*.yml`, and whether they are SHA-pinned |

Also collect every `aws`, `az`, and `gcloud` invocation from the provider
`README.md` files, `TROUBLESHOOTING.md`, and any shell scripts. These are the
commands a learner actually runs.

## Step 2 — Look up current versions

Use deterministic sources, not recollection. Record the date checked.

```bash
# Terraform core
gh api repos/hashicorp/terraform/releases/latest --jq .tag_name

# Providers (substitute each provider source found in Step 1)
curl -s https://registry.terraform.io/v1/providers/hashicorp/aws | jq -r .version

# Python deps (substitute each dependency found in Step 1)
curl -s https://pypi.org/pypi/rich/json | jq -r .info.version
```

For anything without an API, use the official changelog or lifecycle page:
provider `CHANGELOG.md` on GitHub, the Ubuntu release cycle page for whichever
LTS the images pin, and the AWS CLI, Azure CLI, and gcloud release notes for
removed or deprecated commands and flags.

## Step 3 — Decide whether the gap matters

For each surface where the pin trails current, check whether the delta actually
affects this lab:

- **Terraform and providers:** does the allowed range already admit the new
  version? A `~>` or `>=` constraint that silently picks up a major release with
  breaking changes is more urgent than a trailing lower bound. Check the
  provider changelog for breaking changes, removed arguments, and deprecations
  touching the resources this repo declares.
- **Cloud CLIs:** has a command, subcommand, flag, or output field used in the
  READMEs been removed, renamed, or deprecated? An unchanged command is a
  non-finding.
- **Base images:** is the pinned Ubuntu LTS still in standard support, and do
  the image names and filters still resolve? Note upcoming end-of-support dates.
- **Python and uv:** is the pinned Python still supported, and do the dependency
  lower bounds still install cleanly on it?

Anything you cannot determine is a coverage gap, not a finding.

## Report Format

Open with the date checked and a one-line verdict. **If nothing needs changing,
say so and stop** — do not pad the table.

Then one row per surface that needs action:

| Priority | Surface | Current pin | Current release | Why it matters | Evidence | Suggested action |
|----------|---------|-------------|-----------------|----------------|----------|------------------|

- **Priority:** High for a breaking change already admitted by the constraint, a
  removed CLI command, or a support deadline inside 6 months. Medium for a
  trailing pin with a concrete benefit. Low for cosmetic or maintainability
  drift.
- **Evidence:** repository `path:line` plus the official URL and its date.
- **Suggested action:** the bounded edit, and how to verify it — typically a
  `terraform plan` or a `ctf-testing` run, which this skill does not perform.

Close with anything you could not check and why.
