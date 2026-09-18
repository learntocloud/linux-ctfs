---
name: review-lab-maintenance
description: Review Linux CTF maintenance across AWS, Azure, and GCP. Use when asked to assess Terraform and provider compatibility, cloud CLI changes, Python and uv dependencies, image lifecycle, release delivery, or lab documentation drift. Produce an evidence-backed maintainer report without modifying files or cloud resources.
---

# Review Lab Maintenance

Review the lab for changes maintainers should investigate, not for ways to solve
the learner challenges. Default to all three clouds unless the user narrows scope.
Use this review for periodic maintenance or before releases; use `ctf-testing`
for separately authorized deployment and live challenge validation.

## Guardrails

- Report only. Do not edit files, upgrade or install dependencies, deploy or
  destroy infrastructure, change cloud resources, or create issues or PRs.
- Do not run setup, bootstrap, challenge test, or deployment scripts, or invoke
  the learner `verify` command. Inspect them as source; live verification
  requires a separately authorized task.
- Do not run Terraform init, plan, apply, or destroy, or authenticate to cloud
  accounts as part of this review. Keep local checks non-mutating.
- Preserve intentional challenge mechanics, permissions, and misconfigurations.
  Establish each challenge's intended behavior from the learner guide and
  implementation before flagging it as a problem. An unclear boundary is a
  question to investigate, not an instruction to fix it or make it easier.
- Do not reproduce flags, solution commands, or extra hints in reports or
  learner-facing documentation. Keep solution commands only in
  `.github/skills/ctf-testing/test_ctf_challenges.sh`.
- Do not inspect or disclose credentials, private keys, Terraform state, or
  generated completion tokens. Use public documentation queries without
  repository secrets or private code.
- Do not recommend an upgrade merely because a newer version exists. Explain
  the concrete compatibility, support, reliability, or learner-experience benefit.

## Review Process

1. Read the root `README.md`, `CONTRIBUTING.md`, and the selected providers'
   `README.md` files. Identify prerequisites, challenge requirements, the
   documented learner journey, and cleanup guidance. Use repository-relative
   paths, never machine-specific paths.
2. Inventory the selected providers' `main.tf` files, `ctf_setup.sh`, `setup/`,
   `verify/`, and `.github/workflows/`. Read the existing `ctf-testing` skill and
   inspect its scripts as source without executing them.
   Record declared version constraints and dependency sources, including Python,
   uv installation, Python build/runtime dependencies, OS packages, and images.
   Distinguish declared versions, unpinned dependencies, and versions that cannot
   be determined; do not assume an installed local tool represents a learner's
   environment.
3. Review the areas below against the actual implementation. Follow shared
   helpers and callers so a finding is not based on an isolated line.
4. Trace both deployment modes separately:
   - Learner release mode: release packaging and asset names, release selection,
     download and checksum handling, extraction, bootstrap, and readiness checks.
   - Contributor mode: local package creation, upload, bootstrap, readiness, and
     the behavior exercised by `ctf-testing`.
   Passing contributor-mode tests does not establish that published release
   assets or the learner release deployment path work. Inspect
   `.github/workflows/release-setup.yml` and provider consumers together.
5. Verify time-sensitive claims against current official documentation, release
   notes, migration guides, or lifecycle notices. Check applicability to the
   repository's version constraints, cloud, and configuration. Cite source URLs,
   relevant release or retirement dates, and the date checked. If sources are
   unavailable or inconclusive, disclose the gap instead of asserting a change.
6. Return the report in the conversation. Do not create a report file unless
   requested. Separate static evidence from behavior requiring live verification.

## Review Areas

| Area | Inspect |
|------|---------|
| Terraform | Terraform/provider constraints, deprecated resources and arguments, breaking changes applicable to allowed versions, resource wiring, and deployment/teardown assumptions. |
| Cloud CLIs | Commands and flags used by scripts and guides, authentication prerequisites, output parsing, pagination, exit handling, and documented CLI changes that affect these uses. |
| Dependencies | Local tools, VM image and OS support, package repositories, bootstrap packages and downloads, Python/uv compatibility, Python dependency constraints, architecture assumptions, and reproducibility. |
| Release delivery | Agreement between packaged contents and bootstrap expectations, release selection, checksums, failure propagation, readiness markers, and differences between release and contributor modes. |
| Challenge behavior | Whether `setup/` prepares the documented challenges, tests cover actual acceptance criteria without weakening them, and challenge services and required filesystem state survive reboot. |
| Verification | Whether `verify/`, learner documentation, and test expectations agree on challenge counts, progress, timer start/freeze behavior, persistence, username handling, and certificate/token format. Do not print tokens or flag values. |
| Documentation | Whether prerequisites, commands, paths, expected results, troubleshooting markers, and cleanup guidance agree with implementation. Compare clouds for unintended drift without requiring identical provider-specific designs. |
| Maintenance coverage | Whether CI and contributor checks cover changed languages and packaging, what the existing tests establish, and which release, reboot, or cleanup behaviors still require live verification. |

Trace setup through Terraform, bootstrap, Python provisioning, verification,
tests, and cleanup. Include provider-specific readiness mechanisms and shared
helpers rather than treating Terraform alone as the setup workflow. A successful
static check does not prove deployment, connectivity, challenge completion,
certificate generation, reboot persistence, or cleanup works.

## Report Format

Start with the review date, scope, and a short overall assessment. Then provide
only actionable findings, ordered by learner impact and urgency:

| Priority | Evidence status | Cloud or shared component | Finding and learner impact | Repository evidence | Official source | Suggested action |
|----------|-----------------|---------------------------|----------------------------|---------------------|-----------------|------------------|

- **Priority:** High for likely blockers or imminent support deadlines; Medium
  for credible reliability or maintenance risks; Low for minor documentation or
  maintainability issues. Explain the priority rather than relying on the label.
- **Evidence status:** Confirmed problem, upcoming lifecycle risk, or needs live
  verification. Use confirmed only when the available evidence establishes it.
- **Evidence:** Cite repository `path:line` references and applicable official
  URLs with dates. For purely internal inconsistencies, mark the official source
  as not applicable. Separate observed facts from inferred impact, and cite
  sensitive challenge logic by location without reproducing solutions.
- **Suggested action:** Give a bounded next step and how a maintainer could
  verify it. Do not silently turn the recommendation into an implementation.

Finish with coverage gaps: areas not reviewed, unavailable sources or tools, and
specific checks requiring an authorized live lab. Distinguish contributor-mode
checks available through `ctf-testing` from release-mode checks needing published
assets. If there are no actionable findings, say so; do not invent recommendations
to fill the table.
