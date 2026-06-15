---
name: Terraform deployment issue
about: Report errors during terraform init, plan, or apply
title: "[TERRAFORM] "
labels: bug, terraform
assignees: madebygps, rishabkumar7

---

**Cloud Provider:**
- [ ] AWS
- [ ] Azure
- [ ] GCP

**System information:**
- OS: [e.g. macOS, Windows, Linux]
- Terraform Version: [run `terraform version`]
- Cloud CLI Version: [run `aws --version`, `az version`, or `gcloud version`]

**Which Terraform command failed?**
- [ ] `terraform init`
- [ ] `terraform plan`
- [ ] `terraform apply`
- [ ] `terraform destroy`

**Error message**
Paste the full error output below:
```
<paste error here>
```

**Region/Zone used** (if applicable):
[e.g. eastus, us-east-1, us-central1-a]

**VM Size/Instance Type** (if you changed the default):
[e.g. Standard_B1s, t2.micro, e2-micro]

**Have you tried:**
- [ ] Running `terraform init -upgrade`
- [ ] Checking your cloud provider quotas/limits
- [ ] Trying a different region
